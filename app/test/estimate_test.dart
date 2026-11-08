import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/data/estimate.dart';
import 'package:kumpleto/models/localized_text.dart';
import 'package:kumpleto/models/models.dart';

/// The bundle estimate only ever sums numbers an entry states for itself, and
/// says how much of the bundle those numbers cover.
void main() {
  const name = LocalizedText(en: 'Doc', fil: 'Doc');

  Document doc({
    String id = 'doc',
    int? feeMin,
    int? feeMax,
    int? daysMin,
    int? daysMax,
  }) => Document(
    id: id,
    name: name,
    agencyId: 'agency',
    status: DocStatus.verified,
    feeMin: feeMin,
    feeMax: feeMax,
    processingDaysMin: daysMin,
    processingDaysMax: daysMax,
  );

  test('sums a fully covered bundle', () {
    final estimate = bundleEstimate([
      doc(id: 'a', feeMin: 155, feeMax: 160, daysMin: 0, daysMax: 0),
      doc(id: 'b', feeMin: 950, feeMax: 1200, daysMin: 7, daysMax: 12),
    ]);

    expect(estimate.feeCovered, 2);
    expect(estimate.feeMin, 1105);
    expect(estimate.feeMax, 1360);
    expect(estimate.feeIsPartial, isFalse);
    expect(estimate.daysMin, 7);
    expect(estimate.daysMax, 12);
    expect(estimate.daysIsComplete, isTrue);
    expect(estimate.isSameDay, isFalse);
  });

  test('an entry without a fee is counted but not summed', () {
    final estimate = bundleEstimate([
      doc(id: 'a', feeMin: 150, feeMax: 150),
      doc(id: 'b'),
    ]);

    expect(estimate.documentCount, 2);
    expect(estimate.feeCovered, 1);
    expect(estimate.feeMin, 150);
    expect(estimate.feeMax, 150);
    expect(estimate.feeIsPartial, isTrue);
  });

  test('nothing stated means no total at all', () {
    final estimate = bundleEstimate([doc(id: 'a'), doc(id: 'b')]);

    expect(estimate.hasFee, isFalse);
    expect(estimate.hasDays, isFalse);
    expect(estimate.feeIsPartial, isFalse);
    expect(estimate.daysIsComplete, isFalse);
    expect(estimate.isFree, isFalse);
  });

  test('a half-covered day total is not reported', () {
    final estimate = bundleEstimate([
      doc(id: 'a', daysMin: 7, daysMax: 12),
      doc(id: 'b'),
    ]);

    expect(estimate.hasDays, isTrue);
    expect(estimate.daysCovered, 1);
    expect(estimate.daysIsComplete, isFalse);
  });

  test('all-zero fees read as free, all-zero days as same day', () {
    final estimate = bundleEstimate([
      doc(id: 'a', feeMin: 0, feeMax: 0, daysMin: 0, daysMax: 0),
      doc(id: 'b', feeMin: 0, feeMax: 0, daysMin: 0, daysMax: 0),
    ]);

    expect(estimate.isFree, isTrue);
    expect(estimate.isSameDay, isTrue);
    expect(estimate.feeIsPartial, isFalse);
  });

  test('a single-value range is still a range object', () {
    final estimate = bundleEstimate([doc(id: 'a', feeMin: 155, feeMax: 155)]);

    expect(estimate.feeMin, estimate.feeMax);
  });

  group('groupedAmount', () {
    test('groups thousands like a peso amount', () {
      expect(groupedAmount(0), '0');
      expect(groupedAmount(155), '155');
      expect(groupedAmount(1200), '1,200');
      expect(groupedAmount(1105), '1,105');
      expect(groupedAmount(1234567), '1,234,567');
    });

    test('keeps the sign in front', () {
      expect(groupedAmount(-1200), '-1,200');
    });
  });
}
