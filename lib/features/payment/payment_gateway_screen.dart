import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/router.dart';
import '../../core/api/cashfree_api.dart';
import '../../core/services/auth_provider.dart';
import '../../core/storage/local_storage.dart';
import 'cashfree_helper.dart';

class PaymentGatewayScreen extends ConsumerStatefulWidget {
  final String paymentSessionId;
  final String orderId;

  const PaymentGatewayScreen({
    super.key,
    required this.paymentSessionId,
    this.orderId = '',
  });

  @override
  ConsumerState<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends ConsumerState<PaymentGatewayScreen> {
  String? _checkoutHtml;
  bool _loading = true;
  String _statusMessage = 'Preparing payment...';
  bool _checkoutOpened = false;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  WebViewController? _webViewController;
  static const _maxPollAttempts = 120;
  static const _pollInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _checkoutHtml = CashfreeHelper.getCheckoutHtml(widget.paymentSessionId);
    if (_checkoutHtml == null) {
      _loadSdkAndOpenCheckout();
    } else {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String get _sabbpeOrderId {
    try {
      final stored = LocalStorageService.getAugmontOrderReferences();
      if (stored != null && stored.isNotEmpty) {
        final data = jsonDecode(stored) as Map<String, dynamic>;
        return data['sabbpeOrderId']?.toString() ?? widget.orderId;
      }
    } catch (_) {}
    return widget.orderId;
  }

  void _loadSdkAndOpenCheckout() {
    CashfreeHelper.loadSdkAndOpenCheckout(
      paymentSessionId: widget.paymentSessionId,
      onReady: () {
        if (mounted) {
          setState(() {
            _loading = false;
            _statusMessage = 'Payment window opened. Complete your payment.';
          });
        }
        _startPolling();
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _loading = false;
            _statusMessage = error;
          });
        }
        _startPolling();
      },
    );
    _checkoutOpened = true;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (mounted) {
      setState(() {
        _loading = false;
        _checkoutOpened = true;
        _statusMessage = 'Checking payment status...';
      });
    }
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    _pollAttempts++;
    try {
      final api = CashfreeApi(ref.read(dioAugmontProvider));
      final status = await api.checkPaymentStatus(_sabbpeOrderId);
      if (!mounted) return;

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

  void _goToReturn() {
    if (mounted) {
      context.go(AppRoutes.paymentReturn, extra: {
        'orderId': widget.orderId,
      });
    }
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
          onPressed: _goToReturn,
        ),
      ),
      body: _checkoutHtml != null ? _buildWebView() : _buildStatusView(),
    );
  }

  Widget _buildWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) async {
          final url = request.url;
          if (url.contains('/payment/return') || url.contains('payment_return') || url.contains('payment/return')) {
            final uri = Uri.parse(url);
            final orderId = uri.queryParameters['order_id'] ?? uri.queryParameters['order_id'] ?? '';
            if (orderId.isNotEmpty) {
              _pollTimer?.cancel();
              if (mounted) {
                context.go(AppRoutes.paymentReturn, extra: {'orderId': orderId});
              }
              return NavigationDecision.prevent;
            }
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadHtmlString(_checkoutHtml!);
    _webViewController = controller;
    return WebViewWidget(controller: controller);
  }

  Widget _buildStatusView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading) ...[
              const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFFF7CD57))),
              const SizedBox(height: 20),
            ],
            const Icon(Icons.payment, size: 64, color: Color(0xFFF7CD57)),
            const SizedBox(height: 16),
            const Text('Payment Gateway', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9E9A94), fontSize: 13),
            ),
            if (!_loading && !_checkoutOpened) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    gradient: const LinearGradient(colors: [Color(0xFFFED45C), Color(0xFFDB9502)]),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: _loadSdkAndOpenCheckout,
                      child: const Center(child: Text('Retry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black))),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
