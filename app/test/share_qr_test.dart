import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'support/pump_app.dart';

/// A code shown at a counter has to work with no data, so the app link is what
/// the reader sees first; the public page stays one tap away for a phone that
/// has not installed Kumpleto.
void main() {
  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  Future<void> openQr(WidgetTester tester) async {
    await pumpKumpleto(tester);
    await tester.tap(find.text(l10nOf(tester).navDocuments));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NBI Clearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.qr_code_2_rounded));
    await tester.pumpAndSettle();
  }

  /// The dialog prints the encoded link under the code, which is also what a
  /// reader can type by hand when a camera refuses the scheme.
  String dataOf(WidgetTester tester) {
    expect(find.byType(QrImageView), findsOneWidget);
    final link = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          (widget.data ?? '').startsWith(RegExp('kumpleto://|https://')),
    );
    expect(link, findsOneWidget);
    return tester.widget<Text>(link).data!;
  }

  testWidgets('the QR opens the checklist in the app by default', (
    tester,
  ) async {
    await openQr(tester);
    expect(dataOf(tester), 'kumpleto://doc/nbi-clearance');
    expect(find.text(l10nOf(tester).docQrHint), findsOneWidget);
  });

  testWidgets('the web page is one tap away and says it needs a connection', (
    tester,
  ) async {
    await openQr(tester);
    await tester.tap(find.text(l10nOf(tester).docQrModeWeb));
    await tester.pumpAndSettle();
    expect(dataOf(tester), startsWith('https://'));
    expect(dataOf(tester), endsWith('/doc/nbi-clearance'));
    expect(find.text(l10nOf(tester).docQrHintWeb), findsOneWidget);
  });
}
