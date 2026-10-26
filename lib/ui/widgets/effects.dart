import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../theme.dart';

/// [text] in solid ink with a pink glint that sweeps across it now and
/// then: once shortly after it appears, then every [every]. Still with
/// reduce motion on.
class ShineText extends StatefulWidget {
  const ShineText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.every = const Duration(seconds: 7),
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final Duration every;

  @override
  State<ShineText> createState() => _ShineTextState();
}

class _ShineTextState extends State<ShineText>
    with SingleTickerProviderStateMixin {
  late final _sweep = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));
  Timer? _first;
  Timer? _again;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _stop();
    } else if (_again == null) {
      _first = Timer(const Duration(milliseconds: 700), _play);
      _again = Timer.periodic(widget.every, (_) => _play());
    }
  }

  void _play() {
    if (mounted && !_sweep.isAnimating) _sweep.forward(from: 0);
  }

  void _stop() {
    _first?.cancel();
    _again?.cancel();
    _first = _again = null;
    _sweep.value = 0;
  }

  @override
  void dispose() {
    _stop();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.style.color ?? AppColors.ink;
    final text = Text(widget.text,
        textAlign: widget.textAlign,
        style: widget.style.copyWith(color: Colors.white));
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (context, child) {
          // Idle: plain ink, no shader at all.
          if (_sweep.value == 0 || _sweep.isCompleted) {
            return Text(widget.text,
                textAlign: widget.textAlign, style: widget.style);
          }
          final t = Curves.easeInOutCubic.transform(_sweep.value);
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              begin: const Alignment(-1, -0.4),
              end: const Alignment(1, 0.4),
              colors: [
                base,
                base,
                AppColors.accent,
                const Color(0xFFFFB3CF),
                AppColors.accent,
                base,
                base,
              ],
              stops: const [0, 0.38, 0.45, 0.5, 0.55, 0.62, 1],
              transform: _Slide(-1.2 + 2.4 * t),
            ).createShader(bounds),
            child: child,
          );
        },
        child: text,
      ),
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.fraction);

  final double fraction;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * fraction, 0, 0);
}

/// A short comet of light that travels round [child]'s rounded border at an
/// even speed, pink at its head fading to lilac and nothing. For the one
/// panel on a screen that holds its main action. Without motion, just the
/// still rim.
class BorderBeam extends StatefulWidget {
  const BorderBeam({
    super.key,
    required this.child,
    this.radius = AppRadius.xl,
    this.duration = const Duration(seconds: 5),
  });

  final Widget child;
  final double radius;
  final Duration duration;

  @override
  State<BorderBeam> createState() => _BorderBeamState();
}

class _BorderBeamState extends State<BorderBeam>
    with SingleTickerProviderStateMixin {
  late final _run = AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _run.stop();
    } else if (!_run.isAnimating) {
      _run.repeat();
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter:
          _run.isAnimating ? _BeamPainter(_run, radius: widget.radius) : null,
      child: widget.child,
    );
  }
}

class _BeamPainter extends CustomPainter {
  _BeamPainter(this.progress, {required this.radius})
      : super(repaint: progress);

  final Animation<double> progress;
  final double radius;

  Size? _size;
  late PathMetric _metric;

  @override
  void paint(Canvas canvas, Size size) {
    if (size != _size) {
      _size = size;
      final rrect = RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75), Radius.circular(radius));
      _metric = (Path()..addRRect(rrect)).computeMetrics().first;
    }
    final length = _metric.length;
    final beam = (length * 0.2).clamp(70.0, 240.0);
    final head = progress.value * length;
    final tail = head - beam;

    // One stroke, shaded along the straight line from tail to head: close
    // enough to the curve at a corner, and without seams.
    final from = _metric.getTangentForOffset(tail % length)!.position;
    final to = _metric.getTangentForOffset(head % length)!.position;
    final segment = _extract(tail, head, length);
    canvas
      ..drawPath(
        segment,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
          ..shader = _beamShader(from, to, 0.45),
      )
      ..drawPath(
        segment,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..shader = _beamShader(from, to, 1),
      );
  }

  /// The stretch [from]..[to] of the outline, wrapping past the start.
  Path _extract(double from, double to, double length) {
    from %= length;
    to %= length;
    if (from <= to) return _metric.extractPath(from, to);
    return _metric.extractPath(from, length)
      ..addPath(_metric.extractPath(0, to), Offset.zero);
  }

  @override
  bool shouldRepaint(_BeamPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.progress != progress;
}

/// Lilac fading in from nothing at [from] to full pink at [to]. The rect
/// may be inverted: topLeft..bottomRight of it still runs [from] to [to],
/// which keeps the direction Rect.fromPoints would lose.
Shader _beamShader(Offset from, Offset to, double alpha) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.glowLilac.withOpacity(0),
        AppColors.glowLilac.withOpacity(0.6 * alpha),
        AppColors.glow.withOpacity(alpha),
      ],
      stops: const [0, 0.45, 1],
    ).createShader(Rect.fromLTRB(from.dx, from.dy, to.dx, to.dy));

/// Remembers which items of one list have already come in, so scrolling
/// back up doesn't replay them, and staggers the first screenful.
class RevealScope extends StatefulWidget {
  const RevealScope({super.key, required this.child});

  final Widget child;

  @override
  State<RevealScope> createState() => _RevealScopeState();
}

class _RevealScopeState extends State<RevealScope> {
  final _seen = <Object>{};
  final _born = DateTime.now();

  @override
  Widget build(BuildContext context) =>
      _RevealMemory(seen: _seen, born: _born, child: widget.child);
}

class _RevealMemory extends InheritedWidget {
  const _RevealMemory(
      {required this.seen, required this.born, required super.child});

  final Set<Object> seen;
  final DateTime born;

  @override
  bool updateShouldNotify(_RevealMemory oldWidget) => false;
}

/// Fades [child] in as it rises a little into place and slows to a stop:
/// how list items arrive, on first load (staggered by [index]) and as they
/// scroll into view. Give [id] inside a [RevealScope] to play once per item.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.index = 0, this.id});

  final Widget child;
  final int index;
  final Object? id;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  AnimationController? _in;
  late Animation<double> _t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_in != null) return;
    final memory = context.getInheritedWidgetOfExactType<_RevealMemory>();
    final id = widget.id;
    final already = id != null && memory != null && !memory.seen.add(id);
    if (already || MediaQuery.disableAnimationsOf(context)) {
      _in = AnimationController(vsync: this, value: 1);
      _t = _in!;
      return;
    }
    // Only the first screenful is staggered; later items arrive as they
    // scroll in, with nothing to wait for.
    final fresh = memory == null ||
        DateTime.now().difference(memory.born) <
            const Duration(milliseconds: 500);
    final delay = fresh ? math.min(widget.index, 7) * 55 : 0;
    final total = AppMotion.reveal.inMilliseconds + delay;
    _in = AnimationController(
        vsync: this, duration: Duration(milliseconds: total))
      ..forward();
    _t = CurvedAnimation(
        parent: _in!,
        curve: Interval(delay / total, 1, curve: AppMotion.settle));
  }

  @override
  void dispose() {
    _in?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final t = _t.value;
        if (t >= 1) return child!;
        return Opacity(
          opacity: Curves.easeOut.transform(t.clamp(0.0, 1.0)),
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
