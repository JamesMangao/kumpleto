import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../widgets/shared.dart';

/// Bundle detail matching mockup 167c2552-fde9-42a5-8955-b80663ec4b74.jpg.
class BundleDetailScreen extends ConsumerWidget {
  const BundleDetailScreen({super.key, required this.bundleId});

  final String bundleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = ref.watch(currentDataProvider);
    final bundle = data?.bundle(bundleId);
    final progress =
        ref.watch(progressProvider).value ?? const <String, Set<String>>{};

    if (bundle == null || data == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.bundleDetailTitle)),
        body: Center(child: Text(l10n.errorNotFound)),
      );
    }

    final documents = data.documentsOf(bundle);
    final totals = bundleProgress(documents: documents, progress: progress);

    var completedDocs = 0;
    for (final doc in documents) {
      final checked = checkedCount(doc, progress[doc.id] ?? const {});
      if (doc.requirements.isNotEmpty && checked >= doc.requirements.length) {
        completedDocs++;
      }
    }

    final agenciesCount = {for (final d in documents) d.agencyId}.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.back,
          onPressed: () => context.pop(),
        ),
        title: Text(
          bundle.name.localized(context),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // Top Header: Squircle Icon, Title, Description, and Badges
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SquircleIcon(
                        icon: bundleIconData(bundle.icon),
                        size: 44,
                        iconSize: 24,
                        radius: 12,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  bundle.name.localized(context),
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (bundle.status == DocStatus.draft)
                                  const StatusBadge(status: DocStatus.draft),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bundle.description.localized(context),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Header Badges Row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _BadgeChip(
                        icon: Icons.description_outlined,
                        label: '${documents.length} documents',
                      ),
                      _BadgeChip(
                        icon: Icons.account_balance_outlined,
                        label: agenciesCount > 1
                            ? 'Multiple agencies'
                            : (documents.isNotEmpty ? documents.first.agencyId : 'Agency'),
                      ),
                      for (final tag in bundle.tags)
                        _BadgeChip(
                          icon: Icons.person_outline,
                          label: tag.replaceAll('-', ' '),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Compact Circular Progress Card
                  _CompactProgressCard(
                    checked: completedDocs,
                    total: documents.length,
                    totals: totals,
                    bundleName: bundle.name.localized(context),
                  ),
                ],
              ),
            ),

            // Documents in this bundle Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Text(
                l10n.bundleDocuments,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            // Ordered document items with numbered badges
            for (var i = 0; i < documents.length; i++)
              _BundleDocumentModernTile(
                index: i + 1,
                document: documents[i],
                progress: progress,
              ),

            // Tip / Community Notes Section
            if (bundle.notes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(
                  l10n.bundleNotes,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              for (final note in bundle.notes)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SquircleIcon(
                            icon: Icons.lightbulb_outline,
                            size: 36,
                            iconSize: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              note.localized(context),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      children: [
                        SquircleIcon(
                          icon: Icons.lightbulb_outline,
                          size: 36,
                          iconSize: 18,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'First-time jobseeker?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Some fees may be waived. Check the official source.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactProgressCard extends StatelessWidget {
  const _CompactProgressCard({
    required this.checked,
    required this.total,
    required this.totals,
    required this.bundleName,
  });

  final int checked;
  final int total;
  final ({int checked, int total}) totals;
  final String bundleName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fraction = total == 0 ? 0.0 : (checked / total).clamp(0.0, 1.0);

    return Semantics(
      label: '$bundleName, ${l10n.progressOf(totals.checked, totals.total)}',
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: fraction,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        backgroundColor: isDark
                            ? const Color(0xFF24362E)
                            : const Color(0xFFE2ECE7),
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$checked of $total',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            const Text(
                              'ready',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checked == total && total > 0
                          ? 'All documents ready!'
                          : "You're making progress!",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Complete all $total documents to finish this bundle.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BundleDocumentModernTile extends ConsumerWidget {
  const _BundleDocumentModernTile({
    required this.index,
    required this.document,
    required this.progress,
  });

  final int index;
  final Document document;
  final Map<String, Set<String>> progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = ref.watch(currentDataProvider);
    final checked = checkedFor(ref, document.id);
    final done = checkedCount(document, checked);
    final total = document.requirements.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
        ),
        child: ListTile(
          onTap: () => context.push('/doc/${document.id}'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              const SquircleIcon(
                icon: Icons.description_outlined,
                size: 38,
                iconSize: 20,
                radius: 10,
              ),
              Positioned(
                top: -3,
                left: -3,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryTeal,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          title: Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                document.name.localized(context),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              StatusBadge(
                status: document.status,
                lastVerified: document.lastVerified,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                data?.agency(document.agencyId)?.name.localized(context) ??
                    document.agencyId,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              if (total > 0) ...[
                const SizedBox(height: 4),
                ProgressLine(
                  checked: done,
                  total: total,
                  showBar: true,
                ),
              ] else
                Text(
                  l10n.statusDraft,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2A23) : const Color(0xFFEAF5F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2E453A) : const Color(0xFFD4E8E0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryTeal),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF8AE0C4) : AppTheme.primaryTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
