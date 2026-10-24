import 'package:cloud_firestore/cloud_firestore.dart';

/// How the customer gets the order. Stored as its [name] in `delivery_method`.
enum DeliveryMethod {
  delivery('Delivery'),
  pickup('Pick up at shop');

  const DeliveryMethod(this.label);
  final String label;

  static DeliveryMethod fromName(String? name) => DeliveryMethod.values
      .firstWhere((m) => m.name == name, orElse: () => DeliveryMethod.delivery);
}

/// Firestore: `orders/{id}`
/// Fields: user_id, status, items (list of maps), total (int, whole kyats),
/// phone, delivery_method, address, note, created_at.
class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.status,
    required this.total,
    required this.items,
    required this.phone,
    required this.deliveryMethod,
    required this.address,
    required this.note,
    this.createdAt,
  });

  final String id;
  final String status;
  final int total;
  final List<OrderLine> items;
  final String phone;
  final DeliveryMethod deliveryMethod;
  final String address;
  final String note;
  final DateTime? createdAt;

  bool get canCancel => status == 'pending';

  factory ShopOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    return ShopOrder(
      id: doc.id,
      status: data['status'] as String? ?? 'pending',
      total: (data['total'] as num?)?.toInt() ?? 0,
      items: rawItems
          .whereType<Map>()
          .map((m) => OrderLine.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      phone: data['phone'] as String? ?? '',
      deliveryMethod: DeliveryMethod.fromName(data['delivery_method'] as String?),
      address: data['address'] as String? ?? '',
      note: data['note'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String productId;
  final String name;
  final int price;
  final int quantity;

  factory OrderLine.fromMap(Map<String, dynamic> map) => OrderLine(
        productId: map['product_id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        price: (map['price'] as num?)?.toInt() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };
}
