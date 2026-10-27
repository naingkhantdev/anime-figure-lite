import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/inventory_repository.dart';
import '../data/order_repository.dart';
import '../data/photo_repository.dart';
import '../data/product_repository.dart';
import '../data/shop_repository.dart';
import '../logic/catalog.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/item.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../models/shop_order.dart';
import '../models/shop_public.dart';
import '../models/stock_move.dart';

final authRepositoryProvider =
    Provider((ref) => AuthRepository(FirebaseAuth.instance));

final productRepositoryProvider =
    Provider((ref) => ProductRepository(FirebaseFirestore.instance));

final photoRepositoryProvider =
    Provider((ref) => PhotoRepository(FirebaseFirestore.instance));

/// A photo's JPEG bytes, by `photos/{id}`. Kept for the session once
/// loaded, so scrolling back doesn't fetch it again.
final photoBytesProvider = FutureProvider.family<Uint8List?, String>(
  (ref, id) => ref.watch(photoRepositoryProvider).load(id),
);

final orderRepositoryProvider =
    Provider((ref) => OrderRepository(FirebaseFirestore.instance));

/// A payment screenshot's JPEG bytes, by `payment_proofs/{id}`.
final paymentProofProvider = FutureProvider.family<Uint8List?, String>(
  (ref, id) => ref.watch(orderRepositoryProvider).loadPaymentProof(id),
);

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

// ------------------------------------------------------------------ roles
// Who someone is decides what they see; see ui/pages/role_gate.dart.

final shopRepositoryProvider =
    Provider((ref) => ShopRepository(FirebaseFirestore.instance));

final isSuperAdminProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(false);
  return ref.watch(shopRepositoryProvider).watchIsSuperAdmin(user.uid);
});

/// The signed-in owner's shop, or null before they have created it.
final myShopProvider = StreamProvider<Shop?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(shopRepositoryProvider).watchShop(user.uid);
});

/// A shop's phone, delivery fee and ways to pay, readable by anyone; null
/// until the shop has saved its settings.
final shopPublicProvider = StreamProvider.family<ShopPublic?, String>(
  (ref, shopId) => ref.watch(shopRepositoryProvider).watchPublic(shopId),
);

/// Super admin only.
final allShopsProvider = StreamProvider<List<Shop>>(
  (ref) => ref.watch(shopRepositoryProvider).watchAllShops(),
);

/// Whether the signed-in owner's shop may be changed right now. Pages use it
/// to disable buttons; firestore.rules are what actually enforce it.
final canWriteProvider = Provider<bool>((ref) {
  final shop = ref.watch(myShopProvider).valueOrNull;
  return shop?.statusAt(DateTime.now()).canWrite ?? false;
});

/// Only read inside a shop, where somebody is always signed in.
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) throw StateError('No shop without a signed-in owner.');
  return InventoryRepository(
    FirebaseFirestore.instance,
    shopId: user.uid,
    // Read when writing, not watched: a change to the shop shouldn't
    // restart every stock stream.
    shop: () => ref.read(myShopProvider).valueOrNull,
  );
});

final itemsProvider = StreamProvider<List<Item>>(
  (ref) => ref.watch(inventoryRepositoryProvider).watchItems(),
);

final itemProvider = StreamProvider.family<Item?, String>(
  (ref, itemId) => ref.watch(inventoryRepositoryProvider).watchItem(itemId),
);

final recentMovesProvider = StreamProvider<List<StockMove>>(
  (ref) => ref.watch(inventoryRepositoryProvider).watchRecentMoves(),
);

final itemMovesProvider = StreamProvider.family<List<StockMove>, String>(
  (ref, itemId) =>
      ref.watch(inventoryRepositoryProvider).watchItemMoves(itemId),
);

final customersProvider = StreamProvider<List<Customer>>(
  (ref) => ref.watch(inventoryRepositoryProvider).watchCustomers(),
);

/// Customers' orders for the signed-in owner's shop, newest first.
final shopOrdersProvider = StreamProvider<List<ShopOrder>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref.watch(orderRepositoryProvider).watchShopOrders(user.uid);
});

/// What the customer has asked the catalog to show: search, sort, filters.
final catalogFilterProvider =
    StateProvider<CatalogFilter>((ref) => const CatalogFilter());
