import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../l10n/l10n.dart';
import '../../models/shop.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/effects.dart';
import '../widgets/glass.dart';
import '../widgets/brand.dart';

/// Shown until the super admin sets an expiry date. It listens to the shop,
/// so it moves on by itself the moment that happens.
class PendingPage extends ConsumerWidget {
  const PendingPage({super.key, required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authRepositoryProvider);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const BrandHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
              child: BorderBeam(
                radius: AppRadius.xxl,
                child: Glass(
                  radius: AppRadius.xxl,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.hourglass_top,
                          size: 40, color: AppColors.inkMuted),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.shopWaitingForApproval(shop.name),
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.shopWaitingBody(appName) +
                            (supportContact.isEmpty
                                ? ''
                                : '\n\n${context.l10n.contactLine(supportContact)}'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.accountLine(shop.ownerEmail),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.inkSubtle),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: auth.signOut,
                        child: Text(context.l10n.signOut),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
