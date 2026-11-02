import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../widgets/shared.dart';

/// Document detail screen matching mockup 62d05427-34ed-40a8-8826-0388116eb44f.jpg.
class DocumentDetailScreen extends ConsumerStatefulWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = ref.watch(currentDataProvider);
    final document = data?.document(widget.documentId);

    if (document == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.documentDetailTitle)),
        body: Center(child: Text(l10n.errorNotFound)),
      );
    }

    final agency = data?.agency(document.agencyId);
    final checked = checkedFor(ref, document.id);
    final done = checkedCount(document, checked);
    final total = document.requirements.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.back,
          onPressed: () => context.pop(),
        ),
        title: Text(
          document.name.localized(context),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            // Top Header: Squircle icon, Title, Agency, and Status Badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SquircleIcon(
                        icon: Icons.description_outlined,
                        size: 52,
                        iconSize: 28,
                        radius: 14,
                      ),
                      const SizedBox(width: 14),
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
                                  document.name.localized(context),
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                StatusBadge(
                                  status: document.status,
                                  lastVerified: document.lastVerified,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (agency != null)
                              Text(
                                agency.name.localized(context),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            // Verification age. A verified document already
                            // carries its age inside the StatusBadge above, so
                            // only the unverified states get this line.
                            if (document.status != DocStatus.verified)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: VerificationAge(
                                  lastVerified: document.lastVerified,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Metadata Pills Row (Validity, Apply Online)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (document.validityMonths != null)
                        _MetaPill(
                          icon: Icons.calendar_today_outlined,
                          label: document.validityMonths == 0
                              ? l10n.docValidForever
                              : 'Valid ${document.validityMonths} months',
                        ),
                      if (document.applyOnline != null)
                        _MetaPill(
                          icon: Icons.link,
                          label: l10n.docApplyOnline,
                          onTap: document.applyOnlineUrl != null
                              ? () => openExternal(
                                    context,
                                    Uri.parse(document.applyOnlineUrl!),
                                  )
                              : null,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progress Bar & Label
                  ProgressLine(
                    checked: done,
                    total: total,
                  ),
                  if (document.requirements.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _confirmReset(document),
                        child: Text(
                          l10n.docReset,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (document.status == DocStatus.deprecated) ...[
              const SizedBox(height: 14),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3B1515) : AppTheme.statusRedBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF5A2020) : const Color(0xFFF7C8C8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: isDark ? const Color(0xFFF78A8A) : AppTheme.statusRedText,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.deprecatedBanner,
                        style: TextStyle(
                          color: isDark ? const Color(0xFFF78A8A) : AppTheme.statusRedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Requirements Section Card
            if (document.requirements.isNotEmpty)
              SectionCard(
                icon: Icons.checklist_rounded,
                title: l10n.docRequirements,
                subtitle: 'Bring these documents when you apply.',
                child: Column(
                  children: [
                    for (final req in document.requirements)
                      _RequirementItem(
                        document: document,
                        requirement: req,
                        checked: checked.contains(req.id),
                      ),
                  ],
                ),
              ),

            // Empty state notice if requirements and steps are empty
            if (document.requirements.isEmpty && document.steps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l10n.docEmptyNotice)),
                      ],
                    ),
                  ),
                ),
              ),

            // Steps Section Card
            if (document.steps.isNotEmpty)
              SectionCard(
                icon: Icons.format_list_numbered_rounded,
                title: l10n.docSteps,
                subtitle: 'Follow these steps to get your ${document.name.localized(context)}.',
                child: Column(
                  children: [
                    for (var i = 0; i < document.steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryTeal,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                document.steps[i].localized(context),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // Where to apply Card
            if (document.whereToApply != null)
              SectionCard(
                icon: Icons.location_on_outlined,
                title: l10n.docWhere,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.whereToApply!.localized(context),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                  ],
                ),
              ),

            // Fee & Processing Notes
            if (document.feeNote != null || document.processingNote != null)
              SectionCard(
                icon: Icons.payments_outlined,
                title: l10n.docFees,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (document.feeNote != null)
                      Text(
                        document.feeNote!.localized(context),
                        style: theme.textTheme.bodyMedium,
                      ),
                    if (document.processingNote != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${l10n.docProcessing}: ${document.processingNote!.localized(context)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Depends on Card
            if (document.dependsOn.isNotEmpty)
              SectionCard(
                icon: Icons.link,
                title: l10n.docDependsOn,
                subtitle: 'May require these documents first.',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in document.dependsOn)
                      ActionChip(
                        avatar: const Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: AppTheme.primaryTeal,
                        ),
                        label: Text(
                          data?.document(id)?.name.localized(context) ?? id,
                        ),
                        backgroundColor: isDark
                            ? const Color(0xFF1B2A23)
                            : const Color(0xFFEAF5F1),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF2E453A)
                              : const Color(0xFFD4E8E0),
                        ),
                        onPressed: () => context.push('/doc/$id'),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // Bottom Actions: Open official source, Report outdated info, Reset checklist
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (document.sourceUrl != null)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text(l10n.docOfficialSource),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => openExternal(
                          context,
                          Uri.parse(document.sourceUrl!),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.warning_amber_rounded, size: 18),
                      label: Text(l10n.docReportOutdated),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF3B5649)
                              : const Color(0xFF0E6B58),
                          width: 1.5,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => openExternal(
                        context,
                        reportOutdatedUri(
                          documentId: document.id,
                          documentName: document.name.en,
                          appVersion: _appVersion,
                          dataVersion: data?.dataVersion ?? 'unknown',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: document.requirements.isEmpty
                        ? null
                        : () => _confirmReset(document),
                    child: Text(
                      l10n.docReset,
                      style: const TextStyle(
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.primaryTeal,
                      ),
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

  Future<void> _confirmReset(Document document) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.docResetTitle),
        content: Text(l10n.docResetMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(progressRepositoryProvider).resetDocument(document.id);
  }
}

class _RequirementItem extends ConsumerWidget {
  const _RequirementItem({
    required this.document,
    required this.requirement,
    required this.checked,
  });

  final Document document;
  final Requirement requirement;
  final bool checked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final badges = <Widget>[
      if (requirement.original)
        _BadgePill(
          label: l10n.docOriginal,
          bg: isDark ? const Color(0xFF1E332A) : const Color(0xFFE2F0EB),
          fg: isDark ? const Color(0xFF8AE0C4) : AppTheme.primaryTeal,
        ),
      if (requirement.photocopies > 0)
        _BadgePill(
          label: l10n.docPhotocopies(requirement.photocopies),
          bg: isDark ? const Color(0xFF1E332A) : const Color(0xFFE2F0EB),
          fg: isDark ? const Color(0xFF8AE0C4) : AppTheme.primaryTeal,
        ),
      if (requirement.optional)
        _BadgePill(
          label: l10n.docOptional,
          bg: isDark ? const Color(0xFF26332D) : const Color(0xFFEFF3F1),
          fg: isDark ? const Color(0xFFA1B3AB) : const Color(0xFF677E74),
        ),
    ];

    return Theme(
      data: Theme.of(context).copyWith(
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTheme.primaryTeal;
            }
            return Colors.transparent;
          }),
          side: const BorderSide(color: Color(0xFFB0C4BC), width: 1.6),
        ),
      ),
      child: CheckboxListTile(
        value: checked,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        title: Text(
          requirement.text.localized(context),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            decoration: checked ? TextDecoration.lineThrough : null,
            color: checked
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (requirement.note != null) ...[
              const SizedBox(height: 4),
              Text(
                requirement.note!.localized(context),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: badges),
            ],
          ],
        ),
        onChanged: (value) => ref
            .read(progressRepositoryProvider)
            .setChecked(document.id, requirement.id, value ?? false),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D2E27) : const Color(0xFFEAF5F1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2C4439) : const Color(0xFFD4E8E0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryTeal),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF8AE0C4) : AppTheme.primaryTeal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
