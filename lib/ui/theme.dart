import 'package:flutter/material.dart';

/// Minimal theme: white (or near-black) canvas, ink text, neutral surfaces.
/// Pink is the one accent and is kept for main actions, prices, the cart
/// badge and focus. The logo's #FF2E7E is too light for text on white, so the
/// UI uses a deeper pink that passes WCAG AA (4.5:1) for normal text.
abstract final class AppTheme {
  static const _brandPink = Color(0xFFE0115F);
  static const _brandPinkOnDark = Color(0xFFFF6B9E);

  static final light = _build(const ColorScheme(
    brightness: Brightness.light,
    primary: _brandPink,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFE3EC),
    onPrimaryContainer: Color(0xFF5C0026),
    secondary: Color(0xFF4A4550),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEEEBF0),
    onSecondaryContainer: Color(0xFF16131A),
    tertiary: Color(0xFF4A4550),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF16131A),
    onSurfaceVariant: Color(0xFF5E5A63),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFAF9FB),
    surfaceContainer: Color(0xFFF5F4F6),
    surfaceContainerHigh: Color(0xFFEFEDF1),
    surfaceContainerHighest: Color(0xFFE9E7EB),
    outline: Color(0xFF8C8891),
    outlineVariant: Color(0xFFE6E3E8),
    inverseSurface: Color(0xFF2B282E),
    onInverseSurface: Color(0xFFF3F0F5),
    inversePrimary: _brandPinkOnDark,
    surfaceTint: Colors.transparent,
  ));

  static final dark = _build(const ColorScheme(
    brightness: Brightness.dark,
    primary: _brandPinkOnDark,
    onPrimary: Color(0xFF2A0716),
    primaryContainer: Color(0xFF5C0026),
    onPrimaryContainer: Color(0xFFFFD9E3),
    secondary: Color(0xFFCBC5D0),
    onSecondary: Color(0xFF16131A),
    secondaryContainer: Color(0xFF2E2B32),
    onSecondaryContainer: Color(0xFFEDEAF0),
    tertiary: Color(0xFFCBC5D0),
    onTertiary: Color(0xFF16131A),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF121014),
    onSurface: Color(0xFFEDEAF0),
    onSurfaceVariant: Color(0xFFB5B0BA),
    surfaceContainerLowest: Color(0xFF0D0B0F),
    surfaceContainerLow: Color(0xFF1A181C),
    surfaceContainer: Color(0xFF1E1C21),
    surfaceContainerHigh: Color(0xFF252228),
    surfaceContainerHighest: Color(0xFF2E2B32),
    outline: Color(0xFF7E7983),
    outlineVariant: Color(0xFF3A363E),
    inverseSurface: Color(0xFFEDEAF0),
    onInverseSurface: Color(0xFF2B282E),
    inversePrimary: _brandPink,
    surfaceTint: Colors.transparent,
  ));

  static ThemeData _build(ColorScheme c) {
    final radius = BorderRadius.circular(12);
    return ThemeData(
      useMaterial3: true,
      colorScheme: c,
      scaffoldBackgroundColor: c.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: c.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: c.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.outlineVariant, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: c.onSurface,
          side: BorderSide(color: c.outline),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: c.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceContainer,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(color: c.onSurface),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: c.primary,
        textColor: c.onPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
