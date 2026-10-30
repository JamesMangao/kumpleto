import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/l10n/app_localizations.dart';

import 'support/pump_app.dart';

/// Accessibility acceptance (docs/REMAINING_WORK.md, P4):
///
/// * every interactive control is at least 48 dp in both dimensions,
/// * icon-only controls and the search fields carry a spoken label,
/// * every screen lays out cleanly at a 200% text scale.
void main() {
  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  /// Pumps the app and walks Home → Documents → detail → bundle → Settings,
  /// invoking [body] on each screen. The visitor stops on the last screen.
  Future<void> visitScreens(
    WidgetTester tester,
    Future<void> Function(String screen) body,
  ) async {
    await pumpKumpleto(tester);
    await body('Home');

    await tester.tap(find.text(l10nOf(tester).navDocuments));
    await tester.pumpAndSettle();
    await body('Documents');

    await tester.tap(find.text('NBI Clearance'));
    await tester.pumpAndSettle();
    await body('Document detail');
    await tester.tap(find.byTooltip(l10nOf(tester).back));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10nOf(tester).navHome));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Job Hunt Pack'));
    await tester.pumpAndSettle();
    await body('Bundle detail');
    await tester.tap(find.byTooltip(l10nOf(tester).back));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10nOf(tester).navSettings));
    await tester.pumpAndSettle();
    await body('Settings');
  }

  group('Touch targets', () {
    testWidgets('every IconButton is at least 48x48 logical pixels',
        (tester) async {
      await visitScreens(tester, (screen) async {
        final buttons = find.byType(IconButton);
        for (var i = 0; i < buttons.evaluate().length; i++) {
          final size = tester.getSize(buttons.at(i));
          expect(
            size,
            greaterThanOrEqualTo(const Size(48, 48)),
            reason: '$screen: IconButton $size is below the 48 dp minimum',
          );
        }
      });
    });

    testWidgets('the bottom navigation bar is at least 48 dp tall',
        (tester) async {
      await pumpKumpleto(tester);
      final size = tester.getSize(find.byType(NavigationBar));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });
  });

  group('Spoken labels', () {
    testWidgets('every IconButton exposes a tooltip', (tester) async {
      await visitScreens(tester, (screen) async {
        final buttons = tester.widgetList<IconButton>(
          find.byType(IconButton),
        );
        for (final button in buttons) {
          expect(
            button.tooltip,
            isNotNull,
            reason: '$screen: IconButton without a tooltip has no TalkBack '
                'label',
          );
          expect(button.tooltip!.trim(), isNotEmpty);
        }
      });
    });

    testWidgets('the search fields expose a hint', (tester) async {
      await pumpKumpleto(tester);
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields, isNotEmpty);
      for (final field in fields) {
        final decoration = field.decoration as InputDecoration;
        expect(
          (decoration.hintText ?? decoration.labelText ?? '').trim(),
          isNotEmpty,
          reason: 'a search field without a hint or label reads out as empty',
        );
      }
    });

    testWidgets('the navigation destinations expose labels', (tester) async {
      await pumpKumpleto(tester);
      final l10n = l10nOf(tester);
      expect(find.text(l10n.navHome), findsOneWidget);
      expect(find.text(l10n.navDocuments), findsOneWidget);
      expect(find.text(l10n.navSettings), findsOneWidget);
    });
  });

  group('200% text scale', () {
    /// A small phone viewport: the accessibility budget has to hold on the
    /// narrowest screen we support, not only on the 800×600 test default.
    void usePhoneViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(360 * 3, 740 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      // Guard against the viewport silently not applying.
      expect(
        tester.view.physicalSize / tester.view.devicePixelRatio,
        const Size(360, 740),
      );
    }

    testWidgets('every screen lays out without overflowing', (tester) async {
      usePhoneViewport(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await visitScreens(tester, (screen) async {
        expect(
          tester.takeException(),
          isNull,
          reason: '$screen threw while laid out at 200% text scale',
        );
      });
    });

    testWidgets('onboarding lays out without overflowing', (tester) async {
      usePhoneViewport(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await pumpKumpleto(tester, firstRunDone: false);
      expect(tester.takeException(), isNull);
    });
  });
}
