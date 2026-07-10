import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/augmont_api.dart';
import '../api/transbank_api.dart';
import '../storage/local_storage.dart';
import 'rate_provider.dart';

// ── Bank Form Data ──
class BankFormData {
  final String accountName;
  final String accountNumber;
  final String ifscCode;

  const BankFormData({
    this.accountName = '',
    this.accountNumber = '',
    this.ifscCode = '',
  });

  BankFormData copyWith({
    String? accountName,
    String? accountNumber,
    String? ifscCode,
  }) {
    return BankFormData(
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'accountName': accountName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
      };
}

// ── Banner Data ──
class BannerData {
  final String variant;
  final String message;

  const BannerData({this.variant = '', this.message = ''});

  bool get isEmpty => variant.isEmpty && message.isEmpty;
}

// ── Bank State ──
class BankState {
  final List<Map<String, dynamic>> banks;
  final bool loading;
  final bool submitting;
  final bool deleting;
  final bool showForm;
  final Map<String, dynamic>? editingBank;
  final BankFormData formData;
  final Map<String, String> formErrors;
  final String primaryUpdatingId;
  final BannerData banner;
  final BannerData deleteBanner;

  const BankState({
    this.banks = const [],
    this.loading = false,
    this.submitting = false,
    this.deleting = false,
    this.showForm = false,
    this.editingBank,
    this.formData = const BankFormData(),
    this.formErrors = const {},
    this.primaryUpdatingId = '',
    this.banner = const BannerData(),
    this.deleteBanner = const BannerData(),
  });

  BankState copyWith({
    List<Map<String, dynamic>>? banks,
    bool? loading,
    bool? submitting,
    bool? deleting,
    bool? showForm,
    Map<String, dynamic>? editingBank,
    BankFormData? formData,
    Map<String, String>? formErrors,
    String? primaryUpdatingId,
    BannerData? banner,
    BannerData? deleteBanner,
    bool clearEditing = false,
    bool clearBanner = false,
    bool clearDeleteBanner = false,
  }) {
    return BankState(
      banks: banks ?? this.banks,
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      deleting: deleting ?? this.deleting,
      showForm: showForm ?? this.showForm,
      editingBank: clearEditing ? null : (editingBank ?? this.editingBank),
      formData: formData ?? this.formData,
      formErrors: formErrors ?? this.formErrors,
      primaryUpdatingId: primaryUpdatingId ?? this.primaryUpdatingId,
      banner: clearBanner ? const BannerData() : (banner ?? this.banner),
      deleteBanner: clearDeleteBanner ? const BannerData() : (deleteBanner ?? this.deleteBanner),
    );
  }
}

// ── Bank Notifier ──
class BankNotifier extends StateNotifier<BankState> {
  final AugmontApi _augmontApi;
  final TransbankApi _transbankApi;

  BankNotifier(this._augmontApi, this._transbankApi) : super(const BankState());

  String _resolveUniqueId() {
    final augmontUserRaw = LocalStorageService.getAugmontUser();
    if (augmontUserRaw != null && augmontUserRaw.isNotEmpty) {
      try {
        final augmontUser = jsonDecode(augmontUserRaw) as Map<String, dynamic>;
        final uniqueId = augmontUser['uniqueId']?.toString();
        if (uniqueId != null && uniqueId.isNotEmpty) return uniqueId;
      } catch (_) {}
    }

    final storedProfile = LocalStorageService.getUserProfile();
    if (storedProfile != null) {
      final uniqueId = storedProfile['augmontUniqueId']?.toString() ?? storedProfile['uniqueId']?.toString();
      if (uniqueId != null && uniqueId.isNotEmpty) return uniqueId;
    }

    final storedUniqueId = LocalStorageService.getUserUniqueId();
    if (storedUniqueId != null && storedUniqueId.isNotEmpty) return storedUniqueId;

    return '';
  }

  // ── Fetch Banks ──
  Future<void> fetchBanks() async {
    final uniqueId = _resolveUniqueId();
    if (uniqueId.isEmpty) {
      state = state.copyWith(banks: [], loading: false);
      return;
    }

    state = state.copyWith(loading: true, clearBanner: true);

    try {
      final result = await _augmontApi.fetchAugmontUserBanks(uniqueId);
      if (result['ok'] == true) {
        final banks = (result['banks'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        state = state.copyWith(banks: banks, loading: false);
      } else {
        state = state.copyWith(banks: [], loading: false);
      }
    } catch (e) {
      state = state.copyWith(banks: [], loading: false);
    }
  }

  // ── Add Bank ──
  Future<void> addBank() async {
    if (!validateForm()) return;

    final accountName = state.formData.accountName.trim();
    final accountNumber = state.formData.accountNumber.trim();
    final ifscCode = state.formData.ifscCode.trim().toUpperCase();
    final uniqueId = _resolveUniqueId();

    if (uniqueId.isEmpty) {
      state = state.copyWith(banner: const BannerData(variant: 'error', message: 'User not registered'));
      return;
    }

    state = state.copyWith(submitting: true, clearBanner: true);

    try {
      final validateResult = await _transbankApi.transbankValidateBankAccount(
        accountName: accountName,
        accountNumber: accountNumber,
        ifscCode: ifscCode,
        uniqueId: uniqueId,
      );

      if (validateResult['ok'] == true) {
        final createResult = await _augmontApi.createAugmontUserBank(
          uniqueId: uniqueId,
          request: {
            'accountName': accountName,
            'accountNumber': accountNumber,
            'ifscCode': ifscCode,
          },
        );

        if (createResult['ok'] == true) {
          state = state.copyWith(
            submitting: false,
            showForm: false,
            formData: const BankFormData(),
            formErrors: const {},
            banner: const BannerData(variant: 'success', message: 'Bank account added successfully'),
          );
          await fetchBanks();
        } else {
          state = state.copyWith(
            submitting: false,
            banner: BannerData(
              variant: 'error',
              message: createResult['message']?.toString() ?? 'Failed to add bank account',
            ),
          );
        }
      } else {
        state = state.copyWith(
          submitting: false,
          banner: BannerData(
            variant: 'error',
            message: validateResult['message']?.toString() ?? 'Bank verification failed',
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        submitting: false,
        banner: const BannerData(variant: 'error', message: 'Failed to add bank account'),
      );
    }
  }

  // ── Delete Bank ──
  Future<void> deleteBank(String userBankId) async {
    final uniqueId = _resolveUniqueId();
    if (uniqueId.isEmpty) return;

    state = state.copyWith(deleting: true, clearDeleteBanner: true);

    try {
      final result = await _augmontApi.deleteAugmontUserBank(
        uniqueId: uniqueId,
        userBankId: userBankId,
      );

      if (result['ok'] == true) {
        state = state.copyWith(
          deleting: false,
          deleteBanner: const BannerData(variant: 'success', message: 'Bank account deleted successfully'),
        );
        await fetchBanks();
      } else {
        state = state.copyWith(
          deleting: false,
          deleteBanner: BannerData(
            variant: 'error',
            message: result['message']?.toString() ?? 'Failed to delete bank account',
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        deleting: false,
        deleteBanner: const BannerData(variant: 'error', message: 'Failed to delete bank account'),
      );
    }
  }

  // ── Set Primary Bank ──
  Future<void> setPrimary(String userBankId) async {
    final uniqueId = _resolveUniqueId();
    if (uniqueId.isEmpty) return;

    state = state.copyWith(primaryUpdatingId: userBankId, clearBanner: true);

    try {
      final result = await _augmontApi.setPrimaryAugmontUserBank(
        uniqueId: uniqueId,
        userBankId: userBankId,
      );

      if (result['ok'] == true) {
        await LocalStorageService.setPrimaryBankId(userBankId);
        state = state.copyWith(
          primaryUpdatingId: '',
          banner: const BannerData(variant: 'success', message: 'Primary bank updated'),
        );
        await fetchBanks();
      } else {
        state = state.copyWith(
          primaryUpdatingId: '',
          banner: BannerData(
            variant: 'error',
            message: result['message']?.toString() ?? 'Failed to set primary bank',
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        primaryUpdatingId: '',
        banner: const BannerData(variant: 'error', message: 'Failed to set primary bank'),
      );
    }
  }

  // ── Toggle Form ──
  void toggleForm() {
    state = state.copyWith(
      showForm: !state.showForm,
      clearEditing: true,
      formData: const BankFormData(),
      formErrors: const {},
      clearBanner: true,
    );
  }

  // ── Set Editing Bank ──
  void setEditingBank(Map<String, dynamic>? bank) {
    if (bank == null) {
      state = state.copyWith(
        clearEditing: true,
        formData: const BankFormData(),
        formErrors: const {},
        showForm: false,
      );
      return;
    }

    state = state.copyWith(
      editingBank: bank,
      showForm: true,
      formData: BankFormData(
        accountName: bank['accountName']?.toString() ?? '',
        accountNumber: bank['accountNumber']?.toString() ?? '',
        ifscCode: bank['ifscCode']?.toString() ?? '',
      ),
      formErrors: const {},
      clearBanner: true,
    );
  }

  // ── Update Form Field ──
  void updateFormField(String key, String value) {
    final current = state.formData;
    switch (key) {
      case 'accountName':
        state = state.copyWith(formData: current.copyWith(accountName: value));
        break;
      case 'accountNumber':
        state = state.copyWith(formData: current.copyWith(accountNumber: value));
        break;
      case 'ifscCode':
        state = state.copyWith(formData: current.copyWith(ifscCode: value.toUpperCase()));
        break;
    }

    if (state.formErrors.containsKey(key)) {
      final newErrors = Map<String, String>.from(state.formErrors)..remove(key);
      state = state.copyWith(formErrors: newErrors);
    }
  }

  // ── Validate Form ──
  bool validateForm() {
    final errors = <String, String>{};
    final accountName = state.formData.accountName.trim();
    final accountNumber = state.formData.accountNumber.trim();
    final ifscCode = state.formData.ifscCode.trim().toUpperCase();

    if (accountName.isEmpty) {
      errors['accountName'] = 'Account holder name is required';
    }

    if (accountNumber.isEmpty) {
      errors['accountNumber'] = 'Account number is required';
    } else if (accountNumber.length < 9 || accountNumber.length > 18) {
      errors['accountNumber'] = 'Invalid account number';
    }

    if (ifscCode.isEmpty) {
      errors['ifscCode'] = 'IFSC code is required';
    } else if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifscCode)) {
      errors['ifscCode'] = 'Invalid IFSC code format';
    }

    state = state.copyWith(formErrors: errors);
    return errors.isEmpty;
  }
}

// ── Bank Provider ──
final bankProvider = StateNotifierProvider<BankNotifier, BankState>((ref) {
  return BankNotifier(ref.read(augmontApiProvider), ref.read(transbankApiProvider));
});
