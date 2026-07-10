import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/augmont_api.dart';
import '../api/transbank_api.dart';
import '../storage/local_storage.dart';
import 'rate_provider.dart';

// ── Transbank API Provider ──
final transbankApiProvider = Provider<TransbankApi>((ref) {
  return TransbankApi(ref.read(augmontDioProvider));
});

// ── KYC Stage Enum ──
enum KycStage { enter, otp }

// ── KYC State ──
class KycState {
  final String panNumber;
  final String panName;
  final String panDob;
  final String aadhaarNumber;
  final String aadhaarOtp;
  final String sessionId;
  final KycStage kycStage;
  final String bankAccountName;
  final String bankAccountNumber;
  final String bankIfscCode;
  final bool loading;
  final String? error;
  final String? successMessage;
  final bool panVerified;
  final bool aadhaarVerified;
  final bool bankVerified;
  final List<Map<String, dynamic>> banks;
  final bool kycApproved;

  const KycState({
    this.panNumber = '',
    this.panName = '',
    this.panDob = '',
    this.aadhaarNumber = '',
    this.aadhaarOtp = '',
    this.sessionId = '',
    this.kycStage = KycStage.enter,
    this.bankAccountName = '',
    this.bankAccountNumber = '',
    this.bankIfscCode = '',
    this.loading = false,
    this.error,
    this.successMessage,
    this.panVerified = false,
    this.aadhaarVerified = false,
    this.bankVerified = false,
    this.banks = const [],
    this.kycApproved = false,
  });

  KycState copyWith({
    String? panNumber,
    String? panName,
    String? panDob,
    String? aadhaarNumber,
    String? aadhaarOtp,
    String? sessionId,
    KycStage? kycStage,
    String? bankAccountName,
    String? bankAccountNumber,
    String? bankIfscCode,
    bool? loading,
    String? error,
    String? successMessage,
    bool? panVerified,
    bool? aadhaarVerified,
    bool? bankVerified,
    List<Map<String, dynamic>>? banks,
    bool? kycApproved,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return KycState(
      panNumber: panNumber ?? this.panNumber,
      panName: panName ?? this.panName,
      panDob: panDob ?? this.panDob,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      aadhaarOtp: aadhaarOtp ?? this.aadhaarOtp,
      sessionId: sessionId ?? this.sessionId,
      kycStage: kycStage ?? this.kycStage,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfscCode: bankIfscCode ?? this.bankIfscCode,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      panVerified: panVerified ?? this.panVerified,
      aadhaarVerified: aadhaarVerified ?? this.aadhaarVerified,
      bankVerified: bankVerified ?? this.bankVerified,
      banks: banks ?? this.banks,
      kycApproved: kycApproved ?? this.kycApproved,
    );
  }
}

// ── KYC Notifier ──
class KycNotifier extends StateNotifier<KycState> {
  final AugmontApi _augmontApi;
  final TransbankApi _transbankApi;

  KycNotifier(this._augmontApi, this._transbankApi) : super(const KycState());

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

  String _resolvePhone() {
    final phone = LocalStorageService.getUserPhone();
    if (phone != null && phone.isNotEmpty) return phone;
    final profile = LocalStorageService.getUserProfile();
    return profile?['phoneNumber']?.toString() ?? profile?['phone']?.toString() ?? '';
  }

  // ── PAN Verification ──
  Future<void> verifyPan() async {
    final pan = state.panNumber.trim();
    final name = state.panName.trim();
    final mobile = _resolvePhone();

    if (pan.isEmpty || name.isEmpty) {
      state = state.copyWith(error: 'Please enter PAN number and name');
      return;
    }

    state = state.copyWith(loading: true, clearError: true, clearSuccess: true);

    try {
      final result = await _transbankApi.transbankValidatePan(
        panNumber: pan,
        name: name,
        mobile: mobile,
      );

      if (result['ok'] == true) {
        final uniqueId = _resolveUniqueId();
        if (uniqueId.isNotEmpty) {
          await _augmontApi.updateAugmontKyc(
            uniqueId: uniqueId,
            request: {
              'panNumber': pan,
              'panName': name,
              'panDob': state.panDob.trim(),
            },
          );
        }
        await LocalStorageService.setUserPan(pan);
        state = state.copyWith(
          loading: false,
          panVerified: true,
          successMessage: 'PAN verified successfully',
        );
      } else {
        state = state.copyWith(
          loading: false,
          error: result['message']?.toString() ?? 'PAN verification failed',
        );
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Failed to verify PAN');
    }
  }

  // ── Aadhaar OTP Generation ──
  Future<void> sendAadhaarOtp() async {
    final aadhaar = state.aadhaarNumber.trim();

    if (aadhaar.isEmpty || aadhaar.length != 12) {
      state = state.copyWith(error: 'Please enter a valid 12-digit Aadhaar number');
      return;
    }

    state = state.copyWith(loading: true, clearError: true, clearSuccess: true);

    try {
      final result = await _transbankApi.transbankAadhaarGenerateOtp(aadhaar);

      if (result['ok'] == true) {
        final sessionId = result['sessionId']?.toString() ?? '';
        state = state.copyWith(
          loading: false,
          sessionId: sessionId,
          kycStage: KycStage.otp,
          successMessage: 'OTP sent to your registered mobile',
        );
      } else {
        state = state.copyWith(
          loading: false,
          error: result['message']?.toString() ?? 'Failed to send Aadhaar OTP',
        );
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Failed to send Aadhaar OTP');
    }
  }

  // ── Aadhaar OTP Verification ──
  Future<void> verifyAadhaarOtp() async {
    final otp = state.aadhaarOtp.trim();
    final aadhaar = state.aadhaarNumber.trim();
    final sessionId = state.sessionId.trim();
    final uniqueId = _resolveUniqueId();

    if (otp.isEmpty) {
      state = state.copyWith(error: 'Please enter the OTP');
      return;
    }

    if (uniqueId.isEmpty) {
      state = state.copyWith(error: 'User not registered');
      return;
    }

    state = state.copyWith(loading: true, clearError: true, clearSuccess: true);

    try {
      final result = await _transbankApi.transbankAadhaarSubmitOtp(
        aadhaarNumber: aadhaar,
        otp: otp,
        sessionId: sessionId,
        uniqueId: uniqueId,
      );

      if (result['ok'] == true) {
        state = state.copyWith(
          loading: false,
          aadhaarVerified: true,
          kycStage: KycStage.enter,
          successMessage: 'Aadhaar verified successfully',
        );
      } else {
        state = state.copyWith(
          loading: false,
          error: result['message']?.toString() ?? 'Aadhaar OTP verification failed',
        );
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Failed to verify Aadhaar OTP');
    }
  }

  // ── Bank Validation ──
  Future<void> validateBank() async {
    final accountName = state.bankAccountName.trim();
    final accountNumber = state.bankAccountNumber.trim();
    final ifscCode = state.bankIfscCode.trim().toUpperCase();
    final uniqueId = _resolveUniqueId();

    if (accountName.isEmpty || accountNumber.isEmpty || ifscCode.isEmpty) {
      state = state.copyWith(error: 'Please fill all bank details');
      return;
    }

    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifscCode)) {
      state = state.copyWith(error: 'Please enter a valid IFSC code');
      return;
    }

    if (uniqueId.isEmpty) {
      state = state.copyWith(error: 'User not registered');
      return;
    }

    state = state.copyWith(loading: true, clearError: true, clearSuccess: true);

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
            loading: false,
            bankVerified: true,
            successMessage: 'Bank account added successfully',
          );
          await fetchBanks();
        } else {
          state = state.copyWith(
            loading: false,
            error: createResult['message']?.toString() ?? 'Failed to add bank account',
          );
        }
      } else {
        state = state.copyWith(
          loading: false,
          error: validateResult['message']?.toString() ?? 'Bank verification failed',
        );
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Failed to validate bank account');
    }
  }

  // ── Fetch KYC Status ──
  Future<void> fetchKycStatus() async {
    final uniqueId = _resolveUniqueId();
    if (uniqueId.isEmpty) return;

    state = state.copyWith(loading: true, clearError: true);

    try {
      final result = await _augmontApi.fetchAugmontKycProfile(uniqueId);
      if (result['ok'] == true) {
        final kycProfile = result['kycProfile'] as Map<String, dynamic>? ?? {};
        final panStatus = kycProfile['panStatus']?.toString()?.toLowerCase() ?? '';
        final aadhaarStatus = kycProfile['aadhaarStatus']?.toString()?.toLowerCase() ?? '';
        final bankStatus = kycProfile['bankStatus']?.toString()?.toLowerCase() ?? '';
        final approved = kycProfile['status']?.toString()?.toLowerCase() == 'approved';

        state = state.copyWith(
          loading: false,
          panVerified: panStatus == 'verified' || panStatus == 'approved',
          aadhaarVerified: aadhaarStatus == 'verified' || aadhaarStatus == 'approved',
          bankVerified: bankStatus == 'verified' || bankStatus == 'approved',
          kycApproved: approved,
        );
      } else {
        state = state.copyWith(loading: false);
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Failed to fetch KYC status');
    }
  }

  // ── Fetch Banks ──
  Future<void> fetchBanks() async {
    final uniqueId = _resolveUniqueId();
    if (uniqueId.isEmpty) return;

    try {
      final result = await _augmontApi.fetchAugmontUserBanks(uniqueId);
      if (result['ok'] == true) {
        final banks = (result['banks'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        state = state.copyWith(banks: banks);
      }
    } catch (_) {}
  }

  // ── Reset ──
  void reset() {
    state = const KycState();
  }
}

// ── KYC Provider ──
final kycProvider = StateNotifierProvider<KycNotifier, KycState>((ref) {
  return KycNotifier(ref.read(augmontApiProvider), ref.read(transbankApiProvider));
});
