import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/data/calendar_export.dart';

/// The exported `.ics` must survive a reader who is abroad: the event carries
/// its own Asia/Manila definition, is written with `TZID` rather than UTC, and
/// still lands on the expiry day and at a time the phone will actually notify.
void main() {
  final stamp = DateTime.utc(2026, 11, 9, 16, 7, 57);

  String build({DateTime? expiry}) => buildExpiryIcs(
    documentId: 'nbi-clearance',
    title: 'NBI Clearance',
    expiry: expiry ?? DateTime(2027, 3, 15),
    description: 'Valid until 15/3/2027.',
    stamp: stamp,
  );

  /// Unfolds RFC 5545 continuation lines so the assertions read the logical
  /// property rather than the physical one.
  List<String> properties(String ics) => ics
      .replaceAll('\r\n ', '')
      .split('\r\n')
      .where((line) => line.isNotEmpty)
      .toList();

  test('declares the Manila zone once and points the event at it', () {
    final lines = properties(build());

    expect(lines, contains('X-WR-TIMEZONE:Asia/Manila'));
    expect(lines, contains('BEGIN:VTIMEZONE'));
    expect(lines, contains('TZID:Asia/Manila'));
    expect(lines, contains('TZOFFSETFROM:+0800'));
    expect(lines, contains('TZOFFSETTO:+0800'));
    // The Philippines has no daylight saving, so a single STANDARD block is the
    // whole definition and no DAYLIGHT block may appear.
    expect(lines, contains('BEGIN:STANDARD'));
    expect(lines.where((line) => line == 'BEGIN:DAYLIGHT'), isEmpty);
  });

  test('starts at 09:00 Manila time on the expiry day, with an end', () {
    final lines = properties(build());

    expect(
      lines,
      contains('DTSTART;TZID=Asia/Manila:20270315T090000'),
    );
    expect(
      lines,
      contains('DTEND;TZID=Asia/Manila:20270315T091500'),
    );
    // A UTC-based event would still be on the 14th in Manila; assert the event
    // never uses the Z form. The one bare DTSTART in the file belongs to the
    // VTIMEZONE definition, which has no zone of its own.
    expect(
      lines.where((line) => line.startsWith('DTSTART:')),
      ['DTSTART:19700101T000000'],
    );
  });

  test('keeps DTSTAMP in UTC, as the RFC requires', () {
    expect(
      properties(build()),
      contains('DTSTAMP:20261109T160757Z'),
    );
  });

  test('the wall-clock date is the date handed in, whatever its zone', () {
    // A local DateTime and the same wall clock expressed in UTC must produce the
    // same event day: the export names a calendar date, not an instant.
    final local = DateTime(2027, 3, 15, 23, 30);
    final utc = DateTime.utc(2027, 3, 15, 23, 30);

    for (final expiry in [local, utc]) {
      expect(
        properties(build(expiry: expiry)),
        contains('DTSTART;TZID=Asia/Manila:20270315T090000'),
      );
    }
  });

  test('warns 30 days, 7 days and 1 day before', () {
    final lines = properties(build());
    final triggers = lines.where((line) => line.startsWith('TRIGGER:'));

    expect(triggers, ['TRIGGER:-P30D', 'TRIGGER:-P7D', 'TRIGGER:-P1D']);
  });

  test('escapes and folds per RFC 5545', () {
    final ics = buildExpiryIcs(
      documentId: 'lto-drivers-license',
      title: 'Driver\'s licence; renewal',
      expiry: DateTime(2027, 1, 8),
      description:
          'Long description, with commas; and a backslash \\ plus newline\nhere.',
      stamp: stamp,
    );

    // Assertions run on the unfolded text: the description is long enough to be
    // folded, and the fold must not be read as part of the value.
    final unfolded = ics.replaceAll('\r\n ', '');
    expect(unfolded, contains(r"SUMMARY:Driver's licence\; renewal expires"));
    expect(unfolded, contains(r'DESCRIPTION:Long description\, with commas\;'));
    expect(unfolded, contains(r'\\ plus newline\nhere.'));
    for (final line in ics.split('\r\n')) {
      expect(line.length, lessThanOrEqualTo(75), reason: 'folded: $line');
    }
    expect(ics.endsWith('\r\n'), isTrue);
  });
}
