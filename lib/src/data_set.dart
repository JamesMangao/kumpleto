import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

/// Locates the repo root by walking up from [from] until a `pubspec.yaml`
/// with `name: kumpleto_tools` is found. Throws if not found.
Directory repoRoot([Directory? from]) {
  var dir = (from ?? Directory.current).absolute;
  while (true) {
    final pubspec = File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
    if (pubspec.existsSync()) {
      final text = pubspec.readAsStringSync();
      final match = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(text);
      if (match?.group(1) == 'kumpleto_tools') return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'Could not locate the kumpleto_tools repo root from ${from ?? Directory.current}. '
        'Run from inside the repository.',
      );
    }
    dir = parent;
  }
}

/// A single parsed YAML entry with its provenance.
class DataEntry {
  DataEntry({
    required this.kind,
    required this.sourcePath,
    required this.mtime,
    required this.data,
  });

  /// 'agency' | 'document' | 'bundle'
  final String kind;
  final String sourcePath;
  final DateTime mtime;

  /// Deep-converted YAML map.
  final Map<String, dynamic> data;

  String? get id => data['id'] is String ? data['id'] as String : null;

  /// Filesystem-derived id (basename without extension) — used by the
  /// filename==id check.
  String get filenameId {
    final name = sourcePath.replaceAll('\\', '/').split('/').last;
    return name.substring(0, name.length - '.yaml'.length);
  }
}

/// The whole loaded dataset.
class DataSet {
  DataSet({
    required this.agencies,
    required this.documents,
    required this.bundles,
  });

  final List<DataEntry> agencies;
  final List<DataEntry> documents;
  final List<DataEntry> bundles;

  /// Loads and parses `agencies.yaml`, `documents/*.yaml`, `bundles/*.yaml`
  /// from [dataDir]. Parse failures throw a [FormatException] naming the file.
  static DataSet loadFromDirectory(Directory dataDir) {
    List<DataEntry> loadDir(String kind, String sub) {
      final dir = Directory('${dataDir.path}${Platform.pathSeparator}$sub');
      if (!dir.existsSync()) return const []; // e.g. minimal test fixtures
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.yaml'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      return [
        for (final f in files) _parseEntry(kind, f),
      ];
    }

    final agenciesFile = File(
      '${dataDir.path}${Platform.pathSeparator}agencies.yaml',
    );
    if (!agenciesFile.existsSync()) {
      throw StateError('Missing ${agenciesFile.path}');
    }
    final agencies = _parseAgencies(agenciesFile);

    return DataSet(
      agencies: agencies,
      documents: loadDir('document', 'documents'),
      bundles: loadDir('bundle', 'bundles'),
    );
  }

  static List<DataEntry> _parseAgencies(File file) {
    final raw = _loadYaml(file);
    if (raw is! List) {
      throw FormatException(
        '${file.path}: top level must be a list of agencies',
      );
    }
    return [
      for (var i = 0; i < raw.length; i++)
        DataEntry(
          kind: 'agency',
          sourcePath: '${file.path}[$i]',
          mtime: file.lastModifiedSync(),
          data: _deepConvert(raw[i]),
        ),
    ];
  }

  static DataEntry _parseEntry(String kind, File file) {
    final raw = _loadYaml(file);
    if (raw is! Map) {
      throw FormatException('${file.path}: top level must be a mapping');
    }
    return DataEntry(
      kind: kind,
      sourcePath: file.path,
      mtime: file.lastModifiedSync(),
      data: _deepConvert(raw),
    );
  }

  static Object? _loadYaml(File file) {
    try {
      return loadYaml(file.readAsStringSync());
    } on FormatException catch (e) {
      throw FormatException('${file.path}: invalid YAML: ${e.message}');
    }
  }

  /// Converts YamlMap/YamlList (and scalar nodes) into plain Dart maps/lists
  /// of String keys, suitable for JSON encoding and schema validation.
  static Map<String, dynamic> _deepConvert(Object? node) {
    final json = jsonDecode(jsonEncode(node));
    return json as Map<String, dynamic>;
  }
}
