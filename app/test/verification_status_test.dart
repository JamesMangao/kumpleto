import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/l10n/app_localizations.dart';
import 'package:kumpleto/models/models.dart';
import 'package:kumpleto/widgets/shared.dart';

/// Verification rendering for every tier of the verification-age policy
/// (fresh ≤ 90 days, stale 91–180, overdue > 180, grey when never verified).
///
/// These are the only places the "Unverified" state reaches the user, so each
/// tier is pinned by label *and* colour here.
void main() {
  Future<AppLocalizations> pumpLocalized(
    WidgetTester tester,
    Widget child,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      ),
    );
    return AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
  }

  group('StatusBadge', () {
    testWidgets('a draft document reads Unverified on the grey pill', (
      tester,
    ) async {
      final l10n = await pumpLocalized(
        tester,
        const StatusBadge(status: DocStatus.draft),
      );

      expect(find.text(l10n.statusDraft), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(l10n.statusDraft)).style?.color,
        const Color(0xFF5A6E66),
      );
    });

    testWidgets('a deprecated document keeps the red warning pill', (
      tester,
    ) async {
      final l10n = await pumpLocalized(
        tester,
        const StatusBadge(status: DocStatus.deprecated),
      );

      expect(find.text(l10n.statusDeprecated), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(l10n.statusDeprecated)).style?.color,
        const Color(0xFFBC2C2C),
      );
    });

    testWidgets('verified documents take the tier colour of their age', (
      tester,
    ) async {
      final l10n = await pumpLocalized(tester, const SizedBox());

      const cases = <(int, Color)>[
        (30, Color(0xFF1B7A43)), // fresh
        (90, Color(0xFF1B7A43)), // fresh boundary
        (91, Color(0xFFB86A04)), // stale boundary
        (180, Color(0xFFB86A04)), // stale
        (181, Color(0xFFBC2C2C)), // overdue boundary
        (300, Color(0xFFBC2C2C)), // overdue
      ];

      for (final (days, colour) in cases) {
        await pumpLocalized(
          tester,
          StatusBadge(
            status: DocStatus.verified,
            lastVerified: DateTime.now().subtract(Duration(days: days)),
          ),
        );

        final label = find.text(l10n.docVerifiedDays(days));
        expect(label, findsOneWidget, reason: '$days days old');
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(
          tester.widget<Text>(label).style?.color,
          colour,
          reason: '$days days old',
        );
      }
    });

    testWidgets('verified without a date falls back to the plain label', (
      tester,
    ) async {
      final l10n = await pumpLocalized(
        tester,
        const StatusBadge(status: DocStatus.verified),
      );

      expect(find.text(l10n.statusVerified), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });

  group('VerificationAge', () {
    testWidgets('never verified falls back to the maintainer note', (
      tester,
    ) async {
      final l10n = await pumpLocalized(
        tester,
        const VerificationAge(lastVerified: null),
      );

      expect(find.text(l10n.docNeverVerified), findsOneWidget);
    });

    testWidgets('the age line follows the same tier boundaries', (
      tester,
    ) async {
      final l10n = await pumpLocalized(tester, const SizedBox());

      const cases = <(int, Color)>[
        (30, Color(0xFF2E7D32)), // fresh
        (90, Color(0xFF2E7D32)),
        (91, Color(0xFFB26A00)), // stale
        (180, Color(0xFFB26A00)),
        (181, Color(0xFFC62828)), // overdue
        (300, Color(0xFFC62828)),
      ];

      for (final (days, colour) in cases) {
        await pumpLocalized(
          tester,
          VerificationAge(
            lastVerified: DateTime.now().subtract(Duration(days: days)),
          ),
        );

        final label = find.text(l10n.docVerifiedDays(days));
        expect(label, findsOneWidget, reason: '$days days old');
        expect(
          tester.widget<Text>(label).style?.color,
          colour,
          reason: '$days days old',
        );
      }
    });
  });
}