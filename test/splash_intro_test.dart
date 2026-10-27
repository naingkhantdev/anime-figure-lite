import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// The app's assets, with the asset list arriving a moment late.
class _SlowManifestBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('AssetManifest')) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return rootBundle.load(key);
  }
}

/// The pose images the intro is drawing right now.
Set<String> posesShown() => find
    .byType(Image)
    .evaluate()
    .map((e) => (e.widget as Image).image)
    .whereType<AssetImage>()
    .map((i) => i.assetName)
    .toSet();

void main() {
  testWidgets('the combo plays every pose, not just the logo',
      (tester) async {
    // On a phone the intro is built before the list of poses has loaded;
    // a slow bundle makes that happen here too.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => const Stream.empty())
      ],
      child: MaterialApp(
        home: DefaultAssetBundle(
          bundle: _SlowManifestBundle(),
          child: const SplashIntro(child: Scaffold(body: Text('APP'))),
        ),
      ),
    ));
    await tester.pump();
    // The list arrives (test time), then the poses decode (real time).
    await tester.pump(const Duration(milliseconds: 200));
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
    final seen = <String>{};
    for (var ms = 0; ms < 2300; ms += 40) {
      await tester.pump(const Duration(milliseconds: 40));
      seen.addAll(posesShown());
    }
    expect(seen, containsAll(<String>[
      'assets/brand/poses/00.png',
      'assets/brand/poses/01.png',
      'assets/brand/poses/02.png',
      'assets/brand/poses/03.png',
      'assets/brand/poses/04.png',
    ]));
  });

  testWidgets('plays, then reveals the app once sign-in state is known',
      (tester) async {
    await pumpIntro(tester, auth: Stream.value(null));
    // The app is building underneath from the start.
    expect(find.text('APP'), findsOneWidget);
    expect(introShowing(), isTrue);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(introShowing(), isTrue, reason: 'still mid-intro');

    await tester.pump(const Duration(milliseconds: 1400)); // intro ends
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
