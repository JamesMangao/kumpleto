import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/core/settings.dart';
import 'package:kumpleto/l10n/app_localizations.dart';

import 'support/pump_app.dart';

/// Reads the localizations of whatever screen is currently on top.
AppLocalizations l10nOf(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold).last);
  return AppLocalizations.of(context)!;
}

/// Settings must apply the moment they are picked — no relaunch, no
/// "restart the app to see changes".
void main() {
  group('Settings apply instantly', () {
    testWidgets('switching the language re-localizes the running app', (
      tester,
    ) async {
      final AppSettings settings = await pumpKumpleto(tester);
      final before = l10nOf(tester);

      await tester.tap(find.text(before.navSettings));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10nOf(tester).languageFilipino));
      await tester.pumpAndSettle();

      expect(settings.language, 'fil');
      final context = tester.element(find.byType(Scaffold).last);
      expect(Localizations.localeOf(context).languageCode, 'fil');
      // The same screen, re-localized in place.
      expect(find.text(l10nOf(tester).settingsTitle), findsWidgets);
      expect(l10nOf(tester).settingsTitle, isNot(before.settingsTitle));
    });

    testWidgets('switching the theme repaints the running app', (tester) async {
      final AppSettings settings = await pumpKumpleto(tester);

      await tester.tap(find.text(l10nOf(tester).navSettings));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).last);
      expect(Theme.of(context).brightness, Brightness.light);

      await tester.tap(find.text(l10nOf(tester).settingsThemeDark));
      await tester.pumpAndSettle();

      expect(settings.themeMode, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
        Brightness.dark,
      );
    });

    testWidgets('the choice survives a rebuild without touching prefs', (
      tester,
    ) async {
      final AppSettings settings = await pumpKumpleto(tester);
      await settings.setLanguage('fil');
      await settings.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      expect(Localizations.localeOf(
        tester.element(find.byType(Scaffold).last),
      ).languageCode, 'fil');
      expect(
        Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
        Brightness.dark,
      );
    });
  });

  group('Welcome scene', () {
    testWidgets('plays on launch, welcome stays until dismissed', (tester) async {
      await pumpKumpleto(tester, showWelcome: true, settle: false);

      // The scene is up: its stamp and skip control are there from the start.
      expect(find.text('KUMPLETO'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Welcome stays until user taps Skip (no auto-alis)
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('KUMPLETO'), findsNothing);
      expect(find.text('Skip'), findsNothing);
    });
  });
}
