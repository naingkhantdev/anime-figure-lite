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
/// order, then the logo itself.
const _posesFolder = 'assets/brand/poses/';

/// Plays once per launch over [child], which builds and loads underneath
/// the whole time. On the logo's dark navy, the fighter throws a quick
/// combo: each pose snaps in with a red flash and a jolt, then it lands on
/// the logo, which settles a little higher as the name fades in beneath.
/// With only the logo to show, it strikes twice in the same pose.
///
/// It leaves after the intro has played and sign-in state is known, or after
/// [_maxWait] whatever happens, or at once on a tap. With reduce motion on
/// nothing moves; it shows the finished frame briefly and fades.
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
    // Flutter's first frame already has the logo.
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
      for (final pose in {logoAsset, ..._combo.poses})
        precacheImage(AssetImage(pose), context),
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

/// The intro's timeline: a short hold on the logo (what the native splash
/// showed), one beat per pose, then the settle.
class _Combo {
  const _Combo(this.poses);

  /// Ends with the logo.
  final List<String> poses;

  static const _hold = 150;
  static const _settle = 600;

  /// With extra poses, one beat each; with the logo alone, two strikes.
  int get beats => poses.length > 1 ? poses.length : 2;

  /// Snappier the more poses there are, so the whole intro stays under
  /// about 1.9 s.
  int get beatMs => ((1900 - _hold - _settle) ~/ beats).clamp(120, 280);

  int get comboMs => _hold + beats * beatMs;

  Duration get length => Duration(milliseconds: comboMs + _settle);

  /// Where the combo is at [ms] into the intro: which pose shows, and how
  /// far through its beat (0 at the hit, 1 at its end; 1 outside beats).
  (String pose, double beat) at(int ms) {
    if (ms < _hold) return (poses.last, 1);
    final i = (ms - _hold) ~/ beatMs;
    if (i >= beats) return (poses.last, 1);
    final pose = poses.length > 1 ? poses[i] : poses.last;
    return (pose, ((ms - _hold) % beatMs) / beatMs);
  }
}

class _IntroFrame extends StatelessWidget {
  const _IntroFrame({required this.intro, required this.combo});

  final AnimationController intro;
  final _Combo combo;

  // Below the logo: a gap and the name. Fixed heights so the group's centre
  // is known, which is what lets the logo start at screen centre.
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
          final (pose, beat) = combo.at(ms);
          // After the combo: lift into place, then the name.
          final settle = ((ms - combo.comboMs) / _Combo._settle).clamp(0.0, 1.0);
          final lift = Curves.easeInOutCubic.transform(settle);
          final name =
              Curves.easeOutCubic.transform(((settle - 0.3) / 0.7).clamp(0, 1));

          // Each hit: a red flash that fades, a punch in size, and a jolt
          // sideways that dies away.
          final hit = 1 - beat;
          final flash = hit * hit;
          final punch = 1 + 0.09 * math.sin(math.pi * beat.clamp(0, 0.5) * 2);
          final jolt = math.sin(beat * math.pi * 5) * 6 * hit;

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  // Starts _below/2 lower: exactly the screen centre.
                  offset: Offset(jolt, (1 - lift) * _below / 2),
                  child: SizedBox.square(
                    dimension: splashLogoSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        if (flash > 0.01)
                          Transform.scale(
                            scale: 1.6 + 0.5 * beat,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [
                                  AppColors.splashNeon
                                      .withOpacity(0.75 * flash),
                                  AppColors.splashNeon.withOpacity(0),
                                ]),
                              ),
                              child: const SizedBox.square(
                                  dimension: splashLogoSize),
                            ),
                          ),
                        Transform.scale(
                          scale: punch,
                          child: Image.asset(
                            pose,
                            width: splashLogoSize,
                            height: splashLogoSize,
                            gaplessPlayback: true,
                            excludeFromSemantics: true,
                          ),
                        ),
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
