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

  // Dark mode is a deep slate-navy rather than black: pure black made the
  // cards and the page read as one flat sheet, and the green-black tint left
  // the whole app looking murky. The steps below keep the same hierarchy the
  // light theme has (page < card < raised < highest) in the new hue.
  static const Color backgroundDark = Color(0xFF0C1424);
  static const Color surfaceCardDark = Color(0xFF151E31);
  static const Color borderDark = Color(0xFF2A3A59);

  /// 87% white. Full-strength white vibrates against a dark page, so body and
  /// heading text is held just under it.
  static const Color textPrimaryDark = Color(0xDEFFFFFF);
  static const Color textSecondaryDark = Color(0xFF9AA6BF);

  /// The brand teal is too heavy as text or an icon on the dark page, so dark
  /// mode lifts it to mint. [primaryTeal] stays the fill colour of buttons and
  /// chips, where white text carries the contrast.
  static const Color accentDark = Color(0xFF5FD3B6);
  static const Color onAccentDark = Color(0xFF04241C);

  // Status badge colors
  static const Color statusGreenBg = Color(0xFFE6F5ED);
  static const Color statusGreenText = Color(0xFF1B7A43);
  static const Color statusAmberBg = Color(0xFFFEF3E6);
  static const Color statusAmberText = Color(0xFFB86A04);
  static const Color statusRedBg = Color(0xFFFDE8E8);
  static const Color statusRedText = Color(0xFFBC2C2C);
  static const Color statusGrayBg = Color(0xFFF0F4F2);
  static const Color statusGrayText = Color(0xFF5A6E66);

  /// Accent for icons and text: brand teal on paper, lifted mint on the dark
  /// page. Fills keep [primaryTeal] in both modes.
  static Color accentOn(Brightness brightness) =>
      brightness == Brightness.dark ? accentDark : primaryTeal;

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? backgroundDark : backgroundLight;
    final cardBg = isDark ? surfaceCardDark : surfaceCardLight;
    final border = isDark ? borderDark : borderLight;
    final textPrimary = isDark ? textPrimaryDark : textPrimaryLight;
    final textSecondary = isDark ? textSecondaryDark : textSecondaryLight;
    final accent = accentOn(brightness);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: isDark ? onAccentDark : Colors.white,
      primaryContainer: isDark ? const Color(0xFF16283F) : mintContainer,
      onPrimaryContainer: isDark ? const Color(0xFFB9EEDD) : onMintContainer,
      secondary: isDark ? const Color(0xFF7FD8C1) : const Color(0xFF2E7D68),
      onSecondary: isDark ? onAccentDark : Colors.white,
      secondaryContainer: isDark
          ? const Color(0xFF1D2A42)
          : const Color(0xFFD4ECE3),
      onSecondaryContainer: isDark ? const Color(0xFFBEEEDF) : primaryDarkTeal,
      tertiary: isDark ? const Color(0xFF8FC7B8) : const Color(0xFF38655A),
      onTertiary: isDark ? onAccentDark : Colors.white,
      tertiaryContainer: isDark
          ? const Color(0xFF1F3049)
          : const Color(0xFFDBEFE9),
      onTertiaryContainer: isDark
          ? const Color(0xFFC4E7DC)
          : const Color(0xFF1E4D42),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: isDark
          ? const Color(0xFF93000A)
          : const Color(0xFFFFDAD6),
      onErrorContainer: isDark
          ? const Color(0xFFFFDAD6)
          : const Color(0xFF410002),
      surface: bg,
      onSurface: textPrimary,
      surfaceContainer: cardBg,
      surfaceContainerHighest: isDark
          ? const Color(0xFF212F4B)
          : const Color(0xFFF0F5F2),
      surfaceContainerLow: bg,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: isDark
          ? const Color(0xFF223150)
          : const Color(0xFFEDF2EF),
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
        color: isDark ? const Color(0xFF223150) : const Color(0xFFEEF3F0),
        thickness: 1,
        space: 1,
      ),
      // On a dark page the default selected segment sits barely a shade above
      // the card, so "All / Acquired / Not yet" read as three equal options.
      // Dark mode fills the chosen segment with the mint accent and its dark
      // ink, plus a mint hairline; light mode keeps the soft mint container.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (!states.contains(WidgetState.selected)) {
              return Colors.transparent;
            }
            return isDark ? accentDark : const Color(0xFFD4ECE3);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? onAccentDark : primaryDarkTeal;
            }
            return textPrimary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return BorderSide(
              color: selected
                  ? (isDark ? accentDark : const Color(0xFFB7DED2))
                  : border,
              width: selected ? 1.6 : 1,
            );
          }),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        elevation: 0,
        height: 68,
        indicatorColor: isDark
            ? const Color(0xFF1F3049)
            : const Color(0xFFD4ECE3),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: accent, size: 24);
          }
          return IconThemeData(color: textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
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
          foregroundColor: accent,
          side: BorderSide(color: accent, width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF17223A) : const Color(0xFFEEF4F1),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: isDark
            ? const Color(0xFF1F2C46)
            : const Color(0xFFDFEDE8),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}


/// Accent for icons, text and hairlines in the brightness of [context]: the
/// brand teal on paper, the lifted mint on the dark page.
Color accentColorOf(BuildContext context) =>
    AppTheme.accentOn(Theme.of(context).brightness);
