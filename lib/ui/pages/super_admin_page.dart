import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/subscription.dart';
import '../../models/shop.dart';
import '../../providers/providers.dart';
import '../../utils/dates.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';

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
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(
          children: [
            AppLogo(size: 32),
            SizedBox(width: 10),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Wordmark(size: 18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text('Shops',
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
                              label: 'Waiting',
                              value: '${count(ShopStatus.pending)}',
                              color: AppColors.infoInk)),
                      Expanded(
                          child: Stat(
                              label: 'Active',
                              value:
                                  '${count(ShopStatus.active) + count(ShopStatus.expiringSoon)}',
                              color: AppColors.successInk)),
                      Expanded(
                          child: Stat(
                              label: 'Expired',
                              value: '${count(ShopStatus.expired)}',
                              color: AppColors.dangerInk)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search name, email or phone',
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final (label, status) in [
                    ('All', null),
                    ('Waiting', ShopStatus.pending),
                    ('Expiring', ShopStatus.expiringSoon),
                    ('Expired', ShopStatus.expired),
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
                const EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'No shops here',
                  message: 'New shops appear when someone signs up in the app.',
                )
              else
                for (final shop in visible) ...[
                  _ShopTile(shop: shop, now: now),
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
    final subtitle = [
      shop.ownerEmail,
      if (shop.phone.isNotEmpty) shop.phone,
      if (expires == null)
        'Signed up ${shop.createdAt == null ? '' : formatDate(shop.createdAt!)}'
      else if (expires.isAfter(now))
        'Until ${formatDate(expires)} · ${daysLeft(expires, now)} days left'
      else
        'Expired ${formatDate(expires)}',
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
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = widget.shop.expiresAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && current.isAfter(now)
          ? current
          : now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      helpText: 'Shop works until the end of',
    );
    if (picked == null) return;
    // Through the end of the chosen day.
    final end = DateTime(picked.year, picked.month, picked.day, 23, 59);
    await _set(end, '${widget.shop.name} now runs until ${formatDate(end)}.');
  }

  Future<void> _stop() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stop ${widget.shop.name} now?'),
        content: const Text(
            'The shop becomes read-only straight away. Its data is kept, and '
            'renewing turns it back on.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dangerInk),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop now'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _set(DateTime.now(), '${widget.shop.name} has been stopped.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final now = DateTime.now();
    final status = shop.statusAt(now);
    final from =
        status.canWrite ? 'from ${formatDate(shop.expiresAt!)}' : 'from today';
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
                  ? 'Waiting for you to turn it on.'
                  : '${status.canWrite ? 'Runs until' : 'Expired on'} '
                      '${formatDateTime(shop.expiresAt!)}',
              style: const TextStyle(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 20),
            Text('Add time $from',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, months) in [
                  ('1 month', 1),
                  ('3 months', 3),
                  ('6 months', 6),
                  ('1 year', 12),
                ])
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () {
                            final until = extendExpiry(
                                shop.expiresAt, DateTime.now(), months);
                            _set(until,
                                '${shop.name} now runs until ${formatDate(until)}.');
                          },
                    child: Text('+ $label'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _pickDate,
              icon: const Icon(Icons.event),
              label: const Text('Pick an end date'),
            ),
            if (status.canWrite) ...[
              const SizedBox(height: 8),
              TextButton(
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.dangerInk),
                onPressed: _busy ? null : _stop,
                child: const Text('Stop this shop now'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
