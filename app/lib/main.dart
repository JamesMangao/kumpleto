import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/settings.dart';
import 'core/theme.dart';
import 'data/app_paths.dart';
import 'data/progress.dart';
import 'data/providers.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'screens/welcome_screen.dart';

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

/// Root widget.
///
/// The router is built once and kept for the lifetime of the app, while the
/// [MaterialApp] is rebuilt whenever [AppSettings] notifies. That combination
/// is what makes a language or theme change take effect immediately without
/// restarting: the widget tree above the router updates, but the navigation
/// stack (the router instance) survives untouched.
class KumpletoApp extends StatefulWidget {
  const KumpletoApp({
    super.key,
    required this.settings,
    this.showWelcome = true,
  });

  final AppSettings settings;

  /// Widget tests pass false so the first frame is the real screen.
  final bool showWelcome;

  @override
  State<KumpletoApp> createState() => _KumpletoAppState();
}

class _KumpletoAppState extends State<KumpletoApp> {
  late final GoRouter _router = buildRouter(widget.settings);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) => MaterialApp.router(
        title: 'Kumpleto',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: widget.settings.themeMode,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: widget.settings.locale,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => WelcomeGate(
          show: widget.showWelcome,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
