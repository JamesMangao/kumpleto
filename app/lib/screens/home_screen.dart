import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../widgets/shared.dart';
import 'scaffold_with_nav.dart';

/// Home: Hero question, search, Continue items grid, Bundles 2-col grid, and tag chips.
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
    final isDark = theme.brightness == Brightness.dark;
    final isFilipino = Localizations.localeOf(context).languageCode == 'fil';

    // Documents with at least one tick but not finished → "Continue".
    final started = [
      for (final document in documents)
        if (checkedCount(document, progress[document.id] ?? const {}) > 0 &&
            checkedCount(document, progress[document.id] ?? const {}) <
                document.requirements.length)
          document,
    ];

    // Collect sorted unique tags.
    final tags = <String>{
      for (final document in documents) ...document.tags,
      for (final b in bundles) ...b.tags,
    }.toList()..sort();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Hero headline
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            isFilipino
                ? 'Ano ang kailangan mo ngayon?'
                : 'What do you need today?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 26,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),

        // Search Bar (Pill style matching mockup)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: isFilipino
                  ? 'Maghanap ng dokumento o bundle'
                  : 'Search documents or bundles',
              prefixIcon: const Icon(Icons.search, size: 22),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF1B2822)
                  : const Color(0xFFEFF5F2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
              ),
            ),
            onSubmitted: (query) =>
                context.go('/documents?q=${Uri.encodeComponent(query)}'),
          ),
        ),

        const SizedBox(height: 12),

        // Continue section
        if (started.isNotEmpty) ...[
          _SectionHeader(
            title: l10n.homeContinue,
            actionLabel: 'See all >',
            onAction: () => context.go('/documents'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth > 340
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final doc in started)
                      SizedBox(
                        width: cardWidth,
                        child: _ContinueDocCard(
                          document: doc,
                          checked: checkedCount(doc, progress[doc.id] ?? const {}),
                          total: doc.requirements.length,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],

        // Bundles section
        _SectionHeader(
          title: l10n.homeBundles,
          actionLabel: 'See all >',
          onAction: () => context.go('/documents'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth > 340
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final b in bundles)
                    SizedBox(
                      width: cardWidth,
                      child: _BundleGridCard(bundle: b, progress: progress),
                    ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Browse by tag section
        if (tags.isNotEmpty) ...[
          _SectionHeader(title: l10n.homeTags),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                for (final tag in tags)
                  _TagChipButton(
                    tag: tag,
                    onTap: () => context.go(
                      '/documents?tag=${Uri.encodeComponent(tag)}',
                    ),
                  ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // All Documents Link / Footer Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              ),
            ),
            child: ListTile(
              leading: const SquircleIcon(
                icon: Icons.folder_open_outlined,
                size: 38,
                iconSize: 20,
              ),
              title: Text(
                l10n.homeAllDocuments,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/documents'),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContinueDocCard extends StatelessWidget {
  const _ContinueDocCard({
    required this.document,
    required this.checked,
    required this.total,
  });

  final Document document;
  final int checked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fraction = total == 0 ? 0.0 : (checked / total).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/doc/${document.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SquircleIcon(
                    icon: Icons.description_outlined,
                    size: 34,
                    iconSize: 18,
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                document.name.localized(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$checked/$total done',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 4,
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: isDark
                        ? const Color(0xFF24362E)
                        : const Color(0xFFE2ECE7),
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BundleGridCard extends ConsumerWidget {
  const _BundleGridCard({required this.bundle, required this.progress});

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

    return Card(
      elevation: 0,
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
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                bundle.name.localized(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              ProgressLine(
                checked: totals.checked,
                total: totals.total,
                semanticLabel:
                    '${bundle.name.localized(context)}, ${l10n.progressOf(totals.checked, totals.total)}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChipButton extends StatelessWidget {
  const _TagChipButton({required this.tag, required this.onTap});

  final String tag;
  final VoidCallback onTap;

  IconData _iconForTag(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('first') || lower.contains('bago')) return Icons.person_outline;
    if (lower.contains('renew') || lower.contains('bago') || lower.contains('palit')) {
      return Icons.autorenew;
    }
    if (lower.contains('job') || lower.contains('trabaho') || lower.contains('hunt')) {
      return Icons.work_outline;
    }
    if (lower.contains('passport') || lower.contains('travel')) {
      return Icons.flight_takeoff;
    }
    if (lower.contains('driv') || lower.contains('car') || lower.contains('license')) {
      return Icons.directions_car_outlined;
    }
    return Icons.sell_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ActionChip(
      avatar: Icon(
        _iconForTag(tag),
        size: 16,
        color: isDark ? const Color(0xFF8AE0C4) : AppTheme.primaryTeal,
      ),
      label: Text(tag),
      backgroundColor: isDark ? const Color(0xFF192721) : const Color(0xFFEBF5F1),
      side: BorderSide(
        color: isDark ? const Color(0xFF293F34) : const Color(0xFFD4E8E0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: onTap,
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
