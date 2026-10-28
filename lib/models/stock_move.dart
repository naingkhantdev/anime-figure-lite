import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/stock.dart';

/// Firestore: `shops/{shopId}/moves/{id}`. Never edited or deleted.
/// Fields: type ('in' | 'out' | 'adjust'), item_id, item_name, quantity,
/// quantity_before, quantity_after, unit_price (int, whole kyats),
/// customer_id, customer_name (both '' when none), note, created_by,
/// created_at.
class StockMove {
  const StockMove({
    required this.id,
    required this.type,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.unitPrice,
    required this.customerId,
    required this.customerName,
    required this.note,
    this.createdAt,
  });

  final String id;
  final MoveType type;
  final String itemId;
  final String itemName;
  final int quantity;
  final int quantityBefore;
  final int quantityAfter;
  final int unitPrice;
  final String customerId;
  final String customerName;
  final String note;
  final DateTime? createdAt;

  /// The signed change: +5 for stock in, -2 for stock out, and the
  /// difference for a count.
  int get change => quantityAfter - quantityBefore;

  /// Money for in/out lines (cost paid or sale amount). 0 for counts.
  int get total => type == MoveType.adjust ? 0 : unitPrice * quantity;

  factory StockMove.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    int number(String key) => (data[key] as num?)?.toInt() ?? 0;
    return StockMove(
      id: doc.id,
      type: MoveType.fromCode(data['type'] as String?),
      itemId: data['item_id'] as String? ?? '',
      itemName: data['item_name'] as String? ?? '',
      quantity: number('quantity'),
      quantityBefore: number('quantity_before'),
      quantityAfter: number('quantity_after'),
      unitPrice: number('unit_price'),
      customerId: data['customer_id'] as String? ?? '',
      customerName: data['customer_name'] as String? ?? '',
      note: data['note'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }
}
