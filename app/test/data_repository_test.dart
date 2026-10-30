import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/data/app_paths.dart';
import 'package:kumpleto/data/data_repository.dart';

import 'support/fake_asset_bundle.dart';
import 'support/test_payload.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kumpleto_data_repo');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  AppPaths paths() => AppPaths(tempDir);

  DataRepository repositoryWith(
    Map<String, String> assets, {
    AppPaths? withPaths,
  }) => DataRepository(
    assetBundle: FakeAssetBundle(assets),
    paths: withPaths ?? paths(),
  );

  String jsonOf(Map<String, Object?> data) => jsonEncode(data);

  group('bundled asset', () {
    test('loads the release asset when there is no cache', () async {
      final repository = repositoryWith({
        DataRepository.releaseAsset:
            jsonOf(sampleDataJson(dataVersion: '2026-10-01T00:00:00.000Z')),
      });
      final loaded = await repository.load();
      expect(loaded.source, DataSource.bundledRelease);
      expect(loaded.data.documents, hasLength(1));
      expect(loaded.data.dataVersion, '2026-10-01T00:00:00.000Z');
      expect(loaded.skipped, isEmpty);
    });

    test('a missing asset yields an empty dataset, never an exception',
        () async {
      final loaded = await repositoryWith({}).load();
      expect(loaded.data.documents, isEmpty);
      expect(loaded.data.dataVersion, 'none');
      expect(loaded.skipped.join(' '), contains('not found'));
    });

    test('an asset that fails verification is skipped', () async {
      final repository = repositoryWith({
        DataRepository.releaseAsset: '{"schema_version": 1}',
      });
      final loaded = await repository.load();
      expect(loaded.data.documents, isEmpty);
      expect(loaded.skipped.join(' '), contains('agencies/documents/bundles'));
    });
  });

  group('cache vs bundled', () {
    test('a NEWER cache wins over the bundled asset', () async {
      final repository = repositoryWith({
        DataRepository.releaseAsset:
            jsonOf(sampleDataJson(dataVersion: '2026-10-01T00:00:00.000Z')),
      }, withPaths: paths());
      await repository.saveCache(
        jsonOf(sampleDataJson(dataVersion: '2030-06-01T00:00:00.000Z')),
      );

      final loaded = await repository.load();
      expect(loaded.source, DataSource.cache);
      expect(loaded.data.dataVersion, '2030-06-01T00:00:00.000Z');
    });

    test('an OLDER cache loses to the bundled asset', () async {
      final repository = repositoryWith({
        DataRepository.releaseAsset:
            jsonOf(sampleDataJson(dataVersion: '2030-06-01T00:00:00.000Z')),
      });
      await repository.saveCache(
        jsonOf(sampleDataJson(dataVersion: '2026-10-01T00:00:00.000Z')),
      );

      final loaded = await repository.load();
      expect(loaded.source, DataSource.bundledRelease);
      expect(loaded.data.dataVersion, '2030-06-01T00:00:00.000Z');
    });

    test('a corrupt cache is ignored (invalid JSON)', () async {
      final repository = repositoryWith({
        DataRepository.releaseAsset: jsonOf(sampleDataJson()),
      }, withPaths: paths());
      await paths().dataCacheFile.writeAsString('{ this is not json');

      final loaded = await repository.load();
      expect(loaded.source, DataSource.bundledRelease);
      expect(loaded.skipped.join(' '), contains('invalid JSON'));
    });

    test('a cache with a sha256 mismatch is rejected', () async {
      final repository = repositoryWith({
        DataRepository.releaseAsset: jsonOf(sampleDataJson()),
      }, withPaths: paths());
      final tampered = sampleDataJson();
      (tampered['documents']! as List<Object?>).add(<String, Object?>{
        'id': 'evil',
        'name': <String, Object?>{'en': 'Evil'},
        'agency': 'nbi',
        'status': 'verified',
      });
      await paths().dataCacheFile.writeAsString(jsonEncode(tampered));

      final loaded = await repository.load();
      expect(loaded.source, DataSource.bundledRelease);
      expect(loaded.skipped.join(' '), contains('sha256 mismatch'));
    });

    test('a cache with a newer schema_version is rejected', () async {
      final repository = repositoryWith({
        DataRepository.releaseAsset: jsonOf(sampleDataJson()),
      }, withPaths: paths());
      await paths()
          .dataCacheFile
          .writeAsString(jsonEncode(compileDataJson(schemaVersion: 2)));

      final loaded = await repository.load();
      expect(loaded.source, DataSource.bundledRelease);
      expect(loaded.skipped.join(' '), contains('schema_version 2'));
    });

    test('an unreadable cache does not crash the load', () async {
      final repository = repositoryWith({
        DataRepository.releaseAsset: jsonOf(sampleDataJson()),
      }, withPaths: paths());
      // A cache file that exists but cannot be read as UTF-8 text.
      await paths().dataCacheFile.writeAsBytes([0xC3, 0x28, 0xA0, 0xA1]);

      final loaded = await repository.load();
      expect(loaded.source, DataSource.bundledRelease);
      expect(loaded.data.documents, hasLength(1));
    });
  });

  group('saveCache', () {
    test('persists the payload for the next launch', () async {
      final repository = repositoryWith({
        DataRepository.releaseAsset:
            jsonOf(sampleDataJson(dataVersion: '2026-10-01T00:00:00.000Z')),
      });
      final payload = jsonOf(
        sampleDataJson(dataVersion: '2031-01-01T00:00:00.000Z'),
      );
      await repository.saveCache(payload);

      expect(await paths().dataCacheFile.readAsString(), payload);

      final loaded = await repository.load();
      expect(loaded.source, DataSource.cache);
      expect(loaded.data.dataVersion, '2031-01-01T00:00:00.000Z');
    });

    test('a repository without paths neither writes nor throws', () async {
      final repository = DataRepository(
        assetBundle: FakeAssetBundle({
          DataRepository.releaseAsset: jsonOf(sampleDataJson()),
        }),
      );
      await repository.saveCache('{}');
      expect(repository.paths, isNull);

      final loaded = await repository.load();
      expect(loaded.source, DataSource.bundledRelease);
      expect(loaded.data.documents, hasLength(1));
    });
  });
}
