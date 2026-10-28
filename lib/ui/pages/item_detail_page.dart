import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../logic/stock.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/move_tile.dart';
import 'item_form_page.dart';
import 'product_list_page.dart';
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
    final l = context.l10n;

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
                  ? l.itemHidden(item.name)
                  : l.itemBack(item.name));
        }
      } catch (e) {
        if (context.mounted) showMessage(context, friendlyError(context, e));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(item?.name ?? ''),
        actions: [
          if (item != null) ...[
            IconButton(
              tooltip: l.edit,
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
                      ? l.hideFromStockList
                      : l.showInStockListAgain),
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
            return EmptyState(
                icon: Icons.help_outline, title: l.itemIsGone);
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
                      label: Text(l.moveInShort),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: _tight),
                      onPressed:
                          item.isOut ? null : () => move(MoveType.stockOut),
                      icon: const Icon(Icons.north_east),
                      label: Text(l.statOut),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: _tight),
                      onPressed: () => move(MoveType.adjust),
                      icon: const Icon(Icons.tune),
                      label: Text(l.moveCount),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DetailsCard(item: item),
              const SizedBox(height: 20),
              Text(l.tabHistory,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              AsyncBody(
                value: ref.watch(itemMovesProvider(itemId)),
                data: (moves) => moves.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l.noMovesYet,
                            style: const TextStyle(color: AppColors.inkMuted)),
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
            if (item.imageUrl.isNotEmpty) ...[
              SizedBox.square(
                dimension: 84,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: ProductImage(url: item.imageUrl),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.inStock.toUpperCase(),
                      style: const TextStyle(
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
              Pill.info(context.l10n.hidden)
            else if (item.isOut)
              Pill.danger(context.l10n.outOfStock)
            else if (item.isLow)
              Pill.warn(context.l10n.lowStock),
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
    final l = context.l10n;
    final rows = [
      (l.sellingPrice, formatMmk(item.price)),
      (l.costPrice, formatMmk(item.cost)),
      if (item.price > 0 && item.cost > 0)
        (l.profitEach, formatMmk(item.price - item.cost)),
      (l.lowStockAt, '${item.lowStockAt}'),
      if (item.code.isNotEmpty) (l.code, item.code),
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
