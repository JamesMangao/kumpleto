import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import 'shared.dart';

/// Keeps the scheduled expiry reminders in step with the checklist.
///
/// It sits above the router, watches the document list and the dates the user
/// marked, and re-schedules only when the set of dates, the setting or the
/// language actually changed — never on every rebuild.
class ReminderSync extends ConsumerStatefulWidget {
  const ReminderSync({super.key, required this.settings, required this.child});

  final AppSettings settings;
  final Widget child;

  @override
  ConsumerState<ReminderSync> createState() => _ReminderSyncState();
}

class _ReminderSyncState extends ConsumerState<ReminderSync> {
  String? _lastSignature;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    // Language and the reminder switch both change what has to be scheduled.
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
    final enabled = widget.settings.remindersEnabled;

    final signature = [
      enabled,
      widget.settings.language,
      documents.length,
      for (final entry in dates.entries)
        '${entry.key}@${entry.value.millisecondsSinceEpoch}',
    ].join('|');

    if (signature != _lastSignature) {
      _lastSignature = signature;
      final scheduler = ref.read(reminderSchedulerProvider);
      final dateFormatter = MaterialLocalizations.of(context).formatShortDate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scheduler.sync(
          enabled: enabled,
          documents: documents,
          acquired: dates,
          title: (document, daysLeft) =>
              l10n.reminderTitle(document.name.localized(context), daysLeft),
          body: (document, until) => l10n.reminderBody(dateFormatter(until)),
        );
      });
    }

    return widget.child;
  }
}
