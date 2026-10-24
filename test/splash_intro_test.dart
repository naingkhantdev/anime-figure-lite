import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_figure_shop_lite/providers/providers.dart';
import 'package:anime_figure_shop_lite/ui/widgets/splash_intro.dart';

/// Pumps the intro over a marker page. [auth] stands in for Firebase sign-in
/// state; leave it open to simulate a slow start.
Future<void> pumpIntro(
  WidgetTester tester, {
  required Stream<User?> auth,
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [authStateProvider.overrideWith((ref) => auth)],
    child: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: const MaterialApp(
        home: SplashIntro(child: Scaffold(body: Text('APP'))),
      ),
    ),
  ));
  // The logo decodes for real before the intro starts.
  await tester
      .runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
  await tester.pump();
}

/// The intro overlay is the only full-screen opaque tap target.
bool introShowing() => find
    .byWidgetPredicate(
        (w) => w is GestureDetector && w.behavior == HitTestBehavior.opaque)
    .evaluate()
    .isNotEmpty;

void main() {
  testWidgets('plays, then reveals the app once sign-in state is known',
      (tester) async {
    await pumpIntro(tester, auth: Stream.value(null));
    // The app is building underneath from the start.
    expect(find.text('APP'), findsOneWidget);
    expect(introShowing(), isTrue);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(introShowing(), isTrue, reason: 'still mid-intro');

    await tester.pump(const Duration(milliseconds: 1100)); // intro ends
    await tester.pump(const Duration(milliseconds: 600)); // fade out
    await tester.pump();
    expect(introShowing(), isFalse);
    expect(find.text('APP'), findsOneWidget);
  });

  testWidgets('a tap skips it', (tester) async {
    await pumpIntro(tester, auth: Stream.value(null));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(const Offset(200, 300));
    await tester.pump(); // the fade starts on this frame
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(introShowing(), isFalse);
  });

  testWidgets('waits for sign-in state, but never past the cap',
      (tester) async {
    final auth = StreamController<User?>();
    addTearDown(auth.close);
    await pumpIntro(tester, auth: auth.stream);

    await tester.pump(const Duration(milliseconds: 2500));
    expect(introShowing(), isTrue, reason: 'sign-in state not known yet');

    await tester.pump(const Duration(milliseconds: 1600)); // 4s cap
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(introShowing(), isFalse);
  });

  testWidgets('reduce motion: shows the finished frame, then leaves',
      (tester) async {
    await pumpIntro(tester, auth: Stream.value(null), reduceMotion: true);
    expect(introShowing(), isTrue);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(introShowing(), isFalse);
    expect(find.text('APP'), findsOneWidget);
  });
}
