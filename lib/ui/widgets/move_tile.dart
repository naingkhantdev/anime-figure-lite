import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../../logic/stock.dart';
import '../../models/stock_move.dart';
import '../../utils/dates.dart';
import '../../utils/money.dart';
import '../theme.dart';

/// One line of stock history: what moved, how much, and the count after.
class MoveTile extends StatelessWidget {
  const MoveTile({
    super.key,
    required this.move,
    this.showItem = true,
    this.showDay = true,
  });

  final StockMove move;

  /// False on an item's own page, where the name is already on screen.
  final bool showItem;

  /// False under a day heading, where only the time is new.
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final (icon, soft, ink) = switch (move.type) {
      // Neutral tiles; only the signed number below carries colour.
      MoveType.stockIn => (
          Icons.south_west,
          AppColors.surfaceSunken,
          AppColors.successInk
        ),
      MoveType.stockOut => (
          Icons.north_east,
          AppColors.surfaceSunken,
          AppColors.dangerInk
        ),
      MoveType.adjust => (Icons.tune, AppColors.surfaceSunken, AppColors.ink),
    };
    final change = move.change;
    final details = [
      if (!showItem) move.type.label(context.l10n),
      if (move.customerName.isNotEmpty) move.customerName,
      if (move.total > 0)
        '${move.quantity} × ${formatMmk(move.unitPrice)} = ${formatMmk(move.total)}',
      if (move.note.isNotEmpty) move.note,
      if (move.createdAt == null)
        context.l10n.saving
      else
        showDay ? formatDateTime(move.createdAt!) : formatTime(move.createdAt!),
    ];
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: 18, color: AppColors.inkMuted),
      ),
      title: Text(
        showItem ? move.itemName : details.removeAt(0),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        details.join(' · '),
        style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            move.type == MoveType.adjust && change == 0
                ? '±0'
                : '${change > 0 ? '+' : ''}$change',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16, color: ink),
          ),
          Text('→ ${move.quantityAfter}',
              style: const TextStyle(color: AppColors.inkSubtle, fontSize: 12)),
        ],
      ),
    );
  }
}
