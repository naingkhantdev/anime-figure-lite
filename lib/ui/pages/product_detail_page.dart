import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../../logic/catalog.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';
import '../theme.dart';
import '../widgets/catalog_controls.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/glass.dart';
import 'customer_home_page.dart';
import 'product_list_page.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productsProvider).valueOrNull?.where(
          (p) => p.id == productId,
        );
    final p = (product == null || product.isEmpty) ? null : product.first;
    final theme = Theme.of(context);
    final l = context.l10n;

    /// Back to the catalog, showing what [change] asks for.
    void browse(CatalogFilter Function(CatalogFilter) change) {
      ref.read(catalogFilterProvider.notifier).update(change);
      showCustomerTab(Navigator.of(context),
          ref.read(customerTabProvider.notifier), CustomerTab.shop);
    }

    final inCart = ref
        .watch(cartProvider
            .select((cart) => cart.where((i) => i.product.id == productId)))
        .fold(0, (n, i) => n + i.quantity);

    return Scaffold(
      appBar: AppBar(),
      body: p == null
          ? EmptyState(
              icon: Icons.search_off,
              title: l.figureGone,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Glass(
                  radius: AppRadius.xl,
                  padding: const EdgeInsets.all(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Hero(
                      tag: 'product-${p.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
                        child: ProductImage(url: p.imageUrl),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Reveal(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(formatMmk(p.price),
                                style: theme.textTheme.titleLarge?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          p.inStock
                              ? (p.stockQuantity <= 3
                                  ? Pill.warn(l.onlyLeft(p.stockQuantity))
                                  : Pill.success(l.inStockCount(p.stockQuantity)))
                              : Pill.danger(l.soldOut),
                        ],
                      ),
                      if (p.category.isNotEmpty || p.anime.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (p.anime.isNotEmpty)
                              ActionChip(
                                avatar:
                                    const Icon(Icons.movie_outlined, size: 18),
                                label: Text(p.anime),
                                tooltip: l.moreFrom(p.anime),
                                onPressed: () => browse((f) =>
                                    f.cleared().copyWith(anime: p.anime)),
                              ),
                            if (p.category.isNotEmpty)
                              ActionChip(
                                avatar: const Icon(Icons.category_outlined,
                                    size: 18),
                                label: Text(categoryLabel(l, p.category)),
                                tooltip: l.moreOfCategory(
                                    categoryLabel(l, p.category)),
                                onPressed: () => browse((f) =>
                                    f.cleared().copyWith(category: p.category)),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.accentSoft,
                            foregroundColor: AppColors.accent,
                            child: Icon(Icons.storefront_outlined),
                          ),
                          title: Text(sellerName(p),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(l.seeEverythingFromShop),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => browse((f) =>
                              f.cleared().copyWith(shopId: () => p.shopId)),
                        ),
                      ),
                      if (p.description.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(p.description,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(height: 1.55)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: p == null
          ? null
          : Padding(
              padding: EdgeInsets.fromLTRB(
                  12, 0, 12, 10 + MediaQuery.paddingOf(context).bottom),
              child: Glass(
                radius: AppRadius.xxl,
                blur: 20,
                color: const Color(0xC7FFFFFF),
                padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatMmk(p.price),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 17)),
                          if (inCart > 0)
                            Text(
                              l.inYourCart(inCart),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.inkMuted, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.add_shopping_cart, size: 20),
                      label: Text(l.addToCart),
                      onPressed: p.inStock && inCart < p.stockQuantity
                          ? () {
                              ref.read(cartProvider.notifier).add(p);
                              // Read now: the action may run after this page
                              // has closed, while the message is still showing.
                              final navigator = Navigator.of(context);
                              final tabs =
                                  ref.read(customerTabProvider.notifier);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(l.addedToCart(p.name)),
                                    action: SnackBarAction(
                                      label: l.viewCart,
                                      onPressed: () => showCustomerTab(
                                          navigator, tabs, CustomerTab.cart),
                                    ),
                                  ),
                                );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
