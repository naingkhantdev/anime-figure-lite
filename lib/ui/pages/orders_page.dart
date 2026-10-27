import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../../models/shop_order.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/contact_buttons.dart';
import '../widgets/effects.dart';
import '../widgets/glass.dart';
import '../widgets/skeleton.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.myOrders)),
      body: orders.when(
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.receipt_long_outlined,
                title: context.l10n.noOrdersYet,
                message: context.l10n.noOrdersYetBody,
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
                                  context.l10n.itemCount(itemCount) +
                                      (date == null
                                          ? ''
                                          : ' · ${_formatDate(date)}'),
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
          title: context.l10n.couldNotLoadOrders,
          message: friendlyError(context, e),
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
  Widget build(BuildContext context) {
    final l = context.l10n;
    return switch (status) {
      'pending' => Pill.info(l.statusWaitingForShop),
      'confirmed' => Pill.success(l.statusConfirmed),
      'shipped' =>
        Pill.success(pickup ? l.statusPickedUp : l.statusOnItsWay),
      'cancelled' => Pill.danger(l.statusCancelled),
      _ => Pill.info(status),
    };
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
        title: Text(context.l10n.cancelOrderQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.keepOrder),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.cancelOrder),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = context.l10n;
    try {
      await ref.read(orderRepositoryProvider).cancelOrder(widget.order.id);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l.orderCancelled)));
    } catch (e) {
      // Most likely the shop confirmed it in the meantime.
      messenger.showSnackBar(
        SnackBar(content: Text(l.couldNotCancelOrder('$e'))),
      );
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final theme = Theme.of(context);
    // The house's own figures (no shop) are handled by staff, not a shop.
    final shopPhone = order.shopId.isEmpty
        ? ''
        : ref.watch(shopPublicProvider(order.shopId)).valueOrNull?.phone ?? '';

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
            if (order.deliveryFee > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(context.l10n.deliveryMethodDelivery)),
                    Text(formatMmk(order.deliveryFee),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const Divider(height: 24),
            Text('${order.deliveryMethod.label(context.l10n)} · ${order.phone}'),
            if (order.address.isNotEmpty) Text(order.address),
            if (order.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(context.l10n.noteLine(order.note),
                  style: theme.textTheme.bodySmall),
            ],
            if (shopPhone.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(context.l10n.contactTheShop,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ContactButtons(phone: shopPhone),
            ],
            if (order.canCancel) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancelling ? null : _cancel,
                  child: Text(context.l10n.cancelOrder),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
