import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/utils/error_handler.dart';
import 'package:aegis_front/utils/loading_indicator.dart';
import 'package:aegis_front/utils/button_feedback.dart';
import 'package:aegis_front/services/backend_api_service.dart';

/// Widget tests for error handling and user feedback
/// 
/// Tests error message display, loading indicators, button feedback,
/// and button disabling during operations.
/// 
/// Validates: Requirements 10.1, 10.2, 10.3, 10.4, 10.5
void main() {
  group('Error Message Display', () {
    testWidgets('showErrorSnackBar displays error with icon',
        (WidgetTester tester) async {
      // Build a scaffold to show the snackbar
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ErrorHandler.showErrorSnackBar(
                      context,
                      NetworkException('Connection failed'),
                    );
                  },
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to show the snackbar
      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify error message is displayed
      expect(find.text('Connection failed'), findsOneWidget);
      
      // Verify error icon is displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      
      // Verify dismiss action is present
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('showErrorDialog displays error with icon and actions',
        (WidgetTester tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ErrorHandler.showErrorDialog(
                      context,
                      ApiException('Server error', statusCode: 500),
                      title: 'Error Occurred',
                      onRetry: () {
     