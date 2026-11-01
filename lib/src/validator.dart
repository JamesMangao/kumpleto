import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:kumpleto_data_contract/data_contract.dart'
    show VerificationTier, staleVerifiedDays, verificationTier;

import 'data_set.dart';

enum Severity { error, warning }

class Issue {
  Issue(this.severity, this.message);

  final Severity severity;
  final String message;

  @override
  String toString() =>
      '[${severity == Severity.error ? 'ERROR' : 'WARN '}] $message';
}

class ValidationReport {
  ValidationReport(this.issues);

  final List<Issue> issues;

  List<Issue> get errors =>
      issues.where((i) => i.severity == Severity.error).toList();
  List<Issue> get warnings =>
      issues.where((i) => i.severity == Severity.warning).toList();

  /// With [strict], warnings also fail the run.
  bool pass({bool strict = false}) =>
      errors.isEmpty && (!strict || warnings.isEmpty);
}

/// Draft-age threshold (see docs/DECISIONS.md). The verification-age
/// thresholds (90 / 180 days) live in the shared data contract, so the app,
/// the validator and the staleness report cannot drift apart.
const int oldDraftDays = 90;

/// Validates [ds] against the JSON schemas in [schemaDir] plus the semantic
/// rules defined in docs/DATA_GUIDE.md. [now] and [mtimes] are injectable so
/// tests are deterministic.
ValidationReport validateDataSet(
  DataSet ds, {
  required DateTime now,
  Directory? schemaDir,
  Map<String, DateTime> mtimes = const {},
}) {
  final issues = <Issue>[];
  void error(String msg) => issues.add(Issue(Severity.error, msg));
  void warn(String msg) => issues.add(Issue(Severity.warning, msg));

  final schemaRoot = schemaDir ?? Directory('${repoRoot().path}/schema');
  final docSchema = _loadSchema(
    File('${schemaRoot.path}/document.schema.json'),
  );
  final bundleSchema = _loadSchema(
    File('${schemaRoot.path}/bundle.schema.json'),
  );

  // ---- agencies -----------------------------------------------------------
  final agencyIds = <String>{};
  for (final entry in ds.agencies) {
    final data = entry.data;
    final id = data['id'];
    if (id is! String || id.isEmpty) {
      error('agency ${entry.sourcePath}: missing or invalid id');
      continue;
    }
    if (!agencyIds.add(id)) {
      error('agencies.yaml: duplicate agency id "$id"');
    }
    _checkBilingual(data['name'], error, path: 'agency "$id" name');
    _checkWebsite(data['website'], error, warn, path: 'agency "$id" website');
  }

  // ---- documents ----------------------------------------------------------
  final docIds = <String>{};
  final docIdSet = <String>{};
  for (final entry in ds.documents) {
    final data = entry.data;
    final id = entry.id;
    if (id == null) {
      error('document ${entry.sourcePath}: missing id');
      continue;
    }
    if (!docIds.add(id)) error('documents: duplicate document id "$id"');
    docIdSet.add(id);
    final agency = data['agency'];
    if (agency is String && !agencyIds.contains(agency)) {
      error('document "$id": agency "$agency" is not defined in agencies.yaml');
    }
    if (entry.filenameId != id) {
      error('document "$id": id does not equal filename '
          '"${entry.filenameId}.yaml"');
    }
    final schemaResults = docSchema.validate(data);
    for (final e in schemaResults.errors) {
      error('document "$id": schema: ${e.message} (at ${e.instancePath})');
    }

    final status = data['status'];
    _checkUrl(data['source_url'], error, warn, path: 'document "$id" source_url');
    _checkUrl(
      data['apply_online_url'],
      error,
      warn,
      path: 'document "$id" apply_online_url',
    );

    final lastVerified = data['last_verified'];
    if (lastVerified is String) {
      final date = DateTime.tryParse(lastVerified);
      if (date == null) {
        error('document "$id": last_verified "$lastVerified" is not YYYY-MM-DD');
      } else if (date.isAfter(now)) {
        error('document "$id": last_verified $lastVerified is in the future');
      } else if (status == 'verified' &&
          verificationTier(lastVerified: date, now: now) ==
              VerificationTier.overdue) {
        warn('document "$id": verified ${now.difference(date).inDays} days ago '
            '(> $staleVerifiedDays) — stale');
      }
    }

    if (status == 'verified') {
      if (data['source_url'] is! String) {
        error('document "$id": verified entry missing source_url');
      }
      if (lastVerified is! String) {
        error('document "$id": verified entry missing last_verified');
      }
      final reqs = data['requirements'];
      if (reqs is! List || reqs.isEmpty) {
        error('document "$id": verified entry missing requirements');
      }
      final steps = data['steps'];
      if (steps is! List || steps.isEmpty) {
        error('document "$id": verified entry missing steps');
      }
      if (data['fee_note'] == null) {
        warn('document "$id": verified entry has null fee_note '
            '(prefer "see official site" over no guidance)');
      }
    }

    // Duplicate requirement ids within the document.
    final reqs = data['requirements'];
    if (reqs is List) {
      final reqIds = <String>{};
      for (final r in reqs.whereType<Map<dynamic, dynamic>>()) {
        final rid = r['id'];
        if (rid is String && !reqIds.add(rid)) {
          error('document "$id": duplicate requirement id "$rid"');
        }
      }
    }

    // Draft age warning (mtime based; injected in tests).
    if (status == 'draft') {
      final mtime = mtimes[entry.sourcePath] ?? entry.mtime;
      if (now.difference(mtime).inDays > oldDraftDays) {
        warn('document "$id": draft older than $oldDraftDays days — '
            'needs verification');
      }
    }
  }

  // ---- depends_on (known ids + cycle detection) ---------------------------
  final dependsOn = <String, List<String>>{};
  for (final entry in ds.documents) {
    final id = entry.id;
    if (id == null) continue;
    final deps = entry.data['depends_on'];
    if (deps is! List) continue;
    final resolved = <String>[];
    for (final d in deps.whereType<String>()) {
      if (!docIdSet.contains(d)) {
        error('document "$id": depends_on unknown document "$d"');
      } else {
        resolved.add(d);
      }
    }
    dependsOn[id] = resolved;
  }
  for (final cycle in _findCycles(dependsOn)) {
    error('depends_on cycle: ${cycle.join(' -> ')}');
  }

  // ---- bundles ------------------------------------------------------------
  final bundleIds = <String>{};
  for (final entry in ds.bundles) {
    final data = entry.data;
    final id = entry.id;
    if (id == null) {
      error('bundle ${entry.sourcePath}: missing id');
      continue;
    }
    if (!bundleIds.add(id)) error('bundles: duplicate bundle id "$id"');
    if (entry.filenameId != id) {
      error('bundle "$id": id does not equal filename '
          '"${entry.filenameId}.yaml"');
    }
    final schemaResults = bundleSchema.validate(data);
    for (final e in schemaResults.errors) {
      error('bundle "$id": schema: ${e.message} (at ${e.instancePath})');
    }
    final docs = data['documents'];
    if (docs is List) {
      for (final d in docs.whereType<String>()) {
        if (!docIdSet.contains(d)) {
          error('bundle "$id": references unknown document "$d"');
        }
      }
    }
    _checkUrl(data['source_url'], error, warn, path: 'bundle "$id" source_url');
  }

  return ValidationReport(issues);
}

JsonSchema _loadSchema(File file) {
  if (!file.existsSync()) {
    throw StateError('Missing schema file: ${file.path}');
  }
  return JsonSchema.create(_decodeJsonObject(file));
}

/// Parses a JSON schema file into a plain map.
Map<String, dynamic> _decodeJsonObject(File file) {
  final decoded = _jsonDecoder.convert(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('${file.path}: top level must be a JSON object');
  }
  return decoded;
}

final _jsonDecoder = const JsonDecoder();

// ---- helpers --------------------------------------------------------------

void _checkBilingual(
  Object? value,
  void Function(String) error, {
  required String path,
}) {
  if (value == null) return; // optional fields may be null/absent
  if (value is Map) {
    final en = value['en'];
    final fil = value['fil'];
    if (en is! String || en.trim().isEmpty) {
      error('$path: missing or empty "en" string');
    }
    if (fil is! String || fil.trim().isEmpty) {
      error('$path: missing or empty "fil" string');
    }
  }
}

void _checkUrl(
  Object? value,
  void Function(String) error,
  void Function(String) warn, {
  required String path,
}) {
  if (value == null) return;
  if (value is! String) return; // schema flags the type
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.isAbsolute || uri.scheme != 'https') {
    error('$path: "$value" is not an absolute https URL');
    return;
  }
  final host = uri.host.toLowerCase();
  if (host != 'gov.ph' && !host.endsWith('.gov.ph')) {
    warn('$path: host "$host" is not a .gov.ph domain '
        '(some official services use a non-.gov.ph domain; confirm it is '
        'an official site)');
  }
}

void _checkWebsite(
  Object? value,
  void Function(String) error,
  void Function(String) warn, {
  required String path,
}) {
  if (value == null) return; // null allowed (e.g. barangay)
  _checkUrl(value, error, warn, path: path);
}

/// Returns each cycle found in [graph] as a path (first repeat closed).
List<List<String>> _findCycles(Map<String, List<String>> graph) {
  final cycles = <List<String>>{};
  final state = <String, int>{}; // 0=unvisited 1=visiting 2=done
  final stack = <String>[];

  void visit(String node) {
    final s = state[node] ?? 0;
    if (s == 2) return;
    if (s == 1) {
      final start = stack.indexOf(node);
      cycles.add([...stack.sublist(start), node]);
      return;
    }
    state[node] = 1;
    stack.add(node);
    for (final next in graph[node] ?? const <String>[]) {
      visit(next);
    }
    stack.removeLast();
    state[node] = 2;
  }

  for (final node in graph.keys) {
    visit(node);
  }
  return cycles.toList();
}
