import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import '../data/home_widget_sync.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';

/// Keeps the home-screen widget in step with the checklist.
///
/// Sits next to [ReminderSync] above the router and re-pushes only when the
/// marked documents, their dates or the language actually changed. The widget
/// is a convenience surface: if the plugin is missing or the launcher refuses,
/// nothing here throws and the app is unaffected.
class HomeWidgetSync extends ConsumerStatefulWidget {
  const HomeWidgetSync({super.key, required this.settings, required this.child});

  final AppSettings settings;
  final Widget child;

  @override
  ConsumerState<HomeWidgetSync> createState() => _HomeWidgetSyncState();
}

class _HomeWidgetSyncState extends ConsumerState<HomeWidgetSync> {
  String? _lastSignature;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    // The labels are localized, so a language change has to re-push them.
    if (mounted) setState(() => _lastSignature = null);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final documents = ref.watch(documentsProvider);
    final dates = ref.watch(acquiredDatesProvider).value ?? const {};

    final signature = [
      widget.settings.language,
      documents.length,
      for (final entry in dates.entries)
        '${entry.key}@${entry.value.millisecondsSinceEpoch}',
    ].join('|');

    if (signature != _lastSignature) {
      _lastSignature = signature;
      final values = homeWidgetValues(
        documents: documents,
        acquired: dates,
        languageCode: Localizations.localeOf(context).languageCode,
        nextLabel: l10n.widgetNext,
        daysLeftLabel: l10n.widgetDaysLeft,
        summaryLabel: l10n.widgetSummary,
        emptyLabel: () => l10n.widgetEmpty,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pushHomeWidget(values);
      });
    }

    return widget.child;
  }
}
