import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';
import '../models/shop_order.dart';

// These must match firestore.rules.
const maxOrderLines = 20;
const maxPhoneLength = 20;
const maxTextLength = 500;

class OrderException implements Exception {
  OrderException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Removes spaces and dashes, then accepts Myanmar mobile numbers written as
/// `09…` or `+959…`. Deliberately loose so real numbers are never rejected.
/// Returns the cleaned number, or null if it doesn't look like a phone.
String? normalizePhone(String input) {
  final phone = input.replaceAll(RegExp(r'[\s-]'), '');
  return RegExp(r'^(09|\+959)\d{7,9}$').hasMatch(phone) ? phone : null;
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
    required String phone,
    required DeliveryMethod deliveryMethod,
    required String address,
    required String note,
  }) async {
    if (cart.isEmpty) throw OrderException('Your cart is empty.');
    if (cart.length > maxOrderLines) {
      throw OrderException('An order can have at most $maxOrderLines products.');
    }
    final cleanPhone = normalizePhone(phone);
    if (cleanPhone == null) {
      throw OrderException('Enter a phone number like 09xxxxxxxxx.');
    }
    final cleanAddress =
        deliveryMethod == DeliveryMethod.delivery ? address.trim() : '';
    if (deliveryMethod == DeliveryMethod.delivery && cleanAddress.isEmpty) {
      throw OrderException('Enter a delivery address.');
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
        final price = (data['price'] as num?)?.toInt() ?? 0;
        lines.add(OrderLine(
          productId: snap.id,
          name: data['name'] as String? ?? item.product.name,
          price: price,
          quantity: item.quantity,
        ));
        total += price * item.quantity;
      }

      tx.set(_orders.doc(), {
        'user_id': userId,
        'status': 'pending',
        'items': lines.map((l) => l.toMap()).toList(),
        'total': total,
        'phone': cleanPhone,
        'delivery_method': deliveryMethod.name,
        'address': cleanAddress,
        'note': note.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Customers may only move their own order from `pending` to `cancelled`;
  /// firestore.rules enforces this.
  Future<void> cancelOrder(String orderId) =>
      _orders.doc(orderId).update({'status': 'cancelled'});

  /// Sorted client-side (newest first) so no composite index is needed.
  Stream<List<ShopOrder>> watchOrdersFor(String userId) => _orders
      .where('user_id', isEqualTo: userId)
      .snapshots()
      .map((snap) => snap.docs.map(ShopOrder.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now())));
}
