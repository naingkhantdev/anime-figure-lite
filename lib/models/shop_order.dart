import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: `orders/{id}`
/// Fields: user_id, status, items (list of maps), total_cents, created_at.
class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.status,
    required this.totalCents,
    required this.items,
    this.createdAt,
  });

  final String id;
  final String status;
  final int totalCents;
  final List<OrderLine> items;
  final DateTime? createdAt;

  factory ShopOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    return ShopOrder(
      id: doc.id,
      status: data['status'] as String? ?? 'pending',
      totalCents: (data['total_cents'] as num?)?.toInt() ?? 0,
      items: rawItems
          .whereType<Map>()
          .map((m) => OrderLine.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.priceCents,
    required this.quantity,
  });

  final String productId;
  final String name;
  final int priceCents;
  final int quantity;

  factory OrderLine.fromMap(Map<String, dynamic> map) => OrderLine(
        productId: map['product_id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        priceCents: (map['price_cents'] as num?)?.toInt() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'name': name,
        'price_cents': priceCents,
        'quantity': quantity,
      };
}
