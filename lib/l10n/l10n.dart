import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  /// The app's text in the language it is showing: `context.l10n.signIn`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Text picked for the language the app is showing.
typedef LocalizedText = String Function(AppLocalizations l);

/// An error a person can fix, thrown by the data and logic code. The text is
/// picked when it is shown (see friendlyError), so it follows the app's
/// language without that code needing a BuildContext.
abstract class AppException implements Exception {
  AppException(this.message);

  final LocalizedText message;

  /// English, for logs and Crashlytics.
  @override
  String toString() => message(lookupAppLocalizations(const Locale('en')));
}
