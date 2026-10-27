import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/stock.dart';
import '../models/cart_item.dart';
import '../models/shop_order.dart';
import 'inventory_repository.dart';
import '../utils/phone.dart';
import '../l10n/l10n.dart';

// These must match firestore.rules.
const maxOrderLines = 20;
const maxPhoneLength = 20;
const maxTextLength = 500;
const maxProofBytes = 400 * 1024;

class OrderException extends AppException {
  OrderException(super.message);
}

class OrderRepository {
  OrderRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  /// Creates `pending` orders, one for each shop in the cart (the house's
  /// own figures count as one shop), so each shop sees and handles only its
  /// own. Prices, names and each shop's delivery fee are re-read from
  /// Firestore inside a transaction rather than taken from the cart.
  /// Returns how many orders it made.
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
    if (cart.isEmpty) throw OrderException((l) => l.errCartEmpty);
    if (cart.length > maxOrderLines) {
      throw OrderException((l) => l.errTooManyOrderLines(maxOrderLines));
    }
    final cleanPhone = normalizePhone(phone);
    if (cleanPhone == null) {
      throw OrderException((l) => l.errPhoneFormat);
    }
    final cleanAddress =
        deliveryMethod == DeliveryMethod.delivery ? address.trim() : '';
    if (deliveryMethod == DeliveryMethod.delivery && cleanAddress.isEmpty) {
      throw OrderException((l) => l.errAddressEmpty);
    }

    return _db.runTransaction((tx) async {
      final lines = <String, List<OrderLine>>{};
      final totals = <String, int>{};

      for (final item in cart) {
        final snap =
            await tx.get(_db.collection('products').doc(item.product.id));
        final data = snap.data();
        if (data == null || data['is_active'] != true) {
          throw OrderException(
              (l) => l.errProductUnavailable(item.product.name));
        }
        final stock = (data['stock_quantity'] as num?)?.toInt() ?? 0;
        if (stock < item.quantity) {
          throw OrderException(
              (l) => l.errOnlyLeftOf(stock, item.product.name));
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

      // Each shop's own delivery fee, as firestore.rules will check it.
      final fees = <String, int>{};
      for (final shopId in lines.keys) {
        if (deliveryMethod == DeliveryMethod.pickup || shopId.isEmpty) {
          fees[shopId] = 0;
          continue;
        }
        final info = await tx.get(_db.collection('shop_public').doc(shopId));
        fees[shopId] = (info.data()?['delivery_fee'] as num?)?.toInt() ?? 0;
      }

      for (final MapEntry(key: shopId, value: shopLines) in lines.entries) {
        tx.set(_orders.doc(), {
          'user_id': userId,
          'shop_id': shopId,
          'status': 'pending',
          'items': shopLines.map((l) => l.toMap()).toList(),
          'total': totals[shopId]! + fees[shopId]!,
          'delivery_fee': fees[shopId],
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

  /// Before an account is deleted: cancels its pending orders, blanks the
  /// phone, address and note on all of them, and deletes its payment
  /// screenshots. The orders stay, so the shop's sales records still add
  /// up. firestore.rules allows exactly this.
  Future<void> forgetContactDetails(String userId) async {
    final snap = await _orders.where('user_id', isEqualTo: userId).get();
    for (final doc in snap.docs) {
      if (doc.data()['status'] == 'pending') await cancelOrder(doc.id);
      await doc.reference.update({'phone': '', 'address': '', 'note': ''});
    }
    final proofs = await _proofs.where('user_id', isEqualTo: userId).get();
    for (final doc in proofs.docs) {
      await doc.reference.delete();
    }
  }

  CollectionReference<Map<String, dynamic>> get _proofs =>
      _db.collection('payment_proofs');

  /// Attaches [bytes], a screenshot of the customer's payment, to their
  /// waiting [order], replacing any earlier one. firestore.rules check the
  /// order is theirs, still pending, and with a shop.
  Future<void> sendPaymentProof(ShopOrder order, Uint8List bytes,
      {required String userId}) async {
    if (bytes.length > maxProofBytes) {
      throw OrderException((l) => l.errPhotoTooBig);
    }
    final proof = _proofs.doc();
    final batch = _db.batch()
      ..set(proof, {
        'order_id': order.id,
        'user_id': userId,
        'shop_id': order.shopId,
        'data': Blob(bytes),
        'created_at': FieldValue.serverTimestamp(),
      })
      ..update(_orders.doc(order.id), {
        'payment_proof_id': proof.id,
        'payment_sent_at': FieldValue.serverTimestamp(),
      });
    if (order.paymentSent) batch.delete(_proofs.doc(order.paymentProofId));
    await batch.commit();
  }

  /// The JPEG bytes of a payment screenshot, or null if it is gone.
  Future<Uint8List?> loadPaymentProof(String id) async {
    final data = (await _proofs.doc(id).get()).data()?['data'];
    return data is Blob ? data.bytes : null;
  }

  /// Sorted client-side (newest first) so no composite index is needed.
  Stream<List<ShopOrder>> watchOrdersFor(String userId) => _orders
      .where('user_id', isEqualTo: userId)
      .snapshots()
      .map((snap) => snap.docs.map(ShopOrder.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now())));
}
