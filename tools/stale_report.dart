// Kumpleto staleness report: verified documents not re-checked in 180+ days.
//
// Usage (from the repo root):
//   dart run tools/stale_report.dart
//
// Prints a Markdown list suitable for the weekly tracking issue
// (.github/workflows/stale-data.yml). Always exits 0 — staleness is a
// report, not a build failure.
import 'dart:io';

import 'package:kumpleto_tools/kumpleto_data.dart';

/// Same threshold the validator and the app use (shared data contract).
const int staleDays = staleVerifiedDays;

Future<void> main() async {
  final root = repoRoot();
  final ds = DataSet.loadFromDirectory(Directory('${root.path}/data'));
  final now = DateTime.now().toUtc();

  final stale = <MapEntry<DataEntry, int>>[];
  var verifiedCount = 0;
  var draftCount = 0;
  var deprecatedCount = 0;

  for (final entry in ds.documents) {
    final status = entry.data['status'];
    if (status == 'verified') {
      verifiedCount++;
      final lv = entry.data['last_verified'];
      final date = lv is String ? DateTime.tryParse(lv) : null;
      if (date != null) {
        final age = now.difference(date).inDays;
        if (age > staleDays) stale.add(MapEntry(entry, age));
      }
    } else if (status == 'draft') {
      draftCount++;
    } else if (status == 'deprecated') {
      deprecatedCount++;
    }
  }

  stdout.writeln('# Kumpleto stale-data report');
  stdout.writeln();
  stdout.writeln('Generated: ${now.toIso8601String()}');
  stdout.writeln();
  stdout.writeln(
    'Verified: $verifiedCount · Draft: $draftCount · '
    'Deprecated: $deprecatedCount · '
    'Stale (> $staleDays days): ${stale.length}',
  );
  stdout.writeln();

  if (stale.isEmpty) {
    stdout.writeln('No verified documents are older than $staleDays days. ✅');
  } else {
    stdout.writeln(
      'The following verified documents were last checked more than '
      '$staleDays days ago:',
    );
    stdout.writeln();
    for (final item in stale) {
      final id = item.key.id;
      final url = item.key.data['source_url'];
      stdout.writeln('- [ ] **$id** — last verified ${item.value} days ago '
          '($url)');
    }
    stdout.writeln();
    stdout.writeln(
      'Please re-check each against its official source and update '
      '`last_verified`.',
    );
  }
}
