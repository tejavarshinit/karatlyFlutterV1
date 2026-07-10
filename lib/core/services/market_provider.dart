import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/augmont_api.dart';
import '../models/gold_rate_model.dart';
import '../models/product_model.dart';
import 'rate_provider.dart';

// ── Date Range Helper ──
({String fromDate, String toDate}) getDateRange(String period) {
  final toDate = DateTime.now().toUtc();
  DateTime fromDate;

  switch (period) {
    case '3D':
      fromDate = toDate.subtract(const Duration(days: 3));
      break;
    case '1W':
      fromDate = toDate.subtract(const Duration(days: 7));
      break;
    case '1M':
      fromDate = DateTime.utc(toDate.year, toDate.month - 1, toDate.day);
      break;
    case '1Y':
      fromDate = DateTime.utc(toDate.year - 1, toDate.month, toDate.day);
      break;
    default:
      fromDate = DateTime.utc(toDate.year, toDate.month - 1, toDate.day);
  }

  return (
    fromDate: fromDate.toIso8601String().substring(0, 10),
    toDate: toDate.toIso8601String().substring(0, 10),
  );
}

// ── Market State ──
class MarketState {
  final String metalType;
  final String ratePeriod;
  final List<RateHistoryPoint> chartData;
  final GoldRate? liveRate;
  final List<Product> products;
  final String searchQuery;
  final bool loadingChart;
  final bool loadingProducts;
  final String? error;

  const MarketState({
    this.metalType = 'gold',
    this.ratePeriod = '1M',
    this.chartData = const [],
    this.liveRate,
    this.products = const [],
    this.searchQuery = '',
    this.loadingChart = true,
    this.loadingProducts = true,
    this.error,
  });

  MarketState copyWith({
    String? metalType,
    String? ratePeriod,
    List<RateHistoryPoint>? chartData,
    GoldRate? liveRate,
    List<Product>? products,
    String? searchQuery,
    bool? loadingChart,
    bool? loadingProducts,
    String? error,
  }) {
    return MarketState(
      metalType: metalType ?? this.metalType,
      ratePeriod: ratePeriod ?? this.ratePeriod,
      chartData: chartData ?? this.chartData,
      liveRate: liveRate ?? this.liveRate,
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
      loadingChart: loadingChart ?? this.loadingChart,
      loadingProducts: loadingProducts ?? this.loadingProducts,
      error: error,
    );
  }

  List<Product> get filteredProducts {
    var result = products.where((p) {
      final type = p.metalType.toLowerCase();
      return type.contains(metalType);
    }).toList();

    if (searchQuery.trim().isNotEmpty) {
      final term = searchQuery.trim().toLowerCase();
      result = result.where((p) {
        final searchable = [
          p.name,
          p.sku,
          p.purity,
          p.productWeight,
          p.redeemWeight,
          p.jewelleryType,
        ].join(' ').toLowerCase();
        return searchable.contains(term);
      }).toList();
    }

    return result.take(8).toList();
  }
}

// ── Market Notifier ──
class MarketNotifier extends StateNotifier<MarketState> {
  final Ref _ref;

  MarketNotifier(this._ref) : super(const MarketState());

  AugmontApi get _api => _ref.read(augmontApiProvider);

  void init() {
    fetchChartData();
    fetchProducts();
  }

  void setMetalType(String type) {
    if (state.metalType == type) return;
    state = state.copyWith(metalType: type);
    fetchChartData();
  }

  void setRatePeriod(String period) {
    if (state.ratePeriod == period) return;
    state = state.copyWith(ratePeriod: period);
    fetchChartData();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> fetchChartData() async {
    state = state.copyWith(loadingChart: true);
    try {
      final dates = getDateRange(state.ratePeriod);
      final result = await _api.fetchAugmontRateHistory(
        fromDate: dates.fromDate,
        toDate: dates.toDate,
        metalType: state.metalType,
        force: true,
      );

      if (result['ok'] == true) {
        final history = result['history'] as List<RateHistoryPoint>;
        state = state.copyWith(chartData: history, loadingChart: false, error: null);
      } else {
        state = state.copyWith(chartData: [], loadingChart: false, error: result['message']?.toString());
      }
    } catch (e) {
      state = state.copyWith(chartData: [], loadingChart: false, error: 'Failed to load chart data');
    }
  }

  Future<void> fetchProducts() async {
    state = state.copyWith(loadingProducts: true);
    try {
      final result = await _api.fetchAugmontProducts(1, 30);
      if (result['ok'] == true) {
        final rawProducts = result['products'] as List<dynamic>;
        final products = rawProducts
            .map((e) => e is Product ? e : Product.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(products: products, loadingProducts: false);
      } else {
        state = state.copyWith(products: [], loadingProducts: false);
      }
    } catch (e) {
      state = state.copyWith(products: [], loadingProducts: false);
    }
  }

  Future<void> refresh() async {
    await Future.wait([fetchChartData(), fetchProducts()]);
  }
}

// ── Market Provider ──
final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((ref) {
  return MarketNotifier(ref)..init();
});
