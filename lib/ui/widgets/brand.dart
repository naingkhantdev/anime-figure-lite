import 'package:flutter/material.dart';

import '../../config.dart';
import '../theme.dart';
import 'effects.dart';

/// The shop's logo: the fighter's glass tile, `assets/brand/logo.png`,
/// built from assets/brand/source by tool/brand_assets.py (README
/// "Changing the logo").
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

/// The app name, small, uppercase and widely tracked. With [shine], a
/// glint of pink sweeps across it now and then.
class Wordmark extends StatelessWidget {
  const Wordmark({
    super.key,
    this.size = 14,
    this.color = AppColors.ink,
    this.shine = false,
  });

  final double size;
  final Color color;
  final bool shine;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppFonts.sans,
      fontWeight: FontWeight.w600,
      fontSize: size,
      letterSpacing: size * 0.32,
      color: color,
      height: 1.2,
    );
    final text = appName.toUpperCase();
    return shine
        ? ShineText(text, style: style, textAlign: TextAlign.center)
        : Text(text, textAlign: TextAlign.center, style: style);
  }
}

/// Logo and the shining app name, for the title of a home screen's bar.
class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AppLogo(size: 32),
        SizedBox(width: 10),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: ShineText(
              appName,
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Logo and name at the top of the sign-in and status screens: the mark
/// floating on the aurora with room around it.
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
          const Wordmark(shine: true),
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
