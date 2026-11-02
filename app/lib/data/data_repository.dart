import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    show AssetBundle, rootBundle;

import '../core/canonical.dart';
import '../core/constants.dart';
import '../models/models.dart';
import 'app_paths.dart';

/// Where the currently displayed data came from (shown in Settings).
enum DataSource {
  bundledRelease('Bundled (release)'),
  bundledDrafts('Bundled (dev, includes drafts)'),
  cache('Cached update');

  const DataSource(this.label);

  final String label;
}

/// The loaded dataset plus how it was obtained.
class LoadedData {
  const LoadedData({
    required this.data,
    required this.source,
    this.skipped = const <String>[],
  });

  final DataBundle data;
  final DataSource source;

  /// Reasons candidates were rejected (surfaced in Settings for debugging).
  final List<String> skipped;
}

/// Loads the compiled data bundle and keeps the freshest usable copy.
///
/// Order of trust: the bundled asset is always present, so the app works
/// offline on first launch; a cached feed payload is used only when it is
/// *newer* and passes the same verification. A corrupt or unverifiable
/// candidate is skipped, never fatal.
class DataRepository {
  DataRepository({AssetBundle? assetBundle, this.paths})
    : assetBundle = assetBundle ?? rootBundle;

  static const String releaseAsset = 'assets/data/data.json';
  static const String draftsAsset = 'assets/data/data_drafts.json';

  final AssetBundle assetBundle;
  final AppPaths? paths;

  Future<LoadedData> load() async {
    final skipped = <String>[];

    final cached = await _readCache(skipped);
    final bundled = await _readBundled(skipped);

    final candidates = <_Candidate>[?bundled, ?cached];
    if (candidates.isEmpty) {
      return LoadedData(
        data: DataBundle.empty(),
        source: DataSource.bundledRelease,
        skipped: skipped,
      );
    }
    candidates.sort((a, b) => b.dataVersion.compareTo(a.dataVersion));
    final best = candidates.first;
    return LoadedData(data: best.data, source: best.source, skipped: skipped);
  }

  /// Persists an accepted feed payload so it survives restarts.
  Future<void> saveCache(String rawJson) async {
    final paths = this.paths;
    if (paths == null) return;
    try {
      await paths.dataCacheFile.writeAsString(rawJson, flush: true);
    } on FileSystemException catch (error) {
      debugPrint('Kumpleto: could not cache data feed (${error.message})');
    }
  }

  /// The bundled asset. When the compiler shipped a drafts asset
  /// (`dart run tools/build_data.dart --include-drafts`), it is used in every
  /// flavor: the sideloaded APK is expected to carry the whole library, with
  /// each entry badged by its verification state.
  ///
  /// The drafts file is gitignored and is deleted by a plain compiler run, so a
  /// clean or CI build has no such asset and falls back to the verified-only
  /// release feed. The published feed (`dist/data.json`) is unaffected and still
  /// contains verified entries only (docs/DECISIONS.md, P3).
  Future<_Candidate?> _readBundled(List<String> skipped) async {
    final drafts = await _readAsset(draftsAsset);
    if (drafts != null) {
      final candidate = _verify(drafts, DataSource.bundledDrafts, skipped);
      if (candidate != null) return candidate;
    }
    final release = await _readAsset(releaseAsset);
    if (release == null) {
      skipped.add('bundled asset $releaseAsset not found');
      return null;
    }
    return _verify(release, DataSource.bundledRelease, skipped);
  }

  Future<_Candidate?> _readCache(List<String> skipped) async {
    final paths = this.paths;
    if (paths == null) return null;
    try {
      final file = paths.dataCacheFile;
      if (!await file.exists()) return null;
      return _verify(await file.readAsString(), DataSource.cache, skipped);
    } on Object catch (error) {
      // An unreadable or non-UTF-8 cache is not fatal: fall back to the
      // bundled asset (and the next accepted update rewrites the file).
      skipped.add('cache unreadable ($error)');
      return null;
    }
  }

  Future<String?> _readAsset(String key) async {
    try {
      return await assetBundle.loadString(key);
    } on FlutterError {
      return null; // absent asset (release builds have no drafts file)
    }
  }

  _Candidate? _verify(String raw, DataSource source, List<String> skipped) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      skipped.add('${source.label}: invalid JSON (${error.message})');
      return null;
    }
    if (decoded is! Map<Object?, Object?>) {
      skipped.add('${source.label}: top level is not an object');
      return null;
    }
    final json = <String, Object?>{
      for (final entry in decoded.entries) entry.key.toString(): entry.value,
    };
    final reason = verifyDataJson(
      json,
      maxSchemaVersion: supportedSchemaVersion,
    );
    if (reason != null) {
      skipped.add('${source.label}: $reason');
      return null;
    }
    return _Candidate(
      data: DataBundle.fromJson(json),
      source: source,
      dataVersion: json['data_version'] is String
          ? json['data_version']! as String
          : '',
    );
  }
}

class _Candidate {
  const _Candidate({
    required this.data,
    required this.source,
    required this.dataVersion,
  });

  final DataBundle data;
  final DataSource source;
  final String dataVersion;
}