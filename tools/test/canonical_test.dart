import 'package:kumpleto_tools/kumpleto_data.dart';
import 'package:test/test.dart';

void main() {
  group('canonicalize / sha256OfJson', () {
    test('key insertion order does not change the hash', () {
      final a = <String, dynamic>{
        'schema_version': 1,
        'documents': [
          {'id': 'b', 'name': <String, dynamic>{'fil': 'y', 'en': 'x'}},
        ],
        'agencies': <dynamic>[],
        'bundles': <dynamic>[],
      };
      final b = <String, dynamic>{
        'bundles': <dynamic>[],
        'agencies': <dynamic>[],
        'documents': [
          {'name': <String, dynamic>{'en': 'x', 'fil': 'y'}, 'id': 'b'},
        ],
        'schema_version': 1,
      };
      expect(sha256OfJson(a), sha256OfJson(b));
    });

    test('different content changes the hash', () {
      final a = <String, dynamic>{'x': 1};
      final b = <String, dynamic>{'x': 2};
      expect(sha256OfJson(a), isNot(sha256OfJson(b)));
    });

    test('array order is meaningful (not sorted)', () {
      final a = <String, dynamic>{'xs': <dynamic>['a', 'b']};
      final b = <String, dynamic>{'xs': <dynamic>['b', 'a']};
      expect(sha256OfJson(a), isNot(sha256OfJson(b)));
    });
  });

  group('selectForRelease', () {
    final verifiedDoc = <String, dynamic>{'id': 'v', 'status': 'verified'};
    final draftDoc = <String, dynamic>{'id': 'd', 'status': 'draft'};
    final okBundle = <String, dynamic>{
      'id': 'ok',
      'documents': <dynamic>['v'],
    };
    final draftBundle = <String, dynamic>{
      'id': 'bad',
      'documents': <dynamic>['v', 'd'],
    };

    test('drops draft documents and bundles referencing drafts', () {
      final release = selectForRelease(
        [verifiedDoc, draftDoc],
        [okBundle, draftBundle],
      );
      expect(release.documents, [verifiedDoc]);
      expect(release.bundles, [okBundle]);
    });

    test('a fully-draft dataset produces an empty release set', () {
      final release = selectForRelease([draftDoc], [draftBundle]);
      expect(release.documents, isEmpty);
      expect(release.bundles, isEmpty);
    });
  });

  group('verifyDataJson (mirrors the app update gate)', () {
    Map<String, dynamic> compile() => buildDataJson(
      agencies: [
        {'id': 'a', 'name': <String, dynamic>{'en': 'A', 'fil': 'A'}},
      ],
      documents: [
        {'id': 'd', 'status': 'verified'},
      ],
      bundles: [
        {'id': 'b', 'documents': <dynamic>['d']},
      ],
      dataVersion: '2026-10-15T00:00:00.000Z',
      generatedAt: '2026-10-15T00:00:00.000Z',
    );

    test('accepts a valid payload', () {
      expect(verifyDataJson(compile(), maxSchemaVersion: 1), isNull);
    });

    test('rejects tampered content (sha256 mismatch)', () {
      final data = compile();
      (data['documents'] as List<dynamic>).add({'id': 'evil', 'status': 'verified'});
      expect(
        verifyDataJson(data, maxSchemaVersion: 1),
        contains('sha256 mismatch'),
      );
    });

    test('rejects newer schema_version', () {
      final data = compile();
      data['schema_version'] = 2;
      expect(
        verifyDataJson(data, maxSchemaVersion: 1),
        contains('schema_version 2'),
      );
    });

    test('rejects missing/short fields', () {
      expect(
        verifyDataJson(<String, dynamic>{'schema_version': 1},
            maxSchemaVersion: 1),
        contains('agencies/documents/bundles'),
      );
      expect(
        verifyDataJson(<String, dynamic>{'schema_version': 1, 'agencies': <dynamic>[]},
            maxSchemaVersion: 1),
        contains('agencies/documents/bundles'),
      );
    });
  });
}
