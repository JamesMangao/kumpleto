import 'package:flutter/material.dart';

/// Material 3 theme, light + dark.
///
/// Seed-based color only — dynamic color is intentionally not wired yet
/// (would require the extra `dynamic_color` package; see docs/DECISIONS.md).
/// The seed is a neutral teal: distinct from any government agency palette,
/// and white-on-primary meets WCAG AA (>= 4.5:1).
abstract final class AppTheme {
  static const Color _seed = Color(0xFF00796B);

  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      // 48dp minimum touch targets (Material 3 default minimum).
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
