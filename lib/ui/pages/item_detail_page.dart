import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/stock.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/move_tile.dart';
import 'item_form_page.dart';
import 'shop_home_page.dart';
import 'stock_move_page.dart';

/// Three buttons share a 360px-wide row; default padding wraps "Count".
const _tight = EdgeInsets.symmetric(horizontal: 8);

class ItemDetailPage extends ConsumerWidget {
  const ItemDetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = ref.watch(canWriteProvider);
    final itemValue = ref.watch(itemProvider(itemId));
    final item = itemValue.valueOrNull;

    void move(MoveType type) {
      if (!canWrite) return explainReadOnly(context);
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => StockMovePage(item: item!, initialType: type)),
      );
    }

    Future<void> toggleHidden() async {
      if (!canWrite) return explainReadOnly(context);
      try {
        await ref
            .read(inventoryRepositoryProvider)
            .setItemActive(itemId, !item!.isActive);
        if (context.mounted) {
          showMessage(
              context,
              item.isActive
                  ? '${item.name} is hidden.'
                  : '${item.name} is back.');
        }
      } catch (e) {
        if (context.mounted) showMessage(context, friendlyError(e));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(item?.name ?? ''),
        actions: [
          if (item != null) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: canWrite
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ItemFormPage(item: item)))
                  : () => explainReadOnly(context),
            ),
            PopupMenuButton<void>(
              itemBuilder: (_) => [
                PopupMenuItem(
                  onTap: toggleHidden,
                  child: Text(item.isActive
                      ? 'Hide from stock list'
                      : 'Show in stock list again'),
                ),
              ],
            ),
          ],
        ],
      ),
      body: AsyncBody(
        value: itemValue,
        data: (item) {
          if (item == null) {
            return const EmptyState(
                icon: Icons.help_outline, title: 'This item is gone');
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _QuantityCard(item: item),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(padding: _tight),
                      onPressed: () => move(MoveType.stockIn),
                      icon: const Icon(Icons.south_west),
                      label: const Text('In'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: _tight),
                      onPressed:
                          item.isOut ? null : () => move(MoveType.stockOut),
                      icon: const Icon(Icons.north_east),
                      label: const Text('Out'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: _tight),
                      onPressed: () => move(MoveType.adjust),
                      icon: const Icon(Icons.tune),
                      label: const Text('Count'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DetailsCard(item: item),
              const SizedBox(height: 20),
              Text('History',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              AsyncBody(
                value: ref.watch(itemMovesProvider(itemId)),
                data: (moves) => moves.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No stock movements yet.',
                            style: TextStyle(color: AppColors.inkMuted)),
                      )
                    : Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (final (i, m) in moves.indexed) ...[
                              if (i > 0) const Divider(indent: 72),
                              MoveTile(move: m, showItem: false),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuantityCard extends StatelessWidget {
  const _QuantityCard({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final color = item.isOut
        ? AppColors.dangerInk
        : item.isLow
            ? AppColors.warnInk
            : AppColors.ink;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('IN STOCK',
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.66,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSubtle)),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: '${item.quantity}',
                        style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            color: color,
                            height: 1),
                      ),
                      if (item.unit.isNotEmpty)
                        TextSpan(
                          text: '  ${item.unit}',
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.inkMuted),
                        ),
                    ]),
                  ),
                ],
              ),
            ),
            if (!item.isActive)
              const Pill.info('Hidden')
            else if (item.isOut)
              const Pill.danger('Out of stock')
            else if (item.isLow)
              const Pill.warn('Low stock'),
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Selling price', formatMmk(item.price)),
      ('Cost price', formatMmk(item.cost)),
      if (item.price > 0 && item.cost > 0)
        ('Profit each', formatMmk(item.price - item.cost)),
      ('Low stock at', '${item.lowStockAt}'),
      if (item.code.isNotEmpty) ('Code', item.code),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(label,
                        style: const TextStyle(color: AppColors.inkMuted)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(value,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
