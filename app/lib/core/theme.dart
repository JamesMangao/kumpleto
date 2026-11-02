import 'package:flutter/material.dart';

/// Design system theme based on Kumpleto's deep forest teal and fresh mint palette.
abstract final class AppTheme {
  static const Color primaryTeal = Color(0xFF0E6B58);
  static const Color primaryDarkTeal = Color(0xFF0A5344);
  static const Color mintContainer = Color(0xFFE0F0EB);
  static const Color mintContainerLight = Color(0xFFEAF5F1);
  static const Color onMintContainer = Color(0xFF0E6B58);

  static const Color backgroundLight = Color(0xFFF8FAF9);
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5EDE8);
  static const Color textPrimaryLight = Color(0xFF14241E);
  static const Color textSecondaryLight = Color(0xFF60736C);

  static const Color backgroundDark = Color(0xFF101915);
  static const Color surfaceCardDark = Color(0xFF18241F);
  static const Color borderDark = Color(0xFF283A31);
  static const Color textPrimaryDark = Color(0xFFE4EDE8);
  static const Color textSecondaryDark = Color(0xFF8CA397);

  // Status badge colors
  static const Color statusGreenBg = Color(0xFFE6F5ED);
  static const Color statusGreenText = Color(0xFF1B7A43);
  static const Color statusAmberBg = Color(0xFFFEF3E6);
  static const Color statusAmberText = Color(0xFFB86A04);
  static const Color statusRedBg = Color(0xFFFDE8E8);
  static const Color statusRedText = Color(0xFFBC2C2C);
  static const Color statusGrayBg = Color(0xFFF0F4F2);
  static const Color statusGrayText = Color(0xFF5A6E66);

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? backgroundDark : backgroundLight;
    final cardBg = isDark ? surfaceCardDark : surfaceCardLight;
    final border = isDark ? borderDark : borderLight;
    final textPrimary = isDark ? textPrimaryDark : textPrimaryLight;
    final textSecondary = isDark ? textSecondaryDark : textSecondaryLight;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primaryTeal,
      onPrimary: Colors.white,
      primaryContainer: isDark ? const Color(0xFF1D352B) : mintContainer,
      onPrimaryContainer: isDark ? const Color(0xFF9EE5CE) : onMintContainer,
      secondary: const Color(0xFF2E7D68),
      onSecondary: Colors.white,
      secondaryContainer: isDark ? const Color(0xFF233830) : const Color(0xFFD4ECE3),
      onSecondaryContainer: isDark ? const Color(0xFFB0E8D6) : primaryDarkTeal,
      tertiary: const Color(0xFF38655A),
      onTertiary: Colors.white,
      tertiaryContainer: isDark ? const Color(0xFF233B34) : const Color(0xFFDBEFE9),
      onTertiaryContainer: isDark ? const Color(0xFFB5E2D4) : const Color(0xFF1E4D42),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: isDark ? const Color(0xFF93000A) : const Color(0xFFFFDAD6),
      onErrorContainer: isDark ? const Color(0xFFFFDAD6) : const Color(0xFF410002),
      surface: bg,
      onSurface: textPrimary,
      surfaceContainer: cardBg,
      surfaceContainerHighest: isDark ? const Color(0xFF21302A) : const Color(0xFFF0F5F2),
      surfaceContainerLow: bg,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: isDark ? const Color(0xFF2A3C33) : const Color(0xFFEDF2EF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF25332C) : const Color(0xFFEEF3F0),
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        elevation: 0,
        height: 68,
        indicatorColor: isDark ? const Color(0xFF233B32) : const Color(0xFFD4ECE3),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryTeal, size: 24);
          }
          return IconThemeData(color: textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryTeal,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1B2722) : const Color(0xFFEEF4F1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryTeal,
        linearTrackColor: isDark ? const Color(0xFF24362E) : const Color(0xFFDFEDE8),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
