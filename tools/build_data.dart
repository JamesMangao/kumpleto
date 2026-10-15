// Kumpleto data compiler: data/ -> dist/data.json (+ app asset).
//
// Usage (from the repo root):
//   dart run tools/build_data.dart                  # release data (no drafts)
//   dart run tools/build_data.dart --include-drafts # also emit dev drafts asset
//
// Outputs:
//   dist/data.json                 release bundle (status: draft excluded)
//   dist/data-with-drafts.json     dev bundle (drafts included)
//   app/assets/data/data.json      copy of the release bundle (bundled baseline)
//   app/assets/data/data_drafts.json  (only with --include-drafts; gitignored;
//                                      removed again by plain runs so release
//                                      builds can never pick it up)
import 'dart:convert';
import 'dart:io';

import 'package:kumpleto_tools/kumpleto_data.dart';

Future<void> main(List<String> args) async {
  final includeDraftsFlag = args.contains('--include-drafts');

  final root = repoRoot();
  final dataDir = Directory('${root.path}/data');
  final schemaDir = Directory('${root.path}/schema');
  final distDir = Directory('${root.path}/dist');
  final assetDir = Directory('${root.path}/app/assets/data');

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
  if (!report.pass()) {
    stderr.writeln(
      'FATAL: refusing to compile data with ${report.errors.length} error(s).',
    );
    exitCode = 1;
    return;
  }

  final now = DateTime.now().toUtc();
  final iso = now.toIso8601String();

  // Deterministic ordering (sorted by id) so diffs and hashes are stable.
  List<Map<String, dynamic>> sorted(List<DataEntry> entries) {
    final list = [...entries]..sort((a, b) => (a.id ?? '').compareTo(b.id ?? ''));
    return [for (final e in list) e.data];
  }

  final agencies = sorted(ds.agencies);
  final allDocuments = sorted(ds.documents);
  final allBundles = sorted(ds.bundles);

  final release = selectForRelease(allDocuments, allBundles);
  final releaseDocuments = release.documents;
  final releaseBundles = release.bundles;

  final releaseJson = buildDataJson(
    agencies: agencies,
    documents: releaseDocuments,
    bundles: releaseBundles,
    dataVersion: iso,
    generatedAt: iso,
  );
  final withDraftsJson = buildDataJson(
    agencies: agencies,
    documents: allDocuments,
    bundles: allBundles,
    dataVersion: iso,
    generatedAt: iso,
  );

  distDir.createSync(recursive: true);
  assetDir.createSync(recursive: true);

  void writeJson(File file, Map<String, dynamic> json) {
    file.writeAsStringSync(
      JsonEncoder.withIndent('  ').convert(json),
    );
  }

  writeJson(File('${distDir.path}/data.json'), releaseJson);
  writeJson(File('${distDir.path}/data-with-drafts.json'), withDraftsJson);
  writeJson(File('${assetDir.path}/data.json'), releaseJson);

  final draftsAsset = File('${assetDir.path}/data_drafts.json');
  if (includeDraftsFlag) {
    writeJson(draftsAsset, withDraftsJson);
  } else if (draftsAsset.existsSync()) {
    draftsAsset.deleteSync();
    stdout.writeln('Removed stale ${draftsAsset.path} (release safety).');
  }

  stdout.writeln(
    'Built data.json (schema v1, data_version $iso)\n'
    '  sha256:        ${releaseJson['sha256']}\n'
    '  release:       ${releaseDocuments.length} documents, '
    '${releaseBundles.length} bundles, ${agencies.length} agencies\n'
    '  with drafts:   ${allDocuments.length} documents, '
    '${allBundles.length} bundles'
    '${includeDraftsFlag ? '\n  dev asset:     ${draftsAsset.path}' : ''}',
  );
}
