import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_set/views/home/settings_view.dart';

/// The consumer app intentionally exposes no admin entry point; the admin UI
/// belongs to the separate admin app (see ADMIN_APP_GUIDE.md). These tests
/// guard that decision so a hidden backdoor is not reintroduced by accident.
void main() {
  testWidgets('settings does not expose an admin entry point', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsView()));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);

    // Repeatedly tapping the version row must never reveal admin access.
    for (var tap = 0; tap < 10; tap++) {
      await tester.tap(find.text('Version'));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Admin access'), findsNothing);
    expect(find.text('Control room'), findsNothing);
  });

  testWidgets('settings still shows its normal sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsView()));
    await tester.pumpAndSettle();

    expect(find.text('Check for Updates'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('About GameSet'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Contact / Help'), findsOneWidget);
  });
}
