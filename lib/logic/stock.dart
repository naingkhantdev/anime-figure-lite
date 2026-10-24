/// Kinds of stock movement. [code] is what is stored in Firestore and must
/// match firestore.rules.
enum MoveType {
  stockIn('in', 'Stock in'),
  stockOut('out', 'Stock out'),

  /// A stock count: sets the quantity to what is actually on the shelf.
  adjust('adjust', 'Count');

  const MoveType(this.code, this.label);

  final String code;
  final String label;

  static MoveType fromCode(String? code) =>
      values.firstWhere((t) => t.code == code, orElse: () => adjust);
}

/// Upper bound on any stored quantity. Keeps typos like 10000000 out and must
/// match firestore.rules.
const maxQuantity = 1000000;

class StockException implements Exception {
  StockException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The quantity after applying a movement, or a [StockException] explaining
/// why it can't be applied. firestore.rules repeat this check.
int quantityAfter(int current, MoveType type, int quantity) {
  if (quantity < 0) throw StockException('Quantity cannot be negative.');
  if (type != MoveType.adjust && quantity < 1) {
    throw StockException('Enter a quantity of at least 1.');
  }
  final after = switch (type) {
    MoveType.stockIn => current + quantity,
    MoveType.stockOut => current - quantity,
    MoveType.adjust => quantity,
  };
  if (after < 0) {
    throw StockException('Only $current in stock.');
  }
  if (after > maxQuantity) {
    throw StockException('Quantity is too large.');
  }
  return after;
}

/// Parses a whole, non-negative number typed by a person: "25,000" → 25000.
/// Returns null for anything else.
int? parseWholeNumber(String input) {
  final cleaned = input.replaceAll(RegExp(r'[\s,]'), '');
  if (!RegExp(r'^\d{1,12}$').hasMatch(cleaned)) return null;
  return int.parse(cleaned);
}
