import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import 'customer_form_page.dart';
import 'customers_tab.dart';
import 'history_tab.dart';
import 'item_form_page.dart';
import 'items_tab.dart';
import 'shop_tab.dart';

/// A shop owner's home: Stock, History, Customers, Shop.
class ShopHomePage extends ConsumerStatefulWidget {
  const ShopHomePage({super.key});

  @override
  ConsumerState<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends ConsumerState<ShopHomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final shop = ref.watch(myShopProvider).valueOrNull;
    final canWrite = ref.watch(canWriteProvider);

    final fab = switch (_tab) {
      0 => FloatingActionButton.extended(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ItemFormPage())),
          icon: const Icon(Icons.add),
          label: const Text('New item'),
        ),
      2 => FloatingActionButton.extended(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CustomerFormPage())),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('New customer'),
        ),
      _ => null,
    };

    return Scaffold(
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
      body: Column(
        children: [
          if (shop != null) ExpiryBanner(shop: shop),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [
                ItemsTab(),
                HistoryTab(),
                CustomersTab(),
                ShopTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: canWrite ? fab : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Stock'),
          NavigationDestination(
              icon: Icon(Icons.swap_vert),
              selectedIcon: Icon(Icons.swap_vert_circle),
              label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Customers'),
          NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Shop'),
        ],
      ),
    );
  }
}

/// Shown instead of an action when the shop is read-only.
void explainReadOnly(BuildContext context) =>
    showMessage(context, 'Your shop is read-only until the owner renews it.');
