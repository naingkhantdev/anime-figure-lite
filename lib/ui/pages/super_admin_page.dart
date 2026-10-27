import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../logic/subscription.dart';
import '../../models/shop.dart';
import '../../providers/providers.dart';
import '../../utils/dates.dart';
import '../theme.dart';
import '../widgets/effects.dart';
import '../widgets/glass.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import 'blacklist_page.dart';

/// The super admin's only screen: every shop and when it expires.
class SuperAdminPage extends ConsumerStatefulWidget {
  const SuperAdminPage({super.key});

  @override
  ConsumerState<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends ConsumerState<SuperAdminPage> {
  String _query = '';
  ShopStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const AppTitle(),
        actions: [
          IconButton(
            tooltip: l.blacklist,
            icon: const Icon(Icons.block),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute<void>(builder: (_) => const BlacklistPage())),
          ),
          IconButton(
            tooltip: l.signOut,
            icon: const Icon(Icons.logout),
            onPressed: () => confirmSignOut(
                context, ref.read(authRepositoryProvider).signOut),
          ),
        ],
      ),
      body: AsyncBody(
        value: ref.watch(allShopsProvider),
        data: (shops) {
          final now = DateTime.now();
          int count(ShopStatus s) =>
              shops.where((shop) => shop.statusAt(now) == s).length;
          final q = _query.trim().toLowerCase();
          final visible = shops.where((shop) {
            if (_filter != null && shop.statusAt(now) != _filter) return false;
            return q.isEmpty ||
                shop.name.toLowerCase().contains(q) ||
                shop.ownerEmail.toLowerCase().contains(q) ||
                shop.phone.contains(q);
          }).toList()
            // Waiting shops first, they need you; then by what runs out next.
            ..sort((a, b) {
              final ae = a.expiresAt, be = b.expiresAt;
              if (ae == null || be == null) {
                return ae == null ? (be == null ? 0 : -1) : 1;
              }
              return ae.compareTo(be);
            });

          return ListView(
            padding: pagePadding(context),
            children: [
              Text(l.shops,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                          child: Stat(
                              label: l.shopStatusWaiting,
                              value: '${count(ShopStatus.pending)}',
                              color: AppColors.infoInk)),
                      Expanded(
                          child: Stat(
                              label: l.shopStatusActive,
                              value:
                                  '${count(ShopStatus.active) + count(ShopStatus.expiringSoon)}',
                              color: AppColors.successInk)),
                      Expanded(
                          child: Stat(
                              label: l.shopStatusExpired,
                              value: '${count(ShopStatus.expired)}',
                              color: AppColors.dangerInk)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l.searchShops,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final (label, status) in [
                    (l.all, null),
                    (l.shopStatusWaiting, ShopStatus.pending),
                    (l.expiring, ShopStatus.expiringSoon),
                    (l.shopStatusExpired, ShopStatus.expired),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: _filter == status,
                      onSelected: (_) => setState(() => _filter = status),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (visible.isEmpty)
                EmptyState(
                  icon: Icons.storefront_outlined,
                  title: l.noShopsHere,
                  message: l.noShopsHereBody,
                )
              else
                for (final (i, shop) in visible.indexed) ...[
                  Reveal(index: i, child: _ShopTile(shop: shop, now: now)),
                  const SizedBox(height: 8),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({required this.shop, required this.now});

  final Shop shop;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final expires = shop.expiresAt;
    final l = context.l10n;
    final subtitle = [
      shop.ownerEmail,
      if (shop.phone.isNotEmpty) shop.phone,
      if (expires == null)
        l.signedUpOn(
            shop.createdAt == null ? '' : formatDate(shop.createdAt!))
      else if (expires.isAfter(now))
        l.untilDaysLeft(formatDate(expires), daysLeft(expires, now))
      else
        l.expiredOn(formatDate(expires)),
    ].join('\n');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        title: Text(shop.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppColors.inkMuted, height: 1.4)),
        isThreeLine: true,
        trailing: ShopStatusPill(shop: shop, now: now),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => _ExpirySheet(shop: shop),
        ),
      ),
    );
  }
}

/// Renew, set a date, or switch a shop off.
class _ExpirySheet extends ConsumerStatefulWidget {
  const _ExpirySheet({required this.shop});

  final Shop shop;

  @override
  ConsumerState<_ExpirySheet> createState() => _ExpirySheetState();
}

class _ExpirySheetState extends ConsumerState<_ExpirySheet> {
  bool _busy = false;

  Future<void> _set(DateTime? expiresAt, String done) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(shopRepositoryProvider)
          .setExpiry(widget.shop.id, expiresAt);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = widget.shop.expiresAt;
    final l = context.l10n;
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && current.isAfter(now)
          ? current
          : now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      helpText: l.shopWorksUntil,
    );
    if (picked == null) return;
    // Through the end of the chosen day.
    final end = DateTime(picked.year, picked.month, picked.day, 23, 59);
    await _set(end, l.shopNowRunsUntil(widget.shop.name, formatDate(end)));
  }

  Future<void> _stop() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.stopShopQuestion(widget.shop.name)),
        content: Text(l.stopShopBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dangerInk),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.stopNow),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _set(DateTime.now(), l.shopStopped(widget.shop.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final now = DateTime.now();
    final status = shop.statusAt(now);
    final l = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                ShopStatusPill(shop: shop, now: now),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              shop.expiresAt == null
                  ? l.waitingForYou
                  : status.canWrite
                      ? l.runsUntil(formatDateTime(shop.expiresAt!))
                      : l.expiredOn(formatDateTime(shop.expiresAt!)),
              style: const TextStyle(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 20),
            Text(
                status.canWrite
                    ? l.addTimeFrom(formatDate(shop.expiresAt!))
                    : l.addTimeFromToday,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, months) in [
                  (l.addMonths(1), 1),
                  (l.addMonths(3), 3),
                  (l.addMonths(6), 6),
                  (l.addOneYear, 12),
                ])
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () {
                            final until = extendExpiry(
                                shop.expiresAt, DateTime.now(), months);
                            _set(
                                until,
                                l.shopNowRunsUntil(
                                    shop.name, formatDate(until)));
                          },
                    child: Text(label),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _pickDate,
              icon: const Icon(Icons.event),
              label: Text(l.pickEndDate),
            ),
            if (status.canWrite) ...[
              const SizedBox(height: 8),
              TextButton(
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.dangerInk),
                onPressed: _busy ? null : _stop,
                child: Text(l.stopThisShopNow),
              ),
            ],
            if (shop.ownerEmail.isNotEmpty)
              TextButton.icon(
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.dangerInk),
                onPressed: _busy
                    ? null
                    : () {
                        // This sheet's context goes with it; open the next
                        // one from the page underneath.
                        final navigator = Navigator.of(context)..pop();
                        showBlockSheet(navigator.context,
                            email: shop.ownerEmail);
                      },
                icon: const Icon(Icons.block),
                label: Text(l.blockThisOwner),
              ),
          ],
        ),
      ),
    );
  }
}
