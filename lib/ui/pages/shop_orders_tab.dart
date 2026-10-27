import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../../models/shop_order.dart';
import '../../providers/providers.dart';
import '../../utils/dates.dart';
import '../../utils/money.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/glass.dart';
import '../widgets/skeleton.dart';
import 'orders_page.dart';

/// Customers' orders for this shop's figures, newest first, waiting ones on
/// top. The shop confirms (which takes the stock out), ships or cancels.
class ShopOrdersTab extends ConsumerStatefulWidget {
  const ShopOrdersTab({super.key});

  @override
  ConsumerState<ShopOrdersTab> createState() => _ShopOrdersTabState();
}

enum _Show { open, done }

class _ShopOrdersTabState extends ConsumerState<ShopOrdersTab> {
  _Show _show = _Show.open;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AsyncBody(
      value: ref.watch(shopOrdersProvider),
      loading: const SkeletonList(header: false, rows: 4),
      data: (orders) {
        bool open(ShopOrder o) =>
            o.status == 'pending' || o.status == 'confirmed';
        final visible = orders
            .where((o) => _show == _Show.open ? open(o) : !open(o))
            .toList()
          // Waiting for an answer first.
          ..sort((a, b) => (a.status == 'pending' ? 0 : 1)
              .compareTo(b.status == 'pending' ? 0 : 1));
        final waiting = orders.where((o) => o.status == 'pending').length;

        return ListView(
          padding: pagePadding(context),
          children: [
            SegmentedButton<_Show>(
              segments: [
                ButtonSegment(
                    value: _Show.open,
                    label: Text(
                        waiting > 0 ? '${l.toDo} · $waiting' : l.toDo)),
                ButtonSegment(value: _Show.done, label: Text(l.done)),
              ],
              selected: {_show},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _show = s.first),
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              EmptyState(
                icon: Icons.receipt_long_outlined,
                title: _show == _Show.open
                    ? l.noOrdersToHandle
                    : l.noFinishedOrders,
                message: _show == _Show.open
                    ? l.noOrdersToHandleBody
                    : l.noFinishedOrdersBody,
              )
            else
              for (final (i, o) in visible.indexed) ...[
                Reveal(index: i, child: _OrderCard(order: o)),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({required this.order});

  final ShopOrder order;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() step, String done) async {
    setState(() => _busy = true);
    try {
      await step();
      if (mounted) showMessage(context, done);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final cancelled = context.l10n.orderCancelled;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.cancelOrderQuestion),
        content: Text(context.l10n.shopCancelOrderBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.keepIt)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.cancelOrder)),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
        () => ref
            .read(orderRepositoryProvider)
            .setShopOrderStatus(widget.order.id, 'cancelled'),
        cancelled);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final canWrite = ref.watch(canWriteProvider);
    final date = o.createdAt?.toLocal();
    final l = context.l10n;

    return Glass(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(formatMmk(o.total),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              OrderStatusPill(
                  status: o.status,
                  pickup: o.deliveryMethod == DeliveryMethod.pickup),
            ],
          ),
          if (date != null)
            Text(formatDateTime(date),
                style:
                    const TextStyle(color: AppColors.inkSubtle, fontSize: 13)),
          const SizedBox(height: 10),
          for (final line in o.items)
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
          _Detail(
              icon: o.deliveryMethod == DeliveryMethod.pickup
                  ? Icons.storefront_outlined
                  : Icons.local_shipping_outlined,
              text: o.deliveryMethod.label(l)),
          if (o.phone.isNotEmpty)
            _Detail(icon: Icons.call_outlined, text: o.phone),
          if (o.address.isNotEmpty)
            _Detail(icon: Icons.place_outlined, text: o.address),
          if (o.note.isNotEmpty)
            _Detail(icon: Icons.sticky_note_2_outlined, text: o.note),
          if (canWrite && (o.status == 'pending' || o.status == 'confirmed'))
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _busy ? null : _cancel,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.dangerInk),
                    child: Text(l.cancel),
                  ),
                  const Spacer(),
                  if (o.status == 'pending')
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => ref
                                  .read(orderRepositoryProvider)
                                  .confirmShopOrder(
                                      o, ref.read(inventoryRepositoryProvider)),
                              l.orderConfirmedDone),
                      icon: const Icon(Icons.check),
                      label: Text(l.confirm),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => ref
                                  .read(orderRepositoryProvider)
                                  .setShopOrderStatus(o.id, 'shipped'),
                              l.markedOnItsWay),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: Text(o.deliveryMethod == DeliveryMethod.pickup
                          ? l.statusPickedUp
                          : l.shipped),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.inkMuted),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: AppColors.inkMuted))),
        ],
      ),
    );
  }
}
