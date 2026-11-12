import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/core/gate_colors.dart';
import 'package:kumpleto/core/theme.dart';
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
    // At 200% text the bundles sit well below the fold — the home list builds
    // lazily, so the card has to be scrolled into existence first.
    final bundleCard = find.text('Job Hunt Pack');
    await tester.scrollUntilVisible(
      bundleCard,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(bundleCard);
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

  // The device pass covers TalkBack and rendering; contrast is arithmetic, so
  // it belongs here where a palette change cannot slip through by eye.
  group('Colour contrast (WCAG 2.1 AA)', () {
    double luminance(Color colour) {
      double channel(double value) => value <= 0.03928
          ? value / 12.92
          : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
      return 0.2126 * channel(colour.r) +
          0.7152 * channel(colour.g) +
          0.0722 * channel(colour.b);
    }

    double contrast(Color a, Color b) {
      final la = luminance(a);
      final lb = luminance(b);
      final lighter = math.max(la, lb);
      final darker = math.min(la, lb);
      return (lighter + 0.05) / (darker + 0.05);
    }

    Future<GateColors> gateColors(WidgetTester tester, Brightness mode) async {
      late GateColors colors;
      await tester.pumpWidget(
        MaterialApp(
          theme: mode == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          home: Builder(
            builder: (context) {
              colors = GateColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return colors;
    }

    testWidgets('the first-run palette stays readable in both modes',
        (tester) async {
      for (final mode in Brightness.values) {
        final colors = await gateColors(tester, mode);
        final label = mode == Brightness.dark ? 'dark' : 'light';

        // 4.5:1 for body and caption text.
        expect(
          contrast(colors.ink, colors.bg),
          greaterThanOrEqualTo(4.5),
          reason: '$label: body text on the page background',
        );
        expect(
          contrast(colors.muted, colors.bg),
          greaterThanOrEqualTo(4.5),
          reason: '$label: captions on the page background',
        );
        expect(
          contrast(colors.ink, colors.card),
          greaterThanOrEqualTo(4.5),
          reason: '$label: body text on a card',
        );
        expect(
          contrast(colors.muted, colors.card),
          greaterThanOrEqualTo(4.5),
          reason: '$label: captions on a card',
        );
        // 3:1 is the AA floor for icons and other non-text indicators.
        expect(
          contrast(colors.accent, colors.card),
          greaterThanOrEqualTo(3.0),
          reason: '$label: accent icons on a card',
        );
        expect(
          contrast(colors.accent, colors.bg),
          greaterThanOrEqualTo(3.0),
          reason: '$label: accent icons on the page background',
        );
      }
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

    testWidgets('the acquired bar lays out without overflowing', (tester) async {
      usePhoneViewport(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navDocuments));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NBI Clearance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10nOf(tester).docMarkAcquired));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'the acquired bar overflowed at 200% text scale',
      );
    });

    testWidgets('onboarding lays out without overflowing', (tester) async {
      usePhoneViewport(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await pumpKumpleto(tester, firstRunDone: false);
      expect(tester.takeException(), isNull, reason: 'disclaimer gate');

      final agree = find.text(l10nOf(tester).disclaimerScreenAgree);
      await tester.ensureVisible(agree);
      await tester.pumpAndSettle();
      await tester.tap(agree);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
