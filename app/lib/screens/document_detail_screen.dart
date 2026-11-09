import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../core/deep_links.dart';
import '../core/review_prompt.dart';
import '../core/theme.dart';
import '../data/calendar_export.dart';
import '../data/location.dart';
import '../data/place_tokens.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../widgets/share_qr.dart';
import '../widgets/shared.dart';
import '../widgets/validity.dart';

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
    // The authored copy, before the saved location was filled in.
    final awaitingPlace =
        ref
            .watch(loadedDataProvider)
            .value
            ?.data
            .document(widget.documentId)
            ?.awaitsPlace ??
        false;

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
    final acquired = isDocumentAcquired(document, checked);

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
        actions: [
          IconButton(
            tooltip: l10n.docShareQr,
            icon: const Icon(Icons.qr_code_2_rounded),
            onPressed: () => showChecklistQr(
              context,
              title: document.name.localized(context),
              page: documentPageUri(document.id),
            ),
          ),
          IconButton(
            tooltip: l10n.bundleExportShare,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareDoc(context, l10n, document, agency),
          ),
        ],
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
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
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
                              : l10n.docValidMonths(document.validityMonths!),
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

                  // Documents written for a place the user picks (the barangay
                  // clearance) show which place they were filled for, and how
                  // to change it.
                  if (awaitingPlace) ...[
                    const SizedBox(height: 14),
                    const _PlaceStrip(),
                  ],

                  const SizedBox(height: 16),

                  // Progress Bar & Label
                  ProgressLine(checked: done, total: total),
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

            const SizedBox(height: 12),

            if (document.status == DocStatus.deprecated) ...[
              const SizedBox(height: 14),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3B1515)
                      : AppTheme.statusRedBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF5A2020)
                        : const Color(0xFFF7C8C8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: isDark
                          ? const Color(0xFFF78A8A)
                          : AppTheme.statusRedText,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.deprecatedBanner,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFF78A8A)
                              : AppTheme.statusRedText,
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
                subtitle: l10n.docRequirementsSubtitle,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
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
                subtitle: l10n.docStepsSubtitle,
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

            // Where to apply Card. The office is a map search rather than a
            // fixed coordinate: the data names an agency, not a branch.
            if (document.whereToApply != null)
              SectionCard(
                icon: Icons.location_on_outlined,
                title: l10n.docWhere,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.whereToApply!.localized(context),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => openExternal(
                        context,
                        mapsSearchUri(
                          _mapsQuery(
                            context,
                            document: document,
                            agency: agency,
                            place: ref.watch(savedLocationProvider),
                          ),
                        ),
                      ),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF19332A)
                              : const Color(0xFFE8F4F0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2C5546)
                                : const Color(0xFFC7E2D8),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 18,
                              color: isDark
                                  ? const Color(0xFF5ED6B3)
                                  : AppTheme.primaryTeal,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.docOpenInMaps,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF8CEFD0)
                                    : AppTheme.primaryTeal,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_outward_rounded,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF8CEFD0)
                                  : AppTheme.primaryTeal,
                            ),
                          ],
                        ),
                      ),
                    ),
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
                    if (ref.watch(firstTimeJobseekerProvider) &&
                        const {
                          'nbi-clearance',
                          'police-clearance',
                          'barangay-clearance',
                        }.contains(document.id)) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF132D24)
                              : const Color(0xFFE6F5EE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1F5C48)
                                : const Color(0xFFA2DEC7),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppTheme.primaryTeal,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.docFirstTimeFree,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                subtitle: l10n.docDependsOnSubtitle,
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

            // Bag & Departure Checklist (Before You Go)
            SectionCard(
              icon: Icons.backpack_outlined,
              title: l10n.docBeforeYouGoTitle,
              subtitle: l10n.docBeforeYouGoSubtitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BagCheckItem(
                    icon: Icons.edit_outlined,
                    title: l10n.docBagPenTitle,
                    subtitle: l10n.docBagPenBody,
                  ),
                  _BagCheckItem(
                    icon: Icons.badge_outlined,
                    title: l10n.docBagIdsTitle,
                    subtitle: l10n.docBagIdsBody,
                  ),
                  _BagCheckItem(
                    icon: Icons.photo_camera_front_outlined,
                    title: l10n.docBagPhotosTitle,
                    subtitle: l10n.docBagPhotosBody,
                  ),
                  _BagCheckItem(
                    icon: Icons.payments_outlined,
                    title: l10n.docBagCashTitle,
                    subtitle: l10n.docBagCashBody,
                  ),
                  _BagCheckItem(
                    icon: Icons.folder_open_outlined,
                    title: l10n.docBagEnvelopeTitle,
                    subtitle: l10n.docBagEnvelopeBody,
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141F1A) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF24382F)
                    : const Color(0xFFE2EDE7),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: _AcquiredStickyBar(document: document, isAcquired: acquired),
        ),
      ),
    );
  }

  /// "National Bureau of Investigation, Pacita 1, San Pedro, Laguna" — the
  /// agency plus wherever the reader said they live. Without a saved place the
  /// agency alone still opens the map on its branches.
  String _mapsQuery(
    BuildContext context, {
    required Document document,
    required Agency? agency,
    required SavedLocation? place,
  }) {
    final office =
        agency?.name.localized(context) ?? document.name.localized(context);
    if (place == null || place.isEmpty) return office;
    return '$office, ${place.label}';
  }

  void _shareDoc(
    BuildContext context,
    AppLocalizations l10n,
    Document document,
    Agency? agency,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('📋 ${document.name.localized(context)}');
    if (agency != null) {
      buffer.writeln('Ahensya: ${agency.name.localized(context)}');
    }
    buffer.writeln();
    if (document.summary != null) {
      buffer.writeln('${document.summary!.localized(context)}\n');
    }
    if (document.requirements.isNotEmpty) {
      buffer.writeln('Mga Kailangang Dalhin:');
      for (final req in document.requirements) {
        final opt = req.optional ? ' (Optional)' : '';
        final orig = req.original ? ' (Original)' : '';
        buffer.writeln('• ${req.text.localized(context)}$opt$orig');
      }
      buffer.writeln();
    }
    if (document.steps.isNotEmpty) {
      buffer.writeln('Mga Hakbang:');
      for (var i = 0; i < document.steps.length; i++) {
        buffer.writeln('${i + 1}. ${document.steps[i].localized(context)}');
      }
      buffer.writeln();
    }
    if (document.feeNote != null) {
      buffer.writeln('Bayad / Fees: ${document.feeNote!.localized(context)}');
    }
    buffer.writeln(
      '\nIbinahagi mula sa Kumpleto App (100% Offline, Unofficial Citizen Guide).',
    );
    SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: document.name.localized(context),
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
    await ref
        .read(progressRepositoryProvider)
        .resetDocument(ref.read(currentProfileProvider).id, document.id);
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
            .setChecked(
              ref.read(currentProfileProvider).id,
              document.id,
              requirement.id,
              value ?? false,
            ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.label, required this.bg, required this.fg});

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
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, this.onTap});

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
                  color: isDark
                      ? const Color(0xFF8AE0C4)
                      : AppTheme.primaryTeal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcquiredStickyBar extends ConsumerWidget {
  const _AcquiredStickyBar({required this.document, required this.isAcquired});

  final Document document;
  final bool isAcquired;

  /// Hands the expiry date to the reader's own calendar app as an `.ics` file:
  /// no account, no API, and it keeps working offline.
  Future<void> _addExpiryToCalendar(
    BuildContext context,
    AppLocalizations l10n,
    DateTime acquiredAt,
  ) async {
    final months = document.validityMonths ?? 0;
    final expiry = DateTime(
      acquiredAt.year,
      acquiredAt.month + months,
      acquiredAt.day,
    );
    final messenger = ScaffoldMessenger.of(context);
    await shareExpiryIcs(
      documentId: document.id,
      title: document.name.localized(context),
      expiry: expiry,
      description:
          '${document.name.localized(context)} — ${l10n.docValidUntil('${expiry.day}/${expiry.month}/${expiry.year}')}. Unofficial: confirm with the issuing agency.',
    );
    messenger.showSnackBar(SnackBar(content: Text(l10n.docCalendarReady)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final acquiredAt = ref.watch(acquiredDatesProvider).value?[document.id];
    final validity = isAcquired
        ? validityText(context, l10n, document, acquiredAt)
        : null;

    void toggle() {
      final repository = ref.read(progressRepositoryProvider);
      final profileId = ref.read(currentProfileProvider).id;
      if (isAcquired) {
        repository.unmarkDocumentAcquired(profileId, document.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${document.name.localized(context)}: ${l10n.docUnmarkAcquired}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      repository.markDocumentAcquired(
        profileId,
        document.id,
        document.requirements.map((requirement) => requirement.id),
      );
      // Third finished checklist is the moment the reader has seen enough to
      // judge the app; the prompt is local and appears at most once.
      ReviewPrompt.maybeAsk(context, ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${document.name.localized(context)}: ${l10n.docAcquiredBadge}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // A caption beside the action stops fitting once the reader scales text
    // up: at 200% the label alone is wider than a phone, so a Row overflows
    // instead of shrinking the primary action. Past that point the bar stacks,
    // which keeps every word readable and every target tappable.
    final stacked = MediaQuery.textScalerOf(context).scale(13) > 19;

    final markButton = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: toggle,
      icon: const Icon(Icons.check_rounded, size: 18),
      label: Text(
        l10n.docMarkAcquired,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );

    final unmarkButton = OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark
            ? const Color(0xFFF78A8A)
            : AppTheme.statusRedText,
        side: BorderSide(
          color: isDark ? const Color(0xFF5A2020) : const Color(0xFFF7C8C8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: toggle,
      child: Text(
        l10n.docUnmarkAcquired,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );

    final calendarButton =
        isAcquired &&
            acquiredAt != null &&
            document.validityMonths != null &&
            document.validityMonths! > 0
        ? IconButton(
            tooltip: l10n.docCalendarAction,
            icon: const Icon(
              Icons.event_available_outlined,
              size: 20,
              color: AppTheme.primaryTeal,
            ),
            onPressed: () => _addExpiryToCalendar(context, l10n, acquiredAt),
          )
        : null;

    final editDateButton =
        document.validityMonths != null && document.validityMonths! > 0
        ? IconButton(
            tooltip: l10n.docSetDate,
            icon: const Icon(
              Icons.edit_calendar_outlined,
              size: 20,
              color: AppTheme.primaryTeal,
            ),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: acquiredAt ?? DateTime.now(),
                firstDate: DateTime(2010),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                final profileId = ref.read(currentProfileProvider).id;
                await ref
                    .read(progressRepositoryProvider)
                    .updateAcquiredDate(profileId, document.id, picked);
              }
            },
          )
        : null;

    final checkBadge = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle_rounded,
        color: AppTheme.primaryTeal,
        size: 22,
      ),
    );

    final acquiredNotice = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.docAcquiredNotice,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          validity == null
              ? l10n.docAcquiredBadge
              : '${l10n.docAcquiredBadge} · $validity',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryTeal,
          ),
        ),
      ],
    );

    final alreadyHave = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.docAlreadyHaveTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.docAlreadyHaveSubtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    final Widget content;
    if (isAcquired) {
      content = stacked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    checkBadge,
                    const SizedBox(width: 12),
                    Expanded(child: acquiredNotice),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ?editDateButton,
                    ?calendarButton,
                    if (editDateButton != null || calendarButton != null)
                      const SizedBox(width: 4),
                    Flexible(child: unmarkButton),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                checkBadge,
                const SizedBox(width: 12),
                Expanded(child: acquiredNotice),
                ?editDateButton,
                ?calendarButton,
                const SizedBox(width: 4),
                unmarkButton,
              ],
            );
    } else {
      content = stacked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [alreadyHave, const SizedBox(height: 10), markButton],
            )
          : Row(
              children: [
                Expanded(child: alreadyHave),
                const SizedBox(width: 12),
                markButton,
              ],
            );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: content,
    );
  }
}

/// Which place the entry was filled in for, with the PSGC code the barangay
/// hall recognises, and a shortcut to change it.
///
/// Only shown for documents authored with `{{placeholders}}`: for those the
/// text follows Settings → My location, so the reader needs to see — and be
/// able to correct — the place it followed.
class _PlaceStrip extends ConsumerWidget {
  const _PlaceStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final saved = ref.watch(savedLocationProvider);
    final hasPlace = saved != null && !saved.isEmpty;
    final address = PlaceTokens.of(saved).values['address']!;
    // Only the current 10-digit PSGC is published; a place saved by an older
    // build keeps its name but shows no code rather than a stale format.
    final code = saved?.barangay?.code ?? '';
    final psgc = code.length == 10 ? code : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2E27) : AppTheme.mintContainerLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C4439) : const Color(0xFFD4E8E0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.place_outlined,
              size: 18,
              color: AppTheme.primaryTeal,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPlace
                      ? l10n.docPlaceFor(address.localized(context))
                      : l10n.docPlaceMissingTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                if (hasPlace && psgc.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    l10n.docPlacePsgc(psgc),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else if (!hasPlace) ...[
                  const SizedBox(height: 3),
                  Text(
                    l10n.docPlaceMissingBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/location'),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(
              hasPlace ? l10n.docPlaceChange : l10n.docPlaceSet,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _BagCheckItem extends StatefulWidget {
  const _BagCheckItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  State<_BagCheckItem> createState() => _BagCheckItemState();
}

class _BagCheckItemState extends State<_BagCheckItem> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _checked = !_checked),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _checked,
                activeColor: AppTheme.primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (val) => setState(() => _checked = val ?? false),
              ),
              const SizedBox(width: 4),
              Icon(
                widget.icon,
                size: 20,
                color: _checked
                    ? AppTheme.primaryTeal
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: _checked
                            ? TextDecoration.lineThrough
                            : null,
                        color: _checked
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
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
