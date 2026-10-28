import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: `products/{id}`
/// Fields: name, description, price (int, whole kyats), stock_quantity (int),
/// image_url (string, optional), is_active (bool), category, anime (strings,
/// optional).
///
/// The house's own figures are added in the console or by the seed script.
/// A shop's figures are copies of its items, kept in step by the shop
/// owner's app (lib/data/inventory_repository.dart): their id is
/// `{shop id}_{item id}` and they also carry shop_id, shop_name, item_id and
/// shop_open_until (the shop's expiry; past it the figure is hidden).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.isActive,
    this.imageUrl,
    this.category = '',
    this.anime = '',
    this.shopId = '',
    this.shopName = '',
    this.shopOpenUntil,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final int stockQuantity;
  final bool isActive;
  final String? imageUrl;

  /// One of [productCategories], or empty.
  final String category;

  /// The series the character is from, as typed: "One Piece".
  final String anime;

  /// Empty for the house's own figures.
  final String shopId;
  final String shopName;
  final DateTime? shopOpenUntil;

  bool get inStock => isActive && stockQuantity > 0;

  /// The house's own figures always show; a shop's only while it is open.
  bool isVisibleAt(DateTime now) =>
      isActive &&
      (shopId.isEmpty ||
          (shopOpenUntil != null && shopOpenUntil!.isAfter(now)));

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Product(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      stockQuantity: (data['stock_quantity'] as num?)?.toInt() ?? 0,
      isActive: data['is_active'] as bool? ?? false,
      imageUrl: data['image_url'] as String?,
      category: data['category'] as String? ?? '',
      anime: (data['anime'] as String? ?? '').trim(),
      shopId: data['shop_id'] as String? ?? '',
      shopName: data['shop_name'] as String? ?? '',
      shopOpenUntil: (data['shop_open_until'] as Timestamp?)?.toDate(),
    );
  }
}
