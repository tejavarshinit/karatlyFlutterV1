import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
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
  String _message = 'Verifying your payment...';
  String _statusCode = '';
  String _orderId = '';
  String _sabbpeOrderId = '';
  String _metalType = 'gold';
  String _sku = '';
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
        _sku = ctx['sku']?.toString() ?? '';
        _isRedemption = ctx['flowType']?.toString() == 'PHYSICAL_REDEMPTION' || _sku.isNotEmpty;
      }
    } catch (_) {}
    _orderId = _sabbpeOrderId.isNotEmpty ? _sabbpeOrderId : widget.orderId;
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
      _success = ps == 'SUCCESS' || os == 'PAID';
      _pending = ps == 'PENDING' || ps == 'USER_DROPPED';

      if (_success && _isRedemption) {
        final ctx = LocalStorageService.getAugmontOrderReferences();
        Map<String, dynamic> redeemData = {};
        if (ctx != null && ctx.isNotEmpty) {
          try { redeemData = jsonDecode(ctx) as Map<String, dynamic>; } catch (_) {}
        }
        redeemData.addAll({
          'orderId': _orderId,
          'status': 'SUCCESS',
          'message': 'Your ${_metalType == 'silver' ? 'silver' : 'gold'} coin redemption is being processed and will be delivered to your address.',
        });
        await LocalStorageService.setRedeemResult(jsonEncode(redeemData));
      }

      setState(() {
        _loading = false;
        _statusCode = ps.isNotEmpty ? ps : os;
        _message = _success
            ? 'Thank you for your purchase. Your payment has been successfully processed.'
            : _pending
                ? ps == 'USER_DROPPED'
                    ? 'Payment was not completed. You can retry from the order or payment page.'
                    : 'Your payment is still being processed. Please check again shortly.'
                : status.message.isNotEmpty ? status.message : 'Your payment could not be processed. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _message = 'Failed to verify payment status.'; });
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
                    _success ? 'Payment Successful!' : _pending ? 'Payment Pending' : 'Payment Failed',
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
                        if (_orderId.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Order ID', style: TextStyle(fontSize: 12, color: Color(0xFF7E7E7E))),
                                Flexible(child: Text('$_orderId', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white))),
                              ],
                            ),
                          ),
                        if (_sabbpeOrderId.isNotEmpty && _sabbpeOrderId != _orderId)
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
                          onTap: () => context.replace(
                            _isRedemption && _success
                                ? '/sell/gold-coin/3?metal=$_metalType'
                                : AppRoutes.home,
                          ),
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
