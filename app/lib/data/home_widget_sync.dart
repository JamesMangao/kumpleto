import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/models.dart';
import 'validity.dart';

/// Keys the Android widget reads out of the shared preferences file.
///
/// Kept together with the labels so the Dart writer and the Kotlin reader can
/// never drift apart silently.
const String widgetTitleKey = 'kumpleto_next_title';
const String widgetSubtitleKey = 'kumpleto_next_subtitle';
const String widgetSummaryKey = 'kumpleto_summary';

/// Provider class the plugin must refresh, and its fully qualified name.
const String widgetProviderName = 'ChecklistWidgetProvider';
const String widgetProviderQualified =
    'io.github.jamesmangao.kumpleto.ChecklistWidgetProvider';

/// What the home-screen widget shows right now.
@immutable
class HomeWidgetValues {
  const HomeWidgetValues({
    required this.title,
    required this.subtitle,
    required this.summary,
  });

  /// "Next: NBI Clearance", or the empty-state line.
  final String title;

  /// "12 days left", empty when there is nothing to count down to.
  final String subtitle;

  /// "3 of 46 documents marked".
  final String summary;

  bool get hasTitle => title.isNotEmpty;
  bool get hasSubtitle => subtitle.isNotEmpty;
  bool get hasSummary => summary.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetValues &&
      other.title == title &&
      other.subtitle == subtitle &&
      other.summary == summary;

  @override
  int get hashCode => Object.hash(title, subtitle, summary);

  @override
  String toString() =>
      'HomeWidgetValues($title | $subtitle | $summary)';
}

/// Decides what the widget says. Pure, so the choice can be tested without a
/// plugin, a platform channel or a running app.
///
/// The widget answers one question — "what lapses next?" — because that is the
/// only thing worth a glance at the home screen. Labels are passed in as
/// callbacks so this file stays independent of the generated localizations.
HomeWidgetValues homeWidgetValues({
  required List<Document> documents,
  required Map<String, DateTime> acquired,
  required String languageCode,
  required String Function(String document) nextLabel,
  required String Function(int days) daysLeftLabel,
  required String Function(int marked, int total) summaryLabel,
  required String Function() emptyLabel,
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  final summary = summaryLabel(acquired.length, documents.length);

  if (acquired.isEmpty) {
    return HomeWidgetValues(title: emptyLabel(), subtitle: '', summary: summary);
  }

  Document? nextDocument;
  DateTime? nextUntil;
  for (final document in documents) {
    final acquiredAt = acquired[document.id];
    if (acquiredAt == null) continue;
    final until = validUntilOf(document, acquiredAt);
    if (until == null) continue;
    final day = _dateOnly(until);
    // A document that already lapsed is not "next"; the reminder flow handles
    // that case, and counting a negative number down on the home screen would
    // just look broken.
    if (day.isBefore(today)) continue;
    if (nextUntil == null || day.isBefore(nextUntil)) {
      nextUntil = day;
      nextDocument = document;
    }
  }

  if (nextDocument == null || nextUntil == null) {
    return HomeWidgetValues(title: '', subtitle: '', summary: summary);
  }

  return HomeWidgetValues(
    title: nextLabel(nextDocument.name.pick(languageCode)),
    subtitle: daysLeftLabel(nextUntil.difference(today).inDays),
    summary: summary,
  );
}

/// Writes [values] into the shared preferences file the widget reads and asks
/// the launcher to redraw it.
///
/// Every failure is swallowed: a widget that cannot refresh must never break
/// the checklist, and the desktop test run has no plugin at all.
Future<void> pushHomeWidget(HomeWidgetValues values) async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
  try {
    await HomeWidget.saveWidgetData<String>(widgetTitleKey, values.title);
    await HomeWidget.saveWidgetData<String>(
      widgetSubtitleKey,
      values.subtitle,
    );
    await HomeWidget.saveWidgetData<String>(widgetSummaryKey, values.summary);
    await HomeWidget.updateWidget(
      name: widgetProviderName,
      androidName: widgetProviderName,
      qualifiedAndroidName: widgetProviderQualified,
    );
  } on Object catch (error) {
    debugPrint('Home widget update skipped: $error');
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
