import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/shop_repository.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../../logic/stock.dart';
import '../../models/shop.dart';
import '../../models/shop_public.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import 'shop_home_page.dart';

/// The shop's name and phone, its delivery fee, and how customers pay it.
/// Opens with what is saved; saving needs an open shop.
class ShopSettingsPage extends ConsumerStatefulWidget {
  const ShopSettingsPage({super.key, required this.shop, this.public});

  final Shop shop;

  /// Null until the settings are first saved.
  final ShopPublic? public;

  @override
  ConsumerState<ShopSettingsPage> createState() => _ShopSettingsPageState();
}

/// A payment method being edited.
class _MethodDraft {
  _MethodDraft(this.type, String name, String number)
      : name = TextEditingController(text: name),
        number = TextEditingController(text: number);

  PaymentType type;
  final TextEditingController name;
  final TextEditingController number;

  PaymentMethod get value =>
      PaymentMethod(type: type, accountName: name.text, number: number.text);

  void dispose() {
    name.dispose();
    number.dispose();
  }
}

class _ShopSettingsPageState extends ConsumerState<ShopSettingsPage> {
  late final _name = TextEditingController(text: widget.shop.name);
  late final _phone = TextEditingController(text: widget.shop.phone);
  late final _fee = TextEditingController(
      text: (widget.public?.deliveryFee ?? 0) == 0
          ? ''
          : '${widget.public!.deliveryFee}');
  late final _methods = [
    for (final m in widget.public?.paymentMethods ?? const <PaymentMethod>[])
      _MethodDraft(m.type, m.accountName, m.number),
  ];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _fee.dispose();
    for (final m in _methods) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!ref.read(canWriteProvider)) return explainReadOnly(context);
    final l = context.l10n;
    final fee = _fee.text.trim().isEmpty ? 0 : parseWholeNumber(_fee.text);
    if (fee == null) {
      setState(() => _error = l.errPriceWhole);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(shopRepositoryProvider).saveSettings(
        widget.shop.id,
        name: _name.text,
        phone: _phone.text,
        deliveryFee: fee,
        paymentMethods: [for (final m in _methods) m.value],
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(l.settingsSaved)));
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final canWrite = ref.watch(canWriteProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.shopSettings)),
      body: ListView(
        padding: pagePadding(context, top: 8, bottom: 32),
        children: [
          TextField(
            controller: _name,
            enabled: canWrite,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l.shopName),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            enabled: canWrite,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l.phone,
              hintText: '09xxxxxxxxx',
              helperText: l.shopPhoneHelp,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fee,
            enabled: canWrite,
            keyboardType: const TextInputType.numberWithOptions(),
            decoration: InputDecoration(
              labelText: l.deliveryFee,
              hintText: '0',
              suffixText: 'Ks',
              helperText: l.deliveryFeeHelp,
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 24),
          Text(l.waysToPay,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(l.waysToPayHelp,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 13)),
          const SizedBox(height: 12),
          for (final (i, m) in _methods.indexed) ...[
            _MethodEditor(
              draft: m,
              enabled: canWrite,
              onType: (t) => setState(() => m.type = t),
              onRemove: () => setState(() => _methods.removeAt(i).dispose()),
            ),
            const SizedBox(height: 10),
          ],
          if (canWrite && _methods.length < maxPaymentMethods)
            OutlinedButton.icon(
              onPressed: () => setState(() => _methods.add(
                  _MethodDraft(PaymentType.kbzPay, _name.text.trim(), ''))),
              icon: const Icon(Icons.add),
              label: Text(l.addWayToPay),
            ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.dangerInk)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}

class _MethodEditor extends StatelessWidget {
  const _MethodEditor({
    required this.draft,
    required this.enabled,
    required this.onType,
    required this.onRemove,
  });

  final _MethodDraft draft;
  final bool enabled;
  final ValueChanged<PaymentType> onType;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Glass(
      radius: AppRadius.lg,
      shadow: false,
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<PaymentType>(
                  value: draft.type,
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    for (final t in PaymentType.values)
                      DropdownMenuItem(value: t, child: Text(t.label(l))),
                  ],
                  onChanged: enabled ? (t) => onType(t ?? draft.type) : null,
                ),
              ),
              IconButton(
                tooltip: l.remove,
                onPressed: enabled ? onRemove : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                TextField(
                  controller: draft.name,
                  enabled: enabled,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      InputDecoration(labelText: l.accountName, isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: draft.number,
                  enabled: enabled,
                  decoration: InputDecoration(
                    labelText: draft.type == PaymentType.bank
                        ? l.bankAccountNumber
                        : l.walletPhone,
                    hintText: draft.type == PaymentType.bank
                        ? l.bankAccountNumberHint
                        : '09xxxxxxxxx',
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
