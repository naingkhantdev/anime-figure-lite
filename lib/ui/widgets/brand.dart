import 'package:flutter/material.dart';

import '../../config.dart';
import '../theme.dart';

/// The shop's logo, from the transparent `assets/brand/logo.png`. Replace
/// that one file to change it everywhere in the app.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      logoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // Decode near the size it is drawn at, not the full source file.
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      semanticLabel: '$appName logo',
    );
  }
}

const logoAsset = 'assets/brand/logo.png';

/// The app name, small, uppercase and widely tracked.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 14, this.color = AppColors.ink});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      appName.toUpperCase(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppFonts.sans,
        fontWeight: FontWeight.w600,
        fontSize: size,
        letterSpacing: size * 0.32,
        color: color,
        height: 1.2,
      ),
    );
  }
}

/// Logo and name at the top of the sign-in and status screens: just the
/// mark on white with room around it.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.tagline});

  final String? tagline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.paddingOf(context).top + 56, 24, 8),
      child: Column(
        children: [
          const AppLogo(size: 72),
          const SizedBox(height: 20),
          const Wordmark(),
          if (tagline != null) ...[
            const SizedBox(height: 8),
            Text(
              tagline!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
