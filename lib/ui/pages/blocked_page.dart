import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/effects.dart';
import '../widgets/glass.dart';
import '../widgets/brand.dart';

/// All a blocked account sees. The super admin's remark stays private; it
/// listens to the block, so unblocking opens the app by itself.
class BlockedPage extends ConsumerWidget {
  const BlockedPage({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authRepositoryProvider);
    final l = context.l10n;
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
                      const Icon(Icons.block,
                          size: 40, color: AppColors.dangerInk),
                      const SizedBox(height: 12),
                      Text(
                        l.accountBlocked,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.accountBlockedBody(appName) +
                            (supportContact.isEmpty
                                ? ''
                                : '\n\n${l.contactLine(supportContact)}'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.accountLine(email),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.inkSubtle),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: auth.signOut,
                        child: Text(l.signOut),
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
