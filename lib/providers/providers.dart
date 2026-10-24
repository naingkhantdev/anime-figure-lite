import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/order_repository.dart';
import '../data/product_repository.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/shop_order.dart';

final authRepositoryProvider =
    Provider((ref) => AuthRepository(FirebaseAuth.instance));

final productRepositoryProvider =
    Provider((ref) => ProductRepository(FirebaseFirestore.instance));

final orderRepositoryProvider =
    Provider((ref) => OrderRepository(FirebaseFirestore.instance));

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final productsProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).watchActiveProducts(),
);

final myOrdersProvider = StreamProvider<List<ShopOrder>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref.watch(orderRepositoryProvider).watchOrdersFor(user.uid);
});

/// In-memory cart. Cleared on sign-out and after a successful order.
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    // Guests can fill a cart and sign in at checkout, so keep the cart when
    // going from signed-out to signed-in. Clear it on sign-out or when a
    // different account signs in.
    ref.listen(authStateProvider.select((s) => s.valueOrNull?.uid),
        (previous, next) {
      if (previous != null && previous != next) state = const [];
    });
    return const [];
  }

  void add(Product product) {
    final index = state.indexWhere((i) => i.product.id == product.id);
    if (index == -1) {
      if (product.stockQuantity < 1) return;
      state = [...state, CartItem(product: product, quantity: 1)];
    } else {
      setQuantity(product.id, state[index].quantity + 1);
    }
  }

  void setQuantity(String productId, int quantity) {
    if (quantity < 1) {
      remove(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(
            quantity: quantity.clamp(1, item.product.stockQuantity),
          )
        else
          item,
    ];
  }

  void remove(String productId) =>
      state = state.where((i) => i.product.id != productId).toList();

  void clear() => state = const [];
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).fold(0, (total, i) => total + i.quantity),
);
