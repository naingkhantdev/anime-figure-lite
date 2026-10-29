import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../../logic/subscription.dart';
import '../../models/shop.dart';
import '../../models/shop_public.dart';
import '../../providers/providers.dart';
import '../../utils/dates.dart';
import '../../utils/money.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/skeleton.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/language.dart';
import 'delete_account_dialog.dart';
import 'shop_settings_page.dart';

/// The shop's details, how customers pay it, its subscription, and signing
/// out.
class ShopTab extends ConsumerWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody(
      value: ref.watch(myShopProvider),
      loading: const SkeletonList(header: false, rows: 3),
      data: (shop) {
        if (shop == null) return const SizedBox.shrink();
        final now = DateTime.now();
        final status = shop.statusAt(now);
        final public = ref.watch(shopPublicProvider(shop.id)).valueOrNull;
        void openSettings() => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ShopSettingsPage(shop: shop, public: public)),
            );
        return ListView(
          padding: pagePadding(context),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(shop.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          tooltip: context.l10n.edit,
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: openSettings,
                        ),
                      ],
                    ),
                    if (shop.phone.isNotEmpty)
                      Text(shop.phone,
                          style: const TextStyle(color: AppColors.inkMuted)),
                    Text(shop.ownerEmail,
                        style: const TextStyle(color: AppColors.inkMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _PaymentCard(
              shop: shop,
              public: public,
              onTap: openSettings,
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  status.canWrite ? Icons.verified_outlined : Icons.lock_clock,
                  color: status.canWrite
                      ? AppColors.successInk
                      : AppColors.dangerInk,
                ),
                title: Text(status.canWrite
                    ? context.l10n.activeUntil(formatDate(shop.expiresAt!))
                    : context.l10n.expiredOn(formatDate(shop.expiresAt!))),
                subtitle: Text(
                  status.canWrite
                      ? context.l10n
                          .daysLeftRenew(daysLeft(shop.expiresAt!, now))
                      : context.l10n.readOnlyRenew,
                ),
                trailing: ShopStatusPill(shop: shop, now: now),
              ),
            ),
            if (supportContact.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(context.l10n.contactLine(supportContact),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkMuted)),
            ],
            const SizedBox(height: 12),
            const LanguageTile(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => confirmSignOut(
                  context, ref.read(authRepositoryProvider).signOut),
              icon: const Icon(Icons.logout),
              label: Text(context.l10n.signOut),
            ),
            TextButton(
              onPressed: () => showCloseShopDialog(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.dangerInk),
              child: Text(context.l10n.deleteMyAccount),
            ),
            const SizedBox(height: 32),
            const Center(child: AppLogo(size: 56)),
            const SizedBox(height: 8),
            const Center(child: Wordmark(size: 14, shine: true)),
          ],
        );
      },
    );
  }
}

/// The delivery fee and ways to pay, as customers will see them; or, until
/// they are set, what to do first.
class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.shop,
    required this.public,
    required this.onTap,
  });

  final Shop shop;
  final ShopPublic? public;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = public;
    final missing = p == null || shop.phone.isEmpty;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(
          missing ? Icons.error_outline : Icons.payments_outlined,
          color: missing ? AppColors.warnInk : AppColors.accent,
        ),
        title: Text(missing ? l.setUpPayment : l.deliveryAndPayment,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(missing
            ? l.setUpPaymentBody
            : [
                p.deliveryFee == 0
                    ? l.freeDelivery
                    : l.deliveryFeeLine(formatMmk(p.deliveryFee)),
                if (p.paymentMethods.isEmpty)
                  l.noWaysToPay
                else
                  p.paymentMethods.map((m) => m.type.label(l)).join(', '),
              ].join('\n')),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
