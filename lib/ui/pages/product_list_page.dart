import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';
import '../widgets/brand.dart';
import 'cart_page.dart';
import 'create_shop_page.dart';
import 'orders_page.dart';
import 'product_detail_page.dart';
import 'sign_in_page.dart';

class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final cartCount = ref.watch(cartCountProvider);
    final signedIn = ref.watch(authStateProvider).valueOrNull != null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(
          children: [
            AppLogo(size: 32),
            SizedBox(width: 10),
            Flexible(
              child: Text('Figures',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My orders',
            icon: const Icon(Icons.receipt_long),
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (!await ensureSignedIn(context, ref)) return;
              navigator.push(
                MaterialPageRoute(builder: (_) => const OrdersPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Cart',
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartPage()),
            ),
          ),
          _AccountMenu(signedIn: signedIn),
        ],
      ),
      body: products.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('No products yet.'))
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 0.66,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _ProductCard(product: items[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load products.\n$e')),
      ),
    );
  }
}

/// Sign in or out, and the way into running a shop on this app. Once the
/// shop exists, RoleGate shows its screens instead of this page.
class _AccountMenu extends ConsumerWidget {
  const _AccountMenu({required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<VoidCallback>(
      tooltip: 'Account',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        if (!signedIn)
          PopupMenuItem(
            value: () => ensureSignedIn(context, ref),
            child: const ListTile(
                leading: Icon(Icons.login), title: Text('Sign in')),
          ),
        PopupMenuItem(
          value: () async {
            final navigator = Navigator.of(context);
            if (!await ensureSignedIn(context, ref)) return;
            // Just signed in as a shop admin or the super admin: RoleGate
            // switches screens by itself. `.future` waits for this account's
            // answer rather than reading a stale or loading value.
            if (await ref.read(isSuperAdminProvider.future) ||
                await ref.read(myShopProvider.future) != null) {
              return;
            }
            navigator.push(
              MaterialPageRoute(builder: (_) => const CreateShopPage()),
            );
          },
          child: const ListTile(
              leading: Icon(Icons.storefront_outlined),
              title: Text('Open a shop')),
        ),
        if (signedIn)
          PopupMenuItem(
            value: () => ref.read(authRepositoryProvider).signOut(),
            child: const ListTile(
                leading: Icon(Icons.logout), title: Text('Sign out')),
          ),
      ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: ProductImage(url: product.imageUrl)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(formatMmk(product.price),
                      style: theme.textTheme.titleMedium),
                  if (!product.inStock)
                    Text('Out of stock',
                        style: TextStyle(color: theme.colorScheme.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.image_not_supported_outlined, size: 40),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}
