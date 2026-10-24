import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/shop_order.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: orders.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No orders yet.'))
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final order = list[i];
                  final date = order.createdAt?.toLocal();
                  final itemCount =
                      order.items.fold<int>(0, (s, l) => s + l.quantity);
                  return ListTile(
                    title: Text(formatMmk(order.total)),
                    subtitle: Text(
                      '$itemCount item(s)'
                      '${date == null ? '' : ' · ${_formatDate(date)}'}',
                    ),
                    trailing: Chip(label: Text(order.status)),
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _OrderDetailSheet(order: order),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load orders.\n$e')),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

class _OrderDetailSheet extends ConsumerStatefulWidget {
  const _OrderDetailSheet({required this.order});

  final ShopOrder order;

  @override
  ConsumerState<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends ConsumerState<_OrderDetailSheet> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(orderRepositoryProvider).cancelOrder(widget.order.id);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Order cancelled.')));
    } catch (e) {
      // Most likely the shop confirmed it in the meantime.
      messenger.showSnackBar(
        SnackBar(content: Text('Could not cancel this order: $e')),
      );
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(formatMmk(order.total),
                      style: theme.textTheme.titleLarge),
                ),
                Chip(label: Text(order.status)),
              ],
            ),
            const SizedBox(height: 8),
            for (final line in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${line.quantity} × ${line.name} — '
                  '${formatMmk(line.price * line.quantity)}',
                ),
              ),
            const Divider(height: 24),
            Text('${order.deliveryMethod.label} · ${order.phone}'),
            if (order.address.isNotEmpty) Text(order.address),
            if (order.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Note: ${order.note}', style: theme.textTheme.bodySmall),
            ],
            if (order.canCancel) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancelling ? null : _cancel,
                  child: const Text('Cancel order'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
