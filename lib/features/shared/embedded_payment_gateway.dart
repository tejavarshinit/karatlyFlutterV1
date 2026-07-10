import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/augmont_api.dart';
import '../../core/api/cashfree_api.dart';
import '../../core/models/payment_model.dart';
import '../../core/services/auth_provider.dart';
import '../../core/services/rate_provider.dart';
import '../../core/storage/local_storage.dart';

class EmbeddedPaymentGateway extends ConsumerStatefulWidget {
  final double amount;
  final String metalType;
  final String quantity;
  final String lockPrice;
  final String? blockId;
  final String flowType; // DIGITAL_BUY or PHYSICAL_REDEMPTION
  final String? sku;
  final String? addressId;

  const EmbeddedPaymentGateway({
    super.key,
    required this.amount,
    required this.metalType,
    required this.quantity,
    required this.lockPrice,
    this.blockId,
    this.flowType = 'DIGITAL_BUY',
    this.sku,
    this.addressId,
  });

  @override
  ConsumerState<EmbeddedPaymentGateway> createState() => _EmbeddedPaymentGatewayState();
}

class _EmbeddedPaymentGatewayState extends ConsumerState<EmbeddedPaymentGateway> {
  bool _loading = false;
  String _error = '';
  bool _isKycError = false;
  bool _showKycLimitModal = false;
  String _kycLimitTitle = '';
  String _kycLimitMessage = '';
  bool _kycLimitNeedsKyc = false;

  bool get _isSilver => widget.metalType == 'silver';
  bool get _isDiamond => widget.metalType == 'diamond';

  String get _accent => _isSilver ? '#FFFFFF' : (_isDiamond ? '#0084FF' : '#F7CD57');
  String get _accentDark => _isSilver ? '#9EA7B3' : (_isDiamond ? '#004D96' : '#C49012');
  String get _buttonText => _isSilver ? '#111111' : (_isDiamond ? '#FFFFFF' : '#1A1710');

  String _resolveUniqueId() {
    final stored = LocalStorageService.getUserUniqueId();
    if (stored != null && stored.isNotEmpty) return stored;
    final profile = LocalStorageService.getUserProfile() ?? {};
    return profile['uniqueId']?.toString() ?? '';
  }

  final double _nonKycFyLimit = 1000;
  final double _kycVerifiedFyLimit = 500000;

  Future<String?> _checkPurchaseLimit(double amount) async {
    final authState = ref.read(authProvider);
    final isKycDone = authState.user?.kycApproved == true;
    if (isKycDone) return null;

    final uniqueId = _resolveUniqueId();
    if (uniqueId.isEmpty) return null;

    try {
      final api = AugmontApi(ref.read(augmontDioProvider));
      final results = await Future.wait([
        api.fetchInvestmentSummary(uniqueId: uniqueId, metalType: 'gold'),
        api.fetchInvestmentSummary(uniqueId: uniqueId, metalType: 'silver'),
      ]);
      final goldUsed = (results[0]['totalBuyPreTaxAmount'] as num?)?.toDouble() ?? 0;
      final silverUsed = (results[1]['totalBuyPreTaxAmount'] as num?)?.toDouble() ?? 0;
      final fyTotal = goldUsed + silverUsed;
      final fyLimit = _nonKycFyLimit;
      final remaining = (fyLimit - fyTotal).clamp(0, fyLimit);
      if (amount > remaining) {
        return remaining > 0
            ? 'Your remaining non-KYC purchase limit is ₹${remaining.toInt()}. Complete KYC to buy more.'
            : 'You have reached your non-KYC purchase limit of ₹$_nonKycFyLimit. Complete KYC to continue buying.';
      }
    } catch (_) {}
    return null;
  }

  Future<void> _startPayment() async {
    setState(() { _loading = true; _error = ''; _isKycError = false; });

    // Check KYC purchase limit for digital buys
    if (widget.flowType == 'DIGITAL_BUY') {
      final limitMsg = await _checkPurchaseLimit(widget.amount);
      if (limitMsg != null && mounted) {
        setState(() {
          _loading = false;
          _showKycLimitModal = true;
          _kycLimitTitle = 'Purchase limit reached';
          _kycLimitMessage = limitMsg;
          _kycLimitNeedsKyc = true;
        });
        return;
      }
    }

    try {
      final profile = LocalStorageService.getUserProfile() ?? {};
      final uniqueId = _resolveUniqueId();
      if (uniqueId.isEmpty) throw Exception('Please login again');

      final cashfreeApi = CashfreeApi(ref.read(augmontDioProvider));
      final request = PaymentRequest(
        amount: widget.amount,
        currency: 'INR',
        customer: PaymentCustomer(
          customerId: uniqueId,
          name: profile['fullName']?.toString() ?? '',
          email: profile['email']?.toString() ?? '',
          mobile: profile['mobileNumber']?.toString() ?? '',
        ),
        business: PaymentBusiness(
          flowType: widget.flowType,
          uniqueId: uniqueId,
          metalType: widget.metalType,
          quantity: double.tryParse(widget.quantity) ?? 0,
          lockPrice: widget.lockPrice,
          blockId: widget.blockId,
          sku: widget.sku,
          addressId: widget.addressId,
        ),
      );

      final response = await cashfreeApi.createCashfreePayment(request);

      if (response.paymentSessionId.isEmpty) {
        throw Exception(response.message.isNotEmpty ? response.message : 'Payment session ID is missing');
      }

      final existingCtx = LocalStorageService.getAugmontOrderReferences();
      Map<String, dynamic> merged = {};
      if (existingCtx != null && existingCtx.isNotEmpty) {
        try { merged = jsonDecode(existingCtx) as Map<String, dynamic>; } catch (_) {}
      }
      merged.addAll({
        'metalType': widget.metalType,
        'amount': widget.amount,
        'sabbpeOrderId': response.sabbpeOrderId,
        'merchantOrderId': response.merchantOrderId,
        if (widget.sku != null) 'sku': widget.sku,
        if (widget.addressId != null) 'addressId': widget.addressId,
        'flowType': widget.flowType,
      });
      await LocalStorageService.setAugmontOrderReferences(jsonEncode(merged));

      if (!mounted) return;
      context.go(AppRoutes.paymentGateway, extra: {
        'paymentSessionId': response.paymentSessionId,
        'orderId': response.merchantOrderId.isNotEmpty ? response.merchantOrderId : response.sabbpeOrderId,
      });
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      final isKyc = msg.toLowerCase().contains('non-kyc purchase limit') || msg.toLowerCase().contains('kyc') || msg.toLowerCase().contains('purchase limit');
      setState(() { _error = msg; _loading = false; _isKycError = isKyc; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2E2E2E)),
            color: const Color(0xFF1A2332),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [Color(int.parse((_isKycError ? '#FF6B6B' : _accent).replaceFirst('#', '0xFF'))), Color(int.parse((_isKycError ? '#CC4444' : _accentDark).replaceFirst('#', '0xFF')))],
                      ),
                      boxShadow: [BoxShadow(color: Color(int.parse((_isKycError ? '#FF6B6B' : _accent).replaceFirst('#', '0xFF'))).withValues(alpha: 0.25), blurRadius: 22)],
                    ),
                    child: Icon(_isKycError ? Icons.lock : Icons.credit_card, size: 21, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(_isKycError ? 'KYC Required' : 'Pay Now', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2E2E2E)),
                  color: const Color(0xFF101820),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount payable', style: TextStyle(fontSize: 11, color: Color(0xFF7E7E7E))),
                    Text(
                      '₹${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF2A1111),
                    border: Border.all(color: const Color(0xFF6B2A2A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF3A1515),
                        ),
                        child: const Icon(Icons.close, size: 17, color: Color(0xFFFF6B6B)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payment could not start', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                            Text(_error, style: const TextStyle(fontSize: 10, color: Color(0xFFD8B8B8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: _isKycError
                        ? const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFCC4444)])
                        : LinearGradient(
                            colors: [Color(int.parse(_accent.replaceFirst('#', '0xFF'))), Color(int.parse(_accentDark.replaceFirst('#', '0xFF')))],
                          ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: _loading ? null : (_isKycError ? () => context.go('/kyc-verification') : _startPayment),
                      child: Center(
                        child: _loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_isKycError ? Icons.lock : Icons.check_circle, size: 17, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isKycError ? 'Complete KYC' : 'Pay Now',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2E2E2E)),
            color: const Color(0xFF1A2332),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield, size: 12, color: Color(0xFF15EE01)),
              const SizedBox(width: 6),
              const Text('Secure checkout powered by Cashfree', style: TextStyle(fontSize: 9, color: Color(0xFF7E7E7E))),
            ],
          ),
        ),
        // KYC limit modal
        if (_showKycLimitModal) _buildKycLimitModal(),
      ],
    );
  }

  Widget _buildKycLimitModal() {
    return Stack(
      children: [
        Container(color: Colors.black.withValues(alpha: 0.7)),
        Center(
          child: Container(
            width: 358, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0x4DF7CD57)),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF503B15), Color(0xFF1C1408), Color(0xFF080603)]),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Align(alignment: Alignment.topRight, child: GestureDetector(
                onTap: () => setState(() => _showKycLimitModal = false),
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: Colors.white70)),
              )),
              Container(width: 56, height: 56,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(17),
                  gradient: const LinearGradient(colors: [Color(0xFFFFE784), Color(0xFFC88912)])),
                child: Icon(_kycLimitNeedsKyc ? Icons.lock : Icons.verified_user, color: const Color(0xFF11130F), size: 23)),
              const SizedBox(height: 16),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF7CD57))),
                const SizedBox(width: 6),
                Text(_kycLimitNeedsKyc ? 'KYC APPROVAL REQUIRED' : 'PURCHASE LIMIT REACHED',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.4, color: Color(0xFFF7CD57))),
              ]),
              const SizedBox(height: 8),
              Text(_kycLimitTitle, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 8),
              Text(_kycLimitMessage, style: const TextStyle(fontSize: 12, color: Color(0xFFB8B4AD)), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  setState(() => _showKycLimitModal = false);
                  if (_kycLimitNeedsKyc) {
                    context.go('/kyc-verification');
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(width: double.infinity, height: 48,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(colors: [Color(0xFFFED75D), Color(0xFFECB000), Color(0xFFD48D00)])),
                  child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_kycLimitNeedsKyc ? 'Complete KYC' : 'Go Back',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                    Icon(_kycLimitNeedsKyc ? Icons.arrow_forward : Icons.arrow_back, size: 16, color: Colors.black),
                  ])),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () { setState(() => _showKycLimitModal = false); context.go('/home'); },
                child: const Text('I will do it later', style: TextStyle(fontSize: 11, color: Colors.white54)),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
