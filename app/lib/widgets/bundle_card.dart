import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import 'shared.dart';

/// One life-event bundle in a two-column grid.
///
/// The progress line only appears once the reader has started the bundle: a
/// fresh install showed eight identical "0 of N requirements" bars, which read
/// as "nothing here" rather than "nothing started". Every card also reserves
/// two lines for the title, so a long name no longer makes its neighbour
/// shorter.
class BundleCard extends ConsumerWidget {
  const BundleCard({super.key, required this.bundle, required this.progress});

  final Bundle bundle;
  final Map<String, Set<String>> progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = ref.watch(currentDataProvider);
    final documents = data?.documentsOf(bundle) ?? const [];
    final totals = bundleProgress(documents: documents, progress: progress);
    final started = totals.checked > 0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/bundle/${bundle.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SquircleIcon(
                    icon: bundleIconData(bundle.icon),
                    size: 34,
                    iconSize: 18,
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: Text(
                  bundle.name.localized(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
              if (started) ...[
                const SizedBox(height: 8),
                ProgressLine(
                  checked: totals.checked,
                  total: totals.total,
                  semanticLabel:
                      '${bundle.name.localized(context)}, ${l10n.progressOf(totals.checked, totals.total)}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
