import 'package:flutter/material.dart';
import 'package:kumpleto_data_contract/data_contract.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/localized_text.dart';
import '../models/models.dart';

extension LocalizedTextX on LocalizedText {
  /// Picks the string for the current locale (`fil` → Filipino, else English).
  String localized(BuildContext context) =>
      pick(Localizations.localeOf(context).languageCode);
}

/// Brand logo widget for Kumpleto: uses official asset with graceful vector fallback.
class KumpletoLogo extends StatelessWidget {
  const KumpletoLogo({
    super.key,
    this.size = 40,
    this.radius,
  });

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? (size * 0.24);
    return ClipRRect(
      borderRadius: BorderRadius.circular(effectiveRadius),
      child: Image.asset(
        'assets/logo/app-icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal,
            borderRadius: BorderRadius.circular(effectiveRadius),
          ),
          child: Center(
            child: Icon(
              Icons.task_alt,
              color: Colors.white,
              size: size * 0.65,
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal Kumpleto logo lockup.
class KumpletoHorizontalLogo extends StatelessWidget {
  const KumpletoHorizontalLogo({
    super.key,
    this.height = 32,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/horizontal-logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KumpletoLogo(size: height),
          const SizedBox(width: 8),
          const Text(
            'Kumpleto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical Kumpleto logo lockup.
class KumpletoVerticalLogo extends StatelessWidget {
  const KumpletoVerticalLogo({
    super.key,
    this.height = 96,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/vertical-logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KumpletoLogo(size: height * 0.7),
          const SizedBox(height: 8),
          const Text(
            'Kumpleto',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable squircle icon container with pale mint background and deep teal icon.
class SquircleIcon extends StatelessWidget {
  const SquircleIcon({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 22,
    this.backgroundColor,
    this.iconColor,
    this.radius = 12,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? const Color(0xFF1E332B) : AppTheme.mintContainer);
    final fg = iconColor ?? (isDark ? const Color(0xFF8AE0C4) : AppTheme.primaryTeal);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: fg,
      ),
    );
  }
}

/// Progress line with localized text and rounded teal progress bar.
class ProgressLine extends StatelessWidget {
  const ProgressLine({
    super.key,
    required this.checked,
    required this.total,
    this.showBar = true,
    this.semanticLabel,
    this.customLabel,
  });

  final int checked;
  final int total;
  final bool showBar;
  final String? semanticLabel;
  final String? customLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final fraction = total == 0 ? 0.0 : (checked / total).clamp(0.0, 1.0);
    final text = customLabel ?? l10n.progressOf(checked, total);

    return Semantics(
      container: true,
      label: semanticLabel ?? text,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (showBar) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 6,
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF24362E)
                      : const Color(0xFFE2ECE7),
                  color: AppTheme.primaryTeal,
                  semanticsLabel: semanticLabel ?? text,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Verification status pill badge matching the design system mockups.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.lastVerified,
  });

  final DocStatus status;
  final DateTime? lastVerified;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String label;
    final Color bg;
    final Color fg;
    final IconData icon;

    if (status == DocStatus.verified) {
      if (lastVerified != null) {
        final age = DateTime.now().difference(lastVerified!).inDays;
        final tier = verificationTier(lastVerified: lastVerified!, now: DateTime.now());
        label = l10n.docVerifiedDays(age);
        switch (tier) {
          case VerificationTier.fresh:
            bg = isDark ? const Color(0xFF133824) : AppTheme.statusGreenBg;
            fg = isDark ? const Color(0xFF75E6A3) : AppTheme.statusGreenText;
            icon = Icons.check_circle;
          case VerificationTier.stale:
            bg = isDark ? const Color(0xFF382A12) : AppTheme.statusAmberBg;
            fg = isDark ? const Color(0xFFF7BD68) : AppTheme.statusAmberText;
            icon = Icons.check_circle;
          case VerificationTier.overdue:
            bg = isDark ? const Color(0xFF3B1515) : AppTheme.statusRedBg;
            fg = isDark ? const Color(0xFFF78A8A) : AppTheme.statusRedText;
            icon = Icons.check_circle;
          case VerificationTier.unknown:
            bg = isDark ? const Color(0xFF23302A) : AppTheme.statusGrayBg;
            fg = isDark ? const Color(0xFFA1B3AB) : AppTheme.statusGrayText;
            icon = Icons.check_circle;
        }
      } else {
        label = l10n.statusVerified;
        bg = isDark ? const Color(0xFF133824) : AppTheme.statusGreenBg;
        fg = isDark ? const Color(0xFF75E6A3) : AppTheme.statusGreenText;
        icon = Icons.check_circle;
      }
    } else if (status == DocStatus.deprecated) {
      label = l10n.statusDeprecated;
      bg = isDark ? const Color(0xFF3B1515) : AppTheme.statusRedBg;
      fg = isDark ? const Color(0xFFF78A8A) : AppTheme.statusRedText;
      icon = Icons.warning_amber_rounded;
    } else {
      label = l10n.statusDraft;
      bg = isDark ? const Color(0xFF23302A) : AppTheme.statusGrayBg;
      fg = isDark ? const Color(0xFFA1B3AB) : AppTheme.statusGrayText;
      icon = Icons.radio_button_unchecked;
    }

    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Verification age: green ≤ 90 days, amber 91–180, red > 180, grey when the
/// entry was never verified.
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
    final now = DateTime.now();
    final age = now.difference(lastVerified).inDays;
    final tier = verificationTier(lastVerified: lastVerified, now: now);
    final color = switch (tier) {
      VerificationTier.fresh => const Color(0xFF2E7D32),
      VerificationTier.stale => const Color(0xFFB26A00),
      VerificationTier.overdue => const Color(0xFFC62828),
      VerificationTier.unknown => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Semantics(
      container: true,
      label: l10n.docVerifiedDays(age),
      excludeSemantics: true,
      child: Text(
        l10n.docVerifiedDays(age),
        style: textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Circular progress card used in Bundle detail screen.
class CircularProgressCard extends StatelessWidget {
  const CircularProgressCard({
    super.key,
    required this.checked,
    required this.total,
    this.title = "You're making progress!",
    this.subtitle,
  });

  final int checked;
  final int total;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : (checked / total).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: fraction,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      backgroundColor: isDark
                          ? const Color(0xFF24362E)
                          : const Color(0xFFE2ECE7),
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$checked of $total',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'documents\nready',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          height: 1.1,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle ?? 'Complete all $total documents to finish this bundle.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom rounded square checkbox matching the mockup design with 48dp target.
class CustomCheckbox extends StatelessWidget {
  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? AppTheme.primaryTeal : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value
                    ? AppTheme.primaryTeal
                    : const Color(0xFFB0C4BC),
                width: 1.8,
              ),
            ),
            child: value
                ? const Icon(
                    Icons.check,
                    size: 17,
                    color: Colors.white,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Modern pill-shaped chip for filters, metadata, and tags.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isSelected
        ? AppTheme.primaryTeal
        : (isDark ? const Color(0xFF1B2721) : Colors.white);
    final border = isSelected
        ? AppTheme.primaryTeal
        : (isDark ? const Color(0xFF2C3E35) : const Color(0xFFE2EBE5));
    final fg = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFFE2EBE6) : const Color(0xFF1F332A));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Titled card used for detail sections (requirements, steps, notes…).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.icon,
    this.actions,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  SquircleIcon(icon: icon!, size: 36, iconSize: 18),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        semanticsLabel: title,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ...?actions,
              ],
            ),
            const SizedBox(height: 14),
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

/// Helper to get IconData for a bundle icon name.
IconData bundleIconData(String? name) {
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
  return known[name] ?? Icons.folder_open_outlined;
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
