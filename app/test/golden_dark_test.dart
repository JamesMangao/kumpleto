import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/l10n/app_localizations.dart';

import 'support/pump_app.dart';

/// Dark-theme goldens for the three screens where the accent meets a fill.
///
/// The 200% goldens run in the light theme, so they say nothing about the
/// other failure we have actually shipped once: an accent call landing on a
/// filled badge, or a fill quietly turning into the mint accent, leaving white
/// text on `#5FD3B6`. Freezing what dark mode paints makes that visible as an
/// image diff instead of a screenshot someone has to remember to take.
///
/// Regenerate with `flutter test test/golden_dark_test.dart --update-goldens`.
void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360 * 2, 740 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpDark(WidgetTester tester) async {
    phone(tester);
    // 1 == ThemeMode.dark; passing it as a stored preference means the first
    // frame is already dark, so no light flash ends up in the image.
    final settings = await pumpKumpleto(
      tester,
      prefs: <String, Object?>{'theme_mode': ThemeMode.dark.index},
    );
    expect(settings.themeMode, ThemeMode.dark);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(WidgetsApp),
      matchesGoldenFile('goldens/dark_$name.png'),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  testWidgets('home in the dark theme', (tester) async {
    await pumpDark(tester);
    await capture(tester, 'home');
  });

  testWidgets('documents in the dark theme', (tester) async {
    await pumpDark(tester);
    await tester.tap(find.text(l10nOf(tester).navDocuments));
    await tester.pumpAndSettle();
    await capture(tester, 'documents');
  });

  testWidgets('document detail in the dark theme', (tester) async {
    await pumpDark(tester);
    await tester.tap(find.text(l10nOf(tester).navDocuments));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NBI Clearance'));
    await tester.pumpAndSettle();
    await capture(tester, 'document_detail');
  });

  // The bundle tiles carry the third badge we had to put back on the brand
  // teal; its index numeral is white, so it only stays readable as a fill.
  testWidgets('bundle detail in the dark theme', (tester) async {
    await pumpDark(tester);
    final bundle = find.text('Job Hunt Pack');
    await tester.scrollUntilVisible(
      bundle,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(bundle);
    await tester.pumpAndSettle();
    // The 18 dp index badge sits on each document tile, below the header.
    await scrollIntoView(tester, find.text('NBI Clearance'));
    await capture(tester, 'bundle_detail');
  });

  // The numbered step badges are filled circles with a white numeral: the exact
  // shape that broke when the accent call landed on a fill, and they sit below
  // the fold of the golden above.
  testWidgets('document detail steps in the dark theme', (tester) async {
    await pumpDark(tester);
    await tester.tap(find.text(l10nOf(tester).navDocuments));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NBI Clearance'));
    await tester.pumpAndSettle();
    await scrollIntoView(tester, find.text('Register on the NBI portal.'));
    await capture(tester, 'document_detail_steps');
  });
}
