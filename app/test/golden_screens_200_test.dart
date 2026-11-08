import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/l10n/app_localizations.dart';

import 'support/pump_app.dart';

/// A golden per screen at a 200% text scale on a 360×740 phone.
///
/// The accessibility test asserts that nothing throws; these goldens keep the
/// exact layout, so a change that silently squashes or clips a label shows up
/// as an image diff instead of reaching a reader. Regenerate with
/// `flutter test test/golden_screens_200_test.dart --update-goldens`.
void main() {
  void phoneAt200(WidgetTester tester) {
    tester.view.physicalSize = const Size(360 * 2, 740 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(WidgetsApp),
      matchesGoldenFile('goldens/200_$name.png'),
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  testWidgets('home at 200% text scale', (tester) async {
    phoneAt200(tester);
    await pumpKumpleto(tester);
    await capture(tester, 'home');
  });

  testWidgets('documents at 200% text scale', (tester) async {
    phoneAt200(tester);
    await pumpKumpleto(tester);
    await tester.tap(find.text(l10nOf(tester).navDocuments));
    await tester.pumpAndSettle();
    await capture(tester, 'documents');
  });

  testWidgets('document detail at 200% text scale', (tester) async {
    phoneAt200(tester);
    await pumpKumpleto(tester);
    await tester.tap(find.text(l10nOf(tester).navDocuments));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NBI Clearance'));
    await tester.pumpAndSettle();
    await capture(tester, 'document_detail');
  });

  testWidgets('bundle detail at 200% text scale', (tester) async {
    phoneAt200(tester);
    await pumpKumpleto(tester);
    final bundle = find.text('Job Hunt Pack');
    await tester.ensureVisible(bundle);
    await tester.pumpAndSettle();
    await tester.tap(bundle);
    await tester.pumpAndSettle();
    await capture(tester, 'bundle_detail');
  });

  testWidgets('settings at 200% text scale', (tester) async {
    phoneAt200(tester);
    await pumpKumpleto(tester);
    await tester.tap(find.text(l10nOf(tester).navSettings));
    await tester.pumpAndSettle();
    await capture(tester, 'settings');
  });
}
