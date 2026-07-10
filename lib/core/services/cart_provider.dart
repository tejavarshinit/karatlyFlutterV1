import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';

// ── Cart State ──
class CartState {
  final List<CartItem> items;
  final double total;

  const CartState({
    this.items = const [],
    this.total = 0,
  });

  CartState copyWith({
    List<CartItem>? items,
    double? total,
  }) {
    return CartState(
      items: items ?? this.items,
      total: total ?? this.total,
    );
  }
}

// ── Cart Notifier ──
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(CartItem item) {
    final newItems = [...state.items, item];
    state = state.copyWith(
      items: newItems,
      total: newItems.fold<double>(0.0, (sum, item) => sum + item.price),
    );
  }

  void removeItem(String id) {
    final newItems = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(
      items: newItems,
      total: newItems.fold<double>(0.0, (sum, item) => sum + item.price),
    );
  }

  void clearCart() {
    state = const CartState();
  }
}

// ── Provider ──
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
