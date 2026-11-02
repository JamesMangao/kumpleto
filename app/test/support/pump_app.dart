import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/core/settings.dart';
import 'package:kumpleto/data/app_paths.dart';
import 'package:kumpleto/data/data_repository.dart';
import 'package:kumpleto/data/progress.dart';
import 'package:kumpleto/data/providers.dart';
import 'package:kumpleto/main.dart';
import 'package:kumpleto/models/models.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_asset_bundle.dart';
import 'test_payload.dart';

/// The dataset every widget test renders:
///
/// * `nbi-clearance` — draft, 3 requirements (one optional, one original),
///   2 steps, fee note, one dependency;
/// * `psa-birth-certificate` — draft with nothing filled in (empty notice);
/// * `postal-id` — deprecated (banner);
/// * `job-hunt-pack` — bundle containing the first and last documents.
Map<String, Object?> widgetTestData() => compileDataJson(
  dataVersion: '2026-10-01T00:00:00.000Z',
  agencies: [
    <String, Object?>{
      'id': 'nbi',
      'name': <String, Object?>{
        'en': 'National Bureau of Investigation',
        'fil': 'National Bureau of Investigation',
      },
    },
    <String, Object?>{
      'id': 'psa',
      'name': <String, Object?>{
        'en': 'Philippine Statistics Authority',
        'fil': 'Philippine Statistics Authority',
      },
    },
    <String, Object?>{
      'id': 'postal',
      'name': <String, Object?>{
        'en': 'Philippine Postal Corporation',
        'fil': 'Philippine Postal Corporation',
      },
    },
  ],
  documents: [
    <String, Object?>{
      'id': 'nbi-clearance',
      'name': <String, Object?>{'en': 'NBI Clearance', 'fil': 'NBI Clearance'},
      'agency': 'nbi',
      'status': 'draft',
      'summary': <String, Object?>{
        'en': 'Clearance commonly required by employers.',
        'fil': 'Clearance na karaniwang hinihingi ng mga employer.',
      },
      'source_url': 'https://nbi.gov.ph/how-to-apply-nbi-clearance',
      'apply_online': true,
      'apply_online_url': 'https://clearance.nbi.gov.ph',
      'validity_months': 6,
      'tags': ['job-hunt', 'clearance'],
      'requirements': [
        <String, Object?>{
          'id': 'reference-number',
          'text': <String, Object?>{
            'en': 'Printed Reference Number',
            'fil': 'Nakaprintang Reference Number',
          },
        },
        <String, Object?>{
          'id': 'valid-ids',
          'text': <String, Object?>{
            'en': 'Two (2) valid government IDs',
            'fil': 'Dalawang (2) valid na ID ng gobyerno',
          },
          'original': true,
          'photocopies': 2,
        },
        <String, Object?>{
          'id': 'barangay-cert',
          'text': <String, Object?>{
            'en': 'Barangay Certification (RA 11261)',
            'fil': 'Barangay Certification (RA 11261)',
          },
          'optional': true,
        },
      ],
      'steps': [
        <String, Object?>{
          'en': 'Register on the NBI portal.',
          'fil': 'Mag-register sa NBI portal.',
        },
        <String, Object?>{
          'en': 'Pay and keep the reference number.',
          'fil': 'Bayaran at itago ang reference number.',
        },
      ],
      'fee_note': <String, Object?>{
        'en': '₱130 plus an e-payment charge.',
        'fil': '₱130 dagdag sa e-payment charge.',
      },
      'depends_on': ['psa-birth-certificate'],
    },
    <String, Object?>{
      'id': 'psa-birth-certificate',
      'name': <String, Object?>{
        'en': 'PSA Birth Certificate',
        'fil': 'PSA Birth Certificate',
      },
      'agency': 'psa',
      'status': 'draft',
      'source_url': 'https://psa.gov.ph/birth-certificate',
      'tags': ['job-hunt'],
      'requirements': <Object?>[],
      'steps': <Object?>[],
    },
    <String, Object?>{
      'id': 'postal-id',
      'name': <String, Object?>{
        'en': 'Postal ID (old card)',
        'fil': 'Postal ID (lumang card)',
      },
      'agency': 'postal',
      'status': 'deprecated',
      'requirements': <Object?>[],
      'steps': <Object?>[],
    },
  ],
  bundles: [
    <String, Object?>{
      'id': 'job-hunt-pack',
      'name': <String, Object?>{
        'en': 'Job Hunt Pack',
        'fil': 'Job Hunt Pack',
      },
      'description': <String, Object?>{
        'en': 'Documents commonly asked for when applying to jobs.',
        'fil': 'Mga dokumentong karaniwang hinihingi sa pag-aapply.',
      },
      'status': 'draft',
      'documents': ['nbi-clearance', 'postal-id'],
      'tags': ['job-hunt'],
      'icon': 'work',
      'notes': [
        <String, Object?>{
          'en': 'RA 11261 waives fees for first-time jobseekers.',
          'fil': 'Walang bayad sa first-time jobseekers ayon sa RA 11261.',
        },
      ],
    },
  ],
);

/// Pumps the whole app with isolated providers: in-memory database, temp
/// directory, mocked preferences/package info and a fixed dataset.
///
/// Returns the [AppSettings] so tests can assert on persisted values.
Future<AppSettings> pumpKumpleto(
  WidgetTester tester, {
  bool firstRunDone = true,
  Map<String, Object?>? data,
  bool settle = true,
  bool showWelcome = false,
}) async {
  SharedPreferences.setMockInitialValues({'first_run_done': firstRunDone});
  PackageInfo.setMockInitialValues(
    appName: 'Kumpleto',
    packageName: 'io.github.jamesmangao.kumpleto',
    version: '1.2.3',
    buildNumber: '7',
    buildSignature: 'test',
  );
  final settings = await AppSettings.load();

  final dir = Directory.systemTemp.createTempSync('kumpleto_widget');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  final paths = AppPaths(dir);
  final payload = data ?? widgetTestData();
  // `closeStreamsSynchronously` makes drift detach query streams immediately
  // when the last listener goes away instead of one event-loop iteration
  // later. The deferred path uses an internal timer, which the fake test
  // clock would report as still pending at the end of the test.
  final database = KumpletoDb(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPathsProvider.overrideWithValue(paths),
        kumpletoDbProvider.overrideWithValue(database),
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        dataRepositoryProvider.overrideWithValue(
          DataRepository(
            assetBundle: FakeAssetBundle({
              DataRepository.releaseAsset: jsonEncode(payload),
            }),
            paths: paths,
          ),
        ),
        // `testWidgets` runs on a fake clock: real file reads in
        // DataRepository.load() would never complete, and the repository
        // itself is covered by data_repository_test.dart. Here we hand the
        // parsed payload straight to the providers.
        loadedDataProvider.overrideWith(
          (ref) async => LoadedData(
            data: DataBundle.fromJson(payload),
            source: DataSource.bundledRelease,
          ),
        ),
      ],
      child: KumpletoApp(settings: settings, showWelcome: showWelcome),
    ),
  );

  addTearDown(() async {
    // Unmount first so providers release their drift subscriptions, then
    // flush the microtasks that releases schedule before the invariant check.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    // Closing after the pump matters: drift's close() awaits its internal
    // stream timers, which only fire when the fake clock advances.
    await database.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
  return settings;
}

/// Drags from the centre of the app surface, so hit-testing picks whichever
/// scrollable is actually on screen (branch screens stay mounted offstage).
Future<void> dragScreen(WidgetTester tester, Offset delta) async {
  final center = tester.getRect(find.byType(WidgetsApp)).center;
  await tester.dragFrom(center, delta);
  await tester.pumpAndSettle();
}

/// Scrolls until [finder]'s centre is on screen.
///
/// `ListView` children outside the cache extent are not built at all, so this
/// also handles a finder that matches nothing yet by dragging blindly.
Future<void> scrollIntoView(
  WidgetTester tester,
  Finder finder, {
  int maxDrags = 20,
}) async {
  final height = tester.getRect(find.byType(WidgetsApp)).height;
  for (var i = 0; i < maxDrags; i++) {
    if (finder.evaluate().isNotEmpty) {
      final center = tester.getRect(finder).center;
      if (center.dy > 80 && center.dy < height - 100) return;
      final needed = (center.dy - height / 2).clamp(-400.0, 400.0);
      await dragScreen(tester, Offset(0, -needed));
    } else {
      await dragScreen(tester, const Offset(0, -400));
    }
  }
  fail('could not scroll $finder into view');
}

/// Drags the visible page back to the top (momentum stops at offset 0).
Future<void> scrollToTop(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await dragScreen(tester, const Offset(0, 1200));
  }
}
