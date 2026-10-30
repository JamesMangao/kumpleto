import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/core/canonical.dart';

import 'support/test_payload.dart';

/// The app-side guarantees must stay identical to the repo tooling's
/// (`tools/test/canonical_test.dart`) — the app re-derives the published
/// `sha256` from whatever the feed hands it.
void main() {
  group('canonicalize / sha256OfJson', () {
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

    test('nested maps are sorted recursively', () {
      final a = <String, Object?>{
        'outer': <String, Object?>{'z': 1, 'a': <String, Object?>{'y': 2, 'b': 3}},
      };
      final b = <String, Object?>{
        'outer': <String, Object?>{'a': <String, Object?>{'b': 3, 'y': 2}, 'z': 1},
      };
      expect(sha256OfJson(a), sha256OfJson(b));
    });

    test('different content changes the hash', () {
      expect(sha256OfJson(<String, Object?>{'x': 1}),
          isNot(sha256OfJson(<String, Object?>{'x': 2})));
    });

    test('array order is meaningful (not sorted)', () {
      expect(
        sha256OfJson(<String, Object?>{'xs': <Object?>['a', 'b']}),
        isNot(sha256OfJson(<String, Object?>{'xs': <Object?>['b', 'a']})),
      );
    });
  });

  group('verifyDataJson', () {
    test('accepts a payload it compiled itself', () {
      expect(
        verifyDataJson(sampleDataJson(), maxSchemaVersion: 1),
        isNull,
      );
    });

    test('rejects tampered content (sha256 mismatch)', () {
      final data = sampleDataJson();
      (data['documents']! as List<Object?>).add(<String, Object?>{
        'id': 'evil',
        'name': <String, Object?>{'en': 'Evil'},
        'agency': 'nbi',
        'status': 'verified',
      });
      expect(
        verifyDataJson(data, maxSchemaVersion: 1),
        contains('sha256 mismatch'),
      );
    });

    test('rejects a newer schema_version', () {
      expect(
        verifyDataJson(compileDataJson(schemaVersion: 2), maxSchemaVersion: 1),
        contains('schema_version 2'),
      );
    });

    test('rejects a non-int or missing schema_version', () {
      expect(
        verifyDataJson(<String, Object?>{'schema_version': '1'},
            maxSchemaVersion: 1),
        contains('schema_version missing'),
      );
      expect(
        verifyDataJson(<String, Object?>{}, maxSchemaVersion: 1),
        contains('schema_version missing'),
      );
    });

    test('rejects a missing or malformed sha256', () {
      expect(
        verifyDataJson(<String, Object?>{
          'schema_version': 1,
          'agencies': <Object?>[],
          'documents': <Object?>[],
          'bundles': <Object?>[],
        }, maxSchemaVersion: 1),
        contains('sha256 missing'),
      );
    });

    test('rejects non-list sections', () {
      expect(
        verifyDataJson(<String, Object?>{
          'schema_version': 1,
          'agencies': 'nope',
          'documents': <Object?>[],
          'bundles': <Object?>[],
          'sha256': 'x',
        }, maxSchemaVersion: 1),
        contains('agencies/documents/bundles'),
      );
    });
  });
}
