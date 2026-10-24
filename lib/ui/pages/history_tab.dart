import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/inventory_repository.dart';
import '../../logic/stock.dart';
import '../../models/stock_move.dart';
import '../../providers/providers.dart';
import '../../utils/dates.dart';
import '../../utils/money.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/move_tile.dart';
import 'item_detail_page.dart';

/// Recent stock movements across the shop, by day, with today's totals.
class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  MoveType? _filter;

  @override
  Widget build(BuildContext context) {
    return AsyncBody(
      value: ref.watch(recentMovesProvider),
      data: (moves) {
        final now = DateTime.now();
        // Pending local writes have no server time yet; they are "now".
        final today =
            moves.where((m) => isSameDay(m.createdAt ?? now, now)).toList();
        int sumQty(MoveType t) =>
            today.where((m) => m.type == t).fold(0, (s, m) => s + m.quantity);
        final sales = today
            .where((m) => m.type == MoveType.stockOut)
            .fold(0, (s, m) => s + m.total);

        final visible = _filter == null
            ? moves
            : moves.where((m) => m.type == _filter).toList();

        // Group by calendar day, keeping newest-first order.
        final groups = <(DateTime, List<StockMove>)>[];
        for (final m in visible) {
          final at = m.createdAt ?? now;
          final day = DateTime(at.year, at.month, at.day);
          if (groups.isEmpty || groups.last.$1 != day) {
            groups.add((day, [m]));
          } else {
            groups.last.$2.add(m);
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: Stat(
                                label: 'In',
                                value: '${sumQty(MoveType.stockIn)}',
                                color: AppColors.successInk)),
                        Expanded(
                            child: Stat(
                                label: 'Out',
                                value: '${sumQty(MoveType.stockOut)}',
                                color: AppColors.dangerInk)),
                        Expanded(
                            flex: 2,
                            child:
                                Stat(label: 'Sales', value: formatMmk(sales))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final (label, type) in [
                  ('All', null),
                  ('In', MoveType.stockIn),
                  ('Out', MoveType.stockOut),
                  ('Counts', MoveType.adjust),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _filter == type,
                    onSelected: (_) => setState(() => _filter = type),
                  ),
              ],
            ),
            if (groups.isEmpty)
              const EmptyState(
                icon: Icons.swap_vert,
                title: 'No movements yet',
                message: 'Open an item and tap In, Out or Count.',
              ),
            for (final (day, dayMoves) in groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Text(
                  isSameDay(day, now) ? 'Today' : formatDate(day),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.inkMuted),
                ),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, m) in dayMoves.indexed) ...[
                      if (i > 0) const Divider(indent: 72),
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ItemDetailPage(itemId: m.itemId)),
                        ),
                        child: MoveTile(move: m, showDay: false),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (moves.length >= recentMovesLimit)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Showing the latest $recentMovesLimit. Open an item to see '
                  'all of its history.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSubtle, fontSize: 13),
                ),
              ),
          ],
        );
      },
    );
  }
}
