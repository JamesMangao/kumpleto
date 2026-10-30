import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/localized_text.dart';
import '../models/models.dart';

extension LocalizedTextX on LocalizedText {
  /// Picks the string for the current locale (`fil` → Filipino, else English).
  String localized(BuildContext context) =>
      pick(Localizations.localeOf(context).languageCode);
}

/// `count`-aware plural-free progress line, e.g. "3 of 5 requirements".
class ProgressLine extends StatelessWidget {
  const ProgressLine({
    super.key,
    required this.checked,
    required this.total,
    this.showBar = true,
    this.semanticLabel,
  });

  final int checked;
  final int total;
  final bool showBar;

  /// Screen-reader description; defaults to the localized count.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final fraction = total == 0 ? 0.0 : checked / total;
    return Semantics(
      container: true,
      label: semanticLabel ?? l10n.progressOf(checked, total),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.progressOf(checked, total),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (showBar) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                semanticsLabel: semanticLabel ?? l10n.progressOf(checked, total),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Draft / verified / deprecated badge. Text is always present, so status is
/// never communicated by color alone.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final DocStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final (label, background, foreground) = switch (status) {
      DocStatus.verified => (
        l10n.statusVerified,
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      DocStatus.draft => (
        l10n.statusDraft,
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
      DocStatus.deprecated => (
        l10n.statusDeprecated,
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
    };
    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Verification age: green ≤ 90 days, amber 91–180, red > 180, grey when the
/// entry was never verified. The age is always spelled out in words.
class VerificationAge extends StatelessWidget {
  const VerificationAge({super.key, required this.lastVerified});

  final DateTime? lastVerified;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final lastVerified = this.lastVerified;
    if (lastVerified == null) {
      return Text(
        l10n.docNeverVerified,
        style: textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    final age = DateTime.now().difference(lastVerified).inDays;
    final color = switch (age) {
      <= 90 => const Color(0xFF2E7D32), // green
      <= 180 => const Color(0xFFB26A00), // amber
      _ => const Color(0xFFC62828), // red
    };
    return Semantics(
      container: true,
      label: l10n.docVerifiedDays(age),
      excludeSemantics: true,
      child: Text(
        l10n.docVerifiedDays(age),
        style: textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

/// Titled card used for the detail sections (requirements, steps, notes…).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium,
                    semanticsLabel: title,
                  ),
                ),
                ...?actions,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Material icon for a bundle's `icon:` name, with a neutral fallback.
Icon bundleIcon(String? name, {double size = 28}) {
  const known = <String, IconData>{
    'work': Icons.work_outline,
    'flight_takeoff': Icons.flight_takeoff,
    'directions_car': Icons.directions_car_outlined,
    'autorenew': Icons.autorenew,
    'badge': Icons.badge_outlined,
    'family_restroom': Icons.family_restroom_outlined,
    'how_to_reg': Icons.how_to_reg_outlined,
    'description': Icons.description_outlined,
  };
  return Icon(known[name] ?? Icons.folder_open_outlined, size: size);
}

/// Opens an https URL in the system browser; silently ignores a failure so a
/// missing browser never crashes the app.
Future<void> openExternal(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final errorLabel = AppLocalizations.of(context)!.errorNotFound;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) {
    messenger.showSnackBar(SnackBar(content: Text(errorLabel)));
  }
}
