import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Every account that has opened the app, so the super admin can find
/// customers and shop admins by email. Firebase Auth's own list isn't
/// readable from the app.
class UserRepository {
  UserRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Notes that [uid] has opened the app, as [email]. Read first: an
  /// update of a missing document is refused by the rules, not reported as
  /// missing.
  Future<void> record(String uid, String email) async {
    final doc = _users.doc(uid);
    if ((await doc.get()).exists) {
      await doc.update({
        'email': email,
        'last_seen_at': FieldValue.serverTimestamp(),
      });
    } else {
      await doc.set({
        'email': email,
        'created_at': FieldValue.serverTimestamp(),
        'last_seen_at': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Before the account itself is deleted.
  Future<void> forget(String uid) => _users.doc(uid).delete();

  /// Super admin only. Most recently seen first.
  Stream<List<AppUser>> watchAll() => _users
      .orderBy('last_seen_at', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(AppUser.fromDoc).toList());
}
