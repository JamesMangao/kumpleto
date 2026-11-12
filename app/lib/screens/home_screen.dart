import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/categories.dart';
import '../core/theme.dart';
import '../data/profiles.dart';
import '../data/providers.dart';
import '../data/update_service.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../widgets/bundle_card.dart';
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

  /// True once the "new data" notice has been shown for this launch.
  bool _announcedUpdate = false;

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

    // A feed check that replaced the data happened without the reader doing
    // anything, so say it once. Silent until `main()` reports an update.
    if (!_announcedUpdate && ref.watch(lastUpdateProvider) is UpdateAccepted) {
      _announcedUpdate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final version = ref.read(dataBundleProvider).value?.dataVersion;
        if (version == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.dataUpdatedNotice(version))),
        );
      });
    }

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

/// How many bundles Home shows before "See all >". Six fills three rows and
/// leaves no card stranded on its own.
const homeBundleLimit = 6;

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
    final savedLocation = ref.watch(savedLocationProvider);
    final data = ref.watch(currentDataProvider);
    final documents = ref.watch(documentsProvider);
    final bundles = ref.watch(bundlesProvider);
    final isDark = theme.brightness == Brightness.dark;
    final isFilipino = Localizations.localeOf(context).languageCode == 'fil';

    // The popular-document chips are ids in the code and names in the feed, so
    // they follow the language of the data.
    final popularDocuments = [
      for (final id in popularDocumentIds) ?data?.document(id),
    ];

    // Documents with at least one tick but not finished → "Continue".
    final started = [
      for (final document in documents)
        if (checkedCount(document, progress[document.id] ?? const {}) > 0 &&
            checkedCount(document, progress[document.id] ?? const {}) <
                document.requirements.length)
          document,
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Hero headline, with whose checklist this is on the right.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: _ProfileChip(),
              ),
            ],
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
                  ? const Color(0xFF17223A)
                  : const Color(0xFFEFF5F2),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
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
                borderSide: BorderSide(
                  color: accentColorOf(context),
                  width: 1.5,
                ),
              ),
            ),
            onSubmitted: (query) =>
                context.go('/documents?q=${Uri.encodeComponent(query)}'),
          ),
        ),

        // The four documents people most often open one at a time. Chips, not
        // cards: one tap from the search field to the checklist.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final doc in popularDocuments)
                  Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Icon(
                          popularDocumentIcons[doc.id] ??
                              Icons.description_outlined,
                          size: 16,
                          color: accentColorOf(context),
                        ),
                        label: Text(doc.name.localized(context)),
                        backgroundColor: isDark
                            ? const Color(0xFF17223A)
                            : const Color(0xFFEBF5F1),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF243352)
                              : const Color(0xFFD4E8E0),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onPressed: () => context.push('/doc/${doc.id}'),
                      ),
                    ),
              ],
            ),
          ),
        ),

        // How fresh this copy of the requirements is. The app is offline-first,
        // so the date the feed was compiled is the reader's only way to judge
        // whether what they are reading still holds.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.homeDataUpdated(
                    bundle.generatedAt == null
                        ? '—'
                        : MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(bundle.generatedAt!),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Where the user lives — drives the barangay hints. Optional, and
        // only rendered once a place has been picked.
        if (savedLocation != null && !savedLocation.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push('/location'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF17223A)
                      : const Color(0xFFEBF5F1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF243352)
                        : const Color(0xFFD4E8E0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: accentColorOf(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        savedLocation.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFB9E8D8)
                              : AppTheme.primaryDarkTeal,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
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
                          checked: checkedCount(
                            doc,
                            progress[doc.id] ?? const {},
                          ),
                          total: doc.requirements.length,
                          isAcquired: isDocumentAcquired(
                            doc,
                            progress[doc.id] ?? const {},
                          ),
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
          onAction: () => context.push('/bundles'),
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
                  for (final b in bundles.take(homeBundleLimit))
                    SizedBox(
                      width: cardWidth,
                      child: BundleCard(bundle: b, progress: progress),
                    ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Curated categories
        _SectionHeader(
          title: l10n.homeCategories,
          actionLabel: 'See all >',
          onAction: () => context.go('/documents'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final category in docCategories)
                _CategoryChip(
                  category: category,
                  onTap: () => context.go(
                    '/documents?tags=${Uri.encodeComponent(category.tags.join(','))}',
                  ),
                ),
            ],
          ),
        ),

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

/// Whose checklist is on screen, and the way to switch or add a person.
///
/// It sits beside the hero question rather than in Settings because it changes
/// what every list on this screen means.
class _ProfileChip extends ConsumerWidget {
  const _ProfileChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(currentProfileProvider);
    final label = profile.isMe ? l10n.profileMe : profile.name;

    return Semantics(
      button: true,
      label: l10n.profileSwitcher(label),
      child: Tooltip(
        message: l10n.profileSwitcher(label),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showProfileSheet(context, ref),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1D2E27) : const Color(0xFFEAF5F1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF243352) : const Color(0xFFD4E8E0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline,
                size: 15,
                color: accentColorOf(context),
              ),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 92),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.accentDark
                        : AppTheme.primaryTeal,
                  ),
                ),
              ),
              Icon(
                Icons.expand_more,
                size: 15,
                color: isDark ? AppTheme.accentDark : AppTheme.primaryTeal,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

Future<void> _showProfileSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Consumer(
        builder: (sheetContext, sheetRef, _) {
          final l10n = AppLocalizations.of(sheetContext)!;
          final profiles = sheetRef.watch(profilesProvider);
          final active = sheetRef.watch(currentProfileProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  l10n.profileSwitcherHint,
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final profile in profiles)
                ListTile(
                  leading: Icon(
                    profile == active
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: profile == active ? accentColorOf(context) : null,
                  ),
                  title: Text(profile.isMe ? l10n.profileMe : profile.name),
                  trailing: profile.isMe
                      ? null
                      : IconButton(
                          tooltip: l10n.profileRemove,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmRemoveProfile(
                            sheetContext,
                            sheetRef,
                            l10n,
                            profile,
                          ),
                        ),
                  onTap: () async {
                    await sheetRef
                        .read(activeProfileProvider.notifier)
                        .select(profile.id);
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.person_add_alt),
                title: Text(l10n.profileAdd),
                onTap: () => _addProfile(sheetContext, sheetRef, l10n),
              ),
            ],
          );
        },
      ),
    ),
  );
}

Future<void> _addProfile(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) async {
  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) => const _AddProfileDialog(),
  );
  if (name == null || name.trim().isEmpty) return;
  final profile = await ref.read(profilesProvider.notifier).add(name);
  await ref.read(activeProfileProvider.notifier).select(profile.id);
  if (context.mounted) Navigator.of(context).pop();
}

/// Asks for a name. The field owns its controller so it is disposed with the
/// route instead of while the dialog is still closing.
class _AddProfileDialog extends StatefulWidget {
  const _AddProfileDialog();

  @override
  State<_AddProfileDialog> createState() => _AddProfileDialogState();
}

class _AddProfileDialogState extends State<_AddProfileDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.profileAddTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: l10n.profileNameLabel,
          hintText: l10n.profileNameHint,
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}

Future<void> _confirmRemoveProfile(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
  Profile profile,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.profileRemoveTitle(profile.name)),
      content: Text(l10n.profileRemoveMessage),
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
  await ref.read(profilesProvider.notifier).remove(profile.id);
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accentColorOf(context),
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
    this.isAcquired = false,
  });

  final Document document;
  final int checked;
  final int total;
  final bool isAcquired;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fraction = total == 0
        ? (isAcquired ? 1.0 : 0.0)
        : (checked / total).clamp(0.0, 1.0);

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
              if (isAcquired)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: accentColorOf(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.docAcquiredBadge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColorOf(context),
                      ),
                    ),
                  ],
                )
              else
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
                    value: isAcquired ? 1.0 : fraction,
                    backgroundColor: isDark
                        ? const Color(0xFF1F2C46)
                        : const Color(0xFFE2ECE7),
                    color: accentColorOf(context),
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.onTap});

  final DocCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColorOf(context);
    return ActionChip(
      avatar: Icon(category.icon, size: 17, color: accent),
      label: Text(category.label(Localizations.localeOf(context).languageCode)),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFC9ECE0) : AppTheme.primaryDarkTeal,
      ),
      backgroundColor: isDark
          ? const Color(0xFF17223A)
          : const Color(0xFFEBF5F1),
      side: BorderSide(
        color: isDark ? const Color(0xFF243352) : const Color(0xFFD4E8E0),
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
