import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/subscription.dart';

/// Firestore: `shops/{owner uid}`
/// Fields: name, phone, owner_email, expires_at (timestamp or null while
/// pending), created_at.
class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.phone,
    required this.ownerEmail,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String ownerEmail;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  ShopStatus statusAt(DateTime now) => shopStatus(expiresAt, now);

  factory Shop.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Shop(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      ownerEmail: data['owner_email'] as String? ?? '',
      expiresAt: (data['expires_at'] as Timestamp?)?.toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }
}
