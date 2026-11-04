library;

import '../models/models.dart';

/// Validity arithmetic shared by the document list and the detail screen.
///
/// Documents carry `validity_months` in the authored data ("an NBI clearance
/// is good for 6 months"); the day it was acquired lives on the acquired row
/// in the progress table. Together they answer the question a reader actually
/// has: is mine still good, and until when?
///\

/// The day [document] stops being valid, counted from [acquiredAt].
///
/// Null when the entry has no validity period or the acquisition day is
/// unknown — the UI then shows no promise it cannot keep.
DateTime? validUntilOf(Document document, DateTime? acquiredAt) {
  final months = document.validityMonths;
  if (acquiredAt == null || months == null || months <= 0) return null;
  return _addMonths(acquiredAt, months);
}

/// Whole calendar months from [now] to [until]; negative once it has passed.
int monthsBetween(DateTime now, DateTime until) {
  var months = (until.year - now.year) * 12 + (until.month - now.month);
  if (until.day < now.day) months -= 1;
  return months;
}

/// Month arithmetic that cannot overflow: 31 January + 1 month is 28/29
/// February, not 3 March.
DateTime _addMonths(DateTime from, int months) {
  final total = from.month - 1 + months;
  final year = from.year + total ~/ 12;
  final month = total % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = from.day > lastDay ? lastDay : from.day;
  return DateTime(year, month, day);
}