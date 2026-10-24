import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: `products/{id}`
/// Fields: name, description, price_cents (int), stock_quantity (int),
/// image_url (string, optional), is_active (bool).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.stockQuantity,
    required this.isActive,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final int priceCents;
  final int stockQuantity;
  final bool isActive;
  final String? imageUrl;

  bool get inStock => isActive && stockQuantity > 0;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Product(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      priceCents: (data['price_cents'] as num?)?.toInt() ?? 0,
      stockQuantity: (data['stock_quantity'] as num?)?.toInt() ?? 0,
      isActive: data['is_active'] as bool? ?? false,
      imageUrl: data['image_url'] as String?,
    );
  }
}
