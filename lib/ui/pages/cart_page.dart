import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/order_repository.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';
import 'orders_page.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _placing = false;

  Future<void> _placeOrder() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() => _placing = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(orderRepositoryProvider).placeOrder(
            userId: user.uid,
            cart: ref.read(cartProvider),
          );
      ref.read(cartProvider.notifier).clear();
      messenger.showSnackBar(
        const SnackBar(content: Text('Order placed — awaiting confirmation.')),
      );
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const OrdersPage()),
      );
    } on OrderException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not place order: $e')),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final total = cart.fold<int>(0, (sum, i) => sum + i.subtotalCents);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cart.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
          : ListView.separated(
              itemCount: cart.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final item = cart[i];
                return ListTile(
                  title: Text(item.product.name),
                  subtitle: Text(formatCents(item.subtotalCents)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Decrease',
                        icon: const Icon(Icons.remove),
                        onPressed: () => notifier.setQuantity(
                            item.product.id, item.quantity - 1),
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        tooltip: 'Increase',
                        icon: const Icon(Icons.add),
                        onPressed: item.quantity >= item.product.stockQuantity
                            ? null
                            : () => notifier.setQuantity(
                                item.product.id, item.quantity + 1),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Estimated total: ${formatCents(total)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text(
                      'Final price is confirmed by the shop.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _placing ? null : _placeOrder,
                      child: _placing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Place order'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
