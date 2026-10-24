import 'dart:async';

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

/// Plays once per launch over [child], which builds and loads underneath
/// the whole time. Quiet on purpose: the logo settles a little higher, the
/// name fades in beneath it, then everything fades into the app.
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

const _introLength = Duration(milliseconds: 1400);
const _exitLength = Duration(milliseconds: 450);
const _maxWait = Duration(seconds: 4);

class _SplashIntroState extends ConsumerState<SplashIntro>
    with TickerProviderStateMixin {
  late final _intro = AnimationController(vsync: this, duration: _introLength);
  late final _exit = AnimationController(vsync: this, duration: _exitLength);
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
    precacheImage(const AssetImage(logoAsset), context).whenComplete(() {
      _releaseFirstFrame();
      if (!mounted) return;
      if (reduceMotion) {
        _intro.value = 1;
        Future.delayed(const Duration(milliseconds: 700), _onIntroDone);
      } else {
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
              value: SystemUiOverlayStyle.dark,
              child: Semantics(
                label: appName,
                child: _IntroFrame(intro: _intro),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroFrame extends StatelessWidget {
  const _IntroFrame({required this.intro});

  final Animation<double> intro;

  // Below the logo: a gap and the name. Fixed heights so the group's centre
  // is known, which is what lets the logo start at screen centre.
  static const _gap = 28.0;
  static const _nameHeight = 20.0;
  static const _below = _gap + _nameHeight;

  @override
  Widget build(BuildContext context) {
    final lift = CurvedAnimation(
        parent: intro,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOutCubic));
    final name = CurvedAnimation(
        parent: intro,
        curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic));

    return Material(
      // Material, not a bare colour: text outside one gets Flutter's yellow
      // "missing Material" underline.
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: lift,
              builder: (context, child) => Transform.translate(
                // Starts _below/2 lower: exactly the screen centre.
                offset: Offset(0, (1 - lift.value) * _below / 2),
                child: child,
              ),
              child: Image.asset(
                logoAsset,
                width: splashLogoSize,
                height: splashLogoSize,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(height: _gap),
            SizedBox(
              height: _nameHeight,
              child: AnimatedBuilder(
                animation: name,
                builder: (context, child) => Opacity(
                  opacity: name.value,
                  child: Transform.translate(
                    offset: Offset(0, 6 * (1 - name.value)),
                    child: child,
                  ),
                ),
                child: const Wordmark(size: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
