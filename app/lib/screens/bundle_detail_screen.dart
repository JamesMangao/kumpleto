import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import '../data/checklist_export.dart';
import '../data/estimate.dart';
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

    final isFirstTimeJobseeker = ref.watch(firstTimeJobseekerProvider);
    final isJobHuntBundle =
        bundle.id == 'job-hunt-pack' || bundle.tags.contains('job-hunt');

    final documents = data.documentsOf(bundle);
    final totals = bundleProgress(documents: documents, progress: progress);
    final rawEstimate = bundleEstimate(documents);

    // Apply RA 11261 waiver if first-time jobseeker toggle is ON
    final estimate = (isFirstTimeJobseeker && isJobHuntBundle)
        ? BundleEstimate(
            documentCount: rawEstimate.documentCount,
            feeCovered: rawEstimate.feeCovered,
            feeMin: 0,
            feeMax: 0,
            daysCovered: rawEstimate.daysCovered,
            daysMin: rawEstimate.daysMin,
            daysMax: rawEstimate.daysMax,
          )
        : rawEstimate;

    var completedDocs = 0;
    for (final doc in documents) {
      if (isDocumentAcquired(doc, progress[doc.id] ?? const {})) {
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
        actions: [
          PopupMenuButton<_ExportAction>(
            tooltip: l10n.bundleExportMenu,
            icon: const Icon(Icons.ios_share),
            onSelected: (action) => switch (action) {
              _ExportAction.share => _share(
                context,
                l10n,
                _content(context, l10n, bundle, documents, data),
              ),
              _ExportAction.print => _print(
                context,
                l10n,
                _content(context, l10n, bundle, documents, data),
              ),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ExportAction.share,
                child: Text(l10n.bundleExportShare),
              ),
              PopupMenuItem(
                value: _ExportAction.print,
                child: Text(l10n.bundleExportPrint),
              ),
            ],
          ),
        ],
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
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
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
                            : (documents.isNotEmpty
                                  ? documents.first.agencyId
                                  : 'Agency'),
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

                  // What the whole bundle costs and how long it takes, from the
                  // numbers the entries themselves state.
                  if (estimate.hasFee || estimate.daysIsComplete) ...[
                    const SizedBox(height: 10),
                    _EstimateCard(estimate: estimate),
                  ],

                  // First-Time Jobseeker (RA 11261) benefit card & toggle
                  // Exclusive only to Job Hunt / Employment packs
                  if (isJobHuntBundle) ...[
                    const SizedBox(height: 10),
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isFirstTimeJobseeker
                              ? AppTheme.primaryTeal
                              : (isDark
                                    ? AppTheme.borderDark
                                    : AppTheme.borderLight),
                          width: isFirstTimeJobseeker ? 1.5 : 1.0,
                        ),
                      ),
                      color: isFirstTimeJobseeker
                          ? (isDark
                                ? const Color(0xFF132821)
                                : const Color(0xFFE8F5F1))
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              color: isFirstTimeJobseeker
                                  ? AppTheme.primaryTeal
                                  : (isDark ? Colors.white70 : Colors.black87),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'First-Time Jobseeker? (RA 11261)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isFirstTimeJobseeker
                                          ? AppTheme.primaryTeal
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isFirstTimeJobseeker
                                        ? 'Libre ang bayad sa Barangay, Police, at NBI Clearances! (Waived fees applied sa lahat ng docs)'
                                        : 'I-on para maging libre ang clearances sa buong Job Hunt pack.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isFirstTimeJobseeker,
                              activeThumbColor: AppTheme.primaryTeal,
                              onChanged: (val) => ref
                                  .read(firstTimeJobseekerProvider.notifier)
                                  .set(val),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark
                            ? AppTheme.borderDark
                            : AppTheme.borderLight,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? AppTheme.borderDark
                          : AppTheme.borderLight,
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

/// The two things a reader does with a bundle away from the phone: send it to
/// somebody, or print it.
enum _ExportAction { share, print }

/// Wraps the bundle in the one structure both exports read from.
ChecklistContent _content(
  BuildContext context,
  AppLocalizations l10n,
  Bundle bundle,
  List<Document> documents,
  DataBundle data,
) {
  final languageCode = Localizations.localeOf(context).languageCode;
  final date = MaterialLocalizations.of(context)
      .formatShortDate(DateTime.now());
  return ChecklistContent(
    l10n: l10n,
    languageCode: languageCode,
    bundle: bundle,
    documents: documents,
    agencyOf: (document) =>
        data.agency(document.agencyId)?.name.pick(languageCode) ??
        document.agencyId,
    footer: l10n.bundleExportFooter(date),
  );
}

Future<void> _share(
  BuildContext context,
  AppLocalizations l10n,
  ChecklistContent content,
) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: checklistText(content),
        subject: content.bundle.name.pick(content.languageCode),
      ),
    );
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.bundleExportFailed)));
  }
}

Future<void> _print(
  BuildContext context,
  AppLocalizations l10n,
  ChecklistContent content,
) async {
  try {
    final bytes = await checklistPdf(content);
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: '${content.bundle.id}-checklist',
    );
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.bundleExportFailed)));
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
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
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

/// "₱1,105–₱1,355 · About 7–12 working days in total", with the coverage that
/// makes the number honest (how many entries stated one).
class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.estimate});

  final BundleEstimate estimate;

  String? _feeText(AppLocalizations l10n) {
    if (!estimate.hasFee) return null;
    if (estimate.isFree) return l10n.bundleEstimateFeeFree;
    if (estimate.feeMin == estimate.feeMax) {
      return l10n.bundleEstimateFeeSingle(groupedAmount(estimate.feeMin));
    }
    return l10n.bundleEstimateFeeRange(
      groupedAmount(estimate.feeMin),
      groupedAmount(estimate.feeMax),
    );
  }

  String? _timeText(AppLocalizations l10n) {
    if (!estimate.daysIsComplete) return null;
    if (estimate.isSameDay) return l10n.bundleEstimateTimeSameDay;
    if (estimate.daysMin == estimate.daysMax) {
      return l10n.bundleEstimateTimeSingle(estimate.daysMin);
    }
    return l10n.bundleEstimateTimeRange(estimate.daysMin, estimate.daysMax);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fee = _feeText(l10n);
    final time = _timeText(l10n);

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: AppTheme.primaryTeal,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.bundleEstimateTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (fee != null) ...[
              const SizedBox(height: 6),
              Text(
                fee,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
            if (time != null) ...[
              const SizedBox(height: 2),
              Text(
                time,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (estimate.feeIsPartial) ...[
              const SizedBox(height: 6),
              Text(
                l10n.bundleEstimateCaption(
                  estimate.feeCovered,
                  estimate.documentCount,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ],
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
    final acquired = isDocumentAcquired(document, checked);

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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
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
              if (acquired) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 11,
                        color: AppTheme.primaryTeal,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.docAcquiredBadge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (total > 0) ...[
                const SizedBox(height: 4),
                ProgressLine(checked: done, total: total, showBar: true),
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
          trailing: const Icon(
            Icons.chevron_right,
            size: 20,
            color: Colors.grey,
          ),
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
