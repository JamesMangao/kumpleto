import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/core/settings.dart';
import 'package:kumpleto/l10n/app_localizations.dart';

import 'support/pump_app.dart';

/// First-run flow: the disclaimer gate must show before anything else, the
/// language choice comes after it, and the acknowledgement must persist across
/// launches.
void main() {
  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  testWidgets('first run opens the disclaimer gate, not onboarding',
      (tester) async {
    await pumpKumpleto(tester, firstRunDone: false);

    final l10n = l10nOf(tester);
    expect(find.text(l10n.disclaimerScreenTitle), findsOneWidget);
    expect(find.text(l10n.disclaimerScreenAgree), findsOneWidget);
    expect(find.text(l10n.onboardingTitle), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('agreeing on the gate reveals the onboarding recap',
      (tester) async {
    await pumpKumpleto(tester, firstRunDone: false);

    await tester.tap(find.text(l10nOf(tester).disclaimerScreenAgree));
    await tester.pumpAndSettle();

    final l10n = l10nOf(tester);
    expect(find.text(l10n.disclaimerScreenTitle), findsNothing);
    expect(find.text(l10n.onboardingTitle), findsOneWidget);
    expect(find.byType(SegmentedButton<String>), findsOneWidget);
  });

  testWidgets('the gate can open the privacy page before agreeing',
      (tester) async {
    await pumpKumpleto(tester, firstRunDone: false);

    await tester.tap(find.text(l10nOf(tester).settingsPrivacy));
    await tester.pumpAndSettle();

    // The push is not bounced back to the gate by the first-run redirect.
    expect(find.text(l10nOf(tester).disclaimerScreenTitle), findsNothing);
    expect(find.text(l10nOf(tester).settingsPrivacy), findsWidgets);
  });

  testWidgets('acknowledging onboarding reveals bottom navigation',
      (tester) async {
    final settings = await pumpKumpleto(tester, firstRunDone: false);

    await tester.tap(find.text(l10nOf(tester).disclaimerScreenAgree));
    await tester.pumpAndSettle();
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
