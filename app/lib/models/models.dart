/// App-side models for the compiled data bundle.
///
/// Parsing is deliberately tolerant: every entry in `data/` may be a draft
/// with optional fields omitted, and the published feed may add fields later.
/// A missing optional field becomes null (or its schema default) — never an
/// exception. Unknown fields are ignored.
library;

import 'localized_text.dart';

Map<String, Object?>? _map(Object? value) {
  if (value is! Map<Object?, Object?>) return null;
  return <String, Object?>{
    for (final entry in value.entries) entry.key.toString(): entry.value,
  };
}

List<Object?> _list(Object? value) =>
    value is List<Object?> ? value : const <Object?>[];

String? _str(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _int(Object? value) => value is int ? value : null;

bool? _bool(Object? value) => value is bool ? value : null;

/// Verification state of a document or bundle.
enum DocStatus {
  draft,
  verified,
  deprecated;

  static DocStatus parse(Object? value) => switch (value) {
    'verified' => DocStatus.verified,
    'deprecated' => DocStatus.deprecated,
    _ => DocStatus.draft,
  };
}

/// An issuing agency from `data/agencies.yaml`.
class Agency {
  const Agency({required this.id, required this.name, this.website});

  final String id;
  final LocalizedText name;
  final String? website;

  static Agency? fromJson(Object? json) {
    final map = _map(json);
    if (map == null) return null;
    final id = _str(map['id']);
    final name = LocalizedText.fromJson(map['name']);
    if (id == null || name == null) return null;
    return Agency(id: id, name: name, website: _str(map['website']));
  }
}

/// One line item on a document's checklist.
class Requirement {
  const Requirement({
    required this.id,
    required this.text,
    this.original = false,
    this.photocopies = 0,
    this.optional = false,
    this.note,
  });

  final String id;
  final LocalizedText text;
  final bool original;
  final int photocopies;
  final bool optional;
  final LocalizedText? note;

  static Requirement? fromJson(Object? json) {
    final map = _map(json);
    if (map == null) return null;
    final id = _str(map['id']);
    final text = LocalizedText.fromJson(map['text']);
    if (id == null || text == null) return null;
    return Requirement(
      id: id,
      text: text,
      original: _bool(map['original']) ?? false,
      photocopies: _int(map['photocopies']) ?? 0,
      optional: _bool(map['optional']) ?? false,
      note: LocalizedText.fromJson(map['note']),
    );
  }
}

/// A government document entry.
class Document {
  const Document({
    required this.id,
    required this.name,
    required this.agencyId,
    required this.status,
    this.summary,
    this.sourceUrl,
    this.lastVerified,
    this.verifiedBy,
    this.validityMonths,
    this.applyOnline,
    this.applyOnlineUrl,
    this.whereToApply,
    this.dependsOn = const <String>[],
    this.tags = const <String>[],
    this.requirements = const <Requirement>[],
    this.steps = const <LocalizedText>[],
    this.feeNote,
    this.processingNote,
    this.notes = const <LocalizedText>[],
  });

  final String id;
  final LocalizedText name;
  final String agencyId;
  final DocStatus status;
  final LocalizedText? summary;
  final String? sourceUrl;
  final DateTime? lastVerified;
  final String? verifiedBy;
  final int? validityMonths;
  final bool? applyOnline;
  final String? applyOnlineUrl;
  final LocalizedText? whereToApply;
  final List<String> dependsOn;
  final List<String> tags;
  final List<Requirement> requirements;
  final List<LocalizedText> steps;
  final LocalizedText? feeNote;
  final LocalizedText? processingNote;
  final List<LocalizedText> notes;

  /// True when there is nothing factual to show yet (a seed/draft entry).
  bool get isEmpty => requirements.isEmpty && steps.isEmpty;

  static Document? fromJson(Object? json) {
    final map = _map(json);
    if (map == null) return null;
    final id = _str(map['id']);
    final name = LocalizedText.fromJson(map['name']);
    final agencyId = _str(map['agency']);
    if (id == null || name == null || agencyId == null) return null;
    return Document(
      id: id,
      name: name,
      agencyId: agencyId,
      status: DocStatus.parse(map['status']),
      summary: LocalizedText.fromJson(map['summary']),
      sourceUrl: _str(map['source_url']),
      lastVerified: DateTime.tryParse(_str(map['last_verified']) ?? ''),
      verifiedBy: _str(map['verified_by']),
      validityMonths: _int(map['validity_months']),
      applyOnline: _bool(map['apply_online']),
      applyOnlineUrl: _str(map['apply_online_url']),
      whereToApply: LocalizedText.fromJson(map['where_to_apply']),
      dependsOn: _strings(map['depends_on']),
      tags: _strings(map['tags']),
      requirements: [
        for (final raw in _list(map['requirements'])) ?Requirement.fromJson(raw),
      ],
      steps: [
        for (final raw in _list(map['steps'])) ?LocalizedText.fromJson(raw),
      ],
      feeNote: LocalizedText.fromJson(map['fee_note']),
      processingNote: LocalizedText.fromJson(map['processing_note']),
      notes: [
        for (final raw in _list(map['notes'])) ?LocalizedText.fromJson(raw),
      ],
    );
  }
}

/// An ordered set of documents for a life event (e.g. Job Hunt Pack).
class Bundle {
  const Bundle({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.documentIds = const <String>[],
    this.tags = const <String>[],
    this.icon,
    this.notes = const <LocalizedText>[],
  });

  final String id;
  final LocalizedText name;
  final LocalizedText description;
  final DocStatus status;
  final List<String> documentIds;
  final List<String> tags;

  /// Material icon name, e.g. `work` (mapped to an [IconData] in the UI).
  final String? icon;
  final List<LocalizedText> notes;

  static Bundle? fromJson(Object? json) {
    final map = _map(json);
    if (map == null) return null;
    final id = _str(map['id']);
    final name = LocalizedText.fromJson(map['name']);
    final description = LocalizedText.fromJson(map['description']);
    if (id == null || name == null || description == null) return null;
    return Bundle(
      id: id,
      name: name,
      description: description,
      status: DocStatus.parse(map['status']),
      documentIds: _strings(map['documents']),
      tags: _strings(map['tags']),
      icon: _str(map['icon']),
      notes: [
        for (final raw in _list(map['notes'])) ?LocalizedText.fromJson(raw),
      ],
    );
  }
}

List<String> _strings(Object? value) => [
  for (final raw in _list(value)) ?_str(raw),
];

/// The whole compiled dataset, with id lookups.
class DataBundle {
  DataBundle({
    required this.schemaVersion,
    required this.dataVersion,
    required this.agencies,
    required this.documents,
    required this.bundles,
  });

  final int schemaVersion;
  final String dataVersion;
  final List<Agency> agencies;
  final List<Document> documents;
  final List<Bundle> bundles;

  late final Map<String, Agency> _agencyById = {
    for (final agency in agencies) agency.id: agency,
  };
  late final Map<String, Document> _documentById = {
    for (final document in documents) document.id: document,
  };
  late final Map<String, Bundle> _bundleById = {
    for (final bundle in bundles) bundle.id: bundle,
  };

  Agency? agency(String id) => _agencyById[id];
  Document? document(String id) => _documentById[id];
  Bundle? bundle(String id) => _bundleById[id];

  /// The bundle's documents in authored order, skipping ids that are not in
  /// the current dataset (e.g. a draft document excluded from the feed).
  List<Document> documentsOf(Bundle bundle) => [
    for (final id in bundle.documentIds) ?_documentById[id],
  ];

  static DataBundle fromJson(Map<String, Object?> json) {
    List<T> parseAll<T>(Object? raw, T? Function(Object?) parse) => [
      for (final item in _list(raw)) ?parse(item),
    ];
    return DataBundle(
      schemaVersion: _int(json['schema_version']) ?? 0,
      dataVersion: _str(json['data_version']) ?? 'unknown',
      agencies: parseAll(json['agencies'], Agency.fromJson),
      documents: parseAll(json['documents'], Document.fromJson),
      bundles: parseAll(json['bundles'], Bundle.fromJson),
    );
  }

  /// An empty dataset — used while loading and when data is unusable.
  static DataBundle empty() => DataBundle(
    schemaVersion: 0,
    dataVersion: 'none',
    agencies: const <Agency>[],
    documents: const <Document>[],
    bundles: const <Bundle>[],
  );
}