import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_set/views/home/settings_view.dart';

void main() {
  testWidgets('opens admin dashboard after seven taps and valid password', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsView()));

    for (var tap = 0; tap < 7; tap++) {
      await tester.tap(find.text('Version'));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Admin access'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'dumixan10');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Control room'), findsOneWidget);
    expect(find.text('Games'), findsWidgets);
    expect(find.text('Categories'), findsWidgets);
    expect(find.text('Downloads'), findsWidgets);

    await tester.tap(find.text('Add, edit, publish, or remove games'));
    await tester.pumpAndSettle();
    expect(find.text('Games unavailable'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Organize the catalog'));
    await tester.tap(find.text('Organize the catalog'));
    await tester.pumpAndSettle();
    expect(find.text('Categories unavailable'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Review download counts by game'));
    await tester.tap(find.text('Review download counts by game'));
    await tester.pumpAndSettle();
    expect(find.text('Download data unavailable'), findsOneWidget);
  });
}
