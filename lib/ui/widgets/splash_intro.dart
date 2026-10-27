import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import 'brand.dart';

/// Size of the logo on the native splash (android/.../launch_background.xml,
/// splash_icon.xml, and iOS LaunchScreen.storyboard). The intro's first
/// frame draws it at exactly this size and place, so the hand-over from the
/// native splash can't be seen.
const splashLogoSize = 144.0;

/// The fighter's poses, built by tool/brand_assets.py: any extra poses in
/// order, then the logo's own.
const _posesFolder = 'assets/brand/poses/';

/// Plays once per launch over [child], which builds and loads underneath
/// the whole time. On the logo's dark navy, the fighter throws a quick
/// combo: each strike winds up, dashes forward trailing after-images and
/// lands with a red flash, a shockwave and a shake; each extra pose gets
/// its own strike. Then it settles a little higher as the name fades in
/// beneath. With only the logo's pose, it strikes three times in it.
///
/// It leaves after the intro has played and sign-in state is known, or after
/// [_maxWait] whatever happens, or at once on a tap. With reduce motion on
/// (Android: "Remove animations", or animator duration scale off) nothing
/// moves; it shows the finished frame briefly and fades.
class SplashIntro extends ConsumerStatefulWidget {
  const SplashIntro({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SplashIntro> createState() => _SplashIntroState();
}

const _exitLength = Duration(milliseconds: 450);
const _maxWait = Duration(seconds: 4);

class _SplashIntroState extends ConsumerState<SplashIntro>
    with TickerProviderStateMixin {
  late final _intro = AnimationController(vsync: this);
  late final _exit = AnimationController(vsync: this, duration: _exitLength);
  _Combo _combo = const _Combo([logoAsset]);
  Timer? _cap;
  bool _started = false;
  bool _firstFrameHeld = false;
  bool _introDone = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    // Keep the native splash up until the poses are decoded (see below), so
    // Flutter's first frame already has the fighter.
    WidgetsBinding.instance.deferFirstFrame();
    _firstFrameHeld = true;
  }

  void _releaseFirstFrame() {
    if (!_firstFrameHeld) return;
    _firstFrameHeld = false;
    WidgetsBinding.instance.allowFirstFrame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _cap = Timer(_maxWait, _leave);
    _loadPoses().whenComplete(() {
      _releaseFirstFrame();
      if (!mounted) return;
      _intro.duration = _combo.length;
      if (reduceMotion) {
        _intro.value = 1;
        Future.delayed(const Duration(milliseconds: 700), _onIntroDone);
      } else {
        _intro.forward().whenComplete(_onIntroDone);
      }
    });
  }

  /// Finds the pose images in the bundle and decodes them all, so no pose
  /// arrives late in the combo. Falls back to the logo alone.
  Future<void> _loadPoses() async {
    final bundle = DefaultAssetBundle.of(context);
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      final poses = manifest
          .listAssets()
          .where((a) => a.startsWith(_posesFolder) && a.endsWith('.png'))
          .toList()
        ..sort();
      if (poses.isNotEmpty) _combo = _Combo(poses);
    } catch (_) {
      // No manifest: play with the logo alone.
    }
    if (!mounted) return;
    await Future.wait([
      for (final pose in _combo.poses) precacheImage(AssetImage(pose), context),
    ]);
  }

  void _onIntroDone() {
    if (!mounted) return;
    _introDone = true;
    _maybeLeave();
  }

  void _maybeLeave() {
    if (_introDone && ref.read(authStateProvider).hasValue) _leave();
  }

  void _leave() {
    if (!mounted || _exit.isAnimating || _exit.isCompleted) return;
    _cap?.cancel();
    if (MediaQuery.disableAnimationsOf(context)) {
      _exit.duration = const Duration(milliseconds: 250);
    }
    _exit.forward().whenComplete(() {
      if (mounted) setState(() => _gone = true);
    });
  }

  @override
  void dispose() {
    _releaseFirstFrame();
    _cap?.cancel();
    _intro.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sign-in state may arrive after the intro; leave as soon as it does.
    ref.listen(authStateProvider, (_, __) => _maybeLeave());

    if (_gone) return widget.child;

    final reveal = CurvedAnimation(parent: _exit, curve: Curves.easeOutCubic);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        FadeTransition(
          opacity: ReverseAnimation(reveal),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _leave,
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: Semantics(
                label: appName,
                child: _IntroFrame(intro: _intro, combo: _combo),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The intro's timeline: a short hold on the logo's pose (what the native
/// splash showed), one strike per pose, then the settle.
class _Combo {
  const _Combo(this.poses);

  /// Ends with the logo's pose.
  final List<String> poses;

  static const _hold = 150;
  static const _settle = 600;

  /// With extra poses, one strike each; with the logo's pose alone, three.
  int get strikes => poses.length > 1 ? poses.length : 3;

  /// Snappier the more poses there are, so the whole intro stays under
  /// about 1.9 s.
  int get strikeMs => ((1900 - _hold - _settle) ~/ strikes).clamp(160, 380);

  int get comboMs => _hold + strikes * strikeMs;

  Duration get length => Duration(milliseconds: comboMs + _settle);

  /// Where the combo is at [ms] into the intro: which pose shows, and how
  /// far through its strike (null outside strikes).
  (String pose, double? strike) at(int ms) {
    if (ms < _hold) return (poses.last, null);
    final i = (ms - _hold) ~/ strikeMs;
    if (i >= strikes) return (poses.last, null);
    return (
      poses.length == 1 ? poses.last : poses[i],
      ((ms - _hold) % strikeMs) / strikeMs,
    );
  }
}

/// The fighter's place in one strike, [u] from 0 to 1: a wind-up back, a
/// dash forward, then a recovery to the middle. [impact] is how far past
/// the hit it is, null before it.
({double x, double scale, double turn, double? impact}) _strike(double u) {
  double lerp(double a, double b, double t) => a + (b - a) * t;
  const windUp = 0.22, hit = 0.42;
  if (u < windUp) {
    final w = Curves.easeOut.transform(u / windUp);
    return (x: -16 * w, scale: 1 - 0.06 * w, turn: -0.05 * w, impact: null);
  }
  if (u < hit) {
    final d = Curves.easeIn.transform((u - windUp) / (hit - windUp));
    return (
      x: lerp(-16, 30, d),
      scale: lerp(0.94, 1.16, d),
      turn: lerp(-0.05, 0.04, d),
      impact: null,
    );
  }
  final p = (u - hit) / (1 - hit);
  final r = Curves.easeOutCubic.transform(p);
  return (
    x: lerp(30, 0, r),
    scale: lerp(1.16, 1, r),
    turn: lerp(0.04, 0, r),
    impact: p,
  );
}

class _IntroFrame extends StatelessWidget {
  const _IntroFrame({required this.intro, required this.combo});

  final AnimationController intro;
  final _Combo combo;

  // Below the fighter: a gap and the name. Fixed heights so the group's
  // centre is known, which is what lets the fighter start at screen centre.
  static const _gap = 28.0;
  static const _nameHeight = 20.0;
  static const _below = _gap + _nameHeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      // Material, not a bare colour: text outside one gets Flutter's yellow
      // "missing Material" underline.
      color: AppColors.splash,
      child: AnimatedBuilder(
        animation: intro,
        builder: (context, _) {
          final total = intro.duration?.inMilliseconds ?? 1;
          final ms = (intro.value * total).round();
          final (pose, strike) = combo.at(ms);
          // After the combo: lift into place, then the name.
          final settle =
              ((ms - combo.comboMs) / _Combo._settle).clamp(0.0, 1.0);
          final lift = Curves.easeInOutCubic.transform(settle);
          final name = Curves.easeOutCubic
              .transform(((settle - 0.3) / 0.7).clamp(0.0, 1.0));

          final impact = strike == null ? null : _strike(strike).impact;
          final flash = impact == null ? 0.0 : (1 - impact) * (1 - impact);
          // The whole picture shakes for a moment on each hit.
          final shake = impact == null
              ? 0.0
              : math.sin(impact * math.pi * 9) * 4 * (1 - impact);
          // After-images trail the dash and fade soon after the hit.
          final trail = strike == null || strike < 0.2 || strike > 0.62
              ? 0.0
              : 1 - ((strike - 0.2) / 0.42 - 0.5).abs() * 2;

          Widget fighter(double opacity, {double lag = 0}) {
            final at =
                strike == null ? null : _strike((strike - lag).clamp(0.0, 1.0));
            final scale = at?.scale ?? 1;
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(at?.x ?? 0, 0),
                child: Transform.rotate(
                  angle: at?.turn ?? 0,
                  child: Transform.scale(
                    scale: scale,
                    child: Image.asset(
                      pose,
                      width: splashLogoSize,
                      height: splashLogoSize,
                      gaplessPlayback: true,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  // Starts _below/2 lower: exactly the screen centre.
                  offset: Offset(shake, (1 - lift) * _below / 2 + shake / 2),
                  child: SizedBox.square(
                    dimension: splashLogoSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        if (flash > 0.01)
                          _Glow(strength: flash, spread: impact!),
                        if (impact != null && impact < 1)
                          _Shockwave(progress: impact),
                        if (trail > 0.01) ...[
                          fighter(0.12 * trail, lag: 0.15),
                          fighter(0.22 * trail, lag: 0.1),
                          fighter(0.35 * trail, lag: 0.05),
                        ],
                        fighter(1),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: _gap),
                SizedBox(
                  height: _nameHeight,
                  child: Opacity(
                    opacity: name,
                    child: Transform.translate(
                      offset: Offset(0, 6 * (1 - name)),
                      child: const Wordmark(size: 13, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The red light thrown off by a hit, fading as it spreads.
class _Glow extends StatelessWidget {
  const _Glow({required this.strength, required this.spread});

  final double strength;
  final double spread;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.5 + 0.7 * spread,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            AppColors.splashNeon.withOpacity(0.8 * strength),
            AppColors.splashNeon.withOpacity(0),
          ]),
        ),
        child: const SizedBox.square(dimension: splashLogoSize),
      ),
    );
  }
}

/// A thin ring of neon racing outwards from a hit.
class _Shockwave extends StatelessWidget {
  const _Shockwave({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final grow = Curves.easeOutCubic.transform(progress);
    return Transform.scale(
      scale: 0.6 + 1.6 * grow,
      child: Container(
        width: splashLogoSize,
        height: splashLogoSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.splashNeon.withOpacity(0.9 * (1 - progress)),
            width: 3 * (1 - progress) + 0.5,
          ),
        ),
      ),
    );
  }
}
