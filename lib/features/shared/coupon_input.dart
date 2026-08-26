import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/coupon_api.dart';
import '../../core/api/augmont_api.dart';
import '../../core/services/rate_provider.dart';

class CouponInput extends ConsumerStatefulWidget {
  final String orderId;
  final String? clientId;
  final double subtotal;
  final double fee;
  final List<CouponApplyItem> items;
  final String initialCode;
  final Color discountColor;
  final void Function(CouponResult result) onApply;
  final VoidCallback? onRemove;

  const CouponInput({
    super.key,
    required this.orderId,
    this.clientId,
    required this.subtotal,
    this.fee = 0,
    this.items = const [],
    this.initialCode = '',
    this.discountColor = const Color(0xFF15EE01),
    required this.onApply,
    this.onRemove,
  });

  @override
  ConsumerState<CouponInput> createState() => _CouponInputState();
}

class _CouponInputState extends ConsumerState<CouponInput> {
  final _codeController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _corporateIdController = TextEditingController();
  bool _loading = false;
  String _error = '';
  CouponResult? _applied;

  bool get _isEmployeeCoupon => _codeController.text.trim().toUpperCase().startsWith('EMP');
  bool get _isCorporateCoupon => _codeController.text.trim().toUpperCase().startsWith('CORP');

  @override
  void initState() {
    super.initState();
    if (widget.initialCode.isNotEmpty) {
      _codeController.text = widget.initialCode;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _employeeIdController.dispose();
    _corporateIdController.dispose();
    super.dispose();
  }

  Future<void> _handleApply() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter a coupon code');
      return;
    }
    if (_isEmployeeCoupon && _employeeIdController.text.trim().isEmpty) {
      setState(() => _error = 'Employee ID is required for this coupon');
      return;
    }
    if (_isCorporateCoupon && _corporateIdController.text.trim().isEmpty) {
      setState(() => _error = 'Corporate ID is required for this coupon');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      final api = CouponApi(ref.read(augmontDioProvider));
      final res = await api.validateCoupon(
        couponCode: code,
        clientId: widget.clientId,
        subtotal: widget.subtotal,
        fee: widget.fee,
        items: widget.items,
        employeeId: _isEmployeeCoupon ? _employeeIdController.text.trim() : null,
        corporateId: _isCorporateCoupon ? _corporateIdController.text.trim() : null,
      );
      if (res['ok'] == true && CouponApi.isCouponSuccess(res['result'] as CouponResult?)) {
        final result = res['result'] as CouponResult;
        setState(() {
          _applied = result;
          _error = '';
        });
        _codeController.clear();
        widget.onApply(CouponResult(
          valid: result.valid,
          success: result.success,
          reserved: result.reserved,
          reservationId: result.reservationId,
          couponCode: code,
          discountAmount: result.discountAmount,
          finalPayable: result.finalPayable,
          eligibleSubtotal: result.eligibleSubtotal,
          message: result.message,
          employeeId: _isEmployeeCoupon ? _employeeIdController.text.trim() : null,
          corporateId: _isCorporateCoupon ? _corporateIdController.text.trim() : null,
        ));
      } else {
        final message = CouponApi.getErrorMessage(res['raw']);
        setState(() => _error = message);
      }
    } catch (e) {
      setState(() => _error = e.toString().contains('timed out')
          ? 'Request timed out. Please try again.'
          : 'Could not apply coupon. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _handleRemove() {
    setState(() {
      _applied = null;
      _error = '';
    });
    _codeController.clear();
    widget.onRemove?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_applied != null) {
      return _buildAppliedState();
    }
    return _buildInputState();
  }

  Widget _buildAppliedState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2E2E2E)),
            color: const Color(0xFF101820),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A301E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, size: 15, color: Color(0xFF15EE01)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _applied!.couponCode ?? '',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'You save Rs.${_applied!.discountAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 10, color: widget.discountColor),
                    ),
                  ],
                ),
              ),
              if (widget.onRemove != null)
                GestureDetector(
                  onTap: _handleRemove,
                  child: const Icon(Icons.close, size: 15, color: Color(0xFF7E7E7E)),
                ),
            ],
          ),
        ),
        if (_applied!.message != null && _applied!.message != 'Coupon is valid')
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(_applied!.message!, style: TextStyle(fontSize: 11, color: widget.discountColor)),
          ),
      ],
    );
  }

  Widget _buildInputState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2E2E2E)),
            color: const Color(0xFF101820),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_offer, size: 15, color: Color(0xFF7E7E7E)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _codeController,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Have a coupon code?',
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFF5B5B5B)),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _handleApply(),
                ),
              ),
              GestureDetector(
                onTap: _loading ? null : _handleApply,
                child: _loading
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF15EE01)))
                    : Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.discountColor)),
              ),
            ],
          ),
        ),
        if (_isEmployeeCoupon) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2E2E2E)),
              color: const Color(0xFF101820),
            ),
            child: TextField(
              controller: _employeeIdController,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter your Employee ID',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF5B5B5B)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
        if (_isCorporateCoupon) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2E2E2E)),
              color: const Color(0xFF101820),
            ),
            child: TextField(
              controller: _corporateIdController,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter your Corporate ID',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF5B5B5B)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, size: 13, color: Color(0xFFFF6B6B)),
              const SizedBox(width: 4),
              Expanded(child: Text(_error, style: const TextStyle(fontSize: 11, color: Color(0xFFD8B8B8)))),
            ],
          ),
        ],
      ],
    );
  }
}
