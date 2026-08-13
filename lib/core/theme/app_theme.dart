import 'package:flutter/material.dart';

/// Central theme. Deliberately calm/warm rather than a generic Material
/// default — the product is a personal journal as much as a tool.
class AppTheme {
  static const _seed = Color(0xFF6D2740); // deep wine, matches the audit doc

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFFAF9F6),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFAF9F6),
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF181513),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF181513),
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
    );
  }
}
