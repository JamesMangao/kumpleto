import 'package:kumpleto_data_contract/data_contract.dart';
import 'package:test/test.dart';

Map<String, Object?> _doc(String id, String status) => <String, Object?>{
      'id': id,
      'status': status,
      'name': <String, Object?>{'en': id, 'fil': id},
    };

final List<Map<String, Object?>> _agencies = <Map<String, Object?>>[
  <String, Object?>{
    'id': 'nbi',
    'name': <String, Object?>{'en': 'NBI', 'fil': 'NBI'},
  },
];

Map<String, Object?> _feed({
  List<Map<String, Object?>>? documents,
  List<Map<String, Object?>>? bundles,
}) => buildDataJson(
      agencies: _agencies,
      documents: documents ?? <Map<String, Object?>>[_doc('a', 'verified')],
      bundles: bundles ?? const <Map<String, Object?>>[],
      dataVersion: '2026-01-01T00:00:00.000Z',
      generatedAt: '2026-01-01T00:00:00.000Z',
    );

void main() {
  group('schema version', () {
    test('is the value the compiler stamps into every payload', () {
      expect(_feed()['schema_version'], kSchemaVersion);
      expect(buildPayload(_agencies, const [], const [])['schema_version'],
          kSchemaVersion);
    });

    test('is documented as one value across the contract', () {
      expect(kPayloadKeys, contains('schema_version'));
      expect(kMinPublishableDocuments, greaterThan(0));
    });
  });

  group('hash contract', () {
    test('key insertion order does not change the hash', () {
      final a = <String, Object?>{
        'schema_version': 1,
        'documents': [
          <String, Object?>{'id': 'b', 'name': <String, Object?>{'fil': 'y', 'en': 'x'}},
        ],
        'agencies': <Object?>[],
        'bundles': <Object?>[],
      };
      final b = <String, Object?>{
        'bundles': <Object?>[],
        'agencies': <Object?>[],
        'documents': [
          <String, Object?>{'name': <String, Object?>{'en': 'x', 'fil': 'y'}, 'id': 'b'},
        ],
        'schema_version': 1,
      };
      expect(sha256OfJson(a), sha256OfJson(b));
    });

    test('array order is meaningful (not sorted)', () {
      expect(
        sha256OfJson(<String, Object?>{'xs': <Object?>['a', 'b']}),
        isNot(sha256OfJson(<String, Object?>{'xs': <Object?>['b', 'a']})),
      );
    });

    test('a built feed verifies against its own hash', () {
      expect(verifyDataJson(_feed(), maxSchemaVersion: kSchemaVersion), isNull);
    });

    test('a tampered payload fails the hash', () {
      final feed = _feed();
      (feed['documents']! as List<Object?>).add(_doc('injected', 'verified'));
      expect(
        verifyDataJson(feed, maxSchemaVersion: kSchemaVersion),
        contains('sha256 mismatch'),
      );
    });

    test('a non-map entry is rejected rather than silently accepted', () {
      final feed = <String, Object?>{
        ..._feed(),
        'documents': <Object?>[_doc('a', 'verified'), 'not-an-object'],
      };
      expect(
        verifyDataJson(feed, maxSchemaVersion: kSchemaVersion),
        contains('lists of objects'),
      );
    });

    test('a newer schema_version is rejected', () {
      final feed = _feed()..['schema_version'] = kSchemaVersion + 1;
      expect(
        verifyDataJson(feed, maxSchemaVersion: kSchemaVersion),
        contains('> supported'),
      );
    });

    test('missing sections are rejected before hashing', () {
      expect(
        verifyDataJson(<String, Object?>{'schema_version': kSchemaVersion},
            maxSchemaVersion: kSchemaVersion),
        contains('agencies/documents/bundles'),
      );
      expect(
        verifyDataJson(<String, Object?>{
          'schema_version': kSchemaVersion,
          'agencies': <Object?>[],
          'documents': <Object?>[],
          'bundles': <Object?>[],
        }, maxSchemaVersion: kSchemaVersion),
        contains('sha256 missing'),
      );
    });
  });

  group('publishability (empty feeds must not ship)', () {
    test('a valid-but-empty release feed is refused', () {
      final empty = _feed(documents: const <Map<String, Object?>>[]);
      expect(verifyDataJson(empty, maxSchemaVersion: kSchemaVersion), isNull);
      expect(assertPublishable(empty), contains('expected at least 1'));
    });

    test('a feed with a document is publishable', () {
      expect(assertPublishable(_feed()), isNull);
    });

    test('an empty feed is refused even when the hash is correct', () {
      final empty = buildDataJson(
        agencies: _agencies,
        documents: const <Map<String, Object?>>[],
        bundles: const <Map<String, Object?>>[],
        dataVersion: '2026-01-01T00:00:00.000Z',
        generatedAt: '2026-01-01T00:00:00.000Z',
      );
      expect(sha256OfJson(empty), isNot(contains('deadbeef')));
      expect(assertPublishable(empty), isNotNull);
    });
  });

  group('selectForRelease', () {
    test('drops draft documents and bundles referencing them', () {
      final verified = _doc('v', 'verified');
      final draft = _doc('d', 'draft');
      final ok = <String, Object?>{'id': 'ok', 'documents': <Object?>['v']};
      final dangling = <String, Object?>{
        'id': 'bad',
        'documents': <Object?>['v', 'd'],
      };

      final release = selectForRelease([verified, draft], [ok, dangling]);
      expect(release.documents, <Map<String, Object?>>[verified]);
      expect(release.bundles, <Map<String, Object?>>[ok]);
      expect(release.droppedBundleIds, <String>['bad']);
    });

    test('a fully-draft dataset produces an empty release set', () {
      final release = selectForRelease(
        [_doc('d', 'draft')],
        [<String, Object?>{'id': 'b', 'documents': <Object?>['d']}],
      );
      expect(release.documents, isEmpty);
      expect(release.bundles, isEmpty);
      expect(release.droppedBundleIds, <String>['b']);
    });

    test('a bundle with no documents list is reported, not thrown', () {
      final release = selectForRelease(
        const <Map<String, Object?>>[],
        [<String, Object?>{'id': 'broken', 'status': 'draft'}],
      );
      expect(release.bundles, isEmpty);
      expect(release.droppedBundleIds.single, contains('broken'));
    });

    test('an all-drafts dataset can never be published', () {
      final release = selectForRelease(
        [_doc('d', 'draft')],
        const <Map<String, Object?>>[],
      );
      final json = buildDataJson(
        agencies: _agencies,
        documents: release.documents,
        bundles: release.bundles,
        dataVersion: '2026-01-01T00:00:00.000Z',
        generatedAt: '2026-01-01T00:00:00.000Z',
      );
      expect(assertPublishable(json), contains('expected at least 1'));
    });
  });

  group('mapsOf', () {
    test('normalizes map entries and drops non-maps', () {
      expect(
        mapsOf(<Object?>[
          <String, Object?>{'id': 'a'},
          'junk',
          7,
        ]),
        [<String, Object?>{'id': 'a'}],
      );
      expect(mapsOf(<Object?>[]), isEmpty);
      expect(mapsOf('not a list'), isEmpty);
    });
  });
}