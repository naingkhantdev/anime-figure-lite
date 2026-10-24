import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shop.dart';
import '../utils/phone.dart';

// These must match firestore.rules.
const maxShopNameLength = 80;

class ShopException implements Exception {
  ShopException(this.message);
  final String message;
  @override
  String toString() => message;
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

  Future<void> updateShop(String uid,
          {required String name, required String phone}) =>
      _shops.doc(uid).update(_validate(name, phone));

  Map<String, Object> _validate(String name, String phone) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ShopException('Enter the shop name.');
    if (cleanName.length > maxShopNameLength) {
      throw ShopException(
          'Keep the shop name under $maxShopNameLength letters.');
    }
    var cleanPhone = '';
    if (phone.trim().isNotEmpty) {
      cleanPhone = normalizePhone(phone) ??
          (throw ShopException('Enter a phone number like 09xxxxxxxxx.'));
    }
    return {'name': cleanName, 'phone': cleanPhone};
  }

  /// Super admin only. Every shop, sorted client-side by name.
  Stream<List<Shop>> watchAllShops() =>
      _shops.snapshots().map((snap) => snap.docs.map(Shop.fromDoc).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));

  /// Super admin only. Null puts the shop back to pending.
  Future<void> setExpiry(String shopId, DateTime? expiresAt) =>
      _shops.doc(shopId).update({
        'expires_at': expiresAt == null ? null : Timestamp.fromDate(expiresAt),
      });
}
