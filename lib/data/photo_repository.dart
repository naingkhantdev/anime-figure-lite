import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Biggest side of a photo, in pixels, and its JPEG quality. A phone photo
/// (often 4000px, 3–5 MB) comes out around 60–150 KB: sharp on a phone
/// screen and small enough to keep in Firestore on the free plan.
const photoMaxSide = 800.0;
const photoQuality = 70;

/// Must match firestore.rules (photos). A Firestore document holds at most
/// 1 MiB; this leaves plenty of room.
const maxPhotoBytes = 400 * 1024;

/// What an item's image_url says when its photo is in Firestore:
/// `photo:{id}` for `photos/{id}`.
const photoUrlPrefix = 'photo:';

class PhotoException implements Exception {
  PhotoException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Photos of shops' items, kept in Firestore because Firebase Storage needs
/// the paid plan. Each photo is its own document, `photos/{id}`, so the
/// catalog list stays small and each photo is loaded only when shown.
/// Fields: shop_id, data (bytes, JPEG), created_at.
class PhotoRepository {
  PhotoRepository(this._db, {ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final FirebaseFirestore _db;
  final ImagePicker _picker;

  CollectionReference<Map<String, dynamic>> get _photos =>
      _db.collection('photos');

  /// Lets the owner take or choose a photo, already resized and compressed
  /// by the picker. Null when they back out.
  Future<XFile?> pick(ImageSource source) => _picker.pickImage(
        source: source,
        maxWidth: photoMaxSide,
        maxHeight: photoMaxSide,
        imageQuality: photoQuality,
        requestFullMetadata: false,
      );

  /// Saves [photo] for [shopId] and returns what goes in image_url.
  Future<String> save(String shopId, XFile photo) async {
    final bytes = await photo.readAsBytes();
    if (bytes.length > maxPhotoBytes) {
      throw PhotoException('That photo is still too big after shrinking. '
          'Try another one.');
    }
    final ref = _photos.doc();
    await ref.set({
      'shop_id': shopId,
      'data': Blob(bytes),
      'created_at': FieldValue.serverTimestamp(),
    });
    return '$photoUrlPrefix${ref.id}';
  }

  /// The JPEG bytes of `photos/{id}`, or null if it is gone. Served from
  /// the phone's Firestore cache when it has them.
  Future<Uint8List?> load(String id) async {
    final snap = await _photos.doc(id).get();
    final data = snap.data()?['data'];
    return data is Blob ? data.bytes : null;
  }
}
