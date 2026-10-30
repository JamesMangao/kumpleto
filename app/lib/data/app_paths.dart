import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Every on-device file path the app uses, in one place, so tests can point
/// them at a temp directory instead of the real documents dir.
class AppPaths {
  const AppPaths(this.documentsDir);

  /// Resolves the platform documents directory (app-private on Android).
  static Future<AppPaths> resolve() async =>
      AppPaths(await getApplicationDocumentsDirectory());

  final Directory documentsDir;

  /// Last accepted data feed payload (see docs/DECISIONS.md, P2).
  File get dataCacheFile => _file('data_cache.json');

  /// User progress database.
  File get databaseFile => _file('kumpleto.sqlite');

  File _file(String name) =>
      File('${documentsDir.path}${Platform.pathSeparator}$name');
}