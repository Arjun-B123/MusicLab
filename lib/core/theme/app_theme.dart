import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Warm Journal" design tokens — see design_handoff/README.md for the
/// original handoff spec this was built from. Colors/type/spacing here are
/// final per that handoff; this file is the single source of truth for both
/// themes rather than duplicating values across screens.
class AppColors {
  final Color background;
  final Color surface;
  final Color surfaceBorder;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color accent;
  final Color accentDark;
  final Color sage;
  final Color gold;
  final Color tabInactive;
  final Color divider;
  final Color onAccent;

  /// Text sitting directly on the Scaffold background (headers, empty
  /// states) — distinct from [ink]/[inkSoft]/[inkFaint], which are for text
  /// on top of [surface] cards. In light mode these are the same color; in
  /// dark mode [surface] is a saturated orange needing dark espresso text,
  /// while the plain background needs light cream text instead — using
  /// [ink] in both places makes background text nearly invisible (dark
  /// espresso on near-black).
  final Color onBackground;
  final Color onBackgroundSoft;
  final Color onBackgroundFaint;

  /// Accent-colored highlights (active tab, dashed underlines, filled
  /// progress bars/rings/dots) drawn ON TOP OF a [surface] card. In light
  /// mode [surface] is white, so [accent] (orange) pops fine and this
  /// equals [accent]. In dark mode [surface] IS the accent orange — using
  /// [accent] for a foreground element on a [surface] card is invisible
  /// (orange-on-orange), so this is [ink] instead there (the same "text on
  /// orange card" color used elsewhere). Only use [accent] directly for
  /// elements sitting on the plain [background], never inside a card.
  final Color accentOnSurface;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceBorder,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.accent,
    required this.accentDark,
    required this.sage,
    required this.gold,
    required this.tabInactive,
    required this.divider,
    required this.onAccent,
    required this.onBackground,
    required this.onBackgroundSoft,
    required this.onBackgroundFaint,
    required this.accentOnSurface,
  });

  static const light = AppColors(
    background: Color(0xFFFAF3EA),
    surface: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFFECDFC9),
    ink: Color(0xFF3A2B22),
    inkSoft: Color(0xFF8A7A6D),
    inkFaint: Color(0xFFA3947F),
    accent: Color(0xFFD97A4A),
    accentDark: Color(0xFFC15F30),
    sage: Color(0xFF8A9A7E),
    gold: Color(0xFFF2C94C),
    tabInactive: Color(0xFFB0A494),
    divider: Color(0x1A3A2B22),
    onAccent: Color(0xFFFFFFFF),
    onBackground: Color(0xFF3A2B22),
    onBackgroundSoft: Color(0xFF8A7A6D),
    onBackgroundFaint: Color(0xFFA3947F),
    accentOnSurface: Color(0xFFD97A4A),
  );

  // Dark theme: card fills use the saturated orange per the handoff (not a
  // muted/desaturated dark-mode accent) — this is a deliberate "Warm
  // Journal" choice, not an oversight.
  static const dark = AppColors(
    background: Color(0xFF201F1F),
    surface: Color(0xFFDF781D),
    surfaceBorder: Color(0xFF55483A),
    ink: Color(0xFF2B1C10),
    inkSoft: Color(0x9E2B1C10),
    inkFaint: Color(0x802B1C10),
    accent: Color(0xFFDF781D),
    accentDark: Color(0xFFC15F30),
    sage: Color(0xFFA5977F),
    gold: Color(0xFFF2C94C),
    tabInactive: Color(0xFFC9BBA8),
    divider: Color(0x33FFFFFF),
    onAccent: Color(0xFFFFFFFF),
    onBackground: Color(0xFFF3ECE1),
    onBackgroundSoft: Color(0xFFC9BBA8),
    onBackgroundFaint: Color(0xFFA5977F),
    accentOnSurface: Color(0xFF2B1C10),
  );

}

class AppTheme {
  /// Headline/title font — used sparingly (greetings, section headers,
  /// piece titles), never for body text or dense UI.
  static TextStyle handwritten({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w700,
    double height = 1.25,
  }) {
    return GoogleFonts.kalam(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
    );
  }

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: c.ink, displayColor: c.ink);

    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        primary: c.accent,
        onPrimary: c.onAccent,
        surface: c.surface,
        onSurface: c.ink,
        error: const Color(0xFFB3261E),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        titleTextStyle: handwritten(size: 20, color: c.ink),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.surfaceBorder, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.accent,
          side: BorderSide(color: c.accent, width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.accent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: GoogleFonts.inter(color: c.background),
      ),
    );
  }

  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);
}

/// Convenience accessor so widgets can grab the current theme's Warm
/// Journal tokens without importing AppColors' light/dark statics directly.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;
}
