import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/language.dart';
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
/// Guests can sign in from Account or Orders. Checkout still asks for
/// sign-in on the spot so a cart is never lost.
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
      children: const [
        ProductListPage(),
        CartPage(),
        _OrdersTab(),
        _AccountTab(),
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
                          in _sections(context.l10n).indexed)
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

/// The four sections, in [CustomerTab] order: icon, selected icon, label.
List<(IconData, IconData, String)> _sections(AppLocalizations l) => [
      (Icons.storefront_outlined, Icons.storefront, l.tabShop),
      (Icons.shopping_cart_outlined, Icons.shopping_cart, l.tabCart),
      (Icons.receipt_long_outlined, Icons.receipt_long, l.tabOrders),
      (Icons.account_circle_outlined, Icons.account_circle, l.tabAccount),
    ];

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authStateProvider).valueOrNull != null;
    if (signedIn) return const OrdersPage();
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.myOrders)),
      body: ListView(
        padding: pagePadding(context, top: 16),
        children: [
          StartColumn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageIntro(
                    title: l.signInToSeeOrders,
                    message: l.signInToSeeOrdersBody),
                const SizedBox(height: 16),
                const _StatusFlow(),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => ensureSignedIn(context, ref),
                  child: Text(l.signIn),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => ensureSignedIn(context, ref, signUp: true),
                  child: Text(l.createAnAccount),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The statuses an order moves through, as the very pills a placed order
/// wears on the Orders page, so the shopper recognises them later. Wraps
/// onto a second line on a narrow phone.
class _StatusFlow extends StatelessWidget {
  const _StatusFlow();

  @override
  Widget build(BuildContext context) {
    const arrow = ExcludeSemantics(
      child: Icon(Icons.arrow_forward_rounded,
          size: 14, color: AppColors.inkSubtle),
    );
    return const Wrap(
      spacing: 6,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OrderStatusPill(status: 'pending'),
        arrow,
        OrderStatusPill(status: 'confirmed'),
        arrow,
        OrderStatusPill(status: 'shipped'),
      ],
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
      appBar: AppBar(title: Text(context.l10n.tabAccount)),
      body: user == null
          ? const _GuestAccount()
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
                            Text(context.l10n.signedInAs,
                                style: const TextStyle(
                                    color: AppColors.inkMuted, fontSize: 13)),
                            Text(user.email ?? context.l10n.signedIn,
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
                        title: Text(context.l10n.openAShop),
                        subtitle: Text(context.l10n.openAShopSubtitle),
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
                        title: Text(context.l10n.signOut),
                        onTap: () => ref.read(authRepositoryProvider).signOut(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const LanguageTile(),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: AppColors.dangerInk),
                    title: Text(context.l10n.deleteMyAccount,
                        style: const TextStyle(color: AppColors.dangerInk)),
                    onTap: () => showDeleteAccountDialog(context),
                  ),
                ),
              ],
            ),
    );
  }
}

/// The Account tab for someone not signed in. The ways in come first; what
/// an account gives sits below, plain text rather than tappable-looking
/// rows, for whoever wants a reason before they sign up.
class _GuestAccount extends ConsumerWidget {
  const _GuestAccount();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return ListView(
      padding: pagePadding(context, top: 16),
      children: [
        StartColumn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageIntro(title: l.browsingAsGuest, message: l.guestSubtitle),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => ensureSignedIn(context, ref),
                child: Text(l.signIn),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => ensureSignedIn(context, ref, signUp: true),
                child: Text(l.createAnAccount),
              ),
              const SizedBox(height: 40),
              SectionHeading(l.withAnAccount),
              const SizedBox(height: 4),
              _Benefit(
                  icon: Icons.shopping_bag_outlined,
                  title: l.benefitCheckout,
                  line: l.benefitCheckoutLine),
              _Benefit(
                  icon: Icons.local_shipping_outlined,
                  title: l.benefitFollow,
                  line: l.benefitFollowLine),
              _Benefit(
                  icon: Icons.storefront_outlined,
                  title: l.benefitShop,
                  line: l.benefitShopLine),
              const SizedBox(height: 32),
              const LanguageTile(),
            ],
          ),
        ),
      ],
    );
  }
}

/// One thing an account gives: a line icon, what it is, and a line more.
class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.line});

  final IconData icon;
  final String title;
  final String line;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 22, color: AppColors.inkMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(line,
                      style: const TextStyle(
                          color: AppColors.inkMuted, fontSize: 14, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
