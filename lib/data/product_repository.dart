import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

class ProductRepository {
  ProductRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  /// Everything on sale: the house's figures and those of open shops.
  /// Sorted client-side so no composite index is needed.
  Stream<List<Product>> watchActiveProducts() =>
      _products.where('is_active', isEqualTo: true).snapshots().map((snap) {
        final now = DateTime.now();
        return snap.docs
            .map(Product.fromDoc)
            .where((p) => p.isVisibleAt(now))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      });
}
