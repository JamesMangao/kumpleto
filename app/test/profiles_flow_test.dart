import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/l10n/app_localizations.dart';

import 'support/pump_app.dart';

/// A household chases documents for more than one person: ticking a
/// requirement as "me" must not tick it for the profile added afterwards, and
/// switching back must restore my own ticks.
void main() {
  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

  Future<void> openNbi(WidgetTester tester) async {
    await tester.tap(find.text(l10nOf(tester).navDocuments));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NBI Clearance'));
    await tester.pumpAndSettle();
  }

  Future<void> backHome(WidgetTester tester) async {
    await tester.tap(find.byTooltip(l10nOf(tester).back));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nOf(tester).navHome));
    await tester.pumpAndSettle();
  }

  Future<void> markAcquired(WidgetTester tester) async {
    await tester.tap(find.text(l10nOf(tester).docMarkAcquired));
    await tester.pumpAndSettle();
  }

  Future<void> addProfile(WidgetTester tester, String name) async {
    await tester.tap(find.text(l10nOf(tester).profileMe));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nOf(tester).profileAdd));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      name,
    );
    await tester.tap(find.text(l10nOf(tester).confirm));
    await tester.pumpAndSettle();
  }

  testWidgets('a new person starts with an empty checklist', (tester) async {
    await pumpKumpleto(tester);

    await openNbi(tester);
    await markAcquired(tester);
    expect(find.text(l10nOf(tester).docAcquiredNotice), findsOneWidget);

    await backHome(tester);
    expect(find.text(l10nOf(tester).profileMe), findsOneWidget);
    await addProfile(tester, 'Ana');

    // The chip now names the person whose checklist is on screen.
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text(l10nOf(tester).profileMe), findsNothing);

    await openNbi(tester);
    expect(find.text(l10nOf(tester).docMarkAcquired), findsOneWidget);
    expect(find.text(l10nOf(tester).docAcquiredNotice), findsNothing);
  });

  testWidgets('switching back restores my own progress', (tester) async {
    await pumpKumpleto(tester);

    await openNbi(tester);
    await markAcquired(tester);
    await backHome(tester);
    await addProfile(tester, 'Ana');
    await openNbi(tester);
    await backHome(tester);

    // Back to me.
    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nOf(tester).profileMe));
    await tester.pumpAndSettle();

    await openNbi(tester);
    expect(find.text(l10nOf(tester).docAcquiredNotice), findsOneWidget);
  });

  testWidgets('removing a person deletes their progress', (tester) async {
    await pumpKumpleto(tester);

    await addProfile(tester, 'Ana');

    await tester.tap(find.text('Ana'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10nOf(tester).profileRemove));
    await tester.pumpAndSettle();
    expect(
      find.text(l10nOf(tester).profileRemoveMessage),
      findsOneWidget,
    );
    await tester.tap(find.text(l10nOf(tester).confirm));
    await tester.pumpAndSettle();

    // The person is gone from the list, and the active profile fell back to
    // "me" (the sheet stays open on the remaining list).
    expect(find.text('Ana'), findsNothing);
    final meRow = find.widgetWithText(ListTile, l10nOf(tester).profileMe);
    expect(meRow, findsOneWidget);

    await tester.tap(meRow);
    await tester.pumpAndSettle();
    expect(find.text(l10nOf(tester).profileMe), findsOneWidget);
  });
}
