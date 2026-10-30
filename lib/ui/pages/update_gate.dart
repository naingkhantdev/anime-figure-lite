import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../logic/app_update.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Above everything else: a too-old app gets only "Please update"; one with
/// a newer build out gets a banner it can dismiss. See app_config/android.
class UpdateGate extends ConsumerWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(updateCheckProvider, (_, next) {
      final check = next.valueOrNull;
      if (check?.need == UpdateNeed.available) {
        _offer(context, check!.apkUrl);
      }
    });
    final check = ref.watch(updateCheckProvider).valueOrNull;
    if (check?.need == UpdateNeed.required) {
      return UpdateRequiredPage(apkUrl: check!.apkUrl);
    }
    return child;
  }

  void _offer(BuildContext context, String apkUrl) {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showMaterialBanner(MaterialBanner(
      leading: const Icon(Icons.system_update, color: AppColors.inkMuted),
      content: Text(l.updateAvailable),
      actions: [
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: Text(l.later),
        ),
        TextButton(
          onPressed: () {
            messenger.hideCurrentMaterialBanner();
            openApkUrl(apkUrl);
          },
          child: Text(l.updateNow),
        ),
      ],
    ));
  }
}

/// The browser downloads the APK; the person opens it and taps Install.
Future<bool> openApkUrl(String apkUrl) async {
  try {
    return await launchUrl(Uri.parse(apkUrl),
        mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// This build is older than app_config/android's min_version.
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key, required this.apkUrl});

  final String apkUrl;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.system_update,
          title: l.updateRequiredTitle,
          message: l.updateRequiredBody,
          action: FilledButton.icon(
            onPressed: () => openApkUrl(apkUrl),
            icon: const Icon(Icons.download),
            label: Text(l.downloadUpdate),
          ),
          // If no browser opens, the link can still be copied.
          secondary: SelectableText(apkUrl,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.inkSubtle)),
        ),
      ),
    );
  }
}
