import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/augmont_api.dart';
import '../api/diamond_api.dart';
import '../models/augmont_model.dart';
import '../models/diamond_model.dart';
import '../storage/local_storage.dart';
import '../utils/unique_id.dart';
import 'auth_provider.dart';

// ── Orders State ──
class OrdersState {
  final List<AugmontOrder> orders;
  final List<DiamondOrder> diamondOrders;
  final bool loading;
  final String? error;

  const OrdersState({
    this.orders = const [],
    this.diamondOrders = const [],
    this.loading = false,
    this.error,
  });

  OrdersState copyWith({
    List<AugmontOrder>? orders,
    List<DiamondOrder>? diamondOrders,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      diamondOrders: diamondOrders ?? this.diamondOrders,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Derived helpers
  List<AugmontOrder> get buyOrders => orders.where((o) => o.type.toUpperCase() == 'BUY').toList();
  List<AugmontOrder> get sellOrders => orders.where((o) => o.type.toUpperCase() == 'SELL').toList();
  List<AugmontOrder> get redeemOrders => orders.where((o) => o.type.toUpperCase() == 'REDEEM').toList();

  int get buyCount => buyOrders.length;
  int get sellCount => sellOrders.length;
  int get redeemCount => redeemOrders.length;

  double get totalAmount => orders.fold(0, (sum, o) => sum + o.amount);
}

// ── Orders Notifier ──
class OrdersNotifier extends StateNotifier<OrdersState> {
  final AugmontApi _augmontApi;
  final DiamondApi _diamondApi;

  OrdersNotifier(this._augmontApi, this._diamondApi) : super(const OrdersState());

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

  Future<void> fetchAllOrders() async {
    final uniqueId = _resolveUniqueId();
    if (uniqueId.isEmpty) {
      state = state.copyWith(error: 'User not registered', loading: false, clearError: true);
      return;
    }

    state = state.copyWith(loading: true, clearError: true);

    try {
      final results = await Future.wait([
        _augmontApi.fetchAugmontBuyOrders(uniqueId: uniqueId),
        _augmontApi.fetchAugmontSellOrders(uniqueId: uniqueId),
        _augmontApi.fetchAugmontRedeemOrders(uniqueId: uniqueId),
        _diamondApi.fetchDiamondOrders(),
      ]);

      final buyRes = results[0];
      final sellRes = results[1];
      final redeemRes = results[2];
      final diamondRes = results[3];

      final allOrders = <AugmontOrder>[
        ...((buyRes['orders'] as List<AugmontOrder>?) ?? []),
        ...((sellRes['orders'] as List<AugmontOrder>?) ?? []),
        ...((redeemRes['orders'] as List<AugmontOrder>?) ?? []),
      ];

      allOrders.sort((a, b) {
        final dateA = DateTime.tryParse(a.date) ?? DateTime(0);
        final dateB = DateTime.tryParse(b.date) ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      List<DiamondOrder> diamondOrders = [];
      if (diamondRes['ok'] == true && diamondRes['data'] != null) {
        final data = diamondRes['data'] as Map<String, dynamic>;
        final dataList = data['data'];
        if (dataList is List) {
          diamondOrders = dataList
              .map((e) => DiamondOrder.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      state = state.copyWith(
        orders: allOrders,
        diamondOrders: diamondOrders,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Failed to load orders');
    }
  }
}

// ── Provider ──
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final dio = ref.read(dioAugmontProvider);
  final augmontApi = AugmontApi(dio);
  final diamondApi = DiamondApi(dio);
  return OrdersNotifier(augmontApi, diamondApi);
});
