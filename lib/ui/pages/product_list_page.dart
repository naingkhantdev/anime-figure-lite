import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/photo_repository.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../../logic/catalog.dart';
import '../../models/product.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/catalog_controls.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/glass.dart';
import '../widgets/skeleton.dart';
import 'product_detail_page.dart';

const _grid = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 220,
  childAspectRatio: 0.54,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
);

/// The Shop tab of the customer home: every figure on sale, with search,
/// sort and filters.
class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final filter = ref.watch(catalogFilterProvider);

    return Scaffold(
      appBar: AppBar(titleSpacing: 16, title: const AppTitle()),
      body: products.when(
        data: (all) {
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.storefront_outlined,
              title: context.l10n.noFiguresYet,
              message: context.l10n.noFiguresYetBody,
            );
          }
          final shown = filter.apply(all);
          final narrowed =
              filter.activeCount > 0 || filter.query.trim().isNotEmpty;
          return RevealScope(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        CatalogSearchRow(products: all),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: CatalogCategoryBar(products: all)),
                SliverToBoxAdapter(child: CatalogActiveFilters(products: all)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${narrowed ? context.l10n.figuresShownOf(shown.length, all.length) : context.l10n.figuresCountPlain(all.length)}'
                            ' · ${filter.sort.label(context.l10n)}',
                            style: const TextStyle(
                                color: AppColors.inkMuted, fontSize: 13),
                          ),
                        ),
                        if (filter.activeCount > 0)
                          TextButton(
                            style: TextButton.styleFrom(
                                minimumSize: const Size(0, 32),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8)),
                            onPressed: () => ref
                                .read(catalogFilterProvider.notifier)
                                .update((f) => f.cleared()),
                            child: Text(context.l10n.clearAll,
                                style: const TextStyle(fontSize: 13)),
                          ),
                      ],
                    ),
                  ),
                ),
                if (shown.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: context.l10n.noFiguresMatch,
                      message: context.l10n.noFiguresMatchBody,
                      action: OutlinedButton(
                        onPressed: () => ref
                            .read(catalogFilterProvider.notifier)
                            .state = const CatalogFilter(),
                        child: Text(context.l10n.showAllFigures),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: pagePadding(context, side: 12, top: 4),
                    sliver: SliverGrid.builder(
                      gridDelegate: _grid,
                      itemCount: shown.length,
                      itemBuilder: (_, i) => Reveal(
                        index: i,
                        id: shown[i].id,
                        child: _ProductCard(product: shown[i]),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const ProductGridSkeleton(gridDelegate: _grid),
        error: (e, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: context.l10n.couldNotLoadFigures,
          message: friendlyError(context, e),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(productId: product.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'product-${product.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: ProductImage(
                          url: product.imageUrl,
                          dimmed: !product.inStock,
                        ),
                      ),
                    ),
                    if (!product.inStock)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Pill.danger(context.l10n.soldOut),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardKicker(product),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSubtle,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      // Two lines' room, so prices line up across a row.
                      height: 38,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600, height: 1.3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(formatMmk(product.price),
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: product.inStock
                                ? AppColors.accent
                                : AppColors.inkSubtle,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    _StockLine(product: product),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A figure's photo from wherever it is kept: bundled with the app
/// (`assets/...`), saved in Firestore from the app (`photo:{id}`), or on the
/// web (`https://...`). A shimmer stands in while it loads.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, this.url, this.dimmed = false});

  final String? url;

  /// Faded, for a figure that is sold out.
  final bool dimmed;

  static const _placeholder = ColoredBox(
    color: AppColors.surfaceSunken,
    child: Center(
      child: Icon(Icons.image_not_supported_outlined,
          size: 32, color: AppColors.inkSubtle),
    ),
  );

  /// Fades the photo in over the placeholder once it is decoded.
  static Widget _fadeIn(
          BuildContext context, Widget child, int? frame, bool synchronous) =>
      synchronous
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: child,
            );

  @override
  Widget build(BuildContext context) {
    final url = this.url ?? '';
    if (url.isEmpty) return _placeholder;
    final Widget image;
    if (url.startsWith('assets/')) {
      image = Image.asset(url,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder);
    } else if (url.startsWith(photoUrlPrefix)) {
      image = _StoredPhoto(id: url.substring(photoUrlPrefix.length));
    } else {
      image = Image.network(url,
          fit: BoxFit.cover,
          frameBuilder: _fadeIn,
          errorBuilder: (_, __, ___) => _placeholder);
    }
    return ColoredBox(
      color: AppColors.surfaceSunken,
      child: dimmed ? Opacity(opacity: 0.55, child: image) : image,
    );
  }
}

class _StoredPhoto extends ConsumerWidget {
  const _StoredPhoto({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(photoBytesProvider(id)).when(
          data: (bytes) => bytes == null
              ? ProductImage._placeholder
              : Image.memory(bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  frameBuilder: ProductImage._fadeIn,
                  errorBuilder: (_, __, ___) => ProductImage._placeholder),
          loading: () => const SkeletonShimmer(
              child: SkeletonBox(
                  width: double.infinity, height: double.infinity, radius: 0)),
          error: (_, __) => ProductImage._placeholder,
        );
  }
}

/// How many are left, in words that say whether to hurry.
class _StockLine extends StatelessWidget {
  const _StockLine({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final n = product.stockQuantity;
    final l = context.l10n;
    final (text, color, icon) = !product.inStock
        ? (l.soldOut, AppColors.dangerInk, Icons.remove_circle_outline)
        : n <= 3
            ? (
                l.onlyLeft(n),
                AppColors.warnInk,
                Icons.local_fire_department_outlined
              )
            : (
                l.inStockCount(n),
                AppColors.successInk,
                Icons.check_circle_outline
              );
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
