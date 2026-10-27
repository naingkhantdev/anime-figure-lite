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
      // Rebuild with the poses: on a phone the intro has usually been
      // built already, with the logo alone.
      setState(() => _intro.duration = _combo.length);
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
        // On the way out it grows a little as it fades, as if the app
        // came forward through it.
        FadeTransition(
          opacity: ReverseAnimation(reveal),
          child: ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.08).animate(reveal),
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
  /// about 2.3 s.
  int get strikeMs => ((2300 - _hold - _settle) ~/ strikes).clamp(160, 380);

  int get comboMs => _hold + strikes * strikeMs;

  Duration get length => Duration(milliseconds: comboMs + _settle);

  /// Where the combo is at [ms] into the intro: the pose striking, the one
  /// before it (which it blends out of), and how far through its strike
  /// (null outside strikes).
  (String pose, String before, double? strike) at(int ms) {
    final last = poses.last;
    if (ms < _hold) return (last, last, null);
    final i = (ms - _hold) ~/ strikeMs;
    if (i >= strikes) return (last, last, null);
    final single = poses.length == 1;
    return (
      single ? last : poses[i],
      single || i == 0 ? last : poses[i - 1],
      ((ms - _hold) % strikeMs) / strikeMs,
    );
  }
}

/// How long a new pose takes to blend in, as a share of its strike.
const _blend = 0.2;

/// The fighter's place in one strike, [u] from 0 to 1: a wind-up back, a
/// dash forward, then a recovery to the middle. [impact] is how far past
/// the hit it is, null before it.
({double x, double scale, double turn, double? impact}) _strike(double u) {
  double lerp(double a, double b, double t) => a + (b - a) * t;
  const windUp = 0.22, hit = 0.42;
  if (u < windUp) {
    final w = Curves.easeInOutSine.transform(u / windUp);
    return (x: -14 * w, scale: 1 - 0.05 * w, turn: -0.045 * w, impact: null);
  }
  if (u < hit) {
    final d = Curves.easeInCubic.transform((u - windUp) / (hit - windUp));
    return (
      x: lerp(-14, 28, d),
      scale: lerp(0.95, 1.14, d),
      turn: lerp(-0.045, 0.035, d),
      impact: null,
    );
  }
  final p = (u - hit) / (1 - hit);
  final r = Curves.easeOutQuart.transform(p);
  return (
    x: lerp(28, 0, r),
    scale: lerp(1.14, 1, r),
    turn: lerp(0.035, 0, r),
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
          final ms = intro.value * total;
          final (pose, before, strike) = combo.at(ms.round());

          // After the combo: lift into place with a soft bounce, then the
          // name.
          final settle =
              ((ms - combo.comboMs) / _Combo._settle).clamp(0.0, 1.0);
          final lift = Curves.easeInOutCubic.transform(settle);
          final land = math.sin(math.pi * Curves.easeOut.transform(settle));
          final name = Curves.easeOutCubic
              .transform(((settle - 0.3) / 0.7).clamp(0.0, 1.0));

          final at = strike == null ? null : _strike(strike);
          final impact = at?.impact;
          // Strong at the hit, gone by the end of the strike.
          final hit = impact == null ? 0.0 : math.pow(1 - impact, 2.2) * 1.0;
          // A brief, low shake that dies away smoothly.
          final shake = impact == null
              ? 0.0
              : math.sin(impact * math.pi * 6) * 3 * math.pow(1 - impact, 2);
          // After-images and speed lines: the dash and just after the hit.
          final trail = strike == null || strike < 0.2 || strike > 0.62
              ? 0.0
              : math.sin(math.pi * (strike - 0.2) / 0.42);
          // The new pose blends in over the start of its strike.
          final blend = strike == null
              ? 1.0
              : Curves.easeOut.transform((strike / _blend).clamp(0.0, 1.0));

          Widget fighter(String image, double opacity, {double lag = 0}) {
            final p =
                strike == null ? null : _strike((strike - lag).clamp(0.0, 1.0));
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(p?.x ?? 0, 0),
                child: Transform.rotate(
                  angle: p?.turn ?? 0,
                  child: Transform.scale(
                    scale: (p?.scale ?? 1) * (1 + 0.04 * land),
                    child: Image.asset(
                      image,
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

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _Atmosphere(
                  ms: ms,
                  hit: hit,
                  landing: land,
                  trail: trail,
                  dashX: at?.x ?? 0,
                  impact: impact,
                  lift: (1 - lift) * _below / 2 - _below / 2,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      // Starts _below/2 lower: exactly the screen centre.
                      offset:
                          Offset(shake, (1 - lift) * _below / 2 + shake / 2),
                      child: SizedBox.square(
                        dimension: splashLogoSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            if (trail > 0.01) ...[
                              fighter(pose, 0.1 * trail, lag: 0.16),
                              fighter(pose, 0.18 * trail, lag: 0.11),
                              fighter(pose, 0.3 * trail, lag: 0.06),
                            ],
                            if (blend < 1) fighter(before, 1 - blend),
                            fighter(pose, blend),
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
                          child: const Wordmark(
                              size: 13, color: Colors.white, shine: true),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Everything around the fighter, in one paint: red embers drifting up the
/// screen, a glow on the ground under him, and on each strike speed lines,
/// a flash of red light, a shockwave ring and a burst of sparks.
class _Atmosphere extends CustomPainter {
  _Atmosphere({
    required this.ms,
    required this.hit,
    required this.landing,
    required this.trail,
    required this.dashX,
    required this.impact,
    required this.lift,
  });

  final double ms;

  /// 1 at a hit, fading to 0.
  final double hit;

  /// 0 to 1 and back as the fighter lands at the end.
  final double landing;

  /// How strong the speed lines are.
  final double trail;

  /// The fighter's sideways place in the dash.
  final double dashX;

  /// How far past the latest hit it is, null before one.
  final double? impact;

  /// How far above the screen centre the fighter is drawn.
  final double lift;

  static const _embers = 26;
  static final _seeds = List.generate(_embers * 4, (i) {
    // A fixed, even scatter, the same on every frame and every launch.
    final x = math.sin(i * 12.9898 + 78.233) * 43758.5453;
    return x - x.floorToDouble();
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset(0, lift));
    const neon = AppColors.splashNeon;
    final fadeIn = (ms / 300).clamp(0.0, 1.0);

    // Embers: each rises at its own pace, sways, and flickers.
    final ember = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (var i = 0; i < _embers; i++) {
      final sx = _seeds[i * 4], speed = _seeds[i * 4 + 1];
      final r = 0.8 + _seeds[i * 4 + 2] * 1.8, phase = _seeds[i * 4 + 3];
      final travel = (phase + ms / 1000 * (0.12 + speed * 0.22)) % 1.0;
      final y = size.height * (1.05 - travel * 1.1);
      final x = size.width * sx + math.sin(travel * 6 + i) * 10;
      final flicker = 0.5 + 0.5 * math.sin(ms / 140 + i * 1.7);
      final edgeFade = math.sin(math.pi * travel);
      ember.color =
          neon.withOpacity(0.55 * fadeIn * edgeFade * (0.4 + 0.6 * flicker));
      canvas.drawCircle(Offset(x, y), r, ember);
    }

    // Ground glow under the fighter, brighter on each hit and the landing.
    final ground = centre + const Offset(0, splashLogoSize * 0.46);
    final glowStrength = 0.22 + 0.35 * hit + 0.25 * landing;
    canvas.drawOval(
      Rect.fromCenter(
          center: ground,
          width: splashLogoSize * (1.1 + 0.3 * hit),
          height: splashLogoSize * 0.18),
      Paint()
        ..shader = RadialGradient(colors: [
          neon.withOpacity(glowStrength.clamp(0.0, 1.0)),
          neon.withOpacity(0),
        ]).createShader(Rect.fromCenter(
            center: ground,
            width: splashLogoSize * 1.4,
            height: splashLogoSize * 0.3))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // The flash of a hit, and the soft pulse of the landing.
    final flash = math.max(hit, 0.6 * landing);
    if (flash > 0.01) {
      final radius = splashLogoSize * (0.8 + 0.5 * (impact ?? 0.5));
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [
            neon.withOpacity(0.7 * flash),
            neon.withOpacity(0),
          ]).createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
    }

    // Speed lines streaming behind the dash.
    if (trail > 0.01) {
      final line = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2;
      for (var i = 0; i < 7; i++) {
        final dy = (i - 3) * splashLogoSize * 0.11 + _seeds[i] * 8;
        final length = splashLogoSize * (0.35 + 0.45 * _seeds[i + 7]) * trail;
        final start = centre + Offset(dashX - splashLogoSize * 0.42, dy);
        line.shader = LinearGradient(colors: [
          neon.withOpacity(0),
          neon.withOpacity(0.7 * trail),
        ]).createShader(Rect.fromPoints(start - Offset(length, 0), start));
        canvas.drawLine(start - Offset(length, 0), start, line);
      }
    }

    final p = impact;
    if (p != null && p < 1) {
      // Shockwave: a thin ring racing out and thinning.
      final grow = Curves.easeOutCubic.transform(p);
      canvas.drawCircle(
        centre,
        splashLogoSize * (0.3 + 0.9 * grow),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - p) + 0.5
          ..color = neon.withOpacity(0.85 * (1 - p)),
      );

      // Sparks: short streaks flying out from the hit, fading as they go.
      if (p < 0.6) {
        final s = p / 0.6;
        final spark = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3.2 * (1 - s) + 1
          ..color =
              Color.lerp(Colors.white, neon, s)!.withOpacity(0.95 * (1 - s));
        final from = centre + const Offset(splashLogoSize * 0.2, -4);
        for (var i = 0; i < 12; i++) {
          final angle = i / 12 * 2 * math.pi + _seeds[i + 20] * 0.4;
          final reach = splashLogoSize * (0.35 + 0.45 * _seeds[i + 40]);
          final dir = Offset(math.cos(angle), math.sin(angle));
          final head = from + dir * (reach * Curves.easeOutCubic.transform(s));
          canvas.drawLine(head - dir * (24 * (1 - s) + 6), head, spark);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_Atmosphere old) => true;
}
