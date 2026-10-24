import 'package:flutter/material.dart';

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
      MoveType.stockIn => (
          Icons.south_west,
          AppColors.successSoft,
          AppColors.successInk
        ),
      MoveType.stockOut => (
          Icons.north_east,
          AppColors.dangerSoft,
          AppColors.dangerInk
        ),
      MoveType.adjust => (Icons.tune, AppColors.infoSoft, AppColors.infoInk),
    };
    final change = move.change;
    final details = [
      if (!showItem) move.type.label,
      if (move.customerName.isNotEmpty) move.customerName,
      if (move.total > 0)
        '${move.quantity} × ${formatMmk(move.unitPrice)} = ${formatMmk(move.total)}',
      if (move.note.isNotEmpty) move.note,
      if (move.createdAt == null)
        'Saving…'
      else
        showDay ? formatDateTime(move.createdAt!) : formatTime(move.createdAt!),
    ];
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: soft,
        foregroundColor: ink,
        child: Icon(icon, size: 20),
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
