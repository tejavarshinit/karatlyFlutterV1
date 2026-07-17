import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/augmont_api.dart';
import '../../core/api/cashfree_api.dart';
import '../../core/services/auth_provider.dart';
import '../../core/storage/local_storage.dart';

class PaymentReturnScreen extends ConsumerStatefulWidget {
  final String orderId;
  const PaymentReturnScreen({super.key, required this.orderId});

  @override
  ConsumerState<PaymentReturnScreen> createState() => _PaymentReturnScreenState();
}

class _PaymentReturnScreenState extends ConsumerState<PaymentReturnScreen> {
  bool _loading = true;
  bool _success = false;
  bool _pending = false;
  String _paymentStatusRaw = '';
  String _message = 'Verifying your payment...';
  String _statusCode = '';
  String _orderId = '';
  String _sabbpeOrderId = '';
  String _merchantOrderId = '';
  String _metalType = 'gold';
  String _sku = '';
  String _flowType = 'DIGITAL_BUY';
  String _uniqueId = '';
  bool _isRedemption = false;

  @override
  void initState() {
    super.initState();
    _loadContext();
    _check();
  }

  void _loadContext() {
    try {
      final raw = LocalStorageService.getAugmontOrderReferences();
      if (raw != null && raw.isNotEmpty) {
        final ctx = Map<String, dynamic>.from(
          (const JsonDecoder().convert(raw) as Map<String, dynamic>?) ?? {},
        );
        _metalType = ctx['metalType']?.toString() ?? 'gold';
        _sabbpeOrderId = ctx['sabbpeOrderId']?.toString() ?? '';
        _merchantOrderId = ctx['merchantOrderId']?.toString() ?? '';
        _sku = ctx['sku']?.toString() ?? '';
        _flowType = ctx['flowType']?.toString() ?? 'DIGITAL_BUY';
        _isRedemption = _flowType == 'PHYSICAL_REDEMPTION' || _sku.isNotEmpty;
      }
    } catch (_) {}
    _orderId = _sabbpeOrderId.isNotEmpty ? _sabbpeOrderId : widget.orderId;

    final profile = LocalStorageService.getUserProfile();
    _uniqueId = profile?['uniqueId']?.toString().trim() ?? LocalStorageService.getUserUniqueId() ?? '';
  }

  Future<void> _check() async {
    if (_orderId.isEmpty) {
      if (!mounted) return;
      setState(() { _loading = false; _message = 'No order ID found.'; });
      return;
    }

    try {
      final api = CashfreeApi(ref.read(dioAugmontProvider));
      final status = await api.checkPaymentStatus(_orderId);
      if (!mounted) return;

      final ps = status.paymentStatus.toUpperCase();
      final os = status.orderStatus.toUpperCase();
      _paymentStatusRaw = ps.isNotEmpty ? ps : os;
      _success = ps == 'SUCCESS' || os == 'PAID';
      _pending = ps == 'PENDING' || ps == 'USER_DROPPED';

      if (_success) {
        await _verifyWithAugmont();
      } else {
        setState(() {
          _loading = false;
          _statusCode = _paymentStatusRaw;
          _message = _buildStatusMessage();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _message = 'Failed to verify payment status.'; });
    }
  }

  Future<void> _verifyWithAugmont() async {
    final orderRef = _orderId;
    if (orderRef.isEmpty || _uniqueId.isEmpty) {
      setState(() {
        _loading = false;
        _message = 'Payment is processing. Please check your orders shortly.';
      });
      return;
    }

    final augmont = AugmontApi(ref.read(dioAugmontProvider));
    Map<String, dynamic>? detailsRes;

    for (int attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        if (!mounted) return;
        setState(() => _message = 'Payment is processing. Checking again...');
        await Future.delayed(const Duration(seconds: 2));
      }
      detailsRes = await augmont.verifyPaymentDetails(
        orderReference: orderRef,
        uniqueId: _uniqueId,
      );
      if (!mounted) return;
      if (detailsRes['ok'] == true) break;
    }

    if (!mounted) return;

    if (detailsRes != null && detailsRes['ok'] == true) {
      final normalized = _normalizePaymentDetails(detailsRes);
      await LocalStorageService.setMobilePaymentResult(jsonEncode(normalized));

      if (_isRedemption) {
        await _storeRedeemResult(detailsRes);
      }

      final normalizedStatus = (normalized['status'] ?? '').toString().toUpperCase();
      setState(() {
        _loading = false;
        _success = normalizedStatus == 'SUCCESS';
        _pending = normalizedStatus == 'PENDING' || normalizedStatus == 'PROCESSING';
        _statusCode = _paymentStatusRaw;
        _message = _success
            ? 'Thank you for your purchase. Your payment has been successfully processed.'
            : normalizedStatus == 'PROCESSING'
                ? 'Payment successful. Purchase is processing.'
                : normalized['message']?.toString() ?? 'Payment details verified.';
      });
    } else {
      setState(() {
        _loading = false;
        _statusCode = _paymentStatusRaw;
        _message = _buildStatusMessage();
      });
    }
  }

  Map<String, dynamic> _normalizePaymentDetails(Map<String, dynamic> apiResponse) {
    try {
      final data = apiResponse['data'];
      final root = data is Map<String, dynamic> ? data : apiResponse;
      final payload = root['payload'] as Map<String, dynamic>?;
      final result = payload?['result'] as Map<String, dynamic>?;
      final resultData = result?['data'] as Map<String, dynamic>?;
      final details = resultData ?? result ?? payload?['data'] ?? root;

      final rawStatus = (details?['status'] ?? details?['order_status'] ?? '').toString().toUpperCase();

      final buyResponse = details?['buy_response'] ?? details?['buyResponse'];
      Map<String, dynamic> buyData = {};
      if (buyResponse is Map<String, dynamic>) {
        final brPayload = buyResponse['payload'] as Map<String, dynamic>?;
        final brResult = brPayload?['result'] as Map<String, dynamic>?;
        final brData = brResult?['data'] as Map<String, dynamic>?;
        buyData = brData ?? brResult ?? brPayload?['data'] ?? buyResponse;
      }

      final txnId = (buyData['transactionId'] ?? buyData['txnId'] ?? buyData['transactionID'] ?? '').toString();
      final merchantTxnId = (buyData['merchantTransactionId'] ?? buyData['merchant_order_ref'] ?? details?['merchant_order_ref'] ?? _orderId).toString();
      final amount = num.tryParse(buyData['amount']?.toString() ?? buyData['totalAmount']?.toString() ?? details?['amount']?.toString() ?? '')?.toDouble();
      final quantity = num.tryParse(buyData['quantity']?.toString() ?? '')?.toDouble();
      final rate = num.tryParse(buyData['rate']?.toString() ?? details?['rate']?.toString() ?? '')?.toDouble();

      return {
        'status': rawStatus == 'SUCCESS' && txnId.isNotEmpty
            ? 'SUCCESS'
            : rawStatus == 'FAILED'
                ? 'FAILED'
                : rawStatus == 'SUCCESS'
                    ? 'PROCESSING'
                    : rawStatus,
        'message': (buyResponse is Map ? buyResponse['message'] : null) ?? details?['message'] ?? 'Payment verified.',
        'amount': amount,
        'quantity': quantity,
        'rate': rate,
        'transactionId': txnId,
        'merchantTransactionId': merchantTxnId,
        'rawStatus': rawStatus,
        'purchaseData': buyData.isNotEmpty ? buyData : null,
      };
    } catch (_) {
      return {'status': 'UNKNOWN', 'message': 'Payment status is being verified.'};
    }
  }

  Future<void> _storeRedeemResult(Map<String, dynamic> detailsRes) async {
    try {
      final data = detailsRes['data'];
      final root = data is Map<String, dynamic> ? data : detailsRes;
      final payload = root['payload'] as Map<String, dynamic>?;
      final result = payload?['result'] as Map<String, dynamic>?;
      final resultData = result?['data'] as Map<String, dynamic>?;
      final details = resultData ?? result ?? payload?['data'] ?? root;

      final addressCreateResp = details?['address_create_response'];
      Map<String, dynamic> paymentAddress = {};
      if (addressCreateResp is Map<String, dynamic>) {
        final respPayload = addressCreateResp['responsePayload'] as Map<String, dynamic>?;
        final augmontResp = respPayload?['augmontResponse'] ?? addressCreateResp['augmontResponse'];
        if (augmontResp is Map<String, dynamic>) {
          final augmontResult = augmontResp['result'] as Map<String, dynamic>?;
          paymentAddress = (augmontResult?['data'] as Map<String, dynamic>?) ?? augmontResult ?? {};
        }
      }

      final redeemResponse = details?['redeem_response'];
      Map<String, dynamic> redeemOrder = {};
      if (redeemResponse is Map<String, dynamic>) {
        final rrResult = redeemResponse['result'] as Map<String, dynamic>?;
        redeemOrder = (rrResult?['data'] as Map<String, dynamic>?) ?? rrResult ?? {};
      }

      String existingRaw = LocalStorageService.getRedeemResult() ?? '{}';
      Map<String, dynamic> existing = {};
      try { existing = jsonDecode(existingRaw) as Map<String, dynamic>; } catch (_) {}

      final redeemData = Map<String, dynamic>.from(existing);
      if (paymentAddress.isNotEmpty) {
        redeemData['paymentAddress'] = paymentAddress;
      } else if (existing['paymentAddress'] != null) {
        redeemData['paymentAddress'] = existing['paymentAddress'];
      }
      final existingOrder = existing['order'] is Map<String, dynamic> ? existing['order'] as Map<String, dynamic> : {};
      redeemData['order'] = {...existingOrder, ...redeemOrder};
      redeemData['message'] = (redeemResponse is Map ? redeemResponse['message'] : null) ?? existing['message'] ?? 'Redeem order placed successfully.';
      redeemData['orderId'] = _orderId;
      redeemData['status'] = 'SUCCESS';

      await LocalStorageService.setRedeemResult(jsonEncode(redeemData));
    } catch (_) {}
  }

  String _buildStatusMessage() {
    if (_success) return 'Thank you for your purchase. Your payment has been successfully processed.';
    if (_paymentStatusRaw == 'USER_DROPPED') {
      return 'Payment was not completed. You can retry from the order or payment page.';
    }
    if (_pending) return 'Your payment is still being processed. Please check again shortly.';
    return 'Your payment could not be processed. Please try again.';
  }

  String _getStatusTitle() {
    if (_success) return 'Payment Successful!';
    if (_paymentStatusRaw == 'USER_DROPPED') return 'Payment Incomplete';
    if (_pending) return 'Payment Pending';
    return 'Payment Failed';
  }

  String _getContinueRoute() {
    switch (_flowType) {
      case 'diamond':
        return AppRoutes.diamondPaymentSuccess;
      case 'sell_coin':
        return '${AppRoutes.sellGoldCoin3}?metal=$_metalType';
      case 'gold_coin':
        return AppRoutes.goldCoin3;
      default:
        return AppRoutes.home;
    }
  }

  bool get _isSilver => _metalType == 'silver';
  bool get _isDiamond => _metalType == 'diamond';

  Color get _accent => _isSilver ? Colors.white : (_isDiamond ? const Color(0xFF0084FF) : const Color(0xFFF7CD57));
  Color get _accentDark => _isSilver ? const Color(0xFF777F89) : (_isDiamond ? const Color(0xFF004175) : const Color(0xFFB68024));
  Color get _buttonText => _isSilver ? Colors.black : (_isDiamond ? Colors.white : const Color(0xFF1A1710));
  Color get _successBg => _isSilver ? const Color(0xFF394552) : (_isDiamond ? const Color(0xFF0A2A3B) : const Color(0xFF33260D));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.9755, -0.3792),
            radius: 1.04,
            colors: [_success || _pending ? _successBg : const Color(0xFF0A2A3B), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                if (_loading)
                  Column(
                    children: [
                      SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(_accent))),
                      const SizedBox(height: 16),
                      const Text('Verifying your payment...', style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 13)),
                    ],
                  )
                else ...[
                  // Status icon
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: _success
                            ? [_accent, Colors.black]
                            : [const Color(0xFFB80101), Colors.black],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_success ? _accent : const Color(0xFFB80101)).withValues(alpha: 0.4),
                          blurRadius: 80, spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      _success ? Icons.check : Icons.close,
                      size: 50, color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _getStatusTitle(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF7E7E7E), height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  // Details card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1A3040)),
                      color: const Color(0xFF0A1520),
                    ),
                    child: Column(
                      children: [
                        if (_merchantOrderId.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Order ID', style: TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))),
                                Flexible(child: Text(_merchantOrderId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white))),
                              ],
                            ),
                          ),
                        if (_sabbpeOrderId.isNotEmpty && _sabbpeOrderId != _merchantOrderId)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Reference', style: TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))),
                                Text('#$_sabbpeOrderId', style: const TextStyle(fontSize: 11, color: Colors.white)),
                              ],
                            ),
                          ),
                        const Divider(color: Color(0xFF1A3040), height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Status', style: TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))),
                            Row(
                              children: [
                                Icon(
                                  _success ? Icons.shield : Icons.close,
                                  size: 14, color: _success ? const Color(0xFF15EE01) : const Color(0xFFFF4D4D),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _statusCode.isNotEmpty ? _statusCode : 'UNKNOWN',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _success ? const Color(0xFF15EE01) : const Color(0xFFFF4D4D)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_pending) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 44,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2E2E2E)),
                          backgroundColor: const Color(0xFF0A1520),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Retry Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  SizedBox(height: _pending ? 12 : 40),
                  SizedBox(
                    width: double.infinity, height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(colors: [_accent, _accentDark]),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () => context.go(_getContinueRoute()),
                          child: Center(
                            child: Text(
                              _pending ? 'Go Home' : 'Continue Shopping',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _buttonText),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
