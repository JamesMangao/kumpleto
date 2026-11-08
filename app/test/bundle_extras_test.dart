import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/l10n/app_localizations.dart';

import 'support/pump_app.dart';

/// The bundle screen's two additions: what the whole bundle costs (summed from
/// the numbers the entries state), and the share/print menu.
void main() {
  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  Future<void> openJobHuntPack(WidgetTester tester) async {
    await tester.tap(find.text('Job Hunt Pack'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the summed fee and says how much of the bundle it covers',
      (tester) async {
    await pumpKumpleto(tester);
    final l10n = l10nOf(tester);

    await openJobHuntPack(tester);

    // The test bundle holds NBI (₱130–₱160) and a Postal ID with no fee.
    expect(find.text(l10n.bundleEstimateTitle), findsOneWidget);
    expect(find.text('₱130–₱160'), findsOneWidget);
    expect(find.text(l10n.bundleEstimateCaption(1, 2)), findsOneWidget);

    // Only one of the two documents states working days, so no total is shown.
    expect(find.text(l10n.bundleEstimateTimeSameDay), findsNothing);
  });

  testWidgets('the export menu offers share and print', (tester) async {
    await pumpKumpleto(tester);
    final l10n = l10nOf(tester);

    await openJobHuntPack(tester);
    await tester.tap(find.byTooltip(l10n.bundleExportMenu));
    await tester.pumpAndSettle();

    expect(find.text(l10n.bundleExportShare), findsOneWidget);
    expect(find.text(l10n.bundleExportPrint), findsOneWidget);
  });
}
