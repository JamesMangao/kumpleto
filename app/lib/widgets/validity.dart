import 'package:flutter/material.dart';

import '../data/validity.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';

/// "Valid until 5/12/27 · 6 months left", "Expired 1/4/26" — or null when the
/// entry has no validity period or the acquisition day is unknown.
///
/// The date goes through [MaterialLocalizations] so it follows the app's
/// language and the phone's date format instead of adding an intl dependency.
String? validityText(
  BuildContext context,
  AppLocalizations l10n,
  Document document,
  DateTime? acquiredAt,
) {
  final until = validUntilOf(document, acquiredAt);
  if (until == null) return null;
  final date = MaterialLocalizations.of(context).formatShortDate(until);
  final months = monthsBetween(DateTime.now(), until);
  if (months < 0) return l10n.docValidityExpired(date);
  return '${l10n.docValidUntil(date)} · ${_monthsLeft(l10n, months)}';
}

String _monthsLeft(AppLocalizations l10n, int months) => months <= 1
    ? l10n.docValidityOneMonthLeft
    : l10n.docValidityMonthsLeft('$months');

/// The same information as a compact pill for the document cards.
class ValidityPill extends StatelessWidget {
  const ValidityPill({
    super.key,
    required this.document,
    required this.acquiredAt,
    this.dense = false,
  });

  final Document document;
  final DateTime? acquiredAt;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final until = validUntilOf(document, acquiredAt);
    if (until == null) return const SizedBox.shrink();

    final months = monthsBetween(DateTime.now(), until);
    final expired = months < 0;
    final soon = !expired && months <= 2;
    final color = expired || soon
        ? const Color(0xFFB4690E)
        : Theme.of(context).colorScheme.primary;
    final label = expired
        ? l10n.docValidityExpired(
            MaterialLocalizations.of(context).formatShortDate(until),
          )
        : _monthsLeft(l10n, months);

    return Padding(
      padding: EdgeInsets.only(left: dense ? 8 : 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              expired
                  ? Icons.event_busy_rounded
                  : (soon
                        ? Icons.notifications_active_outlined
                        : Icons.event_available_rounded),
              size: 13,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
