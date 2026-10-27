import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_figure_shop_lite/l10n/app_localizations.dart';
import 'package:anime_figure_shop_lite/ui/pages/sign_in_page.dart';
import 'package:anime_figure_shop_lite/ui/theme.dart';

Future<void> pumpSignIn(WidgetTester tester) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SignInPage(),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('the eye icon shows and hides the password', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SignInPage(),
      ),
    ));
    await tester.pump();

    TextField password() => tester.widget<TextField>(find.ancestor(
        of: find.text('Password'), matching: find.byType(TextField)));

    expect(password().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(password().obscureText, isFalse);
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(password().obscureText, isTrue);
  });

  testWidgets('the switch flips between signing in and signing up',
      (tester) async {
    await pumpSignIn(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('Create account').first);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('says what is missing before asking Firebase', (tester) async {
    await pumpSignIn(tester);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.text('Enter your email.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'me@example.com');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.text('Enter your password.'), findsOneWidget);
  });
}
