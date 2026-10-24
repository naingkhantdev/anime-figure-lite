import 'package:flutter/material.dart';

/// Minimal: white space, near-black ink, hairline rules. Pink is the one
/// accent, kept for main actions, prices, the cart badge and focus. Other
/// colour appears only where it carries meaning (in/out, low, expired).
///
/// **Light only.**
abstract final class AppColors {
  // Surfaces. Everything sits on white; cards are separated by hairlines,
  // not shadows or tinted backgrounds.
  static const surface = Color(0xFFFFFFFF);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFF4F4F5);
  static const line = Color(0xFFECECEE);
  static const lineStrong = Color(0xFFD9D9DE);

  // Ink, for text and for selection (chips, segments, tabs).
  // All three clear WCAG AA on white: ink 19.6:1, inkMuted 6.3:1,
  // inkSubtle 4.8:1.
  static const ink = Color(0xFF0A0A0B);
  static const inkMuted = Color(0xFF5F5F67);
  static const inkSubtle = Color(0xFF74747C);

  // The accent. The logo's own pink (#FF2E7E, used for the launcher icon) is
  // too light for text on white, so the UI uses this deeper pink, which
  // passes WCAG AA (5.1:1) for normal text and white text on it.
  static const accent = Color(0xFFE0115F);
  static const accentSoft = Color(0xFFFFE3EC);

  // Semantics: soft = tint background, line = its border, ink = text on the
  // tint. Every pair is at least 5.7:1.
  static const successSoft = Color(0xFFEFF8F3);
  static const successLine = Color(0xFFCFEBDB);
  static const successInk = Color(0xFF0F6B41);

  static const warnSoft = Color(0xFFFDF6EA);
  static const warnLine = Color(0xFFF2E1BF);
  static const warnInk = Color(0xFF8A5300);

  static const dangerSoft = Color(0xFFFDF0F0);
  static const dangerLine = Color(0xFFF6D6D6);
  static const dangerInk = Color(0xFFB3261E);

  static const infoSoft = Color(0xFFF1F5FD);
  static const infoLine = Color(0xFFD3E2F8);
  static const infoInk = Color(0xFF14548F);
}

/// Controls 10, cards 14, sheets 20, pills full.
abstract final class AppRadius {
  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 14.0;
  static const xl = 16.0;
  static const xxl = 20.0;
}

/// Families declared in pubspec.yaml.
abstract final class AppFonts {
  static const sans = 'DMSans';
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.accent,
    onPrimary: Colors.white,
    primaryContainer: AppColors.accentSoft,
    onPrimaryContainer: Color(0xFF5C0026),
    // Selected chips, segments and tonal buttons. Material's default is teal.
    secondary: AppColors.ink,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.ink,
    onSecondaryContainer: Colors.white,
    surface: AppColors.surfaceRaised,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.inkMuted,
    surfaceContainerLowest: AppColors.surfaceRaised,
    surfaceContainerLow: AppColors.surfaceRaised,
    surfaceContainer: AppColors.surfaceSunken,
    surfaceContainerHigh: AppColors.surfaceSunken,
    surfaceContainerHighest: AppColors.surfaceSunken,
    error: AppColors.dangerInk,
    onError: Colors.white,
    outline: AppColors.lineStrong,
    outlineVariant: AppColors.line,
  );

  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: AppFonts.sans,
    splashFactory: InkSparkle.splashFactory,
  );

  // Button styles replace the label text style whole, so the family has to
  // be named again in each.
  const buttonText = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.surface,
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.ink,
      ),
      shape: Border(bottom: BorderSide(color: AppColors.line)),
    ),
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
        .copyWith(
          headlineSmall: base.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.5),
          titleLarge: base.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.3),
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceSunken,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
      ),
      labelStyle: const TextStyle(color: AppColors.inkMuted),
      floatingLabelStyle: const TextStyle(color: AppColors.ink),
      hintStyle: const TextStyle(color: AppColors.inkSubtle),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.surfaceSunken,
        shape: controlShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.lineStrong),
        shape: controlShape,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        textStyle: buttonText.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    chipTheme: const ChipThemeData(
      showCheckmark: false,
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.ink,
      side: BorderSide(color: AppColors.lineStrong),
      shape: StadiumBorder(),
      labelStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontWeight: FontWeight.w500,
          color: AppColors.ink),
      secondaryLabelStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontWeight: FontWeight.w500,
          color: Colors.white),
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
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      height: 64,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.inkSubtle,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.inkSubtle,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      extendedTextStyle: buttonText,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.ink,
        selectedForegroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.lineStrong),
        textStyle: buttonText.copyWith(fontSize: 14),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppColors.lineStrong,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    badgeTheme: const BadgeThemeData(
      backgroundColor: AppColors.accent,
      textColor: Colors.white,
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.accent),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  );
}
