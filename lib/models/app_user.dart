import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: `users/{uid}`, written by each account's own app when it
/// opens (see UserRepository.record) and listed by the super admin.
/// Fields: email, created_at, last_seen_at.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.createdAt,
    this.lastSeenAt,
  });

  final String id;
  final String email;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AppUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      lastSeenAt: (data['last_seen_at'] as Timestamp?)?.toDate(),
    );
  }
}
