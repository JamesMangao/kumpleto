import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/data/home_widget_sync.dart';
import 'package:kumpleto/models/localized_text.dart';
import 'package:kumpleto/models/models.dart';

/// The home-screen widget is a glance, not a dashboard: it names the document
/// that lapses next and how many are marked. These tests pin that choice — the
/// widget has no UI test, so this is the only place the logic is checked.
void main() {
  Document doc(String id, String name, {int? validityMonths = 12}) => Document(
    id: id,
    name: LocalizedText(en: name, fil: name),
    agencyId: 'agency',
    status: DocStatus.verified,
    validityMonths: validityMonths,
  );

  final now = DateTime(2026, 11, 9, 13, 30);

  HomeWidgetValues valuesFor({
    required List<Document> documents,
    required Map<String, DateTime> acquired,
    String languageCode = 'en',
  }) => homeWidgetValues(
    documents: documents,
    acquired: acquired,
    languageCode: languageCode,
    nextLabel: (name) => 'Next: $name',
    daysLeftLabel: (days) => '$days days left',
    summaryLabel: (marked, total) => '$marked of $total documents marked',
    emptyLabel: () => 'Nothing marked yet',
    now: now,
  );

  test('an empty checklist points at the app', () {
    final values = valuesFor(
      documents: [doc('nbi-clearance', 'NBI Clearance')],
      acquired: const {},
    );

    expect(values.title, 'Nothing marked yet');
    expect(values.hasSubtitle, isFalse);
    expect(values.summary, '0 of 1 documents marked');
  });

  test('names the soonest expiry, not the first marked', () {
    final documents = [
      doc('nbi-clearance', 'NBI Clearance', validityMonths: 6),
      doc('passport-dfa', 'Passport', validityMonths: 120),
    ];
    // Marked out of order: the passport is older but valid for a decade.
    final acquired = {
      'passport-dfa': DateTime(2024, 1, 10),
      'nbi-clearance': DateTime(2026, 9, 1),
    };

    final values = valuesFor(documents: documents, acquired: acquired);

    expect(values.title, 'Next: NBI Clearance');
    // 2026-09-01 + 6 months = 2027-03-01, which is 112 days after 2026-11-09.
    expect(values.subtitle, '112 days left');
    expect(values.summary, '2 of 2 documents marked');
  });

  test('a document that already lapsed is not offered as next', () {
    final documents = [
      doc('cedula', 'Cedula', validityMonths: 12),
      doc('nbi-clearance', 'NBI Clearance', validityMonths: 6),
    ];
    final acquired = {
      'cedula': DateTime(2024, 1, 1), // expired long ago
      'nbi-clearance': DateTime(2026, 10, 1),
    };

    final values = valuesFor(documents: documents, acquired: acquired);

    expect(values.title, 'Next: NBI Clearance');
    expect(values.subtitle, '143 days left');
  });

  test('exposes only the summary when nothing has a validity period', () {
    final values = valuesFor(
      documents: [doc('barangay-clearance', 'Barangay Clearance', validityMonths: null)],
      acquired: {'barangay-clearance': DateTime(2026, 1, 1)},
    );

    expect(values.hasTitle, isFalse);
    expect(values.hasSubtitle, isFalse);
    expect(values.summary, '1 of 1 documents marked');
  });

  test('uses the reader\'s language for the document name', () {
    final values = homeWidgetValues(
      documents: [
        Document(
          id: 'nbi-clearance',
          name: const LocalizedText(en: 'NBI Clearance', fil: 'NBI Clearance (Fil)'),
          agencyId: 'nbi',
          status: DocStatus.verified,
          validityMonths: 6,
        ),
      ],
      acquired: {'nbi-clearance': DateTime(2026, 10, 1)},
      languageCode: 'fil',
      nextLabel: (name) => 'Susunod: $name',
      daysLeftLabel: (days) => '$days araw na lang',
      summaryLabel: (marked, total) => '$marked sa $total',
      emptyLabel: () => 'Wala pa',
      now: now,
    );

    expect(values.title, 'Susunod: NBI Clearance (Fil)');
    expect(values.subtitle, '143 araw na lang');
  });
}
