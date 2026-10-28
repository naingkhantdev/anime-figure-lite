import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/l10n.dart';
import '../models/shop.dart';
import '../models/shop_public.dart';
import '../utils/phone.dart';

// These must match firestore.rules.
const maxShopNameLength = 80;
const maxDeliveryFee = 1000000;
const maxPaymentMethods = 6;

// App-side limits on a payment method; the rules cap the list's size.
const maxAccountNameLength = 60;
const maxAccountNumberLength = 40;

class ShopException extends AppException {
  ShopException(super.message);
}

/// Shops and the super admin's view of them. A shop's id is its owner's uid,
/// so an account has exactly one shop.
class ShopRepository {
  ShopRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _shops =>
      _db.collection('shops');

  /// True when `super_admins/{uid}` exists. That document is only ever made
  /// by hand in the Firebase console.
  Stream<bool> watchIsSuperAdmin(String uid) => _db
      .collection('super_admins')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.exists);

  /// Null until the owner has created their shop.
  Stream<Shop?> watchShop(String uid) => _shops
      .doc(uid)
      .snapshots()
      .map((snap) => snap.exists ? Shop.fromDoc(snap) : null);

  /// Creates the signed-in owner's shop. It starts pending: nothing can be
  /// changed until the super admin sets an expiry date.
  Future<void> createShop({
    required String uid,
    required String email,
    required String name,
    required String phone,
  }) async {
    final fields = _validate(name, phone);
    await _shops.doc(uid).set({
      ...fields,
      'owner_email': email,
      'expires_at': null,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// What customers may read about a shop (see ShopPublic). Null until the
  /// owner first saves their settings.
  Stream<ShopPublic?> watchPublic(String shopId) => _db
      .collection('shop_public')
      .doc(shopId)
      .snapshots()
      .map((snap) => snap.exists ? ShopPublic.fromDoc(snap) : null);

  /// Saves the shop's settings in one write: name and phone on the shop,
  /// what customers see in shop_public, and the new name on its figures in
  /// the catalog. firestore.rules allow it only while the shop is open.
  Future<void> saveSettings(
    String uid, {
    required String name,
    required String phone,
    required int deliveryFee,
    required List<PaymentMethod> paymentMethods,
  }) async {
    final fields = _validate(name, phone);
    if (deliveryFee < 0 || deliveryFee > maxDeliveryFee) {
      throw ShopException((l) => l.errDeliveryFeeTooLarge);
    }
    if (paymentMethods.length > maxPaymentMethods) {
      throw ShopException((l) => l.errTooManyPaymentMethods(maxPaymentMethods));
    }
    final methods = [
      for (final m in paymentMethods)
        PaymentMethod(
          type: m.type,
          accountName: m.accountName.trim(),
          number: m.number.trim(),
        ),
    ];
    for (final m in methods) {
      if (m.accountName.isEmpty || m.number.isEmpty) {
        throw ShopException((l) => l.errPaymentMethodIncomplete);
      }
      if (m.accountName.length > maxAccountNameLength ||
          m.number.length > maxAccountNumberLength) {
        throw ShopException((l) => l.errPaymentMethodTooLong);
      }
    }
    final batch = _db.batch()
      ..update(_shops.doc(uid), fields)
      ..set(_db.collection('shop_public').doc(uid), {
        'phone': fields['phone']!,
        'delivery_fee': deliveryFee,
        'payment_methods': [for (final m in methods) m.toMap()],
        'updated_at': FieldValue.serverTimestamp(),
      });
    for (final doc in (await _listings(uid)).docs) {
      batch.update(doc.reference, {
        'shop_name': fields['name'],
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// A shop's figures in the customer catalog (see Product).
  Future<QuerySnapshot<Map<String, dynamic>>> _listings(String shopId) =>
      _db.collection('products').where('shop_id', isEqualTo: shopId).get();

  Map<String, Object> _validate(String name, String phone) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ShopException((l) => l.errShopNameEmpty);
    if (cleanName.length > maxShopNameLength) {
      throw ShopException((l) => l.errShopNameTooLong(maxShopNameLength));
    }
    // Customers call and Viber the shop on it, so it is required.
    final cleanPhone =
        normalizePhone(phone) ?? (throw ShopException((l) => l.errPhoneFormat));
    return {'name': cleanName, 'phone': cleanPhone};
  }

  /// Super admin only. Every shop, sorted client-side by name.
  Stream<List<Shop>> watchAllShops() =>
      _shops.snapshots().map((snap) => snap.docs.map(Shop.fromDoc).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));

  /// Super admin only. Null puts the shop back to pending. The shop's
  /// figures in the catalog show until the same date, so renewing a shop
  /// brings them back and ending it hides them.
  Future<void> setExpiry(String shopId, DateTime? expiresAt) async {
    final stamp = expiresAt == null ? null : Timestamp.fromDate(expiresAt);
    final batch = _db.batch()
      ..update(_shops.doc(shopId), {'expires_at': stamp});
    for (final doc in (await _listings(shopId)).docs) {
      batch.update(doc.reference, {'shop_open_until': stamp});
    }
    await batch.commit();
  }
}
