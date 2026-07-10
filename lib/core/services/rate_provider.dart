import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gold_rate_model.dart';
import '../api/augmont_api.dart';
import '../storage/local_storage.dart';
import '../utils/constants.dart';

// ── Shared Dio for Augmont ──
final augmontDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = LocalStorageService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        LocalStorageService.clearAuthSession();
      }
      handler.next(error);
    },
  ));
  return dio;
});

// ── Shared AugmontApi ──
final augmontApiProvider = Provider<AugmontApi>((ref) {
  return AugmontApi(ref.read(augmontDioProvider));
});

// ── Rate State ──
class RateState {
  final GoldRate? currentRate;
  final List<RateHistoryPointInMemory> history;
  final bool loading;
  final String? error;

  const RateState({
    this.currentRate,
    this.history = const [],
    this.loading = true,
    this.error,
  });

  RateState copyWith({
    GoldRate? currentRate,
    List<RateHistoryPointInMemory>? history,
    bool? loading,
    String? error,
  }) {
    return RateState(
      currentRate: currentRate ?? this.currentRate,
      history: history ?? this.history,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

// ── Rate Notifier ──
class RateNotifier extends StateNotifier<RateState> {
  final AugmontApi _api;
  Timer? _poller;

  RateNotifier(this._api) : super(const RateState()) {
    _startPolling();
  }

  void _startPolling() {
    _fetch();
    _poller = Timer.periodic(AppConstants.rateCacheTtl, (_) => _fetch());
  }

  void stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  Future<void> _fetch() async {
    try {
      final result = await _api.fetchLiveGoldRateSnapshot(force: true);
      if (result['ok'] == true) {
        final snapshot = result['snapshot'] as GoldRate;
        state = state.copyWith(
          currentRate: snapshot,
          loading: false,
          error: null,
        );
      } else {
        state = state.copyWith(loading: false, error: result['message']?.toString());
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Failed to fetch rates');
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    await _fetch();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

// ── Rate Provider ──
final rateProvider = StateNotifierProvider<RateNotifier, RateState>((ref) {
  return RateNotifier(ref.read(augmontApiProvider));
});

// ── Computed Providers ──
final goldPriceProvider = Provider<double>((ref) {
  final rateState = ref.watch(rateProvider);
  return rateState.currentRate?.buyPrice ?? 0.0;
});

final silverPriceProvider = Provider<double>((ref) {
  final rateState = ref.watch(rateProvider);
  return rateState.currentRate?.silver.buyPrice ?? 0.0;
});
