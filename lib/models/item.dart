import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: `shops/{shopId}/items/{id}`
/// Fields: name, code, unit, price (int, whole kyats, selling price),
/// cost (int, whole kyats, buying price), quantity (int), low_stock_at (int),
/// is_active (bool), last_move_id (string), created_at, updated_at.
///
/// `quantity` only changes together with a movement; see firestore.rules.
class Item {
  const Item({
    required this.id,
    required this.name,
    required this.code,
    required this.unit,
    required this.price,
    required this.cost,
    required this.quantity,
    required this.lowStockAt,
    required this.isActive,
  });

  final String id;
  final String name;
  final String code;
  final String unit;
  final int price;
  final int cost;
  final int quantity;
  final int lowStockAt;
  final bool isActive;

  bool get isOut => quantity == 0;
  bool get isLow => quantity <= lowStockAt;

  /// "12 pcs", or just "12" when the item has no unit.
  String get quantityLabel => unit.isEmpty ? '$quantity' : '$quantity $unit';

  factory Item.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Item(
      id: doc.id,
      name: data['name'] as String? ?? '',
      code: data['code'] as String? ?? '',
      unit: data['unit'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      cost: (data['cost'] as num?)?.toInt() ?? 0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      lowStockAt: (data['low_stock_at'] as num?)?.toInt() ?? 0,
      isActive: data['is_active'] as bool? ?? true,
    );
  }
}
