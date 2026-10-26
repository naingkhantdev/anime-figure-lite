import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/item.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';
import '../theme.dart';
import '../widgets/effects.dart';
import '../widgets/glass.dart';
import '../widgets/common.dart';
import 'item_detail_page.dart';
import 'product_list_page.dart';

enum _ItemFilter { all, low, out, hidden }

class ItemsTab extends ConsumerStatefulWidget {
  const ItemsTab({super.key});

  @override
  ConsumerState<ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends ConsumerState<ItemsTab> {
  String _query = '';
  _ItemFilter _filter = _ItemFilter.all;

  @override
  Widget build(BuildContext context) {
    return AsyncBody(
      value: ref.watch(itemsProvider),
      data: (allItems) {
        final active = allItems.where((i) => i.isActive).toList();
        final low = active.where((i) => i.isLow).length;
        final out = active.where((i) => i.isOut).length;
        final value = active.fold(0, (sum, i) => sum + i.cost * i.quantity);

        final q = _query.trim().toLowerCase();
        final visible = allItems.where((i) {
          final matchesFilter = switch (_filter) {
            _ItemFilter.all => i.isActive,
            _ItemFilter.low => i.isActive && i.isLow,
            _ItemFilter.out => i.isActive && i.isOut,
            _ItemFilter.hidden => !i.isActive,
          };
          return matchesFilter &&
              (q.isEmpty ||
                  i.name.toLowerCase().contains(q) ||
                  i.code.toLowerCase().contains(q));
        }).toList();

        return ListView(
          padding: pagePadding(context, bottom: 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                        child: Stat(label: 'Items', value: '${active.length}')),
                    Expanded(
                        child: Stat(
                            label: 'Low',
                            value: '$low',
                            color:
                                low > 0 ? AppColors.warnInk : AppColors.ink)),
                    Expanded(
                        child: Stat(
                            label: 'Out',
                            value: '$out',
                            color:
                                out > 0 ? AppColors.dangerInk : AppColors.ink)),
                  ],
                ),
              ),
            ),
            if (value > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Text(
                  'Stock worth ${formatMmk(value)} at cost',
                  style:
                      const TextStyle(color: AppColors.inkMuted, fontSize: 13),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search name or code',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (label, filter) in [
                  ('All', _ItemFilter.all),
                  ('Low stock', _ItemFilter.low),
                  ('Out of stock', _ItemFilter.out),
                  ('Hidden', _ItemFilter.hidden),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (allItems.isEmpty)
              const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No items yet',
                message: 'Tap "New item" to add the first thing you sell.',
              )
            else if (visible.isEmpty)
              const EmptyState(icon: Icons.search_off, title: 'Nothing matches')
            else
              RevealScope(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (index, item) in visible.indexed) ...[
                        if (index > 0) const Divider(indent: 16),
                        Reveal(
                            index: index,
                            id: item.id,
                            child: _ItemRow(item: item)),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final sub = [
      if (item.code.isNotEmpty) item.code,
      formatMmk(item.price),
      if (item.listed && item.isActive) 'In the app',
    ].join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(12, 4, 16, 4),
      leading: SizedBox.square(
        dimension: 52,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: ProductImage(url: item.imageUrl),
        ),
      ),
      title: Text(item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(sub, style: const TextStyle(color: AppColors.inkMuted)),
      trailing: _QuantityBadge(item: item),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailPage(itemId: item.id)),
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  const _QuantityBadge({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    if (!item.isActive) return Pill.info('Hidden · ${item.quantity}');
    if (item.isOut) return const Pill.danger('Out');
    final text = Text(
      item.quantityLabel,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    );
    return item.isLow ? Pill.warn('Low · ${item.quantityLabel}') : text;
  }
}
