// FIXTURE WARNING: every YAML under tools/test/fixtures/ is FAKE DATA used
// to exercise validator rules. Nothing there is real, and no real entry may
// ever be created as a fixture.
import 'dart:io';

import 'package:kumpleto_tools/kumpleto_data.dart';
import 'package:test/test.dart';

/// Fixed clock so date-sensitive rules are deterministic.
final DateTime now = DateTime.utc(2026, 10, 15);

ValidationReport validateFixture(
  String name, {
  Map<String, DateTime> mtimes = const {},
}) {
  final root = repoRoot(Directory.current);
  final ds = DataSet.loadFromDirectory(
    Directory('${root.path}/tools/test/fixtures/$name'),
  );
  return validateDataSet(
    ds,
    now: now,
    schemaDir: Directory('${root.path}/schema'),
    mtimes: mtimes,
  );
}

void main() {
  group('valid fixtures', () {
    test('valid_ok: no errors, no warnings', () {
      final report = validateFixture('valid_ok');
      expect(report.errors.map((e) => e.message), isEmpty);
      expect(report.warnings.map((e) => e.message), isEmpty);
    });
  });

  group('error classes', () {
    test('schema violation is an error', () {
      final report = validateFixture('err_schema');
      final errors = report.errors.map((e) => e.message).join('\n');
      expect(errors, contains('schema'));
      // Both schema problems surface: missing fil + wrong photocopies type.
      expect(errors, contains('fil'));
      expect(errors, contains('photocopies'));
    });

    test('duplicate document ids are an error', () {
      final report = validateFixture('err_dup_ids');
      expect(
        report.errors.map((e) => e.message),
        contains(contains('duplicate document id "twin"')),
      );
    });

    test('filename != id is an error', () {
      final report = validateFixture('err_filename');
      expect(
        report.errors.map((e) => e.message),
        contains(contains('does not equal filename')),
      );
    });

    test('bundle referencing unknown document is an error', () {
      final report = validateFixture('err_bundle_ref');
      expect(
        report.errors.map((e) => e.message),
        contains(contains('unknown document "ghost-doc"')),
      );
    });

    test('depends_on unknown document is an error', () {
      final report = validateFixture('err_depends_unknown');
      expect(
        report.errors.map((e) => e.message),
        contains(contains('depends_on unknown document "ghost-doc"')),
      );
    });

    test('depends_on cycle is an error', () {
      final report = validateFixture('err_depends_cycle');
      expect(
        report.errors.map((e) => e.message),
        contains(contains('depends_on cycle')),
      );
    });

    test('verified without source_url/last_verified/requirements/steps errs',
        () {
      final report = validateFixture('err_verified_incomplete');
      final errors = report.errors.map((e) => e.message).join('\n');
      expect(errors, contains('verified entry missing source_url'));
      expect(errors, contains('verified entry missing last_verified'));
      expect(errors, contains('verified entry missing requirements'));
      expect(errors, contains('verified entry missing steps'));
      expect(report.errors, hasLength(4));
      // null fee_note on a verified entry is a warning, not an error.
      expect(
        report.warnings.map((e) => e.message),
        contains(contains('null fee_note')),
      );
    });

    test('last_verified in the future is an error', () {
      final report = validateFixture('err_future_verified');
      expect(
        report.errors.map((e) => e.message),
        contains(contains('in the future')),
      );
    });

    test('non-https URL is an error', () {
      final report = validateFixture('err_non_https');
      expect(
        report.errors.map((e) => e.message),
        contains(contains('not an absolute https URL')),
      );
    });

    test('duplicate requirement ids in one document are an error', () {
      final report = validateFixture('err_dup_req_ids');
      expect(
        report.errors.map((e) => e.message),
        contains(contains('duplicate requirement id "same-id"')),
      );
    });

    test('unknown agency key is an error', () {
      final report = validateFixture('err_unknown_agency');
      expect(
        report.errors.map((e) => e.message),
        contains(contains('agency "ghost-agency" is not defined')),
      );
    });

    test('missing en OR fil string is an error (schema enforces both)', () {
      // err_schema's name has only "en".
      final report = validateFixture('err_schema');
      expect(
        report.errors.map((e) => e.message).join('\n'),
        contains('fil'),
      );
    });
  });

  group('warning classes (do not fail by default)', () {
    test('warn_only: four warnings, zero errors', () {
      final ds = DataSet.loadFromDirectory(
        Directory(
          '${repoRoot(Directory.current).path}'
          '/tools/test/fixtures/warn_only',
        ),
      );
      final oldDraftEntry = ds.documents.firstWhere((e) => e.id == 'old-draft');
      final report = validateDataSet(
        ds,
        now: now,
        schemaDir: Directory('${repoRoot(Directory.current).path}/schema'),
        mtimes: {
          oldDraftEntry.sourcePath: now.subtract(const Duration(days: 100)),
        },
      );

      expect(report.errors, isEmpty);
      final warnings = report.warnings.map((e) => e.message).join('\n');
      expect(warnings, contains('not a .gov.ph domain'));
      expect(warnings, contains('stale'));
      expect(warnings, contains('null fee_note'));
      expect(warnings, contains('draft older than 90 days'));
      expect(report.warnings, hasLength(4));
    });

    test('strict mode fails on warnings; default mode passes', () {
      final report = validateFixture('warn_only');
      expect(report.pass(), isTrue);
      expect(report.pass(strict: true), isFalse,
          reason: 'strict mode must fail the run when warnings exist');
    });
  });
}
