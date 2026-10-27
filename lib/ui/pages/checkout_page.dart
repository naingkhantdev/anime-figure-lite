import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/order_repository.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../../models/shop_order.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';
import '../../utils/phone.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import 'customer_home_page.dart';

/// Contact and delivery details, then place the order. Fields are pre-filled
/// from the customer's most recent order, so no separate profile is stored.
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  var _method = DeliveryMethod.delivery;
  bool _prefilled = false;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _prefill(ref.read(myOrdersProvider).valueOrNull);
  }

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Runs once, when the order history first becomes available. Never
  /// overwrites anything the customer has already typed.
  void _prefill(List<ShopOrder>? orders) {
    if (_prefilled || orders == null) return;
    _prefilled = true;
    final last = orders.firstOrNull;
    if (last == null) return;
    setState(() {
      if (_phone.text.isEmpty) _phone.text = last.phone;
      if (_address.text.isEmpty) _address.text = last.address;
      _method = last.deliveryMethod;
    });
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() => _placing = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = context.l10n;
    try {
      final orders = await ref.read(orderRepositoryProvider).placeOrder(
            userId: user.uid,
            cart: ref.read(cartProvider),
            phone: _phone.text,
            deliveryMethod: _method,
            address: _address.text,
            note: _note.text,
          );
      ref.read(cartProvider.notifier).clear();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.ordersPlaced(orders)),
        ),
      );
      showCustomerTab(navigator, ref.read(customerTabProvider.notifier),
          CustomerTab.orders);
    } on OrderException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message(l))));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.couldNotPlaceOrder('$e'))),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(myOrdersProvider, (_, next) => _prefill(next.valueOrNull));
    final cart = ref.watch(cartProvider);
    final total = cart.fold<int>(0, (sum, i) => sum + i.subtotal);
    final isDelivery = _method == DeliveryMethod.delivery;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.checkout)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: pagePadding(context, top: 4, bottom: 24),
          children: [
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: InputDecoration(
                labelText: context.l10n.phone,
                hintText: '09xxxxxxxxx',
              ),
              validator: (v) => normalizePhone(v ?? '') == null
                  ? context.l10n.errPhoneFormat
                  : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<DeliveryMethod>(
              segments: [
                for (final m in DeliveryMethod.values)
                  ButtonSegment(value: m, label: Text(m.label(context.l10n))),
              ],
              selected: {_method},
              onSelectionChanged: (s) => setState(() => _method = s.first),
            ),
            if (isDelivery) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                minLines: 2,
                maxLines: 4,
                maxLength: maxTextLength,
                autofillHints: const [AutofillHints.fullStreetAddress],
                decoration: InputDecoration(
                  labelText: context.l10n.deliveryAddress,
                  hintText: context.l10n.deliveryAddressHint,
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? context.l10n.errAddressEmpty
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLines: 3,
              maxLength: maxTextLength,
              decoration: InputDecoration(labelText: context.l10n.noteOptional),
            ),
            const SizedBox(height: 8),
            Glass(
              radius: AppRadius.xl,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(context.l10n.estimatedTotal,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.inkMuted, fontSize: 13)),
                      ),
                      const SizedBox(width: 12),
                      Text(formatMmk(total),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.payShopDirectly,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.inkSubtle),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _placing || cart.isEmpty ? null : _placeOrder,
                    child: _placing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.placeOrder),
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
