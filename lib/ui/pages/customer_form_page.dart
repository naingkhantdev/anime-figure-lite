import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/stock.dart';
import '../../models/customer.dart';
import '../../models/stock_move.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/move_tile.dart';

/// New customer when [customer] is null, otherwise view and edit one,
/// with what they recently bought.
class CustomerFormPage extends ConsumerStatefulWidget {
  const CustomerFormPage({super.key, this.customer});

  final Customer? customer;

  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  late final _name = TextEditingController(text: widget.customer?.name);
  late final _phone = TextEditingController(text: widget.customer?.phone);
  late final _address = TextEditingController(text: widget.customer?.address);
  late final _note = TextEditingController(text: widget.customer?.note);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(inventoryRepositoryProvider).saveCustomer(
            customerId: widget.customer?.id,
            name: _name.text,
            phone: _phone.text,
            address: _address.text,
            note: _note.text,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final customer = widget.customer!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${customer.name}?'),
        content: const Text('Past stock outs keep their name.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dangerInk),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(inventoryRepositoryProvider).deleteCustomer(customer.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    final canWrite = ref.watch(canWriteProvider);
    final bought = customer == null
        ? const <StockMove>[]
        : (ref.watch(recentMovesProvider).valueOrNull ?? const <StockMove>[])
            .where((m) =>
                m.type == MoveType.stockOut && m.customerId == customer.id)
            .toList();
    final spent = bought.fold(0, (s, m) => s + m.total);

    return Scaffold(
      appBar: AppBar(
        title: Text(customer == null ? 'New customer' : customer.name),
        actions: [
          if (customer != null && canWrite)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            enabled: canWrite,
            autofocus: customer == null,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            enabled: canWrite,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Phone (optional)', hintText: '09xxxxxxxxx'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            enabled: canWrite,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Address (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            enabled: canWrite,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.dangerInk)),
          ],
          if (canWrite) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(customer == null ? 'Add customer' : 'Save'),
            ),
          ],
          if (bought.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Recent purchases',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(formatMmk(spent),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, m) in bought.indexed) ...[
                    if (i > 0) const Divider(indent: 72),
                    MoveTile(move: m),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
