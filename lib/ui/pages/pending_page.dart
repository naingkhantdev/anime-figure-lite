import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
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
                        '${shop.name} is waiting for approval',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The owner of $appName will turn your shop on. This page '
                        'opens your shop by itself as soon as they do.'
                        '${supportContact.isEmpty ? '' : '\n\nContact: $supportContact'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Account: ${shop.ownerEmail}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.inkSubtle),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: auth.signOut,
                        child: const Text('Sign out'),
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
