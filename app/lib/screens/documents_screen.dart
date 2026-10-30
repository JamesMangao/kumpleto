import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../widgets/shared.dart';
import 'scaffold_with_nav.dart';

/// Documents list: live search plus agency/tag filters, status badges and
/// per-document progress. Reads `?q=` / `?tag=` so Home can deep-link here.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _tag;
  String? _agency;
  var _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed (and refresh) from the route's query parameters — Home links here
    // with ?q= and ?tag=.
    final params = GoRouterState.of(context).uri.queryParameters;
    final query = params['q'];
    final tag = params['tag'];
    if (!_seeded || query != null || tag != null) {
      _seeded = true;
      if (query != null && query != _query) {
        _query = query;
        _searchController.text = query;
      }
      if (tag != null && tag != _tag) _tag = tag;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final documents = ref.watch(documentsProvider);
    final data = ref.watch(currentDataProvider);

    final agencies = {
      for (final document in documents) document.agencyId,
    }.toList()..sort();
    final tags = <String>{
      for (final document in documents) ...document.tags,
    }.toList()..sort();

    final needle = _query.trim().toLowerCase();
    final filtered = [
      for (final document in documents)
        if ((_tag == null || document.tags.contains(_tag)) &&
            (_agency == null || document.agencyId == _agency) &&
            (needle.isEmpty ||
                document.name.en.toLowerCase().contains(needle) ||
                document.name.fil.toLowerCase().contains(needle) ||
                (data?.agency(document.agencyId)?.name.en
                        .toLowerCase()
                        .contains(needle) ??
                    false)))
          document,
    ];

    return Scaffold(
      appBar: unofficialAppBar(context, l10n.documentsTitle),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => _toggle(() => _query = value),
                decoration: InputDecoration(
                  hintText: l10n.homeSearchHint,
                  prefixIcon: const Icon(Icons.search),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            if (agencies.isNotEmpty || tags.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.documentsFilterAll),
                      selected: _tag == null && _agency == null,
                      onSelected: (_) =>
                          _toggle(() => _tag = _agency = null),
                    ),
                    for (final agencyId in agencies)
                      FilterChip(
                        label: Text(
                          data?.agency(agencyId)?.name.localized(context) ??
                              agencyId,
                        ),
                        selected: _agency == agencyId,
                        onSelected: (selected) => _toggle(
                          () => _agency = selected ? agencyId : null,
                        ),
                      ),
                    for (final tag in tags)
                      FilterChip(
                        label: Text(tag),
                        selected: _tag == tag,
                        onSelected: (selected) =>
                            _toggle(() => _tag = selected ? tag : null),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.documentsNoResults,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _DocumentTile(document: filtered[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends ConsumerWidget {
  const _DocumentTile({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final data = ref.watch(currentDataProvider);
    final checked = checkedFor(ref, document.id);
    final done = checkedCount(document, checked);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            data?.agency(document.agencyId)?.name.localized(context) ??
                document.agencyId,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (document.requirements.isNotEmpty) ...[
            const SizedBox(height: 6),
            ProgressLine(
              checked: done,
              total: document.requirements.length,
              showBar: false,
            ),
          ] else if (document.isEmpty) ...[
            const SizedBox(height: 6),
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
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/doc/${document.id}'),
    );
  }
}
