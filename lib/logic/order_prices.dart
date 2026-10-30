import '../models/shop_order.dart';

/// An order line whose price is not the item's price now: the shop changed
/// it after the customer ordered, or the order was written with a fake one.
class PriceChange {
  const PriceChange({required this.line, required this.currentPrice});

  final OrderLine line;
  final int currentPrice;
}

/// The lines of an order whose price differs from [currentPrices] (keyed
/// by product_id). Lines missing from [currentPrices] are left out.
List<PriceChange> priceChanges(
        List<OrderLine> lines, Map<String, int> currentPrices) =>
    [
      for (final line in lines)
        if (currentPrices[line.productId] case final price?
            when price != line.price)
          PriceChange(line: line, currentPrice: price),
    ];

/// [order]'s lines at the prices in [changes], the rest as they were.
List<OrderLine> repricedLines(ShopOrder order, List<PriceChange> changes) {
  final prices = {
    for (final c in changes) c.line.productId: c.currentPrice,
  };
  return [
    for (final line in order.items)
      OrderLine(
        productId: line.productId,
        name: line.name,
        price: prices[line.productId] ?? line.price,
        quantity: line.quantity,
      ),
  ];
}

/// What the customer pays for [lines] plus [deliveryFee].
int orderTotal(List<OrderLine> lines, int deliveryFee) =>
    lines.fold(deliveryFee, (sum, l) => sum + l.price * l.quantity);
