import 'package:flutter/material.dart';

import 'widgets/glass.dart';

/// Minimal glass: a pale aurora ground (pink, lilac and sky glows on
/// lavender-white), frosted white panels with a bright rim, near-black ink.
/// Pink is the one accent, kept for main actions, prices, the cart badge and
/// focus. Other colour appears only where it carries meaning (in/out, low,
/// expired).
///
/// Real blur is kept for chrome that content scrolls under (the bottom bar,
/// the product bar); cards are translucent without blur, which reads the
/// same over the soft ground and costs nothing to scroll.
///
/// **Light only.**
abstract final class AppColors {
  // The ground everything floats on, under the aurora glows (glass.dart).
  static const ground = Color(0xFFF5F3F8);

  // Surfaces. Opaque white is for the splash and the few places that must
  // not let the ground through; panels use the glass tones below.
  static const surface = Color(0xFFFFFFFF);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFEEEBF2);
  static const line = Color(0xFFE6E2EC);
  static const lineStrong = Color(0xFFD3CEDB);

  // Glass. Fill for cards and panels, a stronger fill for chrome and
  // sheets, the bright rim light catches on, and the hairline that keeps a
  // panel's edge visible where the ground is palest.
  static const glass = Color(0xA8FFFFFF);
  static const glassStrong = Color(0xD9FFFFFF);
  static const glassRim = Color(0xCCFFFFFF);
  static const glassEdge = Color(0x140A0A0B);
  static const glassShadow = Color(0x1A4A2D63);

  // Ink, for text and for selection (chips, segments, tabs).
  // All three clear WCAG AA on the ground and on glass: ink 18:1,
  // inkMuted 5.9:1, inkSubtle 4.5:1.
  static const ink = Color(0xFF0A0A0B);
  static const inkMuted = Color(0xFF5B5A66);
  static const inkSubtle = Color(0xFF6E6C79);

  // The accent: a deep pink that passes WCAG AA (5.1:1) for normal text on
  // white and white text on it.
  static const accent = Color(0xFFE0115F);
  static const accentSoft = Color(0xFFFFE3EC);

  // The light that runs round a border beam and the glint in the shine:
  // the logo pink, then a lilac from the aurora.
  static const glow = Color(0xFFFF2E7E);
  static const glowLilac = Color(0xFF9B7BFF);

  // The splash, in the logo's own colours: its dark navy (also the native
  // splash, android/.../colors.xml and LaunchScreen.storyboard) and the
  // fighter's red neon.
  static const splash = Color(0xFF12182C);
  static const splashNeon = Color(0xFFFF3B4E);

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

/// Controls 12, cards 18, panels 22, sheets 26, pills full.
abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 18.0;
  static const xl = 22.0;
  static const xxl = 26.0;
}

/// Families declared in pubspec.yaml.
abstract final class AppFonts {
  static const sans = 'DMSans';
}

/// Shared timing. Entrances decelerate hard (an exponential ease-out), so
/// things arrive quickly and settle slowly.
abstract final class AppMotion {
  static const settle = Cubic(0.16, 1, 0.3, 1);
  static const quick = Duration(milliseconds: 180);
  static const reveal = Duration(milliseconds: 650);
}

/// Every page sits on the aurora ground. Done in the page transition, not
/// behind the Navigator, so a page sliding in covers the one below instead
/// of showing it through its glass.
class _GroundedTransitions extends PageTransitionsBuilder {
  const _GroundedTransitions(this.inner);

  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      inner.buildTransitions(route, context, animation, secondaryAnimation,
          AuroraBackground(child: child));
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
  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    // Transparent so the aurora (added per page above) shows through.
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: AppColors.ground,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android:
          _GroundedTransitions(ZoomPageTransitionsBuilder()),
      TargetPlatform.iOS:
          _GroundedTransitions(CupertinoPageTransitionsBuilder()),
      TargetPlatform.windows:
          _GroundedTransitions(ZoomPageTransitionsBuilder()),
      TargetPlatform.macOS:
          _GroundedTransitions(CupertinoPageTransitionsBuilder()),
      TargetPlatform.linux: _GroundedTransitions(ZoomPageTransitionsBuilder()),
    }),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      // Clear over the ground; frosted once content scrolls under it.
      backgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.scrolledUnder)
            ? AppColors.glassStrong
            : Colors.transparent,
      ),
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.ink,
      ),
    ),
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
        .copyWith(
          headlineSmall: base.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6),
          titleLarge: base.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.3),
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.glassStrong,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: inputBorder(AppColors.glassEdge),
      enabledBorder: inputBorder(AppColors.glassEdge),
      disabledBorder: inputBorder(AppColors.glassEdge),
      focusedBorder: inputBorder(AppColors.accent, 1.4),
      errorBorder: inputBorder(AppColors.dangerLine),
      focusedErrorBorder: inputBorder(AppColors.dangerInk, 1.4),
      labelStyle: const TextStyle(color: AppColors.inkMuted),
      floatingLabelStyle: const TextStyle(color: AppColors.ink),
      hintStyle: const TextStyle(color: AppColors.inkSubtle),
      prefixIconColor: AppColors.inkMuted,
      suffixIconColor: AppColors.inkMuted,
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
        backgroundColor: AppColors.glass,
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
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppColors.ink),
    ),
    // Picked chips and segments turn pink-tinted, never solid black.
    chipTheme: const ChipThemeData(
      showCheckmark: false,
      backgroundColor: AppColors.glassStrong,
      selectedColor: AppColors.accentSoft,
      side: BorderSide(color: AppColors.glassEdge),
      shape: StadiumBorder(),
      labelStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontWeight: FontWeight.w500,
          color: AppColors.ink),
      secondaryLabelStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontWeight: FontWeight.w600,
          color: AppColors.accent),
    ),
    cardTheme: CardTheme(
      color: AppColors.glass,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.glassRim),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      iconColor: AppColors.inkMuted,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: AppColors.accentSoft,
      indicatorShape: const StadiumBorder(),
      height: 64,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.inkSubtle,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.inkSubtle,
        ),
      ),
    ),
    // Same look as the bottom bar, for tablets (shop_home_page.dart).
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.glass,
      indicatorColor: AppColors.accentSoft,
      selectedIconTheme: IconThemeData(color: AppColors.accent, size: 24),
      unselectedIconTheme: IconThemeData(color: AppColors.inkSubtle, size: 24),
      selectedLabelTextStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.ink),
      unselectedLabelTextStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.inkSubtle),
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
        backgroundColor: AppColors.glass,
        selectedBackgroundColor: AppColors.accentSoft,
        selectedForegroundColor: AppColors.accent,
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.glassEdge),
        textStyle: buttonText.copyWith(fontSize: 14),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xF5FFFFFF),
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppColors.lineStrong,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xF7FFFFFF),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        side: const BorderSide(color: AppColors.glassRim),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xF7FFFFFF),
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.glassRim),
      ),
    ),
    badgeTheme: const BadgeThemeData(
      backgroundColor: AppColors.accent,
      textColor: Colors.white,
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.accent),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: Color(0x40E0115F),
      selectionHandleColor: AppColors.accent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xF20A0A0B),
      actionTextColor: const Color(0xFFFF8DB8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  );
}
