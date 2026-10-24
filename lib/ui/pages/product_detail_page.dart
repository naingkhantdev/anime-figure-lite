import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../utils/money.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(p?.name ?? 'Product')),
      body: p == null
          ? const Center(child: Text('This product is no longer available.'))
          : ListView(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ProductImage(url: p.imageUrl),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(formatMmk(p.price),
                          style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        p.inStock
                            ? '${p.stockQuantity} in stock'
                            : 'Out of stock',
                        style: TextStyle(
                          color: p.inStock ? null : theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(p.description),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: p == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to cart'),
                  onPressed: p.inStock
                      ? () {
                          ref.read(cartProvider.notifier).add(p);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(content: Text('Added ${p.name}')),
                            );
                        }
                      : null,
                ),
              ),
            ),
    );
  }
}
