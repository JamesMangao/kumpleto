/// Kumpleto data contract — the one implementation of everything the
/// compiled `data.json` feed and the app agree on:
///
///  * canonical JSON + `sha256` over the four-key payload
///    (docs/DECISIONS.md, P1),
///  * the payload shape `{schema_version, agencies, documents, bundles}`,
///  * the schema version constant (single source; `supportedSchemaVersion`
///    in the app and the compiler both read it from here),
///  * the drafts → release selection, and
///  * what makes a payload publishable.
///
/// Pure Dart with no Flutter dependency so the repo tooling (`kumpleto_tools`)
/// and the app (`kumpleto`) can both depend on it. Both used to keep their own
/// port of this file; the ports drifted, so they were replaced by this
/// package (see docs/REMAINING_WORK.md, architecture review).
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The only schema version this contract can build or read.
///
/// Bump together with `schema/*.schema.json` and document the break in
/// docs/DATA_GUIDE.md — nowhere else.
const int kSchemaVersion = 1;

/// The keys covered by the published `sha256`.
///
/// Canonicalization sorts them, so this order is documentation only; adding,
/// removing or renaming a key changes the published hash and is therefore a
/// schema change.
const List<String> kPayloadKeys = <String>[
  'schema_version',
  'agencies',
  'documents',
  'bundles',
];

/// Minimum number of documents a publishable release feed must contain.
///
/// An empty feed is what ships when every document is still `status: draft`
/// — valid JSON, valid hash, useless (and misleading) to users.
const int kMinPublishableDocuments = 1;

/// Recursively sorts object keys so logically equal payloads serialize to
/// identical bytes (and therefore identical SHA-256), regardless of authoring
/// order. Array order is meaningful and preserved. See docs/DECISIONS.md.
Object? canonicalize(Object? node) {
  if (node is Map) {
    final keys = node.keys.map((key) => key.toString()).toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: canonicalize(node[key]),
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

/// Builds the hashable payload: exactly the four keys in [kPayloadKeys],
/// canonicalized when hashed.
Map<String, Object?> buildPayload(
  List<Map<String, Object?>> agencies,
  List<Map<String, Object?>> documents,
  List<Map<String, Object?>> bundles,
) {
  return <String, Object?>{
    'schema_version': kSchemaVersion,
    'agencies': agencies,
    'documents': documents,
    'bundles': bundles,
  };
}

/// Builds the full compiled `data.json` object.
///
/// [sha256] covers the four-key payload only — the client rebuilds that same
/// map, re-canonicalizes and compares. [dataVersion] / [generatedAt] are
/// ISO-8601 UTC timestamps and are not hashed.
Map<String, Object?> buildDataJson({
  required List<Map<String, Object?>> agencies,
  required List<Map<String, Object?>> documents,
  required List<Map<String, Object?>> bundles,
  required String dataVersion,
  required String generatedAt,
}) {
  final payload = buildPayload(agencies, documents, bundles);
  return <String, Object?>{
    'schema_version': kSchemaVersion,
    'data_version': dataVersion,
    'generated_at': generatedAt,
    'sha256': sha256OfJson(payload),
    'agencies': agencies,
    'documents': documents,
    'bundles': bundles,
  };
}

/// What [selectForRelease] kept, plus why the rest was dropped.
typedef ReleaseSelection = ({
  List<Map<String, Object?>> documents,
  List<Map<String, Object?>> bundles,
  List<String> droppedBundleIds,
});

/// Filters a full (drafts-included) dataset down to the release subset:
/// drops `status: draft` documents and any bundle referencing an excluded
/// document, keeping the release bundle referentially intact.
/// Agencies are always included (drafts have no agency-level status).
///
/// A bundle whose `documents` list is missing or malformed is dropped and
/// reported in [ReleaseSelection.droppedBundleIds] instead of throwing.
ReleaseSelection selectForRelease(
  List<Map<String, Object?>> documents,
  List<Map<String, Object?>> bundles,
) {
  final releaseDocuments = <Map<String, Object?>>[
    for (final document in documents)
      if (document['status'] != 'draft') document,
  ];
  final releaseDocIds = <String>{
    for (final document in releaseDocuments)
      if (document['id'] is String) document['id']! as String,
  };

  final releaseBundles = <Map<String, Object?>>[];
  final dropped = <String>[];
  for (final bundle in bundles) {
    final id = bundle['id'];
    final label = id is String ? id : '<bundle without id>';
    final members = bundle['documents'];
    if (members is! List) {
      dropped.add('$label (no documents list)');
      continue;
    }
    if (members.every(
      (member) => member is String && releaseDocIds.contains(member),
    )) {
      releaseBundles.add(bundle);
    } else {
      dropped.add(label);
    }
  }
  return (
    documents: releaseDocuments,
    bundles: releaseBundles,
    droppedBundleIds: dropped,
  );
}

/// Rebuilds the hashable payload from an untrusted parsed document,
/// normalizing every entry to a `Map<String, Object?>`.
/// Non-map entries are dropped — which then fails the hash check, so a
/// malformed feed is rejected rather than quietly accepted.
List<Map<String, Object?>> mapsOf(Object? raw) {
  if (raw is! List) return const <Map<String, Object?>>[];
  return <Map<String, Object?>>[
    for (final item in raw)
      if (item is Map)
        <String, Object?>{
          for (final entry in item.entries) entry.key.toString(): entry.value,
        },
  ];
}

/// Verifies an untrusted parsed payload exactly the way the app does:
/// schema gate → JSON shape → `sha256` of the canonical four-key payload →
/// (optionally) the minimum release size.
///
/// Returns `null` when valid, else a human-readable reason for rejection.
String? verifyDataJson(
  Map<String, Object?> data, {
  required int maxSchemaVersion,
  int minDocuments = 0,
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
  if (agencies is! List || documents is! List || bundles is! List) {
    return 'agencies/documents/bundles must be lists';
  }
  if (expected is! String || expected.isEmpty) return 'sha256 missing';
  for (final section in <List<dynamic>>[agencies, documents, bundles]) {
    if (section.any((item) => item is! Map)) {
      return 'agencies/documents/bundles must be lists of objects';
    }
  }

  final actual = sha256OfJson(
    buildPayload(mapsOf(agencies), mapsOf(documents), mapsOf(bundles)),
  );
  if (actual != expected) {
    return 'sha256 mismatch (expected $expected, got $actual)';
  }
  if (minDocuments > 0 && documents.length < minDocuments) {
    return 'release feed has ${documents.length} document(s), '
        'expected at least $minDocuments';
  }
  return null;
}

/// The publish gate: `null` means this payload is safe to ship and to deploy.
///
/// Used by the compiler (`dart run tools/build_data.dart --strict-release`)
/// so an all-drafts dataset can never reach GitHub Pages as a valid-but-empty
/// feed. Empty is the default state of this project until a human promotes a
/// document to `verified`, which is exactly why it has to be a hard gate.
String? assertPublishable(Map<String, Object?> data) => verifyDataJson(
      data,
      maxSchemaVersion: kSchemaVersion,
      minDocuments: kMinPublishableDocuments,
    );

/// Verification-age thresholds (docs/DECISIONS.md), shared by the validator,
/// the weekly staleness report and the app's document header so a "stale"
/// badge means the same thing everywhere.
const int freshVerifiedDays = 90;
const int staleVerifiedDays = 180;

/// How old a document's `last_verified` is relative to [now].
enum VerificationTier {
  /// Within [freshVerifiedDays] of [now].
  fresh,

  /// Between [freshVerifiedDays] and [staleVerifiedDays] — re-check soon.
  stale,

  /// Older than [staleVerifiedDays] — the validator warns, the app shows red.
  overdue,

  /// Never verified (or the date could not be parsed).
  unknown,
}

VerificationTier verificationTier({
  required DateTime? lastVerified,
  required DateTime now,
}) {
  if (lastVerified == null) return VerificationTier.unknown;
  final age = now.difference(lastVerified).inDays;
  if (age <= freshVerifiedDays) return VerificationTier.fresh;
  if (age <= staleVerifiedDays) return VerificationTier.stale;
  return VerificationTier.overdue;
}