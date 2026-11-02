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
    testWidgets('plays on launch, then hands over to the app', (tester) async {
      await pumpKumpleto(tester, showWelcome: true, settle: false);
      final l10n = l10nOf(tester);

      // Roughly 2 s in: the wordmark/tagline/skip hint are on screen.
      expect(find.text(l10n.welcomeSkip), findsOneWidget);
      expect(find.text(l10n.welcomeTagline), findsOneWidget);
      expect(find.text(l10n.unofficialBadge), findsWidgets);

      // It is a finite animation: settling it removes the scene for good.
      await tester.pumpAndSettle();
      expect(find.text(l10n.welcomeSkip), findsNothing);
      expect(find.text(l10n.welcomeTagline), findsNothing);
    });
  });
}
