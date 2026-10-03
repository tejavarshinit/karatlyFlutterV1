import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/augmont_api.dart';
import '../../core/api/transbank_api.dart';
import '../../core/services/auth_provider.dart';
import '../../core/storage/local_storage.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  static const int _maxBanks = 3;

  bool _showForm = false;
  Map<String, dynamic>? _editingBank;
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();

  final List<Map<String, dynamic>> _banks = [];
  bool _loading = true;
  bool _submitting = false;
  String? _primaryUpdatingId;
  String? _formMessage;
  bool _formMessageSuccess = true;
  String? _deleteMessage;
  String? _primaryMessage;
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBanks());
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  String _resolveUniqueId() {
    final augmontUserRaw = LocalStorageService.getAugmontUser();
    if (augmontUserRaw != null && augmontUserRaw.isNotEmpty) {
      try {
        final augmontUser = jsonDecode(augmontUserRaw) as Map<String, dynamic>;
        final uniqueId = augmontUser['uniqueId']?.toString().trim() ?? '';
        if (uniqueId.isNotEmpty) return uniqueId;
      } catch (_) {}
    }

    final profile = LocalStorageService.getUserProfile();
    final uniqueId = profile?['augmontUniqueId']?.toString().trim() ?? profile?['uniqueId']?.toString().trim() ?? '';
    if (uniqueId.isNotEmpty) return uniqueId;

    return LocalStorageService.getUserUniqueId() ?? '';
  }

  void _resetForm() {
    _accountNameController.clear();
    _accountNumberController.clear();
    _ifscController.clear();
    _editingBank = null;
    _errors.clear();
    _formMessage = null;
  }

  Future<void> _loadBanks() async {
    final uniqueId = _resolveUniqueId();
    if (uniqueId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final api = AugmontApi(ref.read(dioAugmontProvider));
    final result = await api.fetchAugmontUserBanks(uniqueId);
    final banks = (result['banks'] as List<dynamic>? ?? []).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    final primary = banks.where((bank) => (bank['isPrimary'] == true) || (bank['is_primary'] == true)).toList();
    if (primary.isNotEmpty) {
      final bank = primary.first;
      final bankId = _extractBankId(bank);
      if (bankId.isNotEmpty) {
        await LocalStorageService.setPrimaryBankId(bankId);
        await LocalStorageService.setPrimaryBank(jsonEncode({...bank, 'userBankId': bankId, 'isPrimary': true, 'is_primary': true}));
      }
    }

    if (!mounted) return;
    setState(() {
      _banks
        ..clear()
        ..addAll(banks);
      _loading = false;
    });
  }

  String _extractBankId(Map<String, dynamic> bank) {
    final raw =
      (bank['provider_bank_id']?.toString() ??
          bank['userBankId']?.toString() ??
          bank['bankId']?.toString() ??
          bank['id']?.toString() ??
          '').trim();
    return raw.replaceAll(RegExp(r'[()]'), '');
  }

  String? _detectIfscMismatch(String accountNumber, String ifsc) {
    final cleaned = accountNumber.replaceAll(' ', '');
    for (final bank in _banks) {
      final existingAcc = (bank['accountNumber'] ?? bank['account_number'] ?? '').toString().replaceAll(' ', '');
      if (existingAcc == cleaned) {
        final existingIfsc = (bank['ifscCode'] ?? bank['ifsc_code'] ?? '').toString().toUpperCase();
        if (existingIfsc != ifsc.toUpperCase()) {
          return 'Account $cleaned is already registered with IFSC $existingIfsc. Please verify the IFSC code.';
        }
      }
    }
    return null;
  }

  void _openAddForm() {
    setState(() {
      _showForm = true;
      _editingBank = null;
      _formMessage = null;
      _errors.clear();
    });
    _resetForm();
  }

  void _openEditForm(Map<String, dynamic> bank) {
    setState(() {
      _showForm = true;
      _editingBank = bank;
      _formMessage = null;
      _errors.clear();
      _accountNameController.text = (bank['accountName'] ?? bank['account_holder_name'] ?? '').toString();
      _accountNumberController.text = (bank['accountNumber'] ?? bank['account_number'] ?? '').toString();
      _ifscController.text = (bank['ifscCode'] ?? bank['ifsc_code'] ?? '').toString().toUpperCase();
    });
  }

  bool _validate() {
    _errors.clear();
    final accountName = _accountNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim().replaceAll(' ', '');
    final ifsc = _ifscController.text.trim().toUpperCase();

    if (accountName.isEmpty) {
      _errors['accountName'] = 'Account holder name required';
    }
    if (accountNumber.isEmpty || accountNumber.length < 9 || accountNumber.length > 18) {
      _errors['accountNumber'] = 'Enter a valid account number (9-18 digits)';
    }
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
      _errors['ifscCode'] = 'Enter a valid IFSC (e.g. SBIN0001234)';
    }

    setState(() {});
    return _errors.isEmpty;
  }

  Future<void> _submitForm() async {
    if (!_validate()) return;

    final uniqueId = _resolveUniqueId();
    if (uniqueId.isEmpty) {
      setState(() {
        _formMessage = 'User session not found. Please login again.';
        _formMessageSuccess = false;
      });
      return;
    }

    final accountName = _accountNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim().replaceAll(' ', '');
    final ifsc = _ifscController.text.trim().toUpperCase();

    if (_editingBank == null) {
      final mismatch = _detectIfscMismatch(accountNumber, ifsc);
      if (mismatch != null) {
        setState(() {
          _formMessage = mismatch;
          _formMessageSuccess = false;
        });
        return;
      }
    }

    setState(() {
      _submitting = true;
      _formMessage = null;
    });

    final transbank = TransbankApi(ref.read(dioAugmontProvider));
    final validateResult = await transbank.transbankValidateBankAccount(
      accountName: accountName,
      accountNumber: accountNumber,
      ifscCode: ifsc,
      uniqueId: uniqueId,
    );

    if (!mounted) return;
    if (validateResult['ok'] != true || validateResult['isValid'] == false) {
      final msg = validateResult['message']?.toString() ?? 'Bank account validation failed. Please check your details.';
      setState(() {
        _submitting = false;
        _formMessage = msg;
        _formMessageSuccess = false;
      });
      return;
    }

    await _loadBanks();
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _showForm = false;
      _editingBank = null;
      _accountNameController.clear();
      _accountNumberController.clear();
      _ifscController.clear();
      _formMessage = 'Bank account validated successfully.';
      _formMessageSuccess = true;
    });
  }

  Future<void> _deleteBank(Map<String, dynamic> bank) async {
    final uniqueId = _resolveUniqueId();
    final bankId = _extractBankId(bank);
    if (uniqueId.isEmpty || bankId.isEmpty) return;

    final api = AugmontApi(ref.read(dioAugmontProvider));
    final result = await api.deleteAugmontUserBank(uniqueId: uniqueId, userBankId: bankId);
    if (!mounted) return;

    if (result['ok'] == true) {
      await _loadBanks();
      setState(() {
        _deleteMessage = 'Bank account removed.';
      });
      _autoDismissBanner('delete');
    } else {
      setState(() {
        _deleteMessage = result['message']?.toString() ?? 'Failed to delete bank account.';
      });
    }
  }

  Future<void> _setPrimary(Map<String, dynamic> bank) async {
    final uniqueId = _resolveUniqueId();
    final bankId = _extractBankId(bank);
    if (uniqueId.isEmpty || bankId.isEmpty || _primaryUpdatingId != null) return;

    setState(() => _primaryUpdatingId = bankId);
    final api = AugmontApi(ref.read(dioAugmontProvider));
    final result = await api.setPrimaryAugmontUserBank(uniqueId: uniqueId, userBankId: bankId);

    if (!mounted) return;
    if (result['ok'] == true) {
      await LocalStorageService.setPrimaryBankId(bankId);
      await LocalStorageService.setPrimaryBank(jsonEncode({
        ...bank,
        'userBankId': bankId,
        'isPrimary': true,
        'is_primary': true,
      }));
      await _loadBanks();
      setState(() {
        _primaryMessage = 'Primary bank account changed.';
      });
      _autoDismissBanner('primary');
    } else {
      setState(() {
        _primaryMessage = result['message']?.toString() ?? 'Failed to set primary bank.';
      });
    }

    if (mounted) {
      setState(() => _primaryUpdatingId = null);
    }
  }

  void _autoDismissBanner(String type) {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          if (type == 'delete') _deleteMessage = null;
          if (type == 'primary') _primaryMessage = null;
        });
      }
    });
  }

  String _maskAccount(String account) {
    final cleaned = account.replaceAll(' ', '');
    if (cleaned.length <= 4) return '****$cleaned';
    return '****${cleaned.substring(cleaned.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.9755, -0.3792),
            radius: 1.04,
            colors: [Color(0xFF4A3A1E), Colors.black],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 88),
            child: DefaultTextStyle(
              style: const TextStyle(decoration: TextDecoration.none),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                _buildHeader(context, 'Add your bank'),
              const SizedBox(height: 24),
              _buildSectionHeading('SAVED BANK ACCOUNTS'),
              const SizedBox(height: 12),
              _buildInfoBanner(),
              if (_deleteMessage != null) ...[
                const SizedBox(height: 12),
                _banner(_deleteMessage!, success: !_deleteMessage!.toLowerCase().contains('failed')),
              ],
              if (_primaryMessage != null) ...[
                const SizedBox(height: 12),
                _banner(_primaryMessage!, success: !_primaryMessage!.toLowerCase().contains('failed')),
              ],
              if (_loading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator(color: Color(0xFFF7CD57))),
              ] else if (_banks.isEmpty && !_showForm) ...[
                const SizedBox(height: 12),
                _buildEmptyState(),
              ] else ...[
                const SizedBox(height: 12),
                ..._banks.map(_buildBankCard),
              ],
              if (!_showForm && _banks.length < _maxBanks) ...[
                const SizedBox(height: 12),
                _buildAddBankButton(),
              ],
              if (_showForm) ...[
                const SizedBox(height: 12),
                _buildFormCard(),
              ],
              const SizedBox(height: 24),
              _buildSecurityBadge(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => context.go(AppRoutes.profile),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF7CD57), size: 18),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFFF7CD57))),
          ],
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1D170D),
            border: Border.all(color: const Color(0xFF7388A5)),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.go(AppRoutes.notifications),
            icon: Icon(Icons.notifications_outlined, color: Colors.grey[400], size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeading(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFFBFBFBF),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF15EE01).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF15EE01).withOpacity(0.25)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1415EE01),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF15EE01), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tap on any bank below to set it as your primary account.',
              style: TextStyle(fontSize: 11, color: const Color(0xFF15EE01)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner(String message, {required bool success}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: success ? const Color(0xFF4CD676).withOpacity(0.05) : const Color(0xFFEF5350).withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: success ? const Color(0xFF4CD676).withOpacity(0.2) : const Color(0xFFEF5350).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            color: success ? const Color(0xFF4CD676) : const Color(0xFFEF5350),
            size: 13,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 10,
                color: success ? const Color(0xFF4CD676) : const Color(0xFFEF5350),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_outlined, color: Colors.grey[600], size: 40),
          const SizedBox(height: 12),
          Text('No bank accounts added yet', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text('Add your bank account to start investing', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildBankCard(Map<String, dynamic> bank) {
    final bankId = _extractBankId(bank);
    final isPrimary = bank['isPrimary'] == true || bank['is_primary'] == true;
    final accountName = (bank['accountName'] ?? bank['account_holder_name'] ?? 'Bank Account').toString();
    final accountNumber = (bank['accountNumber'] ?? bank['account_number'] ?? '').toString();
    final ifsc = (bank['ifscCode'] ?? bank['ifsc_code'] ?? '').toString();
    final bankName = (bank['bankName'] ?? bank['bank_name'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? const Color(0xFF4CAF50) : const Color(0xFF2E2E2E),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1D170D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2E2E2E)),
            ),
            child: const Icon(Icons.account_balance, color: Color(0xFFF7CD57), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        accountName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPrimary) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF263938),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'Primary',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF6DD6FF)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${_maskAccount(accountNumber)} · $ifsc${bankName.isNotEmpty ? ' · $bankName' : ''}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF7E7E7E)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: isPrimary || _primaryUpdatingId == bankId ? null : () => _setPrimary(bank),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPrimary ? const Color(0xFF1A301E) : const Color(0xFF111416),
                    border: Border.all(
                      color: isPrimary ? const Color(0xFF15EE01) : const Color(0xFF5E5E5E),
                    ),
                  ),
                  child: _primaryUpdatingId == bankId
                      ? const Padding(
                          padding: EdgeInsets.all(7),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF15EE01)),
                        )
                      : isPrimary
                          ? const Icon(Icons.check_circle, color: Color(0xFF15EE01), size: 16)
                          : Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF2A2923),
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _openEditForm(bank),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D170D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_outlined, color: Color(0xFFF7CD57), size: 14),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _deleteBank(bank),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0A0A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: Color(0xFFEF5350), size: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddBankButton() {
    return GestureDetector(
      onTap: _openAddForm,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1416),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2E2E2E)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Color(0xFFF7CD57), size: 18),
            SizedBox(width: 8),
            Text(
              'Add bank account',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF7CD57)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    final editing = _editingBank != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1710),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB28A3B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            editing ? 'Edit Bank Account' : 'Add Bank Account',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 14),
          _formField(
            controller: _accountNameController,
            label: 'Account Holder Name',
            hint: 'Enter name as on bank account',
            errorKey: 'accountName',
            onChanged: (_) => setState(() => _errors.remove('accountName')),
          ),
          const SizedBox(height: 10),
          _formField(
            controller: _accountNumberController,
            label: 'Account Number',
            hint: 'Enter 9-18 digit account number',
            keyboardType: TextInputType.number,
            maxLength: 18,
            errorKey: 'accountNumber',
            onChanged: (value) {
              _accountNumberController.text = value.replaceAll(RegExp(r'\D'), '');
              _accountNumberController.selection = TextSelection.collapsed(offset: _accountNumberController.text.length);
              setState(() => _errors.remove('accountNumber'));
            },
          ),
          const SizedBox(height: 10),
          _formField(
            controller: _ifscController,
            label: 'IFSC Code',
            hint: 'e.g. SBIN0001234',
            maxLength: 11,
            errorKey: 'ifscCode',
            onChanged: (value) {
              _ifscController.text = value.toUpperCase();
              _ifscController.selection = TextSelection.collapsed(offset: _ifscController.text.length);
              setState(() => _errors.remove('ifscCode'));
            },
          ),
          const SizedBox(height: 14),
          if (_formMessage != null) _banner(_formMessage!, success: _formMessageSuccess),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _submitting
                      ? null
                      : () {
                          setState(() {
                            _showForm = false;
                            _editingBank = null;
                            _formMessage = null;
                            _errors.clear();
                          });
                          _resetForm();
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF2E2E2E)),
                    ),
                    child: const Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _submitting ? null : _submitForm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: _submitting
                          ? null
                          : const LinearGradient(colors: [Color(0xFFFED75D), Color(0xFFD48D00)]),
                      color: _submitting ? const Color(0xFF2E2E2E) : null,
                    ),
                    child: Center(
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              editing ? 'Update' : 'Add Account',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String errorKey,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7E7E7E))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 12, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF4E4E4E)),
            filled: true,
            fillColor: const Color(0xFF0F1416),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _errors[errorKey] == null ? const Color(0xFF2E2E2E) : const Color(0xFFEF5350)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _errors[errorKey] == null ? const Color(0xFF2E2E2E) : const Color(0xFFEF5350)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFF7CD57)),
            ),
          ),
        ),
        if (_errors[errorKey] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _errors[errorKey]!,
              style: const TextStyle(fontSize: 10, color: Color(0xFFEF5350)),
            ),
          ),
      ],
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFF4CAF50), size: 16),
          const SizedBox(width: 8),
          Text(
            'Verified beneficiary · Encrypted with 256-bit SSL',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
