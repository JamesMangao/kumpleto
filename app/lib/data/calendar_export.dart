import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Builds a one-event iCalendar file for a document's expiry date.
///
/// The file is plain text (RFC 5545), so any calendar app can import it and
/// nothing needs a network call or an account. Lines are folded and text is
/// escaped per the RFC, which keeps long Filipino titles readable in Google
/// Calendar and the iOS calendar alike.
String buildExpiryIcs({
  required String documentId,
  required String title,
  required DateTime expiry,
  required String description,
}) {
  final day = DateTime(expiry.year, expiry.month, expiry.day);
  final next = day.add(const Duration(days: 1));
  final stamp = DateTime.now().toUtc();
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//Kumpleto//Expiry reminder//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'BEGIN:VEVENT',
    'UID:${_escape(documentId)}-expiry@kumpleto',
    'DTSTAMP:${_utcStamp(stamp)}',
    'DTSTART;VALUE=DATE:${_date(day)}',
    'DTEND;VALUE=DATE:${_date(next)}',
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

String _utcStamp(DateTime value) =>
    '${_date(value)}T'
    '${value.hour.toString().padLeft(2, '0')}'
    '${value.minute.toString().padLeft(2, '0')}'
    '${value.second.toString().padLeft(2, '0')}Z';
