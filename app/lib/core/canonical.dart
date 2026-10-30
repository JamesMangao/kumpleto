/// App-side port of the repo tooling's `lib/src/canonical.dart`.
///
/// The app must be able to re-derive the published `sha256` from a received
/// payload, so both sides canonicalize identically: object keys are sorted
/// recursively, array order is preserved (it is meaningful).
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Recursively sorts object keys so logically equal payloads serialize to
/// identical bytes.
Object? canonicalize(Object? node) {
  if (node is Map<Object?, Object?>) {
    final keys = node.keys.map((key) => key.toString()).toList()..sort();
    return <String, Object?>{for (final key in keys) key: canonicalize(node[key])};
  }
  if (node is List<Object?>) return node.map(canonicalize).toList();
  return node;
}

/// SHA-256 (hex) over the canonical JSON encoding of [value].
String sha256OfJson(Object? value) {
  final bytes = utf8.encode(jsonEncode(canonicalize(value)));
  return sha256.convert(bytes).toString();
}

/// The hashable payload: exactly `{schema_version, agencies, documents,
/// bundles}` (see docs/DECISIONS.md, P1).
Map<String, Object?> buildPayload(
  List<Map<String, Object?>> agencies,
  List<Map<String, Object?>> documents,
  List<Map<String, Object?>> bundles,
) {
  return <String, Object?>{
    'schema_version': 1,
    'agencies': agencies,
    'documents': documents,
    'bundles': bundles,
  };
}

/// Verifies an untrusted parsed payload: schema gate + shape + sha256 over the
/// canonical four-key payload. Returns null when valid, else a reason.
String? verifyDataJson(
  Map<String, Object?> data, {
  required int maxSchemaVersion,
}) {
  final schemaVersion = data['schema_version'];
  if (schemaVersion is! int) return 'schema_version missing or not an int';
  if (schemaVersion > maxSchemaVersion) {
    return 'schema_version $schemaVersion > supported $maxSchemaVersion';
  }
  final agencies = data['agencies'];
  final documents = data['documents'];
  final bundles = data['bundles'];
  final expected = data['sha256'];
  if (agencies is! List<Object?> ||
      documents is! List<Object?> ||
      bundles is! List<Object?>) {
    return 'agencies/documents/bundles must be lists';
  }
  if (expected is! String || expected.isEmpty) return 'sha256 missing';

  List<Map<String, Object?>> mapsOf(List<Object?> raw) => [
    for (final item in raw)
      if (item is Map<Object?, Object?>)
        <String, Object?>{
          for (final entry in item.entries) entry.key.toString(): entry.value,
        },
  ];

  final actual = sha256OfJson(
    buildPayload(mapsOf(agencies), mapsOf(documents), mapsOf(bundles)),
  );
  if (actual != expected) {
    return 'sha256 mismatch (expected $expected, got $actual)';
  }
  return null;
}