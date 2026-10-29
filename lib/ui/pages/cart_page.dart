import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/glass.dart';
import 'checkout_page.dart';
import 'customer_home_page.dart';
import 'product_detail_page.dart';
import 'product_list_page.dart';
import 'sign_in_page.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    if (!await ensureSignedIn(context, ref)) return;
    navigator.push(MaterialPageRoute(builder: (_) => const CheckoutPage()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = cart.fold<int>(0, (sum, i) => sum + i.subtotal);
    final count = cart.fold<int>(0, (sum, i) => sum + i.quantity);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tabCart)),
      body: cart.isEmpty
          ? const _EmptyCart()
          : RevealScope(
              child: ListView(
                padding: pagePadding(context, top: 4),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                    child: Text(
                      context.l10n.itemCount(count),
                      style: const TextStyle(
                          color: AppColors.inkMuted, fontSize: 13),
                    ),
                  ),
                  for (final (i, item) in cart.indexed) ...[
                    Reveal(
                      index: i,
                      id: item.product.id,
                      child: _CartLine(item: item),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 6),
                  Reveal(
                    index: cart.length,
                    child: _Summary(
                      count: count,
                      total: total,
                      shops: cart.map((i) => i.product.shopId).toSet().length,
                      onCheckout: () => _checkout(context, ref),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: () => ref
                          .read(customerTabProvider.notifier)
                          .state = CustomerTab.shop,
                      child: Text(context.l10n.continueShopping),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Nothing in the cart: say so in a line, give the one way back to the shop,
/// then a shelf of figures in stock, so the next step can be a tap away
/// rather than a tab away.
class _EmptyCart extends ConsumerWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final inStock = (ref.watch(productsProvider).valueOrNull ?? const [])
        .where((p) => p.inStock)
        .take(8)
        .toList();

    return ListView(
      padding: pagePadding(context, top: 16, side: 0),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StartColumn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageIntro(title: l.cartEmpty, message: l.cartEmptyBody),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => ref
                      .read(customerTabProvider.notifier)
                      .state = CustomerTab.shop,
                  child: Text(l.browseFigures),
                ),
              ],
            ),
          ),
        ),
        if (inStock.isNotEmpty) ...[
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeading(l.inStockNow),
          ),
          const SizedBox(height: 12),
          _Shelf(products: inStock),
        ],
      ],
    );
  }
}

/// A row of figures that scrolls sideways, edge to edge, starting in line
/// with the page's text.
class _Shelf extends StatelessWidget {
  const _Shelf({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    // Tall enough for the photo, two lines of name and the price at any
    // text size, so a large font never clips the price.
    final scale = MediaQuery.textScalerOf(context);
    final height = _Suggestion.width +
        10 +
        scale.scale(_Suggestion.nameLine) * 2 +
        4 +
        scale.scale(_Suggestion.priceLine) +
        8;
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _Suggestion(product: products[i]),
      ),
    );
  }
}

/// A figure on the empty cart's shelf: photo, name, price, as on the Shop
/// tab but without the card; opens its page.
class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.product});

  final Product product;

  static const width = 144.0;

  // Line heights of the name and price at 1x text (font size x 1.3).
  static const nameLine = 13 * 1.3;
  static const priceLine = 15 * 1.3;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProductDetailPage(productId: product.id),
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: width,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: ProductImage(url: product.imageUrl),
              ),
            ),
            const SizedBox(height: 10),
            // Two lines' room, so prices line up along the shelf.
            SizedBox(
              height: scale.scale(nameLine) * 2,
              child: Text(product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, height: 1.3)),
            ),
            const SizedBox(height: 4),
            // Ink, not the pink of a card's price: on the bare ground, under
            // the aurora, pink text falls short of AA.
            Text(formatMmk(product.price),
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }
}

/// The order summary, in the page right after the items, with Checkout.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.count,
    required this.total,
    required this.shops,
    required this.onCheckout,
  });

  final int count;
  final int total;

  /// How many shops the figures come from; one order each.
  final int shops;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: strong ? AppColors.ink : AppColors.inkMuted,
                        fontWeight:
                            strong ? FontWeight.w700 : FontWeight.w400)),
              ),
              const SizedBox(width: 12),
              Text(value,
                  style: strong
                      ? const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3)
                      : const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        );

    final l = context.l10n;
    return Glass(
      radius: AppRadius.xl,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.orderSummary,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          row(l.figuresCount(count), formatMmk(total)),
          row(l.deliveryMethodDelivery, l.setByShop),
          const Divider(height: 20),
          row(l.estimatedTotal, formatMmk(total), strong: true),
          const SizedBox(height: 6),
          Text(
            shops > 1 ? l.cartManyShops(shops) : l.cartOneShop,
            style: const TextStyle(fontSize: 12, color: AppColors.inkSubtle),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onCheckout, child: Text(l.checkout)),
        ],
      ),
    );
  }
}

class _CartLine extends ConsumerWidget {
  const _CartLine({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    final p = item.product;
    return Glass(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 72,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: ProductImage(url: p.imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(formatMmk(item.subtotal),
                    style: const TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w700)),
                if (item.quantity > 1)
                  Text(context.l10n.priceEach(formatMmk(p.price)),
                      style: const TextStyle(
                          color: AppColors.inkSubtle, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // One stepper; at 1 the minus becomes a bin, so it's clear what
          // the next tap does.
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.glassStrong,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.glassEdge),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: item.quantity == 1
                      ? context.l10n.remove
                      : context.l10n.decrease,
                  icon: Icon(
                      item.quantity == 1 ? Icons.delete_outline : Icons.remove,
                      size: 20),
                  onPressed: () =>
                      notifier.setQuantity(p.id, item.quantity - 1),
                ),
                AnimatedSwitcher(
                  duration: AppMotion.quick,
                  transitionBuilder: (child, a) =>
                      FadeTransition(opacity: a, child: child),
                  child: Text('${item.quantity}',
                      key: ValueKey(item.quantity),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: context.l10n.increase,
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: item.quantity >= p.stockQuantity
                      ? null
                      : () => notifier.setQuantity(p.id, item.quantity + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
