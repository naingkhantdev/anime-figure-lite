import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: `shops/{shopId}/customers/{id}`
/// Fields: name, phone, address, note, created_at, updated_at.
///
/// Customers are records the shop keeps, not app accounts.
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.note,
  });

  final String id;
  final String name;
  final String phone;
  final String address;
  final String note;

  factory Customer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Customer(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      note: data['note'] as String? ?? '',
    );
  }
}
