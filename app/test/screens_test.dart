import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/core/settings.dart';
import 'package:kumpleto/data/providers.dart';
import 'package:kumpleto/l10n/app_localizations.dart';
import 'package:kumpleto/screens/info_page.dart';

import 'support/pump_app.dart';

/// Per-screen widget tests: rendering, search/filter, checklist ticking,
/// the deprecated banner, settings controls and accessibility spot-checks.
void main() {
  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  group('Home', () {
    testWidgets('shows the bundle with aggregate progress and tag chips',
        (tester) async {
      await pumpKumpleto(tester);
      final l10n = l10nOf(tester);

      expect(find.text('Job Hunt Pack'), findsOneWidget);
      // 3 requirements in nbi-clearance, none elsewhere → "0 of 3".
      expect(find.text(l10n.progressOf(0, 3)), findsWidgets);
      expect(find.text(l10n.homeBundles), findsOneWidget);
      expect(find.text('job-hunt'), findsWidgets);
      // The section title and the "All documents" tile share the string.
      expect(find.text(l10n.homeAllDocuments), findsWidgets);
    });

    testWidgets('searching from Home lands on the Documents list',
        (tester) async {
      await pumpKumpleto(tester);
      final l10n = l10nOf(tester);

      await tester.enterText(find.byType(TextField).first, 'nbi');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // The nav bar label and the app bar title both read "Documents".
      expect(find.text(l10n.documentsTitle), findsAtLeastNWidgets(1));
      expect(find.text('NBI Clearance'), findsOneWidget);
      expect(find.text('PSA Birth Certificate'), findsNothing);
    });

    testWidgets('tapping a bundle opens its detail screen', (tester) async {
      await pumpKumpleto(tester);
      final l10n = l10nOf(tester);

      await tester.tap(find.text('Job Hunt Pack'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.bundleDocuments), findsOneWidget);
      expect(find.text('NBI Clearance'), findsOneWidget);
      expect(find.text('Postal ID (old card)'), findsOneWidget);
      expect(find.text(l10n.bundleNotes), findsOneWidget);
    });
  });

  group('Documents', () {
    testWidgets('lists every document with a status badge', (tester) async {
      await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navDocuments));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      expect(find.text('NBI Clearance'), findsOneWidget);
      expect(find.text('PSA Birth Certificate'), findsOneWidget);
      expect(find.text('Postal ID (old card)'), findsOneWidget);
      expect(find.text(l10n.statusDraft), findsWidgets);
      expect(find.text(l10n.statusDeprecated), findsWidgets);
    });

    testWidgets('search narrows the list and shows an empty state',
        (tester) async {
      await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navDocuments));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(l10n.documentsNoResults), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'psa');
      await tester.pumpAndSettle();
      expect(find.text('PSA Birth Certificate'), findsOneWidget);
      expect(find.text('NBI Clearance'), findsNothing);
    });

    testWidgets('an agency filter chip narrows the list', (tester) async {
      await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navDocuments));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'National Bureau of Investigation'));
      await tester.pumpAndSettle();

      expect(find.text('NBI Clearance'), findsOneWidget);
      expect(find.text('PSA Birth Certificate'), findsNothing);
      expect(find.text('Postal ID (old card)'), findsNothing);
    });
  });

  group('Document detail', () {
    testWidgets('ticking a requirement updates the checklist and progress',
        (tester) async {
      await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navDocuments));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NBI Clearance'));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      expect(find.text(l10n.progressOf(0, 3)), findsOneWidget);

      await scrollIntoView(tester, find.text(l10n.docRequirements));
      expect(find.text(l10n.docRequirements), findsOneWidget);
      await scrollIntoView(tester, find.text(l10n.docSteps));
      expect(find.text(l10n.docSteps), findsOneWidget);

      await scrollIntoView(tester, find.text('Printed Reference Number'));
      await tester.tap(find.text('Printed Reference Number'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<CheckboxListTile>(
          find.ancestor(
            of: find.text('Printed Reference Number'),
            matching: find.byType(CheckboxListTile),
          ),
        ).value,
        isTrue,
      );

      await scrollToTop(tester);
      expect(find.text(l10n.progressOf(1, 3)), findsOneWidget);
    });

    testWidgets('an unverified document says so on its detail screen', (
      tester,
    ) async {
      await pumpKumpleto(tester);
      final l10n = l10nOf(tester);

      // Home no longer lists documents directly — reach one through search.
      await tester.enterText(find.byType(TextField).first, 'nbi');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.text('NBI Clearance'));
      await tester.pumpAndSettle();

      // Draft documents state that no maintainer has verified them yet.
      expect(find.text(l10n.docNeverVerified), findsOneWidget);
      expect(find.text(l10n.statusDraft), findsWidgets);
    });

    testWidgets('shows original / photocopy / optional badges', (
      tester,
    ) async {
      await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navDocuments));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NBI Clearance'));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      expect(find.text(l10n.docOriginal), findsOneWidget);
      expect(find.text(l10n.docPhotocopies(2)), findsOneWidget);
      expect(find.text(l10n.docOptional), findsOneWidget);
    });

    testWidgets('a deprecated document shows the warning banner', (
      tester,
    ) async {
      await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navDocuments));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Postal ID (old card)'));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      expect(find.text(l10n.deprecatedBanner), findsOneWidget);
      expect(find.text(l10n.statusDeprecated), findsWidgets);
    });

    testWidgets('an entry with no data shows the empty notice', (
      tester,
    ) async {
      await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navDocuments));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PSA Birth Certificate'));
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).docEmptyNotice), findsOneWidget);
      expect(find.text(l10nOf(tester).docRequirements), findsNothing);
    });

    testWidgets('reset asks for confirmation and clears the ticks', (
      tester,
    ) async {
      await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navDocuments));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NBI Clearance'));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await scrollIntoView(tester, find.text('Printed Reference Number'));
      await tester.tap(find.text('Printed Reference Number'));
      await tester.pumpAndSettle();
      await scrollToTop(tester);
      expect(find.text(l10n.progressOf(1, 3)), findsOneWidget);

      await tester.tap(find.text(l10n.docReset));
      await tester.pumpAndSettle();
      expect(find.text(l10n.docResetTitle), findsOneWidget);

      // Cancel keeps the progress.
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(find.text(l10n.progressOf(1, 3)), findsOneWidget);

      await tester.tap(find.text(l10n.docReset));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.confirm));
      await tester.pumpAndSettle();
      expect(find.text(l10n.progressOf(0, 3)), findsOneWidget);
    });
  });

  group('Settings', () {
    testWidgets('shows the data version, source and update button', (
      tester,
    ) async {
      await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navSettings));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      // _Row renders "<label>: " as a single text.
      expect(find.text('${l10n.settingsDataVersion}: '), findsOneWidget);
      expect(find.text('2026-10-01T00:00:00.000Z'), findsOneWidget);
      expect(find.text(l10n.settingsNeverChecked), findsOneWidget);
      expect(find.text(l10n.settingsCheckForUpdates), findsOneWidget);

      await scrollIntoView(
        tester,
        find.text(l10n.settingsAppVersion('1.2.3')),
      );
      expect(find.text(l10n.settingsAppVersion('1.2.3')), findsOneWidget);
    });

    testWidgets('switching language and theme persists', (tester) async {
      final settings = await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navSettings));
      await tester.pumpAndSettle();

      final l10n = l10nOf(tester);

      // ButtonSegment is data, not a widget — tap its label instead.
      await tester.tap(find.text(l10n.languageFilipino));
      await tester.pumpAndSettle();
      expect(settings.language, 'fil');

      // The app re-localized in place, so the theme label is Tagalog now.
      await tester.tap(find.text(l10nOf(tester).settingsThemeDark));
      await tester.pumpAndSettle();
      expect(settings.themeMode, ThemeMode.dark);

      final reloaded = await AppSettings.load();
      expect(reloaded.language, 'fil');
      expect(reloaded.themeMode, ThemeMode.dark);
    });

    // One dialog cycle per test: opening a second confirmation dialog in the
    // same test gets popped by Flutter before it can be asserted.
    testWidgets('cancelling the reset keeps the progress', (tester) async {
      await pumpKumpleto(tester);
      final l10n = l10nOf(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NavigationBar)),
      );

      // Tick one requirement through the repository (as the UI would).
      await container
          .read(progressRepositoryProvider)
          .setChecked('nbi-clearance', 'reference-number', true);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.navSettings));
      await tester.pumpAndSettle();

      // The reset row sits below the fold of the settings list.
      final resetRow = find.widgetWithText(
        ListTile,
        l10n.settingsResetProgress,
      );
      await scrollIntoView(tester, resetRow);
      await tester.tap(resetRow);
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsResetTitle), findsOneWidget);

      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      // Back to Home, which watches the live progress stream: the tick must
      // have survived the cancelled reset.
      await tester.tap(find.text(l10n.navHome));
      await tester.pumpAndSettle();
      expect(
        container.read(progressProvider).value,
        {'nbi-clearance': {'reference-number'}},
      );
    });

    testWidgets('confirming the reset clears the progress', (tester) async {
      await pumpKumpleto(tester);
      final l10n = l10nOf(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NavigationBar)),
      );

      await container
          .read(progressRepositoryProvider)
          .setChecked('nbi-clearance', 'reference-number', true);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.navSettings));
      await tester.pumpAndSettle();

      final resetRow = find.widgetWithText(
        ListTile,
        l10n.settingsResetProgress,
      );
      await scrollIntoView(tester, resetRow);
      await tester.tap(resetRow);
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsResetTitle), findsOneWidget);

      await tester.tap(find.text(l10n.confirm));
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsProgressReset), findsOneWidget);

      // Let the snackbar's dismissal timer fire instead of leaving it pending.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.navHome));
      await tester.pumpAndSettle();
      expect(container.read(progressProvider).value, isEmpty);
    });

    testWidgets('every settings row is rendered and wired up', (tester) async {
      await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navSettings));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      expect(
        find.widgetWithText(OutlinedButton, l10n.settingsCheckForUpdates),
        findsOneWidget,
      );

      // The rows below the fold only exist once they are scrolled to, so each
      // one is asserted immediately after it is brought into view. Every row
      // but the (informational) app version opens something.
      final rows = <(String, bool)>[
        (l10n.settingsResetProgress, true),
        (l10n.settingsAppVersion('1.2.3'), false),
        (l10n.settingsAbout, true),
        (l10n.settingsDisclaimer, true),
        (l10n.settingsPrivacy, true),
        (l10n.settingsLicenses, true),
      ];
      for (final (text, tappable) in rows) {
        final row = find.widgetWithText(ListTile, text);
        await scrollIntoView(tester, row);
        expect(row, findsOneWidget, reason: 'missing row: $text');
        if (!tappable) continue;
        expect(
          tester.widget<ListTile>(row).onTap,
          isNotNull,
          reason: 'row is not wired up: $text',
        );
      }
    });

    testWidgets('open-source licenses opens the license page', (
      tester,
    ) async {
      await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navSettings));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      final row = find.widgetWithText(ListTile, l10n.settingsLicenses);
      await scrollIntoView(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
    });

    testWidgets('about, disclaimer and privacy open inside the app', (
      tester,
    ) async {
      // Settings must never send the user out to a browser any more.
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      var launches = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async {
          launches++;
          return true;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      });

      await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navSettings));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      for (final label in <String>[
        l10n.settingsAbout,
        l10n.settingsDisclaimer,
        l10n.settingsPrivacy,
      ]) {
        final row = find.widgetWithText(ListTile, label);
        await scrollIntoView(tester, row);
        await tester.tap(row);
        await tester.pumpAndSettle();

        // Rendered by the app itself, with the mandatory notice on top.
        expect(find.byType(InfoPage), findsOneWidget, reason: 'page: $label');
        expect(find.text(l10n.unofficialBadge), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      expect(launches, 0, reason: 'no row may open an external URL');
    });

    testWidgets('the unofficial badge explains what the app is', (
      tester,
    ) async {
      await pumpKumpleto(tester);
      final l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.unofficialBadge).first);
      await tester.pumpAndSettle();

      expect(find.text(l10n.unofficialSheetTitle), findsOneWidget);
      expect(find.text(l10n.unofficialSheetBody), findsOneWidget);
      expect(find.text(l10n.unofficialSheetOffline), findsOneWidget);

      // The sheet's call to action reads the full disclaimer in-app.
      await tester.tap(find.text(l10n.unofficialReadDisclaimer));
      await tester.pumpAndSettle();
      expect(find.byType(InfoPage), findsOneWidget);
    });

    testWidgets('checking for updates finishes and reports a result', (
      tester,
    ) async {
      await pumpKumpleto(tester);
      await tester.tap(find.text(l10nOf(tester).navSettings));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      final button = find.widgetWithText(
        OutlinedButton,
        l10n.settingsCheckForUpdates,
      );
      await scrollIntoView(tester, button);
      await tester.tap(button);
      // The mocked http client answers inside the first pump, so the
      // "Checking…" label is already gone — assert the outcome instead.
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(OutlinedButton, l10n.settingsCheckForUpdates),
        findsOneWidget,
        reason: 'the button never came back from the check',
      );

      final messages = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .toList();
      final failurePrefix = l10n.settingsUpdateFailed('');
      expect(
        messages.any(
          (message) =>
              message == l10n.settingsUpdateDone ||
              message == l10n.settingsUpToDate ||
              message.startsWith(failurePrefix),
        ),
        isTrue,
        reason: 'no update result message in: $messages',
      );
    });
  });
}
