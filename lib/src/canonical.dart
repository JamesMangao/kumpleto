import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Canonicalization: recursively sort object keys so that logically equal
/// payloads always serialize to identical bytes (and therefore identical
/// SHA-256), regardless of authoring order. Array order is meaningful and
/// preserved. See docs/DECISIONS.md (sha256 decision).
dynamic canonicalize(dynamic node) {
  if (node is Map) {
    final keys = node.keys.map((k) => k.toString()).toList()..sort();
    return <String, dynamic>{
      for (final k in keys) k: canonicalize(node[k]),
    };
  }
  if (node is List) return node.map(canonicalize).toList();
  return node;
}

/// SHA-256 (hex) over the canonical JSON encoding of [value].
String sha256OfJson(Object? value) {
  final bytes = utf8.encode(jsonEncode(canonicalize(value)));
  return sha256.convert(bytes).toString();
}

/// Builds the hashable payload: exactly the four keys
/// `{schema_version, agencies, documents, bundles}`, canonicalized on hash.
Map<String, dynamic> buildPayload(
  List<Map<String, dynamic>> agencies,
  List<Map<String, dynamic>> documents,
  List<Map<String, dynamic>> bundles,
) {
  return <String, dynamic>{
    'schema_version': 1,
    'agencies': agencies,
    'documents': documents,
    'bundles': bundles,
  };
}

/// Builds the full compiled data.json object.
///
/// [sha256] covers `{schema_version, agencies, documents, bundles}` only —
/// the client rebuilds the same four-key map, re-canonicalizes and compares.
/// [dataVersion] / [generatedAt] are ISO-8601 UTC timestamps.
Map<String, dynamic> buildDataJson({
  required List<Map<String, dynamic>> agencies,
  required List<Map<String, dynamic>> documents,
  required List<Map<String, dynamic>> bundles,
  required String dataVersion,
  required String generatedAt,
}) {
  final payload = buildPayload(agencies, documents, bundles);
  return <String, dynamic>{
    'schema_version': 1,
    'data_version': dataVersion,
    'generated_at': generatedAt,
    'sha256': sha256OfJson(payload),
    'agencies': agencies,
    'documents': documents,
    'bundles': bundles,
  };
}

/// Filters a full (drafts-included) dataset down to the release subset:
/// drops `status: draft` documents and any bundle referencing an excluded
/// document, keeping the release bundle referentially intact.
/// Agencies are always included (drafts have no agency-level status).
({List<Map<String, dynamic>> documents, List<Map<String, dynamic>> bundles})
    selectForRelease(
  List<Map<String, dynamic>> documents,
  List<Map<String, dynamic>> bundles,
) {
  final releaseDocuments = [
    for (final d in documents) if (d['status'] != 'draft') d,
  ];
  final releaseDocIds = {
    for (final d in releaseDocuments) d['id'] as String,
  };
  final releaseBundles = [
    for (final b in bundles)
      if ((b['documents'] as List).every(releaseDocIds.contains)) b,
  ];
  return (documents: releaseDocuments, bundles: releaseBundles);
}

/// Verifies an untrusted parsed data.json the way the app does:
/// schema_version gate + JSON shape + sha256 of the canonical 4-key payload.
/// Returns null when valid, or a human-readable reason for rejection.
String? verifyDataJson(Map<String, dynamic> data, {required int maxSchemaVersion}) {
  final schemaVersion = data['schema_version'];
  if (schemaVersion is! int) return 'schema_version missing or not an int';
  if (schemaVersion > maxSchemaVersion) {
    return 'schema_version $schemaVersion > supported $maxSchemaVersion';
  }
  final agencies = data['agencies'];
  final documents = data['documents'];
  final bundles = data['bundles'];
  final expected = data['sha256'];
  if (agencies is! List || documents is! List || bundles is! List) {
    return 'agencies/documents/bundles must be lists';
  }
  if (expected is! String || expected.isEmpty) return 'sha256 missing';
  final actual = sha256OfJson(buildPayload(
    List<Map<String, dynamic>>.from(
      agencies.whereType<Map<dynamic, dynamic>>().map(Map<String, dynamic>.from),
    ),
    List<Map<String, dynamic>>.from(
      documents
          .whereType<Map<dynamic, dynamic>>()
          .map(Map<String, dynamic>.from),
    ),
    List<Map<String, dynamic>>.from(
      bundles.whereType<Map<dynamic, dynamic>>().map(Map<String, dynamic>.from),
    ),
  ));
  if (actual != expected) {
    return 'sha256 mismatch (expected $expected, got $actual)';
  }
  return null;
}
