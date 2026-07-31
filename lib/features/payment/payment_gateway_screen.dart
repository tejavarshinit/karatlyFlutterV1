import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/cashfree_api.dart';
import '../../core/api/config.dart';
import '../../core/models/payment_model.dart';
import '../../core/services/auth_provider.dart';
import '../../core/storage/local_storage.dart';

class PaymentGatewayScreen extends ConsumerStatefulWidget {
  final String paymentSessionId;
  final String orderId;
  final double paymentAmount;
  final Map<String, dynamic>? paymentRequest;

  const PaymentGatewayScreen({
    super.key,
    required this.paymentSessionId,
    this.orderId = '',
    this.paymentAmount = 0,
    this.paymentRequest,
  });

  @override
  ConsumerState<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends ConsumerState<PaymentGatewayScreen> {
  static const _methodChannel = MethodChannel('custom_webview_channel');

  bool _loading = true;
  String _statusMessage = 'Preparing payment...';
  String _checkoutUrl = '';
  Timer? _pollTimer;
  int _pollAttempts = 0;
  String _activeOrderId = '';
  String _activePaymentSessionId = '';
  bool _completed = false;
  static const _maxPollAttempts = 120;
  static const _pollInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _methodChannel.setMethodCallHandler(_handleMethodCall);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCheckout());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _methodChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onReturn') {
      // WebView detected the return URL — payment finished.
      final returnUrl = call.arguments?.toString() ?? '';
      debugPrint('[FLOW] METHOD_CHANNEL onReturn | url=$returnUrl');
      String? orderId;
      try {
        final uri = Uri.parse(returnUrl);
        // Handle both "?order_id=" and "??order_id=" (double ? from backend config)
        final fromQuery = uri.queryParameters['order_id'] ?? uri.queryParameters['?order_id'];
        if (fromQuery != null && fromQuery.isNotEmpty) {
          orderId = fromQuery;
        } else {
          final match = RegExp(r'[?&]order_id=([^&]+)').firstMatch(returnUrl);
          if (match != null) orderId = Uri.decodeComponent(match.group(1) ?? '');
        }
      } catch (_) {}
      debugPrint('[FLOW] onReturn extracted orderId=$orderId | activeOrderId=$_activeOrderId');
      if (mounted) _goToReturn(orderId: orderId);
    }
  }

  String get _sabbpeOrderId {
    if (_activeOrderId.isNotEmpty) return _activeOrderId;
    try {
      final stored = LocalStorageService.getAugmontOrderReferences();
      if (stored != null && stored.isNotEmpty) {
        final data = jsonDecode(stored) as Map<String, dynamic>;
        return data['sabbpeOrderId']?.toString() ?? widget.orderId;
      }
    } catch (_) {}
    return widget.orderId;
  }

  Future<void> _initCheckout() async {
    debugPrint('[FLOW] PaymentGatewayScreen._initCheckout | widget.orderId=${widget.orderId} session=${widget.paymentSessionId}');
    try {
      final sessionResult = await _resolvePaymentSession();
      if (!mounted) return;

      _activePaymentSessionId = sessionResult.sessionId;
      if (sessionResult.orderId.isNotEmpty) {
        _activeOrderId = sessionResult.orderId;
      }
      debugPrint('[FLOW] checkout resolved | orderId=$_activeOrderId sessionId=$_activePaymentSessionId');

      if (sessionResult.sessionId.isEmpty) {
        throw Exception('Payment session ID is missing.');
      }

      final url = '${ApiConfig.cashfreeHostedCheckoutUrl}?paymentSessionId=${sessionResult.sessionId}';
      debugPrint('[FLOW] loading WebView url=$url');

      if (!mounted) return;
      setState(() {
        _checkoutUrl = url;
        _loading = false;
        _statusMessage = 'Complete payment in the secure window.';
      });

      _startPolling();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusMessage = 'Could not open payment.';
      });
    }
  }

  Future<_CheckoutSessionResult> _resolvePaymentSession() async {
    // Use the session & order created by EmbeddedPaymentGateway — do NOT re-create,
    // otherwise a second order is created and the status lookup mismatches.
    return _CheckoutSessionResult(
      sessionId: widget.paymentSessionId,
      orderId: widget.orderId,
    );
  }

  void _startPolling() {
    _pollTimer?.cancel();
    setState(() => _statusMessage = 'Checking payment status...');
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    if (_completed) return;
    _pollAttempts++;
    try {
      final api = CashfreeApi(ref.read(dioAugmontProvider));
      final status = await api.checkPaymentStatus(_sabbpeOrderId);
      if (!mounted) return;

      debugPrint('[FLOW] poll #$_pollAttempts order=$_sabbpeOrderId | paymentStatus=${status.paymentStatus} orderStatus=${status.orderStatus}');

      final ps = status.paymentStatus.toUpperCase();
      if (ps == 'SUCCESS' || ps == 'FAILED' || ps == 'CANCELLED' || ps == 'USER_DROPPED') {
        _pollTimer?.cancel();
        _goToReturn();
        return;
      }
      if (_pollAttempts >= _maxPollAttempts) {
        _pollTimer?.cancel();
        if (mounted) _goToReturn();
        return;
      }
    } catch (_) {}
  }

  void _goToReturn({String? orderId}) {
    _pollTimer?.cancel();
    if (!mounted || _completed) return;
    debugPrint('[FLOW] _goToReturn called | orderId=$orderId activeOrderId=$_activeOrderId completed=$_completed');
    _completed = true;
    if (orderId != null && orderId.isNotEmpty) {
      _activeOrderId = orderId;
    }
    // 1. Destroy the WebView first (unmount AndroidView) so the frozen
    //    Cashfree page disappears from screen.
    setState(() => _checkoutUrl = '');
    // 2. Wait two frames for the platform view to actually dispose.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('[FLOW] navigating to paymentReturn | orderId=$_activeOrderId');
          context.go(AppRoutes.paymentReturn, extra: {
            'orderId': _activeOrderId.isNotEmpty ? _activeOrderId : widget.orderId,
          });
        }
      });
    });
  }

  Future<void> _closePayment() async {
    _pollTimer?.cancel();
    debugPrint('[FLOW] _closePayment (cross button) | completed=$_completed orderId=$_activeOrderId');
    _completed = true;
    setState(() => _checkoutUrl = '');
    // Check payment status first — if payment succeeded, show the result page.
    String targetOrder = _activeOrderId.isNotEmpty ? _activeOrderId : widget.orderId;
    bool paid = false;
    if (targetOrder.isNotEmpty) {
      try {
        final api = CashfreeApi(ref.read(dioAugmontProvider));
        final status = await api.checkPaymentStatus(targetOrder);
        final ps = status.paymentStatus.toUpperCase();
        final os = status.orderStatus.toUpperCase();
        paid = ps == 'SUCCESS' || os == 'PAID';
        debugPrint('[FLOW] cross check status | paymentStatus=$ps orderStatus=$os paid=$paid');
      } catch (_) {}
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (paid) {
          debugPrint('[FLOW] cross → payment paid, going to result page');
          context.go(AppRoutes.paymentReturn, extra: {'orderId': targetOrder});
        } else {
          debugPrint('[FLOW] cross → not paid, going home');
          context.go(AppRoutes.home);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1918),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1918),
        automaticallyImplyLeading: false,
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _closePayment,
        ),
      ),
      body: _loading ? _buildLoadingView() : _buildWebView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFFF7CD57))),
            const SizedBox(height: 20),
            Text(_statusMessage, style: const TextStyle(color: Color(0xFF9E9A94), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    if (_checkoutUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_statusMessage, style: const TextStyle(color: Color(0xFF9E9A94), fontSize: 13)),
          ],
        ),
      );
    }

    return AndroidView(
      viewType: 'custom_webview',
      creationParams: {'webUrl': _checkoutUrl},
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

class _CheckoutSessionResult {
  final String sessionId;
  final String orderId;

  const _CheckoutSessionResult({
    required this.sessionId,
    required this.orderId,
  });
}
