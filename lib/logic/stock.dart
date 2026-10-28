import '../l10n/l10n.dart';

/// Kinds of stock movement. [code] is what is stored in Firestore and must
/// match firestore.rules.
enum MoveType {
  stockIn('in'),
  stockOut('out'),

  /// A stock count: sets the quantity to what is actually on the shelf.
  adjust('adjust');

  const MoveType(this.code);

  final String code;

  static MoveType fromCode(String? code) =>
      values.firstWhere((t) => t.code == code, orElse: () => adjust);
}

/// Upper bound on any stored quantity. Keeps typos like 10000000 out and must
/// match firestore.rules.
const maxQuantity = 1000000;

class StockException extends AppException {
  StockException(super.message);
}

/// The quantity after applying a movement, or a [StockException] explaining
/// why it can't be applied. firestore.rules repeat this check.
int quantityAfter(int current, MoveType type, int quantity) {
  if (quantity < 0) throw StockException((l) => l.errQuantityNegative);
  if (type != MoveType.adjust && quantity < 1) {
    throw StockException((l) => l.errQuantityAtLeastOne);
  }
  final after = switch (type) {
    MoveType.stockIn => current + quantity,
    MoveType.stockOut => current - quantity,
    MoveType.adjust => quantity,
  };
  if (after < 0) {
    throw StockException((l) => l.errOnlyInStock(current));
  }
  if (after > maxQuantity) {
    throw StockException((l) => l.errQuantityTooLarge);
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
