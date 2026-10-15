import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/core/settings.dart';
import 'package:kumpleto/l10n/app_localizations.dart';
import 'package:kumpleto/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  testWidgets('first run shows onboarding disclaimer and gate', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    await tester.pumpWidget(KumpletoApp(settings: settings));
    await tester.pumpAndSettle();

    expect(find.text(l10nOf(tester).onboardingTitle), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('acknowledging onboarding reveals bottom navigation',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    await tester.pumpWidget(KumpletoApp(settings: settings));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10nOf(tester).onboardingAcknowledge));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text(l10nOf(tester).navHome), findsOneWidget);

    // The acknowledgement persisted across the settings reload.
    final reloaded = await AppSettings.load();
    expect(reloaded.firstRunDone, isTrue);
    await tester.pumpWidget(KumpletoApp(settings: reloaded));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('returning user lands on home (no onboarding)', (tester) async {
    SharedPreferences.setMockInitialValues({'first_run_done': true});
    final settings = await AppSettings.load();
    await tester.pumpWidget(KumpletoApp(settings: settings));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
