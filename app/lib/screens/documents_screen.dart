import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../data/providers.dart';
import '../data/search.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../widgets/shared.dart';
import '../widgets/validity.dart';
import 'scaffold_with_nav.dart';

/// Which documents to show, based on whether the reader already has them.
///
/// Derived from the same checklist the cards read, so marking a document
/// acquired on its own screen moves it between these filters immediately.
enum _AcquiredFilter { all, acquired, pending }

/// Documents screen matching mockup 57dbaf1b-61d1-4044-8f0e-1d4b292a8522.jpg.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Set<String> _tags = const {};
  String? _agency;
  var _acquired = _AcquiredFilter.all;
  var _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final params = GoRouterState.of(context).uri.queryParameters;
    final query = params['q'];
    // A home category sends several tags at once (`tags=a,b,c`); a single tag
    // chip sends `tag=a`. Both end up as the same set.
    final rawTags = params['tags'] ?? params['tag'];
    if (!_seeded || query != null || rawTags != null) {
      _seeded = true;
      if (query != null && query != _query) {
        _query = query;
        _searchController.text = query;
      }
      if (rawTags != null) {
        final tags = {
          for (final tag in rawTags.split(','))
            if (tag.trim().isNotEmpty) tag.trim(),
        };
        if (tags.isNotEmpty) _tags = tags;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(void Function() change) {
    setState(change);
  }

  bool _matchesAcquired(Document document) {
    if (_acquired == _AcquiredFilter.all) return true;
    final acquired = isDocumentAcquired(
      document,
      checkedFor(ref, document.id),
    );
    return _acquired == _AcquiredFilter.acquired ? acquired : !acquired;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final documents = ref.watch(documentsProvider);
    final data = ref.watch(currentDataProvider);

    final agencies = {
      for (final document in documents) document.agencyId,
    }.toList()..sort();
    final tags = <String>{
      for (final document in documents) ...document.tags,
    }.toList()..sort();

    // Full-text, not just the title: summaries, requirement lines, notes,
    // tags and the agency in both languages all count (see data/search.dart).
    final filtered = [
      for (final document in documents)
        if ((_tags.isEmpty || document.tags.any(_tags.contains)) &&
            (_agency == null || document.agencyId == _agency) &&
            _matchesAcquired(document) &&
            documentMatches(
              document,
              query: _query,
              agency: data?.agency(document.agencyId),
            ))
          document,
    ];

    return Scaffold(
      appBar: unofficialAppBar(
        context,
        l10n.documentsTitle,
        leadingIcon: Icons.folder_shared_outlined,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _toggle(() => _query = value),
                decoration: InputDecoration(
                  hintText: l10n.homeSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 22),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.cancel,
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _toggle(() {
                              _query = '';
                              _searchController.clear();
                            });
                          },
                        ),
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
              ),
            ),

            // Acquired / not-yet filter: the checklist's own state, kept
            // apart from the tag and agency chips below so the two never
            // argue about what "All" means.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<_AcquiredFilter>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: _AcquiredFilter.all,
                      label: Text(l10n.documentsFilterAll),
                    ),
                    ButtonSegment(
                      value: _AcquiredFilter.acquired,
                      label: Text(l10n.documentsFilterAcquired),
                    ),
                    ButtonSegment(
                      value: _AcquiredFilter.pending,
                      label: Text(l10n.documentsFilterPending),
                    ),
                  ],
                  selected: {_acquired},
                  onSelectionChanged: (selection) =>
                      _toggle(() => _acquired = selection.first),
                ),
              ),
            ),

            // Horizontal Filter Chips Bar (All, Agencies, Tags)
            if (agencies.isNotEmpty || tags.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        // "All" already means "any status" in the segmented
                        // control above, so this chip says what it actually
                        // clears: any tag and any agency.
                        label: Text(l10n.documentsFilterAny),
                        selected: _tags.isEmpty && _agency == null,
                        showCheckmark: false,
                        selectedColor: AppTheme.primaryTeal,
                        backgroundColor: isDark
                            ? const Color(0xFF17223A)
                            : Colors.white,
                        labelStyle: TextStyle(
                          color: (_tags.isEmpty && _agency == null)
                              ? Colors.white
                              : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF1B2E26)),
                          fontWeight: (_tags.isEmpty && _agency == null)
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: (_tags.isEmpty && _agency == null)
                              ? AppTheme.primaryTeal
                              : (isDark
                                    ? const Color(0xFF243352)
                                    : const Color(0xFFD6E3DD)),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (_) => _toggle(
                          () => _tags = const {},
                        ),
                      ),
                    ),
                    for (final agencyId in agencies)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            data?.agency(agencyId)?.name.localized(context) ??
                                agencyId,
                          ),
                          selected: _agency == agencyId,
                          showCheckmark: false,
                          selectedColor: AppTheme.primaryTeal,
                          backgroundColor: isDark
                              ? const Color(0xFF17223A)
                              : Colors.white,
                          labelStyle: TextStyle(
                            color: _agency == agencyId
                                ? Colors.white
                                : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF1B2E26)),
                            fontWeight: _agency == agencyId
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: _agency == agencyId
                                ? AppTheme.primaryTeal
                                : (isDark
                                      ? const Color(0xFF243352)
                                      : const Color(0xFFD6E3DD)),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (selected) => _toggle(
                            () => _agency = selected ? agencyId : null,
                          ),
                        ),
                      ),
                    for (final tag in tags)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(tag),
                          selected: _tags.contains(tag),
                          showCheckmark: false,
                          selectedColor: AppTheme.primaryTeal,
                          backgroundColor: isDark
                              ? const Color(0xFF17223A)
                              : Colors.white,
                          labelStyle: TextStyle(
                            color: _tags.contains(tag)
                                ? Colors.white
                                : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF1B2E26)),
                            fontWeight: _tags.contains(tag)
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: _tags.contains(tag)
                                ? AppTheme.primaryTeal
                                : (isDark
                                      ? const Color(0xFF243352)
                                      : const Color(0xFFD6E3DD)),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (selected) => _toggle(
                            () => _tags = selected ? {tag} : const {},
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            // Document List
            Expanded(
              child: documents.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.homeEmptyTitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.homeEmptyBody,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _acquired == _AcquiredFilter.all
                              ? l10n.documentsNoResults
                              : l10n.documentsFilterEmpty,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => StaggeredEntrance(
                        index: index,
                        child: _DocumentModernCard(document: filtered[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentModernCard extends ConsumerWidget {
  const _DocumentModernCard({required this.document});

  final Document document;

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
    final acquiredAt = ref.watch(acquiredDatesProvider).value?[document.id];
    final fraction = total == 0
        ? (acquired ? 1.0 : 0.0)
        : (done / total).clamp(0.0, 1.0);

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
        onTap: () => context.push('/doc/${document.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SquircleIcon(
                    icon: Icons.description_outlined,
                    size: 44,
                    iconSize: 22,
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
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: -0.2,
                              ),
                            ),
                            StatusBadge(
                              status: document.status,
                              lastVerified: document.lastVerified,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          data
                                  ?.agency(document.agencyId)
                                  ?.name
                                  .localized(context) ??
                              document.agencyId,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ],
              ),
              if (acquired) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
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
                      ),
                    ),
                    ValidityPill(
                      document: document,
                      acquiredAt: acquiredAt,
                      dense: true,
                    ),
                  ],
                ),
              ] else if (document.requirements.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$done of $total items',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 5,
                    child: LinearProgressIndicator(
                      value: fraction,
                      backgroundColor: isDark
                          ? const Color(0xFF1F2C46)
                          : const Color(0xFFE2ECE7),
                      color: accentColorOf(context),
                    ),
                  ),
                ),
              ] else if (document.isEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.statusDraft,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
