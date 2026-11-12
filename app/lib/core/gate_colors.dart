import 'package:flutter/material.dart';

import 'theme.dart';

/// One palette for every first-run surface: the welcome scene, the disclaimer
/// gate and the onboarding screen.
///
/// These three screens sit in a single uninterrupted flow, so they must never
/// disagree about light or dark. Keeping the colours here also means a change
/// to the warm-paper light theme happens in exactly one place.
class GateColors {
  const GateColors({
    required this.bg,
    required this.card,
    required this.cardBorder,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.stamp,
  });

  final Color bg;
  final Color card;
  final Color cardBorder;
  final Color ink;

  /// Secondary text: captions, taglines, disclaimer paragraphs.
  final Color muted;

  /// Brand accent for icons, badges and tick boxes.
  final Color accent;

  /// Rubber-stamp colour on the welcome checklist.
  final Color stamp;

  /// Alias kept for the gates, whose cards are the same colour as [card].
  Color get surface => card;

  /// Alias kept for the gates, whose hairlines are the same as [cardBorder].
  Color get border => cardBorder;

  static GateColors of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const GateColors(
            bg: Color(0xFF0C1424),
            card: Color(0xFF151E31),
            cardBorder: Color(0xFF2A3A59),
            ink: Color(0xDEFFFFFF),
            muted: Color(0xFF9AA6BF),
            accent: Color(0xFF5FD3B6),
            stamp: Color(0xFF5FD3B6),
          )
        : const GateColors(
            bg: Color(0xFFF6F1E7), // warm paper
            card: Color(0xFFFFFFFF),
            cardBorder: Color(0xFFE2D9C6),
            ink: Color(0xFF14211D),
            muted: Color(0xFF5E6F69),
            accent: AppTheme.primaryTeal, // #0E6B58
            stamp: AppTheme.primaryTeal,
          );
  }
}
