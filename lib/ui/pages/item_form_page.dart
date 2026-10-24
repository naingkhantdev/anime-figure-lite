import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/inventory_repository.dart';
import '../../logic/stock.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// New item when [item] is null, otherwise edit its details. Quantity is
/// only set here for a new item; after that it moves through stock in/out.
class ItemFormPage extends ConsumerStatefulWidget {
  const ItemFormPage({super.key, this.item});

  final Item? item;

  @override
  ConsumerState<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends ConsumerState<ItemFormPage> {
  late final _name = TextEditingController(text: widget.item?.name);
  late final _code = TextEditingController(text: widget.item?.code);
  late final _unit = TextEditingController(text: widget.item?.unit ?? 'pcs');
  late final _price = TextEditingController(text: _num(widget.item?.price));
  late final _cost = TextEditingController(text: _num(widget.item?.cost));
  late final _lowAt =
      TextEditingController(text: '${widget.item?.lowStockAt ?? 2}');
  final _quantity = TextEditingController();
  bool _busy = false;
  String? _error;

  static String _num(int? v) => v == null || v == 0 ? '' : '$v';

  @override
  void dispose() {
    for (final c in [_name, _code, _unit, _price, _cost, _lowAt, _quantity]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Empty means 0; anything else must be a whole number.
  int _read(TextEditingController c, String label) {
    if (c.text.trim().isEmpty) return 0;
    return parseWholeNumber(c.text) ??
        (throw InventoryException('$label must be a whole number.'));
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = ItemDraft(
        name: _name.text,
        code: _code.text,
        unit: _unit.text,
        price: _read(_price, 'Selling price'),
        cost: _read(_cost, 'Cost price'),
        lowStockAt: _read(_lowAt, 'Low stock level'),
      );
      final repo = ref.read(inventoryRepositoryProvider);
      final item = widget.item;
      if (item == null) {
        await repo.createItem(draft,
            initialQuantity: _read(_quantity, 'Starting quantity'));
      } else {
        await repo.updateItem(item.id, draft);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.item == null;
    const numberKeyboard = TextInputType.numberWithOptions();
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'New item' : 'Edit item')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            autofocus: isNew,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _code,
                  decoration: const InputDecoration(
                      labelText: 'Code (optional)', hintText: 'SKU / barcode'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _unit,
                  decoration: const InputDecoration(
                      labelText: 'Unit', hintText: 'pcs, box, kg'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: numberKeyboard,
                  decoration: const InputDecoration(
                      labelText: 'Selling price', suffixText: 'Ks'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cost,
                  keyboardType: numberKeyboard,
                  decoration: const InputDecoration(
                      labelText: 'Cost price', suffixText: 'Ks'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isNew) ...[
                Expanded(
                  child: TextField(
                    controller: _quantity,
                    keyboardType: numberKeyboard,
                    decoration: const InputDecoration(
                        labelText: 'Starting quantity', hintText: '0'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextField(
                  controller: _lowAt,
                  keyboardType: numberKeyboard,
                  decoration:
                      const InputDecoration(labelText: 'Warn when at or below'),
                ),
              ),
            ],
          ),
          if (!isNew) ...[
            const SizedBox(height: 12),
            const Text(
              'To change the quantity, use In, Out or Count on the item page, '
              'so the history stays right.',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.dangerInk)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(isNew ? 'Add item' : 'Save'),
          ),
        ],
      ),
    );
  }
}
