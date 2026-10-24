import 'package:flutter/material.dart';

import '../../config.dart';
import '../theme.dart';

/// The carved-wood kimono figure from the anime shop, on its navy plate.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/brand/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        // The artwork is 1024px; decode near the size it is drawn at.
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        semanticLabel: '$appName logo',
      ),
    );
  }
}

/// The app name set in the display serif, tracked wide like the anime
/// shop's wordmark.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 24, this.color = AppColors.ink});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      appName.toUpperCase(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontWeight: FontWeight.w600,
        fontSize: size,
        letterSpacing: size * 0.12,
        color: color,
        height: 1.1,
      ),
    );
  }
}

/// The navy panel at the top of the sign-in and status screens.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.tagline});

  final String? tagline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.brand950,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.paddingOf(context).top + 32, 24, 32),
      child: Column(
        children: [
          const AppLogo(size: 112),
          const SizedBox(height: 20),
          const Wordmark(size: 30, color: Colors.white),
          const SizedBox(height: 10),
          Container(width: 48, height: 1, color: AppColors.gold),
          if (tagline != null) ...[
            const SizedBox(height: 10),
            Text(
              tagline!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gold, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
