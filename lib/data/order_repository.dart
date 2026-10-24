import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';
import '../models/shop_order.dart';

const maxOrderLines = 20; // must match firestore.rules

class OrderException implements Exception {
  OrderException(this.message);
  final String message;
  @override
  String toString() => message;
}

class OrderRepository {
  OrderRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  /// Creates a `pending` order. Prices and names are re-read from Firestore
  /// inside a transaction rather than taken from the cart.
  ///
  /// Stock is NOT decremented here: on the Spark plan there are no Cloud
  /// Functions, and security rules can't safely validate a multi-product
  /// stock change. Staff confirm the order and adjust stock in the Firebase
  /// console. See README "Limits of the small tier".
  Future<void> placeOrder({
    required String userId,
    required List<CartItem> cart,
  }) async {
    if (cart.isEmpty) throw OrderException('Your cart is empty.');
    if (cart.length > maxOrderLines) {
      throw OrderException('An order can have at most $maxOrderLines products.');
    }

    await _db.runTransaction((tx) async {
      final lines = <OrderLine>[];
      var total = 0;

      for (final item in cart) {
        final snap =
            await tx.get(_db.collection('products').doc(item.product.id));
        final data = snap.data();
        if (data == null || data['is_active'] != true) {
          throw OrderException('${item.product.name} is no longer available.');
        }
        final stock = (data['stock_quantity'] as num?)?.toInt() ?? 0;
        if (stock < item.quantity) {
          throw OrderException(
              'Only $stock of ${item.product.name} left in stock.');
        }
        final price = (data['price_cents'] as num?)?.toInt() ?? 0;
        lines.add(OrderLine(
          productId: snap.id,
          name: data['name'] as String? ?? item.product.name,
          priceCents: price,
          quantity: item.quantity,
        ));
        total += price * item.quantity;
      }

      tx.set(_orders.doc(), {
        'user_id': userId,
        'status': 'pending',
        'items': lines.map((l) => l.toMap()).toList(),
        'total_cents': total,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Sorted client-side so no composite index is needed.
  Stream<List<ShopOrder>> watchOrdersFor(String userId) => _orders
      .where('user_id', isEqualTo: userId)
      .snapshots()
      .map((snap) => snap.docs.map(ShopOrder.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now())));
}
