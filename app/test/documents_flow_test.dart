import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/l10n/app_localizations.dart';

import 'support/pump_app.dart';

void main() {
  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  Future<void> openNbi(WidgetTester tester) async {
    await tester.tap(find.text(l10nOf(tester).navDocuments));
    await tester.pumpAndSettle();
    final documentsTitle = l10nOf(tester).documentsTitle;
    expect(find.text(documentsTitle), findsWidgets);
    await tester.tap(find.text('NBI Clearance'));
    await tester.pumpAndSettle();
  }

  testWidgets('swiping right marks the document, swiping left undoes it',
      (tester) async {
    await pumpKumpleto(tester);
    await openNbi(tester);
    final l10n = l10nOf(tester);

    expect(find.text(l10n.docAlreadyHaveTitle), findsOneWidget);

    await tester.drag(find.text(l10n.docSwipeToMark), const Offset(220, 0));
    await tester.pumpAndSettle();
    expect(find.text(l10n.docAcquiredNotice), findsOneWidget);
    expect(find.text(l10n.docAlreadyHaveTitle), findsNothing);

    await tester.drag(find.text(l10n.docSwipeToUnmark), const Offset(-220, 0));
    await tester.pumpAndSettle();
    expect(find.text(l10n.docAlreadyHaveTitle), findsOneWidget);
    expect(find.text(l10n.docAcquiredNotice), findsNothing);
  });

  testWidgets('a short swipe springs back without marking', (tester) async {
    await pumpKumpleto(tester);
    await openNbi(tester);
    final l10n = l10nOf(tester);

    await tester.drag(find.text(l10n.docSwipeToMark), const Offset(30, 0));
    await tester.pumpAndSettle();
    expect(find.text(l10n.docAlreadyHaveTitle), findsOneWidget);
    expect(find.text(l10n.docAcquiredNotice), findsNothing);
  });

  testWidgets('the search box matches tags, not only titles', (tester) async {
    await pumpKumpleto(tester);
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.navDocuments));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'job-hunt');
    await tester.pumpAndSettle();
    expect(find.text(l10n.documentsNoResults), findsNothing);
  });
}
