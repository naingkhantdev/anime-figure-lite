import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import '../widgets/glass.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import 'customer_form_page.dart';
import 'customers_tab.dart';
import 'history_tab.dart';
import 'item_form_page.dart';
import 'items_tab.dart';
import 'shop_orders_tab.dart';
import 'shop_tab.dart';

/// A shop owner's home: Stock, Orders, History, Customers, Shop. Bottom bar on
/// phones, side rail on tablets.
class ShopHomePage extends ConsumerStatefulWidget {
  const ShopHomePage({super.key});

  @override
  ConsumerState<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends ConsumerState<ShopHomePage> {
  int _tab = 0;

  /// Where a new-order notification leads.
  static const _ordersTab = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAlerts());
  }

  /// Turns on new-order notifications, and the first time explains how to
  /// keep the phone's battery saver from stopping them.
  Future<void> _startAlerts() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final alerts = ref.read(orderAlertsProvider);
    void openOrders() {
      if (mounted) setState(() => _tab = _ordersTab);
    }

    final openedByAlert = await alerts.start(user.uid, onTap: openOrders);
    if (openedByAlert) openOrders();
    if (!await alerts.takeBatteryTip() || !mounted) return;
    final l = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined),
        title: Text(l.batteryTipTitle),
        content: Text(l.batteryTipBody(appName)),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context), child: Text(l.ok)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Waiting orders that weren't there before ring, as long as the app
    // runs; the first load only takes note of what is already waiting.
    ref.listen(shopOrdersProvider, (previous, next) {
      final orders = next.valueOrNull;
      if (orders == null || ref.read(authStateProvider).valueOrNull == null) {
        return;
      }
      ref.read(orderAlertsProvider).alertNew(
          [for (final o in orders) if (o.status == 'pending') o.id],
          context.l10n,
          notify: previous?.hasValue == true);
    });
    final shop = ref.watch(myShopProvider).valueOrNull;
    final canWrite = ref.watch(canWriteProvider);
    final waiting = ref.watch(shopOrdersProvider.select((orders) =>
        orders.valueOrNull?.where((o) => o.status == 'pending').length ?? 0));

    // Orders waiting for an answer show as a count on their tab.
    Widget icon(IconData data, int i) => i == 1
        ? Badge(
            isLabelVisible: waiting > 0,
            label: Text('$waiting'),
            child: Icon(data),
          )
        : Icon(data);

    final fab = switch (_tab) {
      0 => FloatingActionButton.extended(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ItemFormPage())),
          icon: const Icon(Icons.add),
          label: Text(context.l10n.newItem),
        ),
      3 => FloatingActionButton.extended(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CustomerFormPage())),
          icon: const Icon(Icons.person_add_alt),
          label: Text(context.l10n.newCustomer),
        ),
      _ => null,
    };

    // Phones get a bottom bar, which the thumb reaches. From tablet width
    // (Material's 600dp breakpoint) there is room for a rail at the side,
    // and the content stops stretching so lines stay readable.
    final wide = MediaQuery.sizeOf(context).width >= 600;

    final content = Column(
      children: [
        if (shop != null) ExpiryBanner(shop: shop),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: IndexedStack(
                index: _tab,
                children: const [
                  ItemsTab(),
                  ShopOrdersTab(),
                  HistoryTab(),
                  CustomersTab(),
                  ShopTab(),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    void select(int i) => setState(() => _tab = i);

    return Scaffold(
      // The phone's bar floats; tabs scroll on underneath it.
      extendBody: !wide,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                shop?.name ?? '',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _tab,
                  onDestinationSelected: select,
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: -0.9,
                  destinations: [
                    for (final (i, (outlined, selected, label))
                        in _sections(context.l10n).indexed)
                      NavigationRailDestination(
                        icon: icon(outlined, i),
                        selectedIcon: icon(selected, i),
                        label: Text(label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      floatingActionButton: canWrite ? fab : null,
      bottomNavigationBar: wide
          ? null
          : GlassNavBar(
              child: NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: select,
                destinations: [
                  for (final (i, (outlined, selected, label))
                      in _sections(context.l10n).indexed)
                    NavigationDestination(
                      icon: icon(outlined, i),
                      selectedIcon: icon(selected, i),
                      label: label,
                    ),
                ],
              ),
            ),
    );
  }
}

/// The sections, in tab order: icon, selected icon, label.
List<(IconData, IconData, String)> _sections(AppLocalizations l) => [
      (Icons.inventory_2_outlined, Icons.inventory_2, l.tabStock),
      (Icons.receipt_long_outlined, Icons.receipt_long, l.tabOrders),
      (Icons.swap_vert, Icons.swap_vert, l.tabHistory),
      (Icons.people_outline, Icons.people, l.tabCustomers),
      (Icons.storefront_outlined, Icons.storefront, l.tabShop),
    ];

/// Shown instead of an action when the shop is read-only.
void explainReadOnly(BuildContext context) =>
    showMessage(context, context.l10n.shopReadOnly);
