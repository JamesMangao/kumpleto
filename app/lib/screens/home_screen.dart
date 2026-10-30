import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../widgets/shared.dart';
import 'scaffold_with_nav.dart';

/// Home: search, bundles with aggregate progress, a "Continue" row for
/// documents the user already started, and tag chips.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final data = ref.watch(dataBundleProvider);
    final progress = ref.watch(progressProvider).value ?? const {};

    return Scaffold(
      appBar: unofficialAppBar(context, l10n.appTitle),
      body: SafeArea(
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _Message(
            title: l10n.errorNotFound,
            body: '$error',
            actionLabel: l10n.retry,
            onAction: () => ref.invalidate(loadedDataProvider),
          ),
          // Empty: no bundled data at all (never expected on a real device).
          data: (bundle) => bundle.documents.isEmpty
              ? _Message(title: l10n.homeEmptyTitle, body: l10n.homeEmptyBody)
              : _HomeBody(
                  bundle: bundle,
                  progress: progress,
                  searchController: _searchController,
                  l10n: l10n,
                  theme: theme,
                ),
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({
    required this.bundle,
    required this.progress,
    required this.searchController,
    required this.l10n,
    required this.theme,
  });

  final DataBundle bundle;
  final Map<String, Set<String>> progress;
  final TextEditingController searchController;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentsProvider);
    final bundles = ref.watch(bundlesProvider);

    // Documents with at least one tick but not finished → "Continue".
    final started = [
      for (final document in documents)
        if (checkedCount(document, progress[document.id] ?? const {}) > 0 &&
            checkedCount(document, progress[document.id] ?? const {}) <
                document.requirements.length)
        document,
    ];

    final tags = <String>{
      for (final document in documents) ...document.tags,
      for (final bundle in bundles) ...bundle.tags,
    }.toList()..sort();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.homeSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onSubmitted: (query) => context.go('/documents?q=${Uri.encodeComponent(query)}'),
          ),
        ),
        if (started.isNotEmpty) ...[
          _SectionTitle(l10n.homeContinue),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: started.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final document = started[index];
                final checked = checkedCount(
                  document,
                  progress[document.id] ?? const {},
                );
                return SizedBox(
                  width: 240,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('/doc/${document.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              document.name.localized(context),
                              style: theme.textTheme.titleSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            ProgressLine(
                              checked: checked,
                              total: document.requirements.length,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        _SectionTitle(l10n.homeBundles),
        for (final bundle in bundles) _BundleCard(bundle: bundle, progress: progress),
        if (tags.isNotEmpty) ...[
          _SectionTitle(l10n.homeTags),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tags)
                  ActionChip(
                    label: Text(tag),
                    onPressed: () =>
                        context.go('/documents?tag=${Uri.encodeComponent(tag)}'),
                  ),
              ],
            ),
          ),
        ],
        _SectionTitle(l10n.homeAllDocuments),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(l10n.homeAllDocuments),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/documents'),
            ),
          ),
        ),
      ],
    );
  }
}

class _BundleCard extends ConsumerWidget {
  const _BundleCard({required this.bundle, required this.progress});

  final Bundle bundle;
  final Map<String, Set<String>> progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final data = ref.watch(currentDataProvider);
    if (data == null) return const SizedBox.shrink();
    final documents = data.documentsOf(bundle);
    final totals = bundleProgress(documents: documents, progress: progress);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/bundle/${bundle.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bundleIcon(bundle.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bundle.name.localized(context),
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          if (bundle.status == DocStatus.draft)
                            const StatusBadge(status: DocStatus.draft),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bundle.description.localized(context),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      ProgressLine(
                        checked: totals.checked,
                        total: totals.total,
                        semanticLabel:
                            '${bundle.name.localized(context)}, ${l10n.progressOf(totals.checked, totals.total)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
