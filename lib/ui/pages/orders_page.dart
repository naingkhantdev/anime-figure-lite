import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/shop_order.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/glass.dart';
import '../widgets/skeleton.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: orders.when(
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message: 'When you check out, your order shows up here.',
              )
            : RevealScope(
                child: ListView.separated(
                  padding: pagePadding(context, top: 4),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final order = list[i];
                    final date = order.createdAt?.toLocal();
                    final itemCount =
                        order.items.fold<int>(0, (s, l) => s + l.quantity);
                    final names = order.items.map((l) => l.name).join(', ');
                    return Reveal(
                      index: i,
                      id: order.id,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => _OrderDetailSheet(order: order),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(formatMmk(order.total),
                                          style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    OrderStatusPill(
                                        status: order.status,
                                        pickup: order.deliveryMethod ==
                                            DeliveryMethod.pickup),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(names,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                  '$itemCount ${itemCount == 1 ? 'item' : 'items'}'
                                  '${date == null ? '' : ' · ${_formatDate(date)}'}',
                                  style: const TextStyle(
                                      color: AppColors.inkMuted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
        loading: () => const SkeletonList(header: false, rows: 4),
        error: (e, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load your orders',
          message: friendlyError(e),
        ),
      ),
    );
  }
}

/// An order's status in words a customer understands, coloured by what it
/// means for them.
class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill({super.key, required this.status, this.pickup = false});

  final String status;

  /// Picked up at the shop rather than delivered.
  final bool pickup;

  @override
  Widget build(BuildContext context) => switch (status) {
        'pending' => const Pill.info('Waiting for shop'),
        'confirmed' => const Pill.success('Confirmed'),
        'shipped' => Pill.success(pickup ? 'Picked up' : 'On its way'),
        'cancelled' => const Pill.danger('Cancelled'),
        _ => Pill.info(status),
      };
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                OrderStatusPill(
                    status: order.status,
                    pickup: order.deliveryMethod == DeliveryMethod.pickup),
              ],
            ),
            const SizedBox(height: 8),
            for (final line in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text('${line.quantity} × ${line.name}')),
                    const SizedBox(width: 12),
                    Text(formatMmk(line.price * line.quantity),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
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
