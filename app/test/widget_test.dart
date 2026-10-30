import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/core/settings.dart';
import 'package:kumpleto/l10n/app_localizations.dart';

import 'support/pump_app.dart';

/// First-run flow: the disclaimer gate must show before anything else and the
/// acknowledgement must persist across launches.
void main() {
  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  testWidgets('first run shows onboarding disclaimer and gate', (tester) async {
    await pumpKumpleto(tester, firstRunDone: false);

    expect(find.text(l10nOf(tester).onboardingTitle), findsOneWidget);
    expect(find.text(l10nOf(tester).onboardingDisclaimer), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(SegmentedButton<String>), findsOneWidget);
  });

  testWidgets('acknowledging onboarding reveals bottom navigation',
      (tester) async {
    final settings = await pumpKumpleto(tester, firstRunDone: false);

    await tester.tap(find.text(l10nOf(tester).onboardingAcknowledge));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text(l10nOf(tester).navHome), findsOneWidget);

    // The acknowledgement persisted (same in-process preferences store).
    expect(settings.firstRunDone, isTrue);
    final reloaded = await AppSettings.load();
    expect(reloaded.firstRunDone, isTrue);
  });

  testWidgets('returning user lands on home (no onboarding)', (tester) async {
    await pumpKumpleto(tester, firstRunDone: true);

    expect(find.byType(NavigationBar), findsOneWidget);
    // No ticks yet, so the "Continue" row is hidden and bundles show instead.
    expect(find.text(l10nOf(tester).homeBundles), findsOneWidget);
  });
}
