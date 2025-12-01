import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AegisApp());

    // Verify that the app title is displayed.
    expect(find.text('AEGIS RPA Frontend'), findsOneWidget);
  });
}
