import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/providers.dart';
import '../theme.dart';

/// The languages the app has (lib/l10n), each named in itself so anyone
/// can find their own.
const _languages = [
  (Locale('en'), 'English'),
  (Locale('my'), 'မြန်မာ'),
];

String _nameOf(BuildContext context, Locale? picked) {
  if (picked == null) return context.l10n.languagePhone;
  for (final (locale, name) in _languages) {
    if (locale.languageCode == picked.languageCode) return name;
  }
  return picked.languageCode;
}

/// Picks the app's language in a bottom sheet: the phone's, or one of
/// [_languages]. The choice is kept on the phone.
Future<void> showLanguageSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const _LanguageSheet(),
    );

/// "Language" with the current choice under it, for an Account or Shop
/// page.
class LanguageTile extends ConsumerWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: const Icon(Icons.translate),
        title: Text(context.l10n.language),
        subtitle: Text(_nameOf(context, ref.watch(localeProvider))),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showLanguageSheet(context),
      ),
    );
  }
}

/// The same choice from a top bar.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.language,
      icon: const Icon(Icons.translate),
      onPressed: () => showLanguageSheet(context),
    );
  }
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picked = ref.watch(localeProvider);
    Widget option(Locale? locale, String name) {
      final on = picked?.languageCode == locale?.languageCode;
      return ListTile(
        title: Text(name,
            style: TextStyle(
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                color: on ? AppColors.accent : AppColors.ink)),
        trailing: on
            ? const Icon(Icons.check_rounded, color: AppColors.accent)
            : null,
        selected: on,
        onTap: () {
          ref.read(localeProvider.notifier).pick(locale);
          Navigator.pop(context);
        },
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(context.l10n.language,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            option(null, context.l10n.languagePhone),
            for (final (locale, name) in _languages) option(locale, name),
          ],
        ),
      ),
    );
  }
}
