import 'package:flutter/material.dart';

/// The look of the anime figure shop (D:\anime_figures_shop, web/src/index.css
/// and mobile/lib/ui/theme.dart), copied so this app feels like the same
/// family: brand navy and crane gold from the kimono logo, DM Sans for text,
/// Cormorant Garamond for the wordmark.
///
/// **Light only**, like that app.
abstract final class AppColors {
  // Surfaces. The page sits on a faint cool grey so white cards read as
  // objects on it.
  static const surface = Color(0xFFF6F6F9);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFEEEEF3);
  static const line = Color(0xFFE3E3EA);
  static const lineStrong = Color(0xFFCDCDD7);

  // Ink. All three clear WCAG AA on both surfaces:
  // ink 16.9:1, inkMuted 7.3:1, inkSubtle 5.1:1.
  static const ink = Color(0xFF17171F);
  static const inkMuted = Color(0xFF55555F);
  static const inkSubtle = Color(0xFF6E6E7A);

  // Brand navy, taken from the Archive mark: brand950 is the exact plate
  // colour of the launcher icon, and the ramp is built up from it. brand600
  // is 9.3:1 both ways on white, so one value covers buttons, links and
  // focus rings. Keep these in step with web/src/index.css.
  static const brand50 = Color(0xFFF5F7FA);
  static const brand100 = Color(0xFFE7ECF3);
  static const brand200 = Color(0xFFCBD6E5);
  static const brand600 = Color(0xFF33476E);
  static const brand700 = Color(0xFF273A5B);
  static const brand950 = Color(0xFF131A2B);

  // The mark's second colour, matching the gold of the origami cranes in the
  // brand artwork. DECORATIVE ONLY — 2.9:1 on white, so it fails WCAG AA for
  // text and must stay on rules and hairlines. It is safe as text on
  // brand950 (6.1:1). For gold text on a light surface use goldInk (5.1:1).
  static const gold = Color(0xFFC0912F);
  static const goldInk = Color(0xFF8A6A15);

  // Semantics: soft = tint background, line = its border, ink = text on the
  // tint. Every pair is at least 5.7:1.
  static const successSoft = Color(0xFFE8F7EF);
  static const successLine = Color(0xFFBCE5D0);
  static const successInk = Color(0xFF0F6B41);

  static const warnSoft = Color(0xFFFDF4E5);
  static const warnLine = Color(0xFFF2DDB2);
  static const warnInk = Color(0xFF8A5300);

  static const dangerSoft = Color(0xFFFDEDED);
  static const dangerLine = Color(0xFFF6CFCF);
  static const dangerInk = Color(0xFFB3261E);

  static const infoSoft = Color(0xFFECF3FE);
  static const infoLine = Color(0xFFC6DDFA);
  static const infoInk = Color(0xFF14548F);
}

/// The 4px radius rhythm: controls 8, cards 12–16, panels 20, pills full.
abstract final class AppRadius {
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const xxl = 20.0;
}

/// Families declared in pubspec.yaml.
abstract final class AppFonts {
  static const sans = 'DMSans';

  /// Wordmark only: fine hairlines that fall apart below about 16px.
  static const display = 'CormorantGaramond';
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.brand600,
    onPrimary: Colors.white,
    primaryContainer: AppColors.brand100,
    onPrimaryContainer: AppColors.brand700,
    // Selected chips, segments and tonal buttons use these; Material's
    // default is teal.
    secondary: AppColors.brand600,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.brand100,
    onSecondaryContainer: AppColors.brand700,
    surface: AppColors.surfaceRaised,
    onSurface: AppColors.ink,
    surfaceContainerLowest: AppColors.surfaceRaised,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surfaceSunken,
    error: AppColors.dangerInk,
    onError: Colors.white,
    outline: AppColors.lineStrong,
    outlineVariant: AppColors.line,
  );

  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: AppFonts.sans,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.surface,
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceRaised,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.brand600, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.inkSubtle),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        // Button styles replace the label text style whole, so the family
        // has to be named again here.
        textStyle: const TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: 15,
            fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.lineStrong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.brand100,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.brand700
              : AppColors.inkMuted,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.brand600,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.brand950,
    ),
  );
}
