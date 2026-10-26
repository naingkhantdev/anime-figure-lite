import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/subscription.dart';
import '../../providers/providers.dart';
import '../widgets/common.dart';
import 'pending_page.dart';
import 'customer_home_page.dart';
import 'shop_home_page.dart';
import 'super_admin_page.dart';

/// One app, three kinds of people. The first screen follows the role:
///
/// - guests and customers → the figure shop (browse, cart, orders)
/// - super admin (`super_admins/{uid}` exists) → every shop and its expiry
/// - shop admin (`shops/{uid}` exists) → their own stock, or "waiting for
///   approval" until the super admin turns the shop on
///
/// A customer becomes a shop admin through "Open a shop" on the Account tab.
class RoleGate extends ConsumerWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _gate(ref.watch(authStateProvider), (user) {
      if (user == null) return const CustomerHomePage();
      return _gate(ref.watch(isSuperAdminProvider), (isSuperAdmin) {
        if (isSuperAdmin) return const SuperAdminPage();
        return _gate(ref.watch(myShopProvider), (shop) {
          if (shop == null) return const CustomerHomePage();
          if (shop.statusAt(DateTime.now()) == ShopStatus.pending) {
            return PendingPage(shop: shop);
          }
          return const ShopHomePage();
        });
      });
    });
  }

  /// Each page brings its own Scaffold; loading and errors get a bare one.
  /// `isLoading` also covers a switch of account, when Riverpod still holds
  /// the previous account's value: never show one account another's screen.
  Widget _gate<T>(AsyncValue<T> value, Widget Function(T) page) =>
      value.hasValue && !value.isLoading
          ? page(value.requireValue)
          : Scaffold(
              body: AsyncBody(value: value, data: (_) => const SizedBox()));
}
