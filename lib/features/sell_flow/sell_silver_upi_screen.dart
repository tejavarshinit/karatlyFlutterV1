import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/api/augmont_api.dart';
import '../../core/services/rate_provider.dart';
import '../../core/services/gold_flow_provider.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/unique_id.dart';

class SellSilverUpiScreen extends ConsumerStatefulWidget {
  const SellSilverUpiScreen({super.key});

  @override
  ConsumerState<SellSilverUpiScreen> createState() =>
      _SellSilverUpiScreenState();
}

class _SellSilverUpiScreenState extends ConsumerState<SellSilverUpiScreen> {
  final _upiController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _loading = false;
  String? _error;

  String _resolveUniqueId() {
    final stored = LocalStorageService.getUserUniqueId();
    if (stored != null && stored.isNotEmpty) return stored;
    final profile = LocalStorageService.getUserProfile() ?? {};
    final uid = profile['uniqueId']?.toString();
    if (uid != null && uid.isNotEmpty) return uid;
    final phone = LocalStorageService.getUserPhone();
    if (phone != null && phone.isNotEmpty) {
      final dob = profile['dateOfBirth']?.toString() ?? '';
      return UniqueIdHelper.buildMobileDobUniqueId(
          mobileNumber: phone, dateOfBirth: dob);
    }
    return '';
  }

  Future<void> _addUpi() async {
    final upiId = _upiController.text.trim();
    final mobile = _mobileController.text.trim();
    if (upiId.isEmpty) {
      setState(() => _error = 'Enter a UPI ID');
      return;
    }
    if (mobile.isEmpty || mobile.length < 10) {
      setState(() => _error = 'Enter a valid mobile number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AugmontApi(ref.read(augmontDioProvider));
      final uniqueId = _resolveUniqueId();
      final result = await api.createAugmontUpi(uniqueId: uniqueId, request: {
        'upiId': upiId,
        'mobileNumber': mobile,
      });
      if (result['ok'] == true) {
        ref.read(goldFlowProvider.notifier).updateSellState(
              payoutMethod: 'upi',
              upiId: upiId,
              mobileNumber: mobile,
              payoutVerified: true,
              metalType: 'silver',
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('UPI added successfully')),
          );
          context.go('/sell-silver/3?metal=silver');
        }
      } else {
        setState(() {
          _error = result['message']?.toString() ?? 'Failed to add UPI';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _upiController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1918),
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(60)),
            gradient: RadialGradient(
              center: Alignment(0.94, -0.95),
              radius: 1.2,
              colors: [Color(0xFF293341), Colors.black],
            ),
            boxShadow: [
              BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 60,
                  offset: Offset(0, -24))
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(60)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 100,
                      height: 10,
                      decoration: BoxDecoration(
                          color: const Color(0xFF3E3E3E),
                          borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                            left: 0,
                            child: GestureDetector(
                                onTap: () =>
                                    context.go('/sell-silver/3?metal=silver'),
                                child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 20,
                                    color: Colors.white))),
                        const Center(
                            child: Text('Add UPI',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(_upiController, 'UPI ID (e.g. name@upi)',
                      icon: Icons.account_balance_wallet),
                  const SizedBox(height: 12),
                  _buildTextField(_mobileController, 'Mobile Number',
                      keyboardType: TextInputType.phone, icon: Icons.phone),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFFF6B6B))),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: const LinearGradient(
                              colors: [Color(0xFFFFFFFF), Color(0xFF999999)])),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: _loading ? null : _addUpi,
                          child: Center(
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black))
                                : const Text('Add UPI',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint,
      {TextInputType? keyboardType, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4E4E4E)),
          color: const Color(0xFF21211A)),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: const Color(0xFF7E7E7E)),
            const SizedBox(width: 12)
          ],
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                  hintText: hint,
                  hintStyle:
                      const TextStyle(fontSize: 13, color: Color(0xFF5E5E5E)),
                  border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}
