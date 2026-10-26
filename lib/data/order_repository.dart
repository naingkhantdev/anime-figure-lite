import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/stock.dart';
import '../models/cart_item.dart';
import '../models/shop_order.dart';
import 'inventory_repository.dart';
import '../utils/phone.dart';

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

class OrderRepository {
  OrderRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  /// Creates `pending` orders, one for each shop in the cart (the house's
  /// own figures count as one shop), so each shop sees and handles only its
  /// own. Prices and names are re-read from Firestore inside a transaction
  /// rather than taken from the cart. Returns how many orders it made.
  ///
  /// Stock is NOT decremented here: on the Spark plan there are no Cloud
  /// Functions, and security rules can't safely validate a multi-product
  /// stock change. Staff confirm the order and adjust stock in the Firebase
  /// console. See README "Limits of the small tier".
  Future<int> placeOrder({
    required String userId,
    required List<CartItem> cart,
    required String phone,
    required DeliveryMethod deliveryMethod,
    required String address,
    required String note,
  }) async {
    if (cart.isEmpty) throw OrderException('Your cart is empty.');
    if (cart.length > maxOrderLines) {
      throw OrderException(
          'An order can have at most $maxOrderLines products.');
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

    return _db.runTransaction((tx) async {
      final lines = <String, List<OrderLine>>{};
      final totals = <String, int>{};

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
        final shopId = data['shop_id'] as String? ?? '';
        (lines[shopId] ??= []).add(OrderLine(
          productId: snap.id,
          name: data['name'] as String? ?? item.product.name,
          price: price,
          quantity: item.quantity,
        ));
        totals[shopId] = (totals[shopId] ?? 0) + price * item.quantity;
      }

      for (final MapEntry(key: shopId, value: shopLines) in lines.entries) {
        tx.set(_orders.doc(), {
          'user_id': userId,
          'shop_id': shopId,
          'status': 'pending',
          'items': shopLines.map((l) => l.toMap()).toList(),
          'total': totals[shopId],
          'phone': cleanPhone,
          'delivery_method': deliveryMethod.name,
          'address': cleanAddress,
          'note': note.trim(),
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      return lines.length;
    });
  }

  /// A shop's orders, newest first. firestore.rules lets only its owner
  /// read them. Sorted client-side so no composite index is needed.
  Stream<List<ShopOrder>> watchShopOrders(String shopId) => _orders
      .where('shop_id', isEqualTo: shopId)
      .snapshots()
      .map((snap) => snap.docs.map(ShopOrder.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now())));

  /// The shop accepts an order. Each figure leaves its stock as a "Stock
  /// out" at the order's price, so stock and history stay true; then the
  /// order is marked confirmed. Stops at the first figure short of stock.
  Future<void> confirmShopOrder(
      ShopOrder order, InventoryRepository inventory) async {
    final prefix = '${inventory.shopId}_';
    for (final line in order.items) {
      if (!line.productId.startsWith(prefix)) continue;
      await inventory.recordMove(
        itemId: line.productId.substring(prefix.length),
        type: MoveType.stockOut,
        quantity: line.quantity,
        unitPrice: line.price,
        note: 'App order ${order.id.substring(0, 6).toUpperCase()}',
      );
    }
    await setShopOrderStatus(order.id, 'confirmed');
  }

  /// The shop moves its order on: confirmed, shipped, or cancelled.
  /// firestore.rules allows only the steps a shop may take.
  Future<void> setShopOrderStatus(String orderId, String status) =>
      _orders.doc(orderId).update({'status': status});

  /// Customers may only move their own order from `pending` to `cancelled`;
  /// firestore.rules enforces this.
  Future<void> cancelOrder(String orderId) =>
      _orders.doc(orderId).update({'status': 'cancelled'});

  /// Before an account is deleted: cancels its pending orders and blanks
  /// the phone, address and note on all of them. The orders stay, so the
  /// shop's sales records still add up. firestore.rules allows exactly this.
  Future<void> forgetContactDetails(String userId) async {
    final snap = await _orders.where('user_id', isEqualTo: userId).get();
    for (final doc in snap.docs) {
      if (doc.data()['status'] == 'pending') await cancelOrder(doc.id);
      await doc.reference.update({'phone': '', 'address': '', 'note': ''});
    }
  }

  /// Sorted client-side (newest first) so no composite index is needed.
  Stream<List<ShopOrder>> watchOrdersFor(String userId) => _orders
      .where('user_id', isEqualTo: userId)
      .snapshots()
      .map((snap) => snap.docs.map(ShopOrder.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now())));
}
