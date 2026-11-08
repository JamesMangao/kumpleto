/// What a bundle costs and how long it takes, summed from the numbers the
/// entries themselves state.
///
/// This is not a price quote. Each document carries `fee_min`/`fee_max` only
/// when its own `fee_note` states an amount, so a total is reported together
/// with how many entries it covers ([feeCovered] of [documentCount]) — a total
/// that silently ignored half a bundle would read as a promise the data cannot
/// make.
library;

import '../models/models.dart';

class BundleEstimate {
  const BundleEstimate({
    required this.documentCount,
    required this.feeCovered,
    required this.feeMin,
    required this.feeMax,
    required this.daysCovered,
    required this.daysMin,
    required this.daysMax,
  });

  /// Documents in the bundle (drafts included, since they are listed too).
  final int documentCount;

  /// How many of them state a fee, and the summed range in pesos.
  final int feeCovered;
  final int feeMin;
  final int feeMax;

  /// How many of them state a working-day figure, and the summed range.
  final int daysCovered;
  final int daysMin;
  final int daysMax;

  bool get hasFee => feeCovered > 0;

  bool get hasDays => daysCovered > 0;

  /// Every covered entry is explicitly free (e.g. SSS, PhilHealth, PhilSys).
  bool get isFree => hasFee && feeMin == 0 && feeMax == 0;

  /// Every covered entry is released the same day.
  bool get isSameDay => hasDays && daysMax == 0;

  /// True when at least one entry is missing a fee, i.e. the total is partial.
  bool get feeIsPartial => hasFee && feeCovered < documentCount;

  /// The day total is only shown when every entry states its own figure:
  /// "about 6 days" drawn from half the bundle would be a guess dressed up as
  /// a sum.
  bool get daysIsComplete => hasDays && daysCovered == documentCount;
}

/// Sums the structured numbers across [documents].
///
/// A document contributes to the fee total only when both `fee_min` and
/// `fee_max` are present (the validator guarantees a pair, but a feed from an
/// older schema_version may not have them at all), and to the day total only
/// when both day fields are present.
BundleEstimate bundleEstimate(List<Document> documents) {
  var feeCovered = 0;
  var feeMin = 0;
  var feeMax = 0;
  var daysCovered = 0;
  var daysMin = 0;
  var daysMax = 0;

  for (final document in documents) {
    final minFee = document.feeMin;
    final maxFee = document.feeMax;
    if (minFee != null && maxFee != null) {
      feeCovered += 1;
      feeMin += minFee;
      feeMax += maxFee;
    }
    final minDays = document.processingDaysMin;
    final maxDays = document.processingDaysMax;
    if (minDays != null && maxDays != null) {
      daysCovered += 1;
      daysMin += minDays;
      daysMax += maxDays;
    }
  }

  return BundleEstimate(
    documentCount: documents.length,
    feeCovered: feeCovered,
    feeMin: feeMin,
    feeMax: feeMax,
    daysCovered: daysCovered,
    daysMin: daysMin,
    daysMax: daysMax,
  );
}

/// `1200` → `1,200`, so pesos read like peso amounts without pulling `intl`
/// in for one group separator.
String groupedAmount(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer(amount < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
