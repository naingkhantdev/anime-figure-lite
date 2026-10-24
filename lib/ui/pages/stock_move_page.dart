import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/stock.dart';
import '../../models/customer.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Record stock in, stock out (a sale), or a count for one item.
class StockMovePage extends ConsumerStatefulWidget {
  const StockMovePage({
    super.key,
    required this.item,
    required this.initialType,
  });

  final Item item;
  final MoveType initialType;

  @override
  ConsumerState<StockMovePage> createState() => _StockMovePageState();
}

class _StockMovePageState extends ConsumerState<StockMovePage> {
  late MoveType _type = widget.initialType;
  late final _quantity = TextEditingController(
      text: widget.initialType == MoveType.adjust
          ? '${widget.item.quantity}'
          : '1');
  late final _price = TextEditingController(text: _defaultPrice(_type));
  final _note = TextEditingController();
  Customer? _customer;
  bool _busy = false;
  String? _error;

  String _defaultPrice(MoveType type) => switch (type) {
        MoveType.stockIn => widget.item.cost == 0 ? '' : '${widget.item.cost}',
        MoveType.stockOut =>
          widget.item.price == 0 ? '' : '${widget.item.price}',
        MoveType.adjust => '',
      };

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  void _setType(MoveType type) => setState(() {
        _type = type;
        _price.text = _defaultPrice(type);
        _quantity.text = type == MoveType.adjust ? '${_current()}' : '1';
        _error = null;
      });

  /// The latest stored quantity, falling back to the one we opened with.
  int _current() =>
      ref.read(itemProvider(widget.item.id)).valueOrNull?.quantity ??
      widget.item.quantity;

  void _bump(int by) {
    final q = (parseWholeNumber(_quantity.text) ?? 0) + by;
    if (q < 0) return;
    setState(() => _quantity.text = '$q');
  }

  Future<void> _save() async {
    final quantity = parseWholeNumber(_quantity.text);
    final price =
        _price.text.trim().isEmpty ? 0 : parseWholeNumber(_price.text);
    if (quantity == null) {
      setState(() => _error = 'Quantity must be a whole number.');
      return;
    }
    if (price == null) {
      setState(() => _error = 'Price must be a whole number of kyats.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(inventoryRepositoryProvider).recordMove(
            itemId: widget.item.id,
            type: _type,
            quantity: quantity,
            unitPrice: price,
            customer: _customer,
            note: _note.text,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
          content: Text('${_type.label} saved for ${widget.item.name}.')));
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item =
        ref.watch(itemProvider(widget.item.id)).valueOrNull ?? widget.item;
    final quantity = parseWholeNumber(_quantity.text);
    final price =
        _price.text.trim().isEmpty ? 0 : parseWholeNumber(_price.text) ?? 0;

    String preview;
    var previewOk = true;
    try {
      if (quantity == null) throw StockException('Enter a whole number.');
      final after = quantityAfter(item.quantity, _type, quantity);
      preview = '${item.quantity} → $after';
    } on StockException catch (e) {
      preview = e.message;
      previewOk = false;
    }

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<MoveType>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                  value: MoveType.stockIn,
                  label: Text('In'),
                  icon: Icon(Icons.south_west)),
              ButtonSegment(
                  value: MoveType.stockOut,
                  label: Text('Out'),
                  icon: Icon(Icons.north_east)),
              ButtonSegment(
                  value: MoveType.adjust,
                  label: Text('Count'),
                  icon: Icon(Icons.tune)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => _setType(s.first),
          ),
          const SizedBox(height: 8),
          Text(
            switch (_type) {
              MoveType.stockIn => 'New stock arrived.',
              MoveType.stockOut => 'Sold or taken out.',
              MoveType.adjust =>
                'You counted the shelf. Enter how many are really there.',
            },
            style: const TextStyle(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => _bump(-1),
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    labelText:
                        _type == MoveType.adjust ? 'Counted' : 'Quantity',
                    suffixText: item.unit,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => _bump(1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              preview,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: previewOk ? AppColors.inkMuted : AppColors.dangerInk,
              ),
            ),
          ),
          if (_type != MoveType.adjust) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(),
              decoration: InputDecoration(
                labelText: _type == MoveType.stockIn
                    ? 'Cost each'
                    : 'Selling price each',
                suffixText: 'Ks',
                helperText: quantity != null && quantity > 0 && price > 0
                    ? 'Total ${formatMmk(price * quantity)}'
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_type == MoveType.stockOut) ...[
            const SizedBox(height: 12),
            _CustomerPicker(
              value: _customer,
              onChanged: (c) => setState(() => _customer = c),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            maxLines: 2,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.dangerInk)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy || !previewOk ? null : _save,
            child: Text('Save ${_type.label.toLowerCase()}'),
          ),
        ],
      ),
    );
  }
}

class _CustomerPicker extends ConsumerWidget {
  const _CustomerPicker({required this.value, required this.onChanged});

  final Customer? value;
  final ValueChanged<Customer?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider).valueOrNull ?? const [];
    return DropdownButtonFormField<String>(
      value: value?.id ?? '',
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Customer (optional)'),
      items: [
        const DropdownMenuItem(value: '', child: Text('Walk-in customer')),
        for (final c in customers)
          DropdownMenuItem(
            value: c.id,
            child: Text(
              c.phone.isEmpty ? c.name : '${c.name} · ${c.phone}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (id) =>
          onChanged(customers.where((c) => c.id == id).firstOrNull),
    );
  }
}
