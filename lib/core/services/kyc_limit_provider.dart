import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api/augmont_api.dart';
import '../storage/local_storage.dart';
import '../utils/unique_id.dart';
import 'auth_provider.dart';
import 'rate_provider.dart';

const double _nonKycFyLimit = 1000;

class KycLimitState {
  final double remainingLimit;
  final double remainingLimitPreTax;
  final bool isKycVerified;
  final bool isLoading;
  final bool kycLimitExceeded;

  const KycLimitState({
    this.remainingLimit = 1000,
    this.remainingLimitPreTax = 970.87,
    this.isKycVerified = false,
    this.isLoading = false,
    this.kycLimitExceeded = false,
  });

  KycLimitState copyWith({
    double? remainingLimit,
    double? remainingLimitPreTax,
    bool? isKycVerified,
    bool? isLoading,
    bool? kycLimitExceeded,
  }) {
    return KycLimitState(
      remainingLimit: remainingLimit ?? this.remainingLimit,
      remainingLimitPreTax: remainingLimitPreTax ?? this.remainingLimitPreTax,
      isKycVerified: isKycVerified ?? this.isKycVerified,
      isLoading: isLoading ?? this.isLoading,
      kycLimitExceeded: kycLimitExceeded ?? this.kycLimitExceeded,
    );
  }
}

class KycLimitNotifier extends StateNotifier<KycLimitState> {
  final Ref _ref;

  KycLimitNotifier(this._ref) : super(const KycLimitState());

  Future<void> fetchKycLimit() async {
    final authState = _ref.read(authProvider);
    final isKycDone = authState.user?.kycApproved == true;
    if (isKycDone) {
      state = state.copyWith(isKycVerified: true, remainingLimit: _nonKycFyLimit, remainingLimitPreTax: _nonKycFyLimit / 1.03);
      return;
    }

    final uniqueId = _resolveUniqueId();
    if (uniqueId.isEmpty) return;

    state = state.copyWith(isLoading: true);
    try {
      final dio = _ref.read(augmontDioProvider);
      final api = AugmontApi(dio);
      final results = await Future.wait([
        api.fetchInvestmentSummary(uniqueId: uniqueId, metalType: 'gold'),
        api.fetchInvestmentSummary(uniqueId: uniqueId, metalType: 'silver'),
      ]);
      final goldUsed = (results[0]['totalBuyPostTaxAmount'] as num?)?.toDouble() ?? 0;
      final silverUsed = (results[1]['totalBuyPostTaxAmount'] as num?)?.toDouble() ?? 0;
      final fyTotal = goldUsed + silverUsed;
      final remaining = (_nonKycFyLimit - fyTotal).clamp(0, _nonKycFyLimit).toDouble();
      state = state.copyWith(
        remainingLimit: remaining,
        remainingLimitPreTax: remaining / 1.03,
        isLoading: false,
        isKycVerified: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void checkAmount(double amount) {
    final exceeded = !state.isKycVerified && amount > 0 && amount > state.remainingLimitPreTax;
    state = state.copyWith(kycLimitExceeded: exceeded);
  }

  void reset() {
    state = const KycLimitState();
  }

  String _resolveUniqueId() {
    final storedUniqueId = LocalStorageService.getUserUniqueId();
    if (storedUniqueId != null && storedUniqueId.isNotEmpty) return storedUniqueId;
    final profile = LocalStorageService.getUserProfile() ?? {};
    final uniqueId = profile['uniqueId']?.toString();
    if (uniqueId != null && uniqueId.isNotEmpty) return uniqueId;
    final phone = LocalStorageService.getUserPhone();
    if (phone != null && phone.isNotEmpty) {
      final dob = profile['dateOfBirth']?.toString() ?? '';
      return UniqueIdHelper.buildMobileDobUniqueId(mobileNumber: phone, dateOfBirth: dob);
    }
    return '';
  }
}

final kycLimitProvider = StateNotifierProvider<KycLimitNotifier, KycLimitState>((ref) {
  return KycLimitNotifier(ref);
});
