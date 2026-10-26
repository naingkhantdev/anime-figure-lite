import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../logic/subscription.dart';
import '../../models/shop.dart';
import '../../providers/providers.dart';
import '../../utils/dates.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/skeleton.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import 'delete_account_dialog.dart';

/// The shop's details, its subscription, and signing out.
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
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => _EditShopDialog(shop: shop),
                          ),
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
            Card(
              child: ListTile(
                leading: Icon(
                  status.canWrite ? Icons.verified_outlined : Icons.lock_clock,
                  color: status.canWrite
                      ? AppColors.successInk
                      : AppColors.dangerInk,
                ),
                title: Text(status.canWrite
                    ? 'Active until ${formatDate(shop.expiresAt!)}'
                    : 'Expired on ${formatDate(shop.expiresAt!)}'),
                subtitle: Text(
                  status.canWrite
                      ? '${daysLeft(shop.expiresAt!, now)} days left. '
                          'Contact the owner to renew.'
                      : 'Read-only. Contact the owner to renew.',
                ),
                trailing: ShopStatusPill(shop: shop, now: now),
              ),
            ),
            if (supportContact.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Contact: $supportContact',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkMuted)),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => confirmSignOut(
                  context, ref.read(authRepositoryProvider).signOut),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
            TextButton(
              onPressed: () => showCloseShopDialog(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.dangerInk),
              child: const Text('Delete my account'),
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

class _EditShopDialog extends ConsumerStatefulWidget {
  const _EditShopDialog({required this.shop});

  final Shop shop;

  @override
  ConsumerState<_EditShopDialog> createState() => _EditShopDialogState();
}

class _EditShopDialogState extends ConsumerState<_EditShopDialog> {
  late final _name = TextEditingController(text: widget.shop.name);
  late final _phone = TextEditingController(text: widget.shop.phone);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(shopRepositoryProvider)
          .updateShop(widget.shop.id, name: _name.text, phone: _phone.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Shop details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Shop name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone (optional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.dangerInk)),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: _busy ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
