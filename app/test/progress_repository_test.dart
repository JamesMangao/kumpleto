import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/data/progress.dart';
import 'package:kumpleto/data/progress_repository.dart';

/// Progress is stored as `documentId → {requirementId}` rows; nothing is
/// written for an unchecked requirement, so "no row" means unchecked.
void main() {
  late KumpletoDb db;
  late ProgressRepository repository;

  setUp(() {
    db = KumpletoDb(NativeDatabase.memory());
    repository = ProgressRepository(db);
  });

  tearDown(() => db.close());

  test('setChecked + watchAll group rows by document', () async {
    await repository.setChecked('nbi-clearance', 'valid-id', true);
    await repository.setChecked('nbi-clearance', 'psa-copy', true);
    await repository.setChecked('sss', 'umber-number', true);

    final progress = await repository.watchAll().first;
    expect(progress, {
      'nbi-clearance': {'valid-id', 'psa-copy'},
      'sss': {'umber-number'},
    });
  });

  test('watchAll pushes changes to an existing listener', () async {
    final expectation = expectLater(
      repository.watchAll(),
      emitsInOrder(<Object?>[
        isEmpty,
        <String, Set<String>>{'doc': {'req'}},
      ]),
    );
    // Give the subscription a moment to attach before mutating the table.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await repository.setChecked('doc', 'req', true);
    await expectation;
  });

  test('a stored false row is not shown as progress', () async {
    await repository.setChecked('doc', 'req', true);
    await repository.setChecked('doc', 'req', false);
    expect(await repository.watchAll().first, isEmpty);
  });

  test('resetDocument clears one document only', () async {
    await repository.setChecked('doc-a', 'r1', true);
    await repository.setChecked('doc-b', 'r2', true);

    await repository.resetDocument('doc-a');

    expect(await repository.watchAll().first, {
      'doc-b': {'r2'},
    });
  });

  test('resetAll clears everything', () async {
    await repository.setChecked('doc-a', 'r1', true);
    await repository.setChecked('doc-b', 'r2', true);

    await repository.resetAll();

    expect(await repository.watchAll().first, isEmpty);
  });

  test('pruneOrphans removes rows whose requirement disappeared', () async {
    await repository.setChecked('doc-a', 'kept', true);
    await repository.setChecked('doc-a', 'renamed', true);
    await repository.setChecked('doc-b', 'withdrawn', true);

    final removed = await repository.pruneOrphans({
      'doc-a/kept',
      'doc-a/some-new-requirement',
    });

    expect(removed, 2);
    expect(await repository.watchAll().first, {
      'doc-a': {'kept'},
    });
  });

  test('pruneOrphans with a full valid set removes nothing', () async {
    await repository.setChecked('doc-a', 'r1', true);
    expect(await repository.pruneOrphans({'doc-a/r1'}), 0);
    expect(await repository.watchAll().first, {
      'doc-a': {'r1'},
    });
  });

  test('re-ticking the same requirement does not duplicate rows', () async {
    await repository.setChecked('doc', 'req', true);
    await repository.setChecked('doc', 'req', true);

    expect(await repository.watchAll().first, {
      'doc': {'req'},
    });
  });
}
