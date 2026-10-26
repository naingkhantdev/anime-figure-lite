import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../widgets/common.dart';
import 'cart_page.dart';
import 'create_shop_page.dart';
import 'orders_page.dart';
import 'product_list_page.dart';
import 'sign_in_page.dart';

/// The customer home's sections, in tab order.
enum CustomerTab { shop, cart, orders, account }

/// The open tab, so pages pushed on top (checkout, a product) can send the
/// customer to one after closing themselves.
final customerTabProvider =
    StateProvider<CustomerTab>((ref) => CustomerTab.shop);

/// Closes every page above the customer home and opens [tab] on it.
void showCustomerTab(NavigatorState navigator,
    StateController<CustomerTab> tabs, CustomerTab tab) {
  navigator.popUntil((route) => route.isFirst);
  tabs.state = tab;
}

/// A guest's or customer's home: Shop, Cart, Orders, Account. Bottom bar on
/// phones, side rail on tablets, like the shop owner's home.
///
/// Account is the one place to sign in from; Orders sends guests there.
/// Checkout still asks for sign-in on the spot so a cart is never lost.
class CustomerHomePage extends ConsumerWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final tab = ref.watch(customerTabProvider).index;
    final wide = MediaQuery.sizeOf(context).width >= 600;

    void select(int i) =>
        ref.read(customerTabProvider.notifier).state = CustomerTab.values[i];

    Widget icon(IconData data, int i) => i == 1
        ? Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: Icon(data),
          )
        : Icon(data);

    final content = IndexedStack(
      index: tab,
      children: [
        const ProductListPage(),
        const CartPage(),
        _OrdersTab(onSignIn: () => select(CustomerTab.account.index)),
        const _AccountTab(),
      ],
    );

    return Scaffold(
      body: wide
          ? Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: tab,
                    onDestinationSelected: select,
                    labelType: NavigationRailLabelType.all,
                    groupAlignment: -0.9,
                    destinations: [
                      for (final (i, (outlined, selected, label))
                          in _sections.indexed)
                        NavigationRailDestination(
                          icon: icon(outlined, i),
                          selectedIcon: icon(selected, i),
                          label: Text(label),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: select,
              destinations: [
                for (final (i, (outlined, selected, label))
                    in _sections.indexed)
                  NavigationDestination(
                    icon: icon(outlined, i),
                    selectedIcon: icon(selected, i),
                    label: label,
                  ),
              ],
            ),
    );
  }
}

/// The four sections, in [CustomerTab] order: icon, selected icon, label.
const _sections = [
  (Icons.storefront_outlined, Icons.storefront, 'Shop'),
  (Icons.shopping_cart_outlined, Icons.shopping_cart, 'Cart'),
  (Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
  (Icons.account_circle_outlined, Icons.account_circle, 'Account'),
];

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authStateProvider).valueOrNull != null;
    if (signedIn) return const OrdersPage();
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Sign in to see your orders',
            ),
            FilledButton(
              onPressed: onSignIn,
              child: const Text('Go to Account'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sign in or out, and the way into running a shop on this app. Once the
/// shop exists, RoleGate shows its screens instead of this page.
class _AccountTab extends ConsumerWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: user == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EmptyState(
                    icon: Icons.account_circle_outlined,
                    title: 'You are browsing as a guest',
                    message: 'Sign in to check out, see your orders '
                        'or open your own shop.',
                  ),
                  FilledButton.icon(
                    onPressed: () => ensureSignedIn(context, ref),
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in'),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(user.email ?? 'Signed in'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Open a shop'),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    // A shop admin or the super admin is switched to their
                    // own screens by RoleGate. `.future` waits for this
                    // account's answer rather than a stale or loading value.
                    if (await ref.read(isSuperAdminProvider.future) ||
                        await ref.read(myShopProvider.future) != null) {
                      return;
                    }
                    navigator.push(MaterialPageRoute(
                        builder: (_) => const CreateShopPage()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: () => ref.read(authRepositoryProvider).signOut(),
                ),
              ],
            ),
    );
  }
}
