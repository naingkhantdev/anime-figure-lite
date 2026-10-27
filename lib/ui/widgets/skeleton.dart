import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme.dart';
import 'glass.dart';

/// Shapes of the content that is on its way, with one band of light
/// passing over all of them together. Still with reduce motion on.
class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final _band = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _band.stop();
    } else if (!_band.isAnimating) {
      _band.repeat();
    }
  }

  @override
  void dispose() {
    _band.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loading,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _band,
          builder: (context, child) => ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              // The band crosses the whole area, edge to edge, each cycle.
              final x = -bounds.width + _band.value * bounds.width * 3;
              return const LinearGradient(
                colors: [
                  Color(0x00FFFFFF),
                  Color(0xA6FFFFFF),
                  Color(0x00FFFFFF),
                ],
                stops: [0, 0.5, 1],
              ).createShader(Rect.fromLTWH(x, 0, bounds.width, bounds.height));
            },
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// One placeholder shape.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 12,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE7E2EE),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Rows in a glass card: a square or round mark, a title and a line under
/// it. The default while a list loads.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.rows = 6,
    this.round = false,
    this.header = true,
  });

  final int rows;

  /// Round marks (people) instead of square tiles (things).
  final bool round;

  /// A summary card above the rows, like the stock and history tabs have.
  final bool header;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        // Also used inside other scrolling pages (an item's history).
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: pagePadding(context),
        children: [
          if (header) ...[
            Glass(
              shadow: false,
              radius: AppRadius.lg,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 44, height: 9),
                          SizedBox(height: 8),
                          SkeletonBox(width: 56, height: 18),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const SkeletonBox(height: 48, radius: AppRadius.md),
            const SizedBox(height: 16),
          ],
          Glass(
            shadow: false,
            radius: AppRadius.lg,
            child: Column(
              children: [
                for (var i = 0; i < rows; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        SkeletonBox(
                            width: 40,
                            height: 40,
                            radius: round ? 20 : AppRadius.md),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FractionallySizedBox(
                                  widthFactor: i.isEven ? 0.7 : 0.5,
                                  child: const SkeletonBox(height: 13)),
                              const SizedBox(height: 8),
                              const FractionallySizedBox(
                                  widthFactor: 0.35,
                                  child: SkeletonBox(height: 10)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        const SkeletonBox(width: 28, height: 16),
                      ],
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

/// The product grid while figures load: photo, name, price.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, required this.gridDelegate});

  final SliverGridDelegate gridDelegate;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: pagePadding(context, side: 12, top: 8),
        gridDelegate: gridDelegate,
        itemCount: 6,
        itemBuilder: (_, i) => Glass(
          shadow: false,
          radius: AppRadius.lg,
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: SkeletonBox(
                    width: double.infinity,
                    height: double.infinity,
                    radius: AppRadius.md),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                        widthFactor: i.isEven ? 0.85 : 0.65,
                        child: const SkeletonBox(height: 12)),
                    const SizedBox(height: 7),
                    const FractionallySizedBox(
                        widthFactor: 0.45, child: SkeletonBox(height: 12)),
                    const SizedBox(height: 12),
                    const SkeletonBox(width: 70, height: 15),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
