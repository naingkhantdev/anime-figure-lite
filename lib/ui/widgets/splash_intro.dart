import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../providers/providers.dart';
import '../theme.dart';

/// Size of the logo on the native splash (android/.../launch_background.xml,
/// splash_icon.xml, and iOS LaunchScreen.storyboard). The intro's first
/// frame draws it at exactly this size and place, so the hand-over from the
/// native splash can't be seen.
const splashLogoSize = 144.0;

const _logoAsset = 'assets/brand/app_icon_foreground.png';

/// Plays once per launch over [child], which builds and loads underneath
/// the whole time. The logo rises, a glow and a few sakura petals come in,
/// the name appears letter by letter, the gold rule draws out, then it all
/// fades into the app.
///
/// It leaves after the intro has played and sign-in state is known, or after
/// [_maxWait] whatever happens, or at once on a tap. With reduce motion on it
/// shows the finished frame briefly and fades, with nothing moving.
class SplashIntro extends ConsumerStatefulWidget {
  const SplashIntro({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SplashIntro> createState() => _SplashIntroState();
}

const _introLength = Duration(milliseconds: 2000);
const _exitLength = Duration(milliseconds: 550);
const _maxWait = Duration(seconds: 4);

class _SplashIntroState extends ConsumerState<SplashIntro>
    with TickerProviderStateMixin {
  late final _intro = AnimationController(vsync: this, duration: _introLength);
  late final _exit = AnimationController(vsync: this, duration: _exitLength);
  late final _petals =
      AnimationController(vsync: this, duration: const Duration(seconds: 12));
  Timer? _cap;
  bool _started = false;
  bool _firstFrameHeld = false;
  bool _introDone = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    // Keep the native splash up until the logo is decoded (see below), so
    // Flutter's first frame already has it.
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
    // Decode the logo before the first frame that shows it, so it is never
    // missing for a frame after the native splash goes.
    precacheImage(const AssetImage(_logoAsset), context).whenComplete(() {
      _releaseFirstFrame();
      if (!mounted) return;
      if (reduceMotion) {
        _intro.value = 1;
        Future.delayed(const Duration(milliseconds: 700), _onIntroDone);
      } else {
        _petals.repeat();
        _intro.forward().whenComplete(_onIntroDone);
      }
    });
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
      if (!mounted) return;
      _petals.stop();
      setState(() => _gone = true);
    });
  }

  @override
  void dispose() {
    _releaseFirstFrame();
    _cap?.cancel();
    _intro.dispose();
    _exit.dispose();
    _petals.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sign-in state may arrive after the intro; leave as soon as it does.
    ref.listen(authStateProvider, (_, __) => _maybeLeave());

    if (_gone) return widget.child;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final reveal = CurvedAnimation(parent: _exit, curve: Curves.easeOutCubic);
    return Stack(
      fit: StackFit.expand,
      children: [
        // The app settles in from very slightly smaller as the splash lifts.
        AnimatedBuilder(
          animation: reveal,
          builder: (context, child) => Transform.scale(
            scale: reduceMotion ? 1 : 0.985 + 0.015 * reveal.value,
            child: child,
          ),
          child: widget.child,
        ),
        FadeTransition(
          opacity: ReverseAnimation(reveal),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _leave,
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: Semantics(
                label: appName,
                child: _IntroFrame(
                  intro: _intro,
                  exit: reveal,
                  petals: _petals,
                  reduceMotion: reduceMotion,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroFrame extends StatelessWidget {
  const _IntroFrame({
    required this.intro,
    required this.exit,
    required this.petals,
    required this.reduceMotion,
  });

  final Animation<double> intro;
  final Animation<double> exit;
  final Animation<double> petals;
  final bool reduceMotion;

  // Below the logo: gap, wordmark, gap, rule. Fixed heights so the group's
  // centre is known, which is what lets the logo start at screen centre.
  static const _gap1 = 28.0;
  static const _wordmarkHeight = 36.0;
  static const _gap2 = 16.0;
  static const _below = _gap1 + _wordmarkHeight + _gap2 + 1;

  @override
  Widget build(BuildContext context) {
    Animation<double> part(double begin, double end,
            [Curve curve = Curves.easeOutCubic]) =>
        CurvedAnimation(
            parent: intro, curve: Interval(begin, end, curve: curve));

    final glow = part(0.0, 0.45);
    final lift = part(0.10, 0.55, Curves.easeInOutCubic);
    final rule = part(0.62, 0.86, Curves.easeInOutCubic);
    final petalsIn = part(0.15, 0.6);

    // Material, not a bare colour: text outside one gets Flutter's yellow
    // "missing Material" underline.
    return Material(
      color: AppColors.brand950,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A soft pool of lighter navy behind the logo, for depth.
          FadeTransition(
            opacity: glow,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.75,
                  colors: [Color(0xFF243656), AppColors.brand950],
                ),
              ),
            ),
          ),
          if (!reduceMotion)
            FadeTransition(
              opacity: petalsIn,
              child: RepaintBoundary(
                child: CustomPaint(painter: _PetalPainter(petals)),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([lift, exit]),
                  builder: (context, child) => Transform.translate(
                    // Starts _below/2 lower: exactly the screen centre.
                    offset: Offset(0, (1 - lift.value) * _below / 2),
                    child: Transform.scale(
                      scale: (1 - 0.04 * lift.value) + 0.06 * exit.value,
                      child: child,
                    ),
                  ),
                  child: Image.asset(
                    _logoAsset,
                    width: splashLogoSize,
                    height: splashLogoSize,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(height: _gap1),
                SizedBox(
                  height: _wordmarkHeight,
                  child: _LetterReveal(intro: intro),
                ),
                const SizedBox(height: _gap2),
                AnimatedBuilder(
                  animation: rule,
                  builder: (context, _) => Container(
                    width: 72 * rule.value,
                    height: 1,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The name in the display serif. Each letter fades up a few pixels in turn
/// while the tracking closes in slightly.
class _LetterReveal extends StatelessWidget {
  const _LetterReveal({required this.intro});

  final Animation<double> intro;

  static const _start = 0.30;
  static const _spread = 0.30;
  static const _each = 0.22;

  @override
  Widget build(BuildContext context) {
    final letters = appName.toUpperCase().characters.toList();
    final step = letters.length < 2 ? 0.0 : _spread / (letters.length - 1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: AnimatedBuilder(
          animation: intro,
          builder: (context, _) {
            final spacingT = Curves.easeOutCubic.transform(
                ((intro.value - _start) / (_spread + _each)).clamp(0.0, 1.0));
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, letter) in letters.indexed)
                  _letter(letter, i * step, spacingT,
                      // No tracking after the last letter: keeps it centred.
                      last: i == letters.length - 1),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _letter(String letter, double offset, double spacingT,
      {required bool last}) {
    final t = Curves.easeOutCubic
        .transform(((intro.value - _start - offset) / _each).clamp(0.0, 1.0));
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - t)),
        child: Text(
          letter,
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w600,
            fontSize: 24,
            height: 1.1,
            // From airy to the wordmark's own tracking.
            letterSpacing: last ? 0 : 24 * (0.22 - 0.08 * spacingT),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// A few sakura petals and gold flecks drifting down, from the logo's own
/// palette. Deterministic, so every launch looks the same.
class _PetalPainter extends CustomPainter {
  _PetalPainter(this.time) : super(repaint: time);

  final Animation<double> time;

  static final _petals = () {
    final r = math.Random(7);
    return List.generate(11, (i) {
      return (
        x: r.nextDouble(),
        phase: r.nextDouble(),
        // Screen heights per 12s loop: slow, unhurried.
        speed: 0.9 + r.nextDouble() * 0.7,
        sway: 10 + r.nextDouble() * 22,
        size: 5 + r.nextDouble() * 6,
        spin: (r.nextDouble() - 0.5) * 4,
        gold: i % 4 == 0,
      );
    });
  }();

  static const _pink = Color(0xFFF0C4CC);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    for (final p in _petals) {
      final progress = (t * p.speed + p.phase) % 1.0;
      final y = -20 + progress * (size.height + 40);
      final x = p.x * size.width +
          math.sin((progress * 2 + p.phase) * math.pi * 2) * p.sway;
      // Fade in at the top, out near the bottom.
      final edge = math.min(progress / 0.12, (1 - progress) / 0.2);
      final alpha = (p.gold ? 0.55 : 0.45) * edge.clamp(0.0, 1.0);
      final paint = Paint()
        ..color = (p.gold ? AppColors.gold : _pink).withOpacity(alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.spin * math.pi * 2);
      final s = p.size;
      final petal = Path()
        ..moveTo(0, -s)
        ..quadraticBezierTo(s * 0.95, -s * 0.15, 0, s)
        ..quadraticBezierTo(-s * 0.95, -s * 0.15, 0, -s)
        ..close();
      canvas.drawPath(petal, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PetalPainter old) => false;
}
