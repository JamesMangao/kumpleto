import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/core/reminders.dart';

/// The reminder schedule is the part that has to be right: the notification
/// just delivers whatever these moments say.
void main() {
  test('warns thirty, seven and one day before expiry, at 9am', () {
    final moments = reminderMoments(
      DateTime(2027, 3, 15),
      now: DateTime(2026, 11, 6),
    );

    expect(moments.map((moment) => moment.daysLeft), [30, 7, 1]);
    expect(moments.map((moment) => moment.when), [
      DateTime(2027, 2, 13, 9),
      DateTime(2027, 3, 8, 9),
      DateTime(2027, 3, 14, 9),
    ]);
  });

  test('drops the reminders that already passed', () {
    final moments = reminderMoments(
      DateTime(2026, 12, 1),
      now: DateTime(2026, 11, 20),
    );

    expect(moments.map((moment) => moment.daysLeft), [7, 1]);
  });

  test('crosses a month boundary without skipping a day', () {
    final moments = reminderMoments(
      DateTime(2027, 1, 5),
      now: DateTime(2026, 11, 1),
    );

    expect(moments.first.when, DateTime(2026, 12, 6, 9));
  });

  test('an already expired document schedules nothing', () {
    expect(
      reminderMoments(DateTime(2026, 10, 1), now: DateTime(2026, 11, 6)),
      isEmpty,
    );
  });
}
