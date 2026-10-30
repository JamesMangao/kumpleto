import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../widgets/shared.dart';

/// Bundle detail: overall progress, the ordered document list with per-document
/// progress, and the bundle's community notes.
class BundleDetailScreen extends ConsumerWidget {
  const BundleDetailScreen({super.key, required this.bundleId});

  final String bundleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.back,
          onPressed: () => context.pop(),
        ),
        title: Text(bundle.name.localized(context)),
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
                      bundleIcon(bundle.icon, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          bundle.name.localized(context),
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      if (bundle.status == DocStatus.draft)
                        const StatusBadge(status: DocStatus.draft),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(bundle.description.localized(context)),
                  const SizedBox(height: 16),
                  ProgressLine(
                    checked: totals.checked,
                    total: totals.total,
                    semanticLabel:
                        '${bundle.name.localized(context)}, ${l10n.progressOf(totals.checked, totals.total)}',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text(
                l10n.bundleDocuments,
                style: theme.textTheme.titleMedium,
              ),
            ),
            for (final document in documents)
              _BundleDocumentTile(document: document, progress: progress),
            if (bundle.notes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text(
                  l10n.bundleNotes,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              for (final note in bundle.notes)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(note.localized(context)),
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

class _BundleDocumentTile extends ConsumerWidget {
  const _BundleDocumentTile({
    required this.document,
    required this.progress,
  });

  final Document document;
  final Map<String, Set<String>> progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final checked = progress[document.id] ?? const <String>{};
    final done = checkedCount(document, checked);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () => context.push('/doc/${document.id}'),
        title: Row(
          children: [
            Expanded(
              child: Text(
                document.name.localized(context),
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: document.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: document.requirements.isEmpty
              ? Text(
                  l10n.statusDraft,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : ProgressLine(
                  checked: done,
                  total: document.requirements.length,
                  showBar: false,
                ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
