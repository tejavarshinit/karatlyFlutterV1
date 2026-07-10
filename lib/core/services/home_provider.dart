import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/augmont_api.dart';
import '../storage/local_storage.dart';
import '../utils/unique_id.dart';
import 'rate_provider.dart';

// ── Investment Data ──
class InvestmentData {
  final double goldHoldingGrams;
  final double goldHoldingWithMultiplier;
  final double goldTotalInvested;
  final double goldTotalBuyPreTaxAmount;
  final double silverHoldingGrams;
  final double silverHoldingWithMultiplier;
  final double silverTotalInvested;
  final double silverTotalBuyPreTaxAmount;

  const InvestmentData({
    this.goldHoldingGrams = 0,
    this.goldHoldingWithMultiplier = 0,
    this.goldTotalInvested = 0,
    this.goldTotalBuyPreTaxAmount = 0,
    this.silverHoldingGrams = 0,
    this.silverHoldingWithMultiplier = 0,
    this.silverTotalInvested = 0,
    this.silverTotalBuyPreTaxAmount = 0,
  });

  double get totalInvested => goldTotalInvested + silverTotalInvested;
}

// ── Home State ──
class HomeState {
  final InvestmentData investment;
  final bool loading;
  final String? error;

  const HomeState({
    this.investment = const InvestmentData(),
    this.loading = false,
    this.error,
  });

  HomeState copyWith({
    InvestmentData? investment,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return HomeState(
      investment: investment ?? this.investment,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Home Notifier ──
class HomeNotifier extends StateNotifier<HomeState> {
  final AugmontApi _api;

  HomeNotifier(this._api) : super(const HomeState());

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
      final uniqueId = storedProfile['uniqueId']?.toString();
      if (uniqueId != null && uniqueId.isNotEmpty) return uniqueId;
    }
    final storedUniqueId = LocalStorageService.getUserUniqueId();
    if (storedUniqueId != null && storedUniqueId.isNotEmpty) return storedUniqueId;
    final phone = LocalStorageService.getUserPhone();
    if (phone != null && phone.isNotEmpty) {
      final profile = LocalStorageService.getUserProfile();
      final dob = profile?['dateOfBirth']?.toString() ?? '';
      final generated = UniqueIdHelper.buildMobileDobUniqueId(mobileNumber: phone, dateOfBirth: dob);
      if (generated.isNotEmpty) return generated;
    }
    return '';
  }

  Future<void> fetchInvestmentData() async {
    final uniqueId = _resolveUniqueId();
    if (uniqueId.isEmpty) return;

    state = state.copyWith(loading: true, clearError: true);

    try {
      final results = await Future.wait([
        _api.fetchInvestmentSummary(uniqueId: uniqueId, metalType: 'gold'),
        _api.fetchInvestmentSummary(uniqueId: uniqueId, metalType: 'silver'),
      ]);

      final goldRes = results[0];
      final silverRes = results[1];

      final investment = InvestmentData(
        goldHoldingGrams: (goldRes['currentHoldingGrams'] as num?)?.toDouble() ?? 0,
        goldHoldingWithMultiplier: (goldRes['currentHoldingWithMultiplier'] as num?)?.toDouble() ?? 0,
        goldTotalInvested: (goldRes['totalInvested'] as num?)?.toDouble() ?? 0,
        goldTotalBuyPreTaxAmount: (goldRes['totalBuyPreTaxAmount'] as num?)?.toDouble() ?? 0,
        silverHoldingGrams: (silverRes['currentHoldingGrams'] as num?)?.toDouble() ?? 0,
        silverHoldingWithMultiplier: (silverRes['currentHoldingWithMultiplier'] as num?)?.toDouble() ?? 0,
        silverTotalInvested: (silverRes['totalInvested'] as num?)?.toDouble() ?? 0,
        silverTotalBuyPreTaxAmount: (silverRes['totalBuyPreTaxAmount'] as num?)?.toDouble() ?? 0,
      );

      state = state.copyWith(investment: investment, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Failed to load investment data');
    }
  }
}

// ── Provider ──
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final api = AugmontApi(ref.read(augmontDioProvider));
  return HomeNotifier(api);
});
