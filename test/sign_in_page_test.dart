import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_figure_shop_lite/ui/pages/sign_in_page.dart';
import 'package:anime_figure_shop_lite/ui/theme.dart';

void main() {
  testWidgets('the eye icon shows and hides the password', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: buildAppTheme(), home: const SignInPage()),
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
}
