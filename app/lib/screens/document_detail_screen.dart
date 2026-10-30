import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/constants.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../widgets/shared.dart';

/// Full document detail: header chips, requirements checklist, steps,
/// fee/processing notes, official source and report links, progress + reset.
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.back,
          onPressed: () => context.pop(),
        ),
        title: Text(document.name.localized(context)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          document.name.localized(context),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      StatusBadge(status: document.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (agency != null)
                    Text(
                      agency.name.localized(context),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      VerificationAge(lastVerified: document.lastVerified),
                      _ValidityChip(document: document),
                      if (document.applyOnline != null)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                            document.applyOnline == true
                                ? Icons.public
                                : Icons.apartment,
                            size: 16,
                          ),
                          label: Text(l10n.docApplyOnline),
                        ),
                    ],
                  ),
                  if (document.summary != null) ...[
                    const SizedBox(height: 12),
                    Text(document.summary!.localized(context)),
                  ],
                ],
              ),
            ),
            if (document.status == DocStatus.deprecated) ...[
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.block,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.deprecatedBanner,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SectionCard(
                title: l10n.homeContinue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProgressLine(checked: done, total: document.requirements.length),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.restart_alt),
                            label: Text(l10n.docReset),
                            onPressed: document.requirements.isEmpty
                                ? null
                                : () => _confirmReset(document),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (document.dependsOn.isNotEmpty) ...[
              SectionCard(
                title: l10n.docDependsOn,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in document.dependsOn)
                      ActionChip(
                        label: Text(
                          data?.document(id)?.name.localized(context) ?? id,
                        ),
                        onPressed: () => context.push('/doc/$id'),
                      ),
                  ],
                ),
              ),
            ],
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l10n.docEmptyNotice)),
                      ],
                    ),
                  ),
                ),
              ),
            if (document.requirements.isNotEmpty)
              SectionCard(
                title: l10n.docRequirements,
                child: Column(
                  children: [
                    for (final requirement in document.requirements)
                      _RequirementTile(
                        document: document,
                        requirement: requirement,
                        checked: checked.contains(requirement.id),
                      ),
                  ],
                ),
              ),
            if (document.steps.isNotEmpty)
              SectionCard(
                title: l10n.docSteps,
                child: Column(
                  children: [
                    for (var i = 0; i < document.steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondaryContainer,
                              child: Text(
                                '${i + 1}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(document.steps[i].localized(context)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            if (document.feeNote != null ||
                document.processingNote != null ||
                document.whereToApply != null)
              SectionCard(
                title: l10n.docFees,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (document.feeNote != null) ...[
                      Text(
                        document.feeNote!.localized(context),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (document.processingNote != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${l10n.docProcessing}: ',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(document.processingNote!.localized(context)),
                    ],
                    if (document.whereToApply != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${l10n.docWhere}: ',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(document.whereToApply!.localized(context)),
                    ],
                  ],
                ),
              ),
            if (document.notes.isNotEmpty)
              SectionCard(
                title: l10n.docNotes,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final note in document.notes) ...[
                      Text(note.localized(context)),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (document.sourceUrl != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_new),
                        label: Text(l10n.docOfficialSource),
                        onPressed: () =>
                            openExternal(context, Uri.parse(document.sourceUrl!)),
                      ),
                    ),
                  if (document.sourceUrl != null &&
                      document.applyOnlineUrl != null)
                    const SizedBox(width: 8),
                  if (document.applyOnlineUrl != null)
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.launch),
                        label: Text(l10n.docApplyOnline),
                        onPressed: () => openExternal(
                          context,
                          Uri.parse(document.applyOnlineUrl!),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (document.sourceUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(l10n.docReportOutdated),
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

class _RequirementTile extends ConsumerWidget {
  const _RequirementTile({
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
    final theme = Theme.of(context);
    final badges = <Widget>[
      if (requirement.original)
        _Badge(label: l10n.docOriginal, color: theme.colorScheme.primary),
      if (requirement.photocopies > 0)
        _Badge(
          label: l10n.docPhotocopies(requirement.photocopies),
          color: theme.colorScheme.tertiary,
        ),
      if (requirement.optional)
        _Badge(
          label: l10n.docOptional,
          color: theme.colorScheme.surfaceContainerHighest,
          foreground: theme.colorScheme.onSurfaceVariant,
        ),
    ];

    return CheckboxListTile(
      value: checked,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(requirement.text.localized(context)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (requirement.note != null) ...[
            const SizedBox(height: 4),
            Text(
              requirement.note!.localized(context),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.foreground,
  });

  final String label;
  final Color color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground ?? color,
        ),
      ),
    );
  }
}

class _ValidityChip extends StatelessWidget {
  const _ValidityChip({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final months = document.validityMonths;
    if (months == null) return const SizedBox.shrink();
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: const Icon(Icons.event_available, size: 16),
      label: Text(
        months == 0 ? l10n.docValidForever : l10n.docValidMonths(months),
      ),
    );
  }
}
