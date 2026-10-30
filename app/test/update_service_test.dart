import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kumpleto/core/settings.dart';
import 'package:kumpleto/data/app_paths.dart';
import 'package:kumpleto/data/data_repository.dart';
import 'package:kumpleto/data/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_asset_bundle.dart';
import 'support/test_payload.dart';

/// P2 fetch hardening: HTTPS only, ≤ 3 redirects, 2 MB cap, 10 s timeout,
/// ETag revalidation. Every failure is a value, never an exception.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const feedUrl = 'https://feed.example/data.json';
  final feedUri = Uri.parse(feedUrl);

  late SharedPreferences prefs;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tempDir = Directory.systemTemp.createTempSync('kumpleto_update');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  UpdateService serviceWith(
    http.Client client, {
    Uri? url,
    DataRepository? repository,
    Duration timeout = const Duration(seconds: 10),
    DateTime Function()? now,
  }) => UpdateService(
    client: client,
    url: url ?? feedUri,
    prefs: prefs,
    repository: repository ?? DataRepository(),
    timeout: timeout,
    now: now ?? DateTime.now,
  );

  /// Returns a *valid* payload so gate tests can assert a real success.
  MockClient okClient(List<http.Request> log) => MockClient((request) async {
    log.add(request);
    return http.Response(jsonEncode(sampleDataJson()), 200);
  });

  group('success paths', () {
    test('304 revalidates and keeps the stored ETag', () async {
      await prefs.setString(PrefsKeys.lastDataETag, '"v1"');
      final log = <http.Request>[];

      final result = await serviceWith(
        MockClient((request) async {
          log.add(request);
          return http.Response('', 304);
        }),
      ).checkNow();

      expect(result, isA<UpdateNotModified>());
      expect(log.single.headers['if-none-match'], '"v1"');
      expect(prefs.getString(PrefsKeys.lastDataETag), '"v1"');
      expect(prefs.getInt(PrefsKeys.lastDataCheck), isNotNull);
    });

    test('200 with a valid payload updates, stores the ETag and caches',
        () async {
      final body = jsonEncode(sampleDataJson());
      // The bundled copy is older than the fetched payload, so the cache wins.
      final repository = DataRepository(
        assetBundle: FakeAssetBundle({
          DataRepository.releaseAsset: jsonEncode(
            sampleDataJson(dataVersion: '2020-01-01T00:00:00.000Z'),
          ),
        }),
        paths: AppPaths(tempDir),
      );

      final result = await serviceWith(
        MockClient((_) async => http.Response(body, 200, headers: {'etag': '"v2"'})),
        repository: repository,
      ).checkNow();

      expect(result, isA<UpdateAccepted>());
      expect(prefs.getString(PrefsKeys.lastDataETag), '"v2"');
      expect(await tempDirFile(tempDir).readAsString(), body);

      final loaded = await repository.load();
      expect(loaded.source, DataSource.cache);
      expect(loaded.data.documents, hasLength(1));
    });

    test('a stored ETag is dropped when the server stops sending one',
        () async {
      await prefs.setString(PrefsKeys.lastDataETag, '"stale"');
      await serviceWith(
        MockClient(
          (_) async => http.Response(jsonEncode(sampleDataJson()), 200),
        ),
      ).checkNow();
      expect(prefs.getString(PrefsKeys.lastDataETag), isNull);
    });
  });

  group('invalid payloads (current data is kept)', () {
    test('200 with a non-JSON body', () async {
      final result = await serviceWith(
        MockClient((_) async => http.Response('<html>maintenance</html>', 200)),
      ).checkNow();
      expect(result, isA<UpdateInvalid>());
      expect(result.reasonOrNull, contains('not valid JSON'));
    });

    test('200 with a JSON list instead of an object', () async {
      final result = await serviceWith(
        MockClient((_) async => http.Response('[1, 2, 3]', 200)),
      ).checkNow();
      expect(result, isA<UpdateInvalid>());
      expect(result.reasonOrNull, contains('not an object'));
    });

    test('200 with a tampered payload (sha256 mismatch)', () async {
      final tampered = sampleDataJson();
      (tampered['documents']! as List<Object?>).add(<String, Object?>{
        'id': 'evil',
        'name': <String, Object?>{'en': 'Evil'},
        'agency': 'nbi',
        'status': 'verified',
      });
      final result = await serviceWith(
        MockClient((_) async => http.Response(jsonEncode(tampered), 200)),
      ).checkNow();
      expect(result, isA<UpdateInvalid>());
      expect(result.reasonOrNull, contains('sha256 mismatch'));
    });

    test('200 with an unsupported schema_version', () async {
      final result = await serviceWith(
        MockClient(
          (_) async => http.Response(
            jsonEncode(compileDataJson(schemaVersion: 2)),
            200,
          ),
        ),
      ).checkNow();
      expect(result, isA<UpdateInvalid>());
      expect(result.reasonOrNull, contains('schema_version 2'));
    });
  });

  group('failures (current data is kept)', () {
    test('non-200 response', () async {
      final result = await serviceWith(
        MockClient((_) async => http.Response('boom', 500)),
      ).checkNow();
      expect(result, isA<UpdateFailed>());
      expect(result.reasonOrNull, contains('HTTP 500'));
    });

    test('an http feed URL is rejected before anything is sent', () async {
      final log = <http.Request>[];
      final result = await serviceWith(
        okClient(log),
        url: Uri.parse('http://feed.example/data.json'),
      ).checkNow();
      expect(result, isA<UpdateFailed>());
      expect(result.reasonOrNull, contains('https'));
      expect(log, isEmpty);
    });

    test('Content-Length over the cap is refused without reading', () async {
      final client = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream<List<int>>.fromIterable(<List<int>>[utf8.encode('{}')]),
          200,
          contentLength: 3 * 1024 * 1024,
          headers: const {'content-type': 'application/json'},
        );
      });
      final result = await serviceWith(client).checkNow();
      expect(result, isA<UpdateFailed>());
      expect(result.reasonOrNull, contains('body too large'));
    });

    test('a body that exceeds the cap while streaming is aborted', () async {
      final chunk = List<int>.filled(512 * 1024, 0x20); // 0.5 MB of spaces
      final client = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream<List<int>>.fromIterable(List.generate(6, (_) => chunk)),
          200,
          headers: const {'content-type': 'application/json'},
        );
      });
      final result = await serviceWith(client).checkNow();
      expect(result, isA<UpdateFailed>());
      expect(result.reasonOrNull, contains('2 MB'));
    });

    test('a hanging response hits the overall timeout', () async {
      final client = MockClient((_) => Completer<http.Response>().future);
      final result = await serviceWith(
        client,
        timeout: const Duration(milliseconds: 20),
      ).checkNow();
      expect(result, isA<UpdateFailed>());
      expect(result.reasonOrNull, contains('timed out'));
    });
  });

  group('redirects (manual loop, max 3 hops, https only)', () {
    MockClient clientWith(MockClientHandler handler) => MockClient(handler);

    test('follows up to 3 redirects and still parses the body', () async {
      final log = <http.Request>[];
      final body = jsonEncode(sampleDataJson());
      final client = clientWith((request) async {
        log.add(request);
        return switch (request.url.path) {
          '/data.json' => http.Response(
              '',
              301,
              headers: {'location': 'https://feed.example/a.json'},
            ),
          '/a.json' => http.Response(
              '',
              302,
              headers: {'location': 'https://feed.example/b.json'},
            ),
          '/b.json' => http.Response(
              '',
              307,
              headers: {'location': 'https://feed.example/final.json'},
            ),
          '/final.json' => http.Response(body, 200),
          _ => http.Response('unexpected path ${request.url.path}', 404),
        };
      });

      final result = await serviceWith(client).checkNow();
      expect(result, isA<UpdateAccepted>());
      expect(log.map((r) => r.url.path), [
        '/data.json',
        '/a.json',
        '/b.json',
        '/final.json',
      ]);
      // If-None-Match is only sent on the first hop, not on every redirect.
      expect(log.first.headers.containsKey('if-none-match'), isFalse);
      expect(log.where((r) => r.headers.containsKey('if-none-match')), isEmpty);
    });

    test('a 4th redirect fails the check', () async {
      final client = clientWith((request) async => http.Response(
        '',
        302,
        headers: {'location': 'https://feed.example${request.url.path}x'},
      ));
      final result = await serviceWith(client).checkNow();
      expect(result, isA<UpdateFailed>());
      expect(result.reasonOrNull, contains('more than 3 redirects'));
    });

    test('a redirect to an http URL fails the check', () async {
      final log = <http.Request>[];
      final client = clientWith((request) async {
        log.add(request);
        return http.Response(
          '',
          302,
          headers: {'location': 'http://feed.example/data.json'},
        );
      });
      final result = await serviceWith(client).checkNow();
      expect(result, isA<UpdateFailed>());
      expect(result.reasonOrNull, contains('non-https'));
      expect(log, hasLength(1));
    });

    test('a redirect without a Location header fails the check', () async {
      final client = clientWith((_) async => http.Response('', 302));
      final result = await serviceWith(client).checkNow();
      expect(result, isA<UpdateFailed>());
      expect(result.reasonOrNull, contains('Location'));
    });
  });

  group('24 h gate', () {
    test('runs on first launch (nothing recorded yet)', () async {
      final log = <http.Request>[];
      final result = await serviceWith(okClient(log)).maybeCheck();
      expect(result, isA<UpdateAccepted>());
      expect(log, hasLength(1));
    });

    test('is skipped when the last check is younger than 24 h', () async {
      final now = DateTime(2026, 10, 29, 12);
      await prefs.setInt(
        PrefsKeys.lastDataCheck,
        now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
      );
      final log = <http.Request>[];
      final result = await serviceWith(
        okClient(log),
        now: () => now,
      ).maybeCheck();
      expect(result, isNull);
      expect(log, isEmpty);
    });

    test('runs again once 24 h have elapsed', () async {
      final now = DateTime(2026, 10, 29, 12);
      await prefs.setInt(
        PrefsKeys.lastDataCheck,
        now.subtract(const Duration(hours: 25)).millisecondsSinceEpoch,
      );
      final log = <http.Request>[];
      final result = await serviceWith(
        okClient(log),
        now: () => now,
      ).maybeCheck();
      expect(result, isA<UpdateAccepted>());
      expect(log, hasLength(1));
      expect(prefs.getInt(PrefsKeys.lastDataCheck), now.millisecondsSinceEpoch);
    });

    test('checkNow ignores the gate (manual Settings check)', () async {
      final now = DateTime(2026, 10, 29, 12);
      await prefs.setInt(
        PrefsKeys.lastDataCheck,
        now.millisecondsSinceEpoch,
      );
      final log = <http.Request>[];
      await serviceWith(okClient(log), now: () => now).checkNow();
      expect(log, hasLength(1));
    });
  });
}

File tempDirFile(Directory dir) =>
    File('${dir.path}${Platform.pathSeparator}data_cache.json');
