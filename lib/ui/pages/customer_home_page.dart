import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/glass.dart';
import 'cart_page.dart';
import 'create_shop_page.dart';
import 'delete_account_dialog.dart';
import 'orders_page.dart';
import 'product_list_page.dart';
import 'sign_in_page.dart';

/// The customer home's sections, in tab order.
enum CustomerTab { shop, cart, orders, account }

/// The open tab, so pages pushed on top (checkout, a product) can send the
/// customer to one after closing themselves. Back to Shop when someone signs
/// out or another account takes over; signing in keeps the open tab.
final customerTabProvider = StateProvider<CustomerTab>((ref) {
  ref.listen(authStateProvider.select((s) => s.valueOrNull?.uid),
      (previous, next) {
    if (previous != null && previous != next) {
      ref.controller.state = CustomerTab.shop;
    }
  });
  return CustomerTab.shop;
});

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
      // The phone's bar floats; pages scroll on underneath it.
      extendBody: !wide,
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
          : GlassNavBar(
              child: NavigationBar(
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
      body: EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Sign in to see your orders',
        message: 'Orders you place show up here, with what the shop '
            'is doing with them.',
        action: FilledButton(
          onPressed: onSignIn,
          child: const Text('Go to Account'),
        ),
        secondary: TextButton(
          onPressed: () =>
              ref.read(customerTabProvider.notifier).state = CustomerTab.shop,
          child: const Text('Browse figures'),
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
          ? const _GuestWelcome()
          : ListView(
              padding: pagePadding(context, top: 8),
              children: [
                Glass(
                  radius: AppRadius.lg,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.accentSoft,
                        foregroundColor: AppColors.accent,
                        child: Text(
                          (user.email ?? '?').characters.first.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Signed in as',
                                style: TextStyle(
                                    color: AppColors.inkMuted, fontSize: 13)),
                            Text(user.email ?? 'Signed in',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.storefront_outlined),
                        title: const Text('Open a shop'),
                        subtitle: const Text('Sell and track your own stock'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final navigator = Navigator.of(context);
                          // A shop admin or the super admin is switched to
                          // their own screens by RoleGate. `.future` waits for
                          // this account's answer rather than a stale or
                          // loading value.
                          if (await ref.read(isSuperAdminProvider.future) ||
                              await ref.read(myShopProvider.future) != null) {
                            return;
                          }
                          navigator.push(MaterialPageRoute(
                              builder: (_) => const CreateShopPage()));
                        },
                      ),
                      const Divider(indent: 56),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Sign out'),
                        onTap: () => ref.read(authRepositoryProvider).signOut(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: AppColors.dangerInk),
                    title: const Text('Delete my account',
                        style: TextStyle(color: AppColors.dangerInk)),
                    onTap: () => showDeleteAccountDialog(context),
                  ),
                ),
              ],
            ),
    );
  }
}

/// The Account tab for someone not signed in: what an account gives them,
/// and the two ways in.
class _GuestWelcome extends ConsumerWidget {
  const _GuestWelcome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ListView(
      padding: pagePadding(context, top: 8),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Glass(
                  radius: AppRadius.xxl,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AppLogo(size: 64)),
                      const SizedBox(height: 16),
                      Text('You are browsing as a guest',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      const Text(
                        'Look around as much as you like. An account '
                        'lets you:',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.inkMuted),
                      ),
                      const SizedBox(height: 20),
                      for (final (i, (icon, title, line)) in const [
                        (
                          Icons.shopping_bag_outlined,
                          'Check out in a few taps',
                          'Your phone and address are remembered.'
                        ),
                        (
                          Icons.local_shipping_outlined,
                          'Follow every order',
                          'See when the shop confirms and sends it.'
                        ),
                        (
                          Icons.storefront_outlined,
                          'Open your own shop',
                          'Track stock and sell your figures here.'
                        ),
                      ].indexed)
                        Reveal(
                          index: i,
                          child: _Benefit(icon: icon, title: title, line: line),
                        ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => ensureSignedIn(context, ref),
                        child: const Text('Sign in'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () =>
                            ensureSignedIn(context, ref, signUp: true),
                        child: const Text('Create an account'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref
                      .read(customerTabProvider.notifier)
                      .state = CustomerTab.shop,
                  child: const Text('Keep browsing'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.line});

  final IconData icon;
  final String title;
  final String line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(line,
                    style: const TextStyle(
                        color: AppColors.inkMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
