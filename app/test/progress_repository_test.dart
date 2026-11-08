import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/data/progress.dart';
import 'package:kumpleto/data/progress_repository.dart';

/// Progress is stored as `profileId → documentId → {requirementId}` rows;
/// nothing is written for an unchecked requirement, so "no row" means
/// unchecked. Every read and write names the person the row is for.
void main() {
  late KumpletoDb db;
  late ProgressRepository repository;

  const me = ProgressRepository.defaultProfileId;
  const wife = 'p1';

  setUp(() {
    db = KumpletoDb(NativeDatabase.memory());
    repository = ProgressRepository(db);
  });

  tearDown(() => db.close());

  test('setChecked + watchAll group rows by document', () async {
    await repository.setChecked(me, 'nbi-clearance', 'valid-id', true);
    await repository.setChecked(me, 'nbi-clearance', 'psa-copy', true);
    await repository.setChecked(me, 'sss', 'umber-number', true);

    final progress = await repository.watchAll(me).first;
    expect(progress, {
      'nbi-clearance': {'valid-id', 'psa-copy'},
      'sss': {'umber-number'},
    });
  });

  test('each profile keeps its own ticks for the same document', () async {
    await repository.setChecked(me, 'nbi-clearance', 'valid-id', true);
    await repository.setChecked(wife, 'nbi-clearance', 'valid-id', true);
    await repository.setChecked(wife, 'nbi-clearance', 'psa-copy', true);

    expect(await repository.watchAll(me).first, {
      'nbi-clearance': {'valid-id'},
    });
    expect(await repository.watchAll(wife).first, {
      'nbi-clearance': {'valid-id', 'psa-copy'},
    });
  });

  test('acquired dates are per profile', () async {
    await repository.markDocumentAcquired(me, 'psa-birth-cert', ['orig']);
    await repository.markDocumentAcquired(wife, 'sss', ['id']);

    expect((await repository.watchAcquiredDates(me).first).keys, [
      'psa-birth-cert',
    ]);
    expect((await repository.watchAcquiredDates(wife).first).keys, ['sss']);
  });

  test('watchAll pushes changes to an existing listener', () async {
    final expectation = expectLater(
      repository.watchAll(me),
      emitsInOrder(<Object?>[
        isEmpty,
        <String, Set<String>>{
          'doc': {'req'},
        },
      ]),
    );
    // Give the subscription a moment to attach before mutating the table.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await repository.setChecked(me, 'doc', 'req', true);
    await expectation;
  });

  test('a stored false row is not shown as progress', () async {
    await repository.setChecked(me, 'doc', 'req', true);
    await repository.setChecked(me, 'doc', 'req', false);
    expect(await repository.watchAll(me).first, isEmpty);
  });

  test('resetDocument clears one document only', () async {
    await repository.setChecked(me, 'doc-a', 'r1', true);
    await repository.setChecked(me, 'doc-b', 'r2', true);

    await repository.resetDocument(me, 'doc-a');

    expect(await repository.watchAll(me).first, {
      'doc-b': {'r2'},
    });
  });

  test('resetDocument leaves other profiles alone', () async {
    await repository.setChecked(me, 'doc-a', 'r1', true);
    await repository.setChecked(wife, 'doc-a', 'r1', true);

    await repository.resetDocument(me, 'doc-a');

    expect(await repository.watchAll(me).first, isEmpty);
    expect(await repository.watchAll(wife).first, {
      'doc-a': {'r1'},
    });
  });

  test('resetAll clears one profile', () async {
    await repository.setChecked(me, 'doc-a', 'r1', true);
    await repository.setChecked(wife, 'doc-b', 'r2', true);

    await repository.resetAll(me);

    expect(await repository.watchAll(me).first, isEmpty);
    expect(await repository.watchAll(wife).first, {
      'doc-b': {'r2'},
    });
  });

  test('resetEverything clears every profile', () async {
    await repository.setChecked(me, 'doc-a', 'r1', true);
    await repository.setChecked(wife, 'doc-b', 'r2', true);

    await repository.resetEverything();

    expect(await repository.watchAll(me).first, isEmpty);
    expect(await repository.watchAll(wife).first, isEmpty);
  });

  test('pruneOrphans removes rows whose requirement disappeared', () async {
    await repository.setChecked(me, 'doc-a', 'kept', true);
    await repository.setChecked(me, 'doc-a', 'renamed', true);
    await repository.setChecked(me, 'doc-b', 'withdrawn', true);

    final removed = await repository.pruneOrphans(me, {
      'doc-a/kept',
      'doc-a/some-new-requirement',
    });

    expect(removed, 2);
    expect(await repository.watchAll(me).first, {
      'doc-a': {'kept'},
    });
  });

  test('pruneOrphans with a full valid set removes nothing', () async {
    await repository.setChecked(me, 'doc-a', 'r1', true);
    expect(await repository.pruneOrphans(me, {'doc-a/r1'}), 0);
    expect(await repository.watchAll(me).first, {
      'doc-a': {'r1'},
    });
  });

  test('re-ticking the same requirement does not duplicate rows', () async {
    await repository.setChecked(me, 'doc', 'req', true);
    await repository.setChecked(me, 'doc', 'req', true);

    expect(await repository.watchAll(me).first, {
      'doc': {'req'},
    });
  });

  test('markDocumentAcquired sets all requirements plus acquired marker',
      () async {
    await repository.markDocumentAcquired(me, 'psa-birth-cert', [
      'orig',
      'photocopy',
    ]);

    final progress = await repository.watchAll(me).first;
    expect(progress['psa-birth-cert'], {'orig', 'photocopy', '__acquired__'});

    await repository.unmarkDocumentAcquired(me, 'psa-birth-cert');
    final afterReset = await repository.watchAll(me).first;
    expect(afterReset['psa-birth-cert'], isNull);
  });
}
