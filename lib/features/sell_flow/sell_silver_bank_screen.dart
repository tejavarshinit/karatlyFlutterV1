import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/api/augmont_api.dart';
import '../../core/services/rate_provider.dart';
import '../../core/services/gold_flow_provider.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/unique_id.dart';

class SellSilverBankScreen extends ConsumerStatefulWidget {
  const SellSilverBankScreen({super.key});

  @override
  ConsumerState<SellSilverBankScreen> createState() =>
      _SellSilverBankScreenState();
}

class _SellSilverBankScreenState extends ConsumerState<SellSilverBankScreen> {
  final _accountController = TextEditingController();
  final _holderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _ifscController = TextEditingController();
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

  Future<void> _addBank() async {
    final account = _accountController.text.trim();
    final holder = _holderController.text.trim();
    final bankName = _bankNameController.text.trim();
    final ifsc = _ifscController.text.trim().toUpperCase();
    if (account.isEmpty || holder.isEmpty || bankName.isEmpty || ifsc.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = AugmontApi(ref.read(augmontDioProvider));
      final uniqueId = _resolveUniqueId();
      final result =
          await api.createAugmontUserBank(uniqueId: uniqueId, request: {
        'accountNumber': account,
        'holderName': holder,
        'bankName': bankName,
        'ifscCode': ifsc,
      });
      if (result['ok'] == true) {
        final bankId = result['userBankId']?.toString() ??
            result['bankId']?.toString() ??
            '';
        if (bankId.isNotEmpty) {
          await api.setPrimaryAugmontUserBank(
              uniqueId: uniqueId, userBankId: bankId);
        }
        ref.read(goldFlowProvider.notifier).updateSellState(
              payoutMethod: 'bank',
              accountNumber: account,
              accountHolderName: holder,
              bankName: bankName,
              ifscCode: ifsc,
              userBankId: bankId,
              payoutVerified: true,
              metalType: 'silver',
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bank account added successfully')),
          );
          context.go('/sell-silver/3?metal=silver');
        }
      } else {
        setState(() {
          _error = result['message']?.toString() ?? 'Failed to add bank';
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
    _accountController.dispose();
    _holderController.dispose();
    _bankNameController.dispose();
    _ifscController.dispose();
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
            child: SingleChildScrollView(
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
                            child: Text('Add Bank Account',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(_accountController, 'Account Number',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _buildTextField(_holderController, 'Account Holder Name'),
                  const SizedBox(height: 12),
                  _buildTextField(_bankNameController, 'Bank Name'),
                  const SizedBox(height: 12),
                  _buildTextField(_ifscController, 'IFSC Code',
                      keyboardType: TextInputType.text),
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
                          onTap: _loading ? null : _addBank,
                          child: Center(
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black))
                                : const Text('Add Bank Account',
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
      {TextInputType? keyboardType}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4E4E4E)),
          color: const Color(0xFF21211A)),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF5E5E5E)),
            border: InputBorder.none),
      ),
    );
  }
}
