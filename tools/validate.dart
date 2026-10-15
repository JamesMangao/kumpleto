// Kumpleto data validator.
//
// Usage (from the repo root):
//   dart run tools/validate.dart                     # fail on errors (default)
//   dart run tools/validate.dart --strict-on=errors  # explicit default
//   dart run tools/validate.dart --strict            # warnings also fail
import 'dart:io';

import 'package:kumpleto_tools/kumpleto_data.dart';

Future<void> main(List<String> args) async {
  final strict = args.contains('--strict');
  // --strict-on=errors is the documented default and accepted as a no-op so
  // CI invocations are explicit about intent.
  final strictOnErrors = args.contains('--strict-on=errors');

  final root = repoRoot();
  final dataDir = Directory('${root.path}/data');
  final schemaDir = Directory('${root.path}/schema');

  final DataSet ds;
  try {
    ds = DataSet.loadFromDirectory(dataDir);
  } catch (e) {
    stderr.writeln('FATAL: failed to load dataset: $e');
    exitCode = 1;
    return;
  }

  final report = validateDataSet(
    ds,
    now: DateTime.now().toUtc(),
    schemaDir: schemaDir,
  );

  for (final issue in report.issues) {
    stdout.writeln(issue);
  }

  final ok = report.pass(strict: strict);
  stdout.writeln(
    'Validated ${ds.agencies.length} agencies, '
    '${ds.documents.length} documents, ${ds.bundles.length} bundles — '
    '${report.errors.length} error(s), ${report.warnings.length} warning(s) '
    '(${strict ? 'strict' : (strictOnErrors ? 'errors-only' : 'default')} mode).',
  );
  exitCode = ok ? 0 : 1;
}
