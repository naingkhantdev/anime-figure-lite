import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/l10n.dart';
import '../models/blacklist_entry.dart';

// These must match firestore.rules.
const maxEmailLength = 254;
const maxRemarkLength = 500;

class BlacklistException extends AppException {
  BlacklistException(super.message);
}

/// Accounts the super admin has blocked, by email.
///
/// Each block is two documents, written and deleted together:
/// - `blacklist/{email}`: the email and the super admin's private remark.
/// - `blocked/{email}`: empty, so the blocked account itself can find out
///   it is blocked without ever seeing the remark.
class BlacklistRepository {
  BlacklistRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _blacklist =>
      _db.collection('blacklist');

  CollectionReference<Map<String, dynamic>> get _blocked =>
      _db.collection('blocked');

  /// The document id for [email]: Firebase compares emails ignoring case.
  static String keyFor(String email) => email.trim().toLowerCase();

  /// Whether the account with [email] is blocked.
  Stream<bool> watchIsBlocked(String email) =>
      _blocked.doc(keyFor(email)).snapshots().map((snap) => snap.exists);

  /// Super admin only. Newest first.
  Stream<List<BlacklistEntry>> watchAll() => _blacklist
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(BlacklistEntry.fromDoc).toList());

  /// The document id and cleaned remark for a block, or a
  /// [BlacklistException] saying what to fix.
  static (String, String) check(String email, String remark) {
    final key = keyFor(email);
    if (key.isEmpty ||
        key.length > maxEmailLength ||
        key.contains('/') ||
        !RegExp(r'^[^@\s]+@[^@\s]+$').hasMatch(key)) {
      throw BlacklistException((l) => l.errEmailInvalid);
    }
    final cleanRemark = remark.trim();
    if (cleanRemark.isEmpty) {
      throw BlacklistException((l) => l.errRemarkEmpty);
    }
    if (cleanRemark.length > maxRemarkLength) {
      throw BlacklistException((l) => l.errTextTooLong(maxRemarkLength));
    }
    return (key, cleanRemark);
  }

  /// Super admin only. Blocks [email], or changes the remark of an email
  /// already blocked.
  Future<void> block(String email, String remark) async {
    final (key, cleanRemark) = check(email, remark);
    final existing = await _blacklist.doc(key).get();
    if (existing.exists) {
      await _blacklist.doc(key).update({'remark': cleanRemark});
      return;
    }
    await (_db.batch()
          ..set(_blacklist.doc(key), {
            'email': key,
            'remark': cleanRemark,
            'created_at': FieldValue.serverTimestamp(),
          })
          ..set(_blocked.doc(key), {
            'created_at': FieldValue.serverTimestamp(),
          }))
        .commit();
  }

  /// Super admin only.
  Future<void> unblock(String email) {
    final key = keyFor(email);
    return (_db.batch()
          ..delete(_blacklist.doc(key))
          ..delete(_blocked.doc(key)))
        .commit();
  }
}
