import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme.dart';

/// The ground every page floats on: lavender-white with three soft glows,
/// pink from the logo at the top, lilac and sky lower down. Static and
/// painted once; glass panels above it are what move.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.ground),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          const Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: _Aurora())),
          ),
          child,
        ],
      ),
    );
  }
}

class _Aurora extends CustomPainter {
  const _Aurora();

  // Centre (as a fraction of the screen), radius (fraction of the longer
  // side), colour at the centre.
  static const _glows = [
    (Offset(0.08, -0.04), 0.62, Color(0x33FF2E7E)),
    (Offset(1.02, 0.38), 0.58, Color(0x2E9B7BFF)),
    (Offset(0.12, 1.02), 0.6, Color(0x266CC6FF)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final longest = size.longestSide;
    for (final (at, r, color) in _glows) {
      final center = Offset(at.dx * size.width, at.dy * size.height);
      final radius = r * longest;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withOpacity(0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_Aurora oldDelegate) => false;
}

/// A frosted panel: translucent white, a bright rim, a soft drop shadow.
/// [blur] adds a real backdrop blur; keep it for chrome that content
/// scrolls under, since every blurred panel costs a pass on each frame.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = AppRadius.xl,
    this.padding = EdgeInsets.zero,
    this.color = AppColors.glass,
    this.blur = 0,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double blur;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    Widget panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        border: Border.all(color: AppColors.glassRim),
        // A sheen from the top edge, where light would catch the glass.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withOpacity(0.35), Colors.white.withOpacity(0)],
          stops: const [0, 0.5],
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (blur > 0) {
      panel = ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: ColoredBox(color: color, child: panel),
        ),
      );
    } else {
      panel = DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: shape),
        child: panel,
      );
    }
    if (!shadow) return panel;
    return CustomPaint(painter: _OuterShadow(radius), child: panel);
  }
}

/// The panel's drop shadow, painted only outside its shape. A plain
/// BoxShadow would also darken the panel from behind, through the glass.
class _OuterShadow extends CustomPainter {
  const _OuterShadow(this.radius);

  final double radius;

  static const _shadows = [
    BoxShadow(
        color: AppColors.glassShadow,
        offset: Offset(0, 10),
        blurRadius: 30,
        spreadRadius: -8),
    BoxShadow(color: Color(0x0D0A0A0B), offset: Offset(0, 1), blurRadius: 2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final shape =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    canvas
      ..save()
      ..clipPath(Path.combine(
        PathOperation.difference,
        Path()..addRect((Offset.zero & size).inflate(80)),
        Path()..addRRect(shape),
      ));
    for (final s in _shadows) {
      canvas.drawRRect(
          shape.shift(s.offset).inflate(s.spreadRadius), s.toPaint());
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadow oldDelegate) => oldDelegate.radius != radius;
}

/// The bottom bar as a floating sheet of frosted glass, clear of the screen
/// edges, with the page scrolling underneath. Pair with `extendBody: true`
/// on the Scaffold; lists then pad by [MediaQuery.paddingOf] bottom.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({super.key, required this.child});

  /// A [NavigationBar].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 10 + inset),
      child: Glass(
        radius: AppRadius.xxl,
        blur: 20,
        color: const Color(0xB8FFFFFF),
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: child,
        ),
      ),
    );
  }
}

/// Padding for a scrolling page body: [base] plus whatever the floating
/// bottom bar covers.
EdgeInsets pagePadding(BuildContext context,
        {double top = 12, double bottom = 32, double side = 16}) =>
    EdgeInsets.fromLTRB(
        side, top, side, bottom + MediaQuery.paddingOf(context).bottom);
