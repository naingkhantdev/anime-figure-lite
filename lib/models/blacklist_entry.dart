import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: `blacklist/{email, lowercased}`, read by the super admin only.
/// Fields: email, remark (why they were blocked), created_at.
class BlacklistEntry {
  const BlacklistEntry({
    required this.email,
    required this.remark,
    this.createdAt,
  });

  final String email;
  final String remark;
  final DateTime? createdAt;

  factory BlacklistEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return BlacklistEntry(
      email: data['email'] as String? ?? doc.id,
      remark: data['remark'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }
}
