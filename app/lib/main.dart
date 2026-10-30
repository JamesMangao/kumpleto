import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/settings.dart';
import 'core/theme.dart';
import 'data/app_paths.dart';
import 'data/progress.dart';
import 'data/providers.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  final prefs = await SharedPreferences.getInstance();
  // Opened once for the app's lifetime and injected, so every screen shares a
  // single connection and tests can override both.
  final paths = await AppPaths.resolve();
  final database = KumpletoDb(
    NativeDatabase.createInBackground(paths.databaseFile),
  );
  final container = ProviderContainer(
    overrides: [
      appPathsProvider.overrideWithValue(paths),
      kumpletoDbProvider.overrideWithValue(database),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: KumpletoApp(settings: settings),
    ),
  );
  // Silent, at most once per 24 h: the first frame never waits for this.
  container.read(scheduledUpdateProvider.future);
}

class KumpletoApp extends ConsumerWidget {
  const KumpletoApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = buildRouter(settings);
    return MaterialApp.router(
      title: 'Kumpleto',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: settings.locale,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
