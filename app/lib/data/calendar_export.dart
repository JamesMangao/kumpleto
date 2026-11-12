import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// The zone every Philippine document date is written in.
///
/// The Philippines has observed a single offset (UTC+8, no daylight saving)
/// since 1978, so one STANDARD block describes every date this app exports.
const String manilaTimeZoneId = 'Asia/Manila';

/// Hour of day (Asia/Manila) the exported event starts at.
///
/// An all-day event would be the obvious encoding for an expiry date, but both
/// Android and iOS fire an all-day alarm at local midnight and most people
/// never see it. A 09:00 timed event keeps the same calendar day and actually
/// produces a notification.
const int expiryEventHour = 9;

/// Builds a one-event iCalendar file for a document's expiry date.
///
/// The file is plain text (RFC 5545), so any calendar app can import it and
/// nothing needs a network call or an account. Lines are folded and text is
/// escaped per the RFC, which keeps long Filipino titles readable in Google
/// Calendar and the iOS calendar alike.
///
/// The event carries its own `Asia/Manila` definition and is written with
/// `TZID`, not as UTC: a reader who is abroad on the expiry date still gets the
/// alarm at 09:00 Philippine time (the moment the document actually lapses), and
/// a reader whose phone is in Manila never sees a date shifted by a day.
String buildExpiryIcs({
  required String documentId,
  required String title,
  required DateTime expiry,
  required String description,
  DateTime? stamp,
}) {
  final day = DateTime(expiry.year, expiry.month, expiry.day);
  final start = DateTime(day.year, day.month, day.day, expiryEventHour);
  final end = start.add(const Duration(minutes: 15));
  final now = (stamp ?? DateTime.now()).toUtc();

  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Kumpleto//Expiry reminder//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    // Tells the receiving app which zone to use for any floating time in this
    // file, including the ones inside the alarms.
    'X-WR-TIMEZONE:$manilaTimeZoneId',
    'BEGIN:VTIMEZONE',
    'TZID:$manilaTimeZoneId',
    'X-LIC-LOCATION:$manilaTimeZoneId',
    'BEGIN:STANDARD',
    'TZOFFSETFROM:+0800',
    'TZOFFSETTO:+0800',
    'TZNAME:PHT',
    'DTSTART:19700101T000000',
    'END:STANDARD',
    'END:VTIMEZONE',
    'BEGIN:VEVENT',
    'UID:${_escape(documentId)}-expiry@kumpleto',
    'DTSTAMP:${_utcStamp(now)}',
    'DTSTART;TZID=$manilaTimeZoneId:${_localStamp(start)}',
    'DTEND;TZID=$manilaTimeZoneId:${_localStamp(end)}',
    'SUMMARY:${_escape('$title expires')}',
    'DESCRIPTION:${_escape(description)}',
    'TRANSP:TRANSPARENT',
    'BEGIN:VALARM',
    'TRIGGER:-P30D',
    'ACTION:DISPLAY',
    'DESCRIPTION:${_escape('$title expires in 30 days')}',
    'END:VALARM',
    'BEGIN:VALARM',
    'TRIGGER:-P7D',
    'ACTION:DISPLAY',
    'DESCRIPTION:${_escape('$title expires in 7 days')}',
    'END:VALARM',
    'BEGIN:VALARM',
    'TRIGGER:-P1D',
    'ACTION:DISPLAY',
    'DESCRIPTION:${_escape('$title expires tomorrow')}',
    'END:VALARM',
    'END:VEVENT',
    'END:VCALENDAR',
  ];
  return '${lines.map(_fold).join('\r\n')}\r\n';
}

/// Writes the event to a temporary `.ics` file and hands it to the share sheet,
/// so the reader picks their own calendar app.
Future<void> shareExpiryIcs({
  required String documentId,
  required String title,
  required DateTime expiry,
  required String description,
}) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$documentId-expiry.ics');
  await file.writeAsString(
    buildExpiryIcs(
      documentId: documentId,
      title: title,
      expiry: expiry,
      description: description,
    ),
  );
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/calendar')],
      subject: title,
      text: description,
    ),
  );
}

/// RFC 5545 wants lines folded at 75 octets; calendars accept 75 characters.
String _fold(String line) {
  if (line.length <= 75) return line;
  final buffer = StringBuffer(line.substring(0, 75));
  var index = 75;
  while (index < line.length) {
    final end = (index + 74).clamp(0, line.length);
    buffer
      ..write('\r\n ')
      ..write(line.substring(index, end));
    index = end;
  }
  return buffer.toString();
}

String _escape(String value) => value
    .replaceAll('\\', '\\\\')
    .replaceAll(';', '\\;')
    .replaceAll(',', '\\,')
    .replaceAll('\n', '\\n');

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}'
    '${value.month.toString().padLeft(2, '0')}'
    '${value.day.toString().padLeft(2, '0')}';

/// `DTSTART`/`DTEND` value for a wall-clock time in the named zone: the digits
/// are written as-is because `TZID` already supplies the offset.
String _localStamp(DateTime value) =>
    '${_date(value)}T'
    '${value.hour.toString().padLeft(2, '0')}'
    '${value.minute.toString().padLeft(2, '0')}'
    '${value.second.toString().padLeft(2, '0')}';

String _utcStamp(DateTime value) => '${_localStamp(value)}Z';
