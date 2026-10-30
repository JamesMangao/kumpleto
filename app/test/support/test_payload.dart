import 'package:kumpleto/core/canonical.dart';

/// Builds a *valid* `data.json` payload (correct `sha256`, matching
/// `schema_version`) so repository/update tests can focus on the behaviour
/// under test instead of re-deriving the hash.
///
/// Pass `schemaVersion: 2` to exercise the app's schema gate — the hash is
/// then computed over schema 1 (as `buildPayload` does) and the gate must
/// reject the payload before hashing matters.
Map<String, Object?> compileDataJson({
  int schemaVersion = 1,
  String dataVersion = '2026-01-01T00:00:00.000Z',
  List<Map<String, Object?>> agencies = const <Map<String, Object?>>[],
  List<Map<String, Object?>> documents = const <Map<String, Object?>>[],
  List<Map<String, Object?>> bundles = const <Map<String, Object?>>[],
}) {
  final payload = buildPayload(agencies, documents, bundles);
  return <String, Object?>{
    'schema_version': schemaVersion,
    'data_version': dataVersion,
    'generated_at': dataVersion,
    'sha256': sha256OfJson(payload),
    'agencies': agencies,
    'documents': documents,
    'bundles': bundles,
  };
}

/// One tiny but complete agency/document/bundle trio, for tests that care
/// about content rather than emptiness.
Map<String, Object?> sampleDataJson({
  String dataVersion = '2026-01-01T00:00:00.000Z',
}) => compileDataJson(
  dataVersion: dataVersion,
  agencies: [
    <String, Object?>{
      'id': 'nbi',
      'name': <String, Object?>{'en': 'NBI', 'fil': 'NBI'},
    },
  ],
  documents: [
    <String, Object?>{
      'id': 'nbi-clearance',
      'name': <String, Object?>{'en': 'NBI Clearance', 'fil': 'NBI Clearance'},
      'agency': 'nbi',
      'status': 'verified',
      'requirements': [
        <String, Object?>{
          'id': 'valid-id',
          'text': <String, Object?>{
            'en': 'Valid ID',
            'fil': 'Valid na ID',
          },
          'original': true,
        },
      ],
    },
  ],
  bundles: [
    <String, Object?>{
      'id': 'job-hunt-pack',
      'name': <String, Object?>{'en': 'Job Hunt Pack', 'fil': 'Job Hunt Pack'},
      'description': <String, Object?>{'en': 'Docs', 'fil': 'Mga dok'},
      'documents': ['nbi-clearance'],
    },
  ],
);
