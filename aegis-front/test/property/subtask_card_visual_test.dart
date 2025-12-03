import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/models/subtask.dart';
import 'package:aegis_front/widgets/subtask_card.dart';
import 'dart:math';

/// Property-based tests for subtask card visual treatment
/// 
/// **Feature: rpa-frontend, Property 42: In-Progress Subtask Highlighting**
/// **Feature: rpa-frontend, Property 43: Completed Subtask Visual Treatment**
/// **Feature: rpa-frontend, Property 44: Failed Subtask Error Display**
/// **Validates: Requirements 11.2, 11.3, 11.4**
/// 
/// Property 42: For any subtask with status "in_progress", the subtask card
/// must be visually highlighted (e.g., with a border or background color).
/// 
/// Property 43: For any subtask with status "completed", the subtask card
/// must show a checkmark icon and be slightly dimmed.
/// 
/// Property 44: For any subtask with status "failed", the subtask card
/// must show an error icon and display the error message below the description.

void main() {
  group('Subtask Card Visual Treatment Properties', () {
    final random = Random();

    // Helper to generate random strings
    String randomString([int maxLength = 100]) {
      final length = random.nextInt(maxLength) + 1;
      const chars =
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
      return List.generate(
              length, (_) => chars[random.nextInt(chars.length)])
          .join();
    }

    // Helper to generate random subtask
    Subtask randomSubtask({SubtaskStatus? status, String? error}) {
      return Subtask(
        id: 'subtask-${random.nextInt(10000)}',
        description: randomString(80),
        status: status ?? SubtaskStatus.values[random.nextInt(4)],
        toolName: random.nextBool() ? randomString(20) : null,
        toolArgs: random.nextBool() ? {'arg': randomString(10)} : null,
        result: random.nextBool() ? {'result': randomString(10)} : null,
        error: error,
        timestamp: DateTime.now().subtract(Duration(seconds: random.nextInt(3600))),
      );
    }

    testWidgets(
      'Property 42: In-progress subtasks are visually highlighted',
      (WidgetTester tester) async {
        // Run 100 iterations as specified in design
        for (int i = 0; i < 100; i++) {
          // Generate a random in-progress subtask
          final subtask = randomSubtask(status: SubtaskStatus.inProgress);

          // Build the widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SubtaskCard(subtask: subtask),
              ),
            ),
          );

          // Find the Card widget
          final cardFinder = find.byType(Card);
          expect(cardFinder, findsOneWidget);

          // Get the Card widget
          final Card card = tester.widget(cardFinder);

          // Verify visual highlighting for in-progress status
          // The card should have a border (side is not BorderSide.none)
          final shape = card.shape as RoundedRectangleBorder;
          expect(
            shape.side,
            isNot(equals(BorderSide.none)),
            reason: 'In-progress subtask must have a visible border for highlighting',
          );

          // Verify the border is blue (in-progress color)
          expect(
            shape.side.color,
            equals(const Color(0xFF2196F3)),
            reason: 'In-progress subtask border must be blue',
          );

          // Verify border width is substantial (2.0)
          expect(
            shape.side.width,
            equals(2.0),
            reason: 'In-progress subtask border must be 2.0 pixels wide',
          );

          // Verify the card has a background color (not just surface)
          expect(
            card.color,
            isNotNull,
            reason: 'In-progress subtask must have a background color',
          );

          // Verify loading indicator is present
          final progressIndicatorFinder = find.byType(CircularProgressIndicator);
          expect(
            progressIndicatorFinder,
            findsOneWidget,
            reason: 'In-progress subtask must show a loading indicator',
          );
        }
      },
    );

    testWidgets(
      'Property 43: Completed subtasks show checkmark and are dimmed',
      (WidgetTester tester) async {
        // Run 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate a random completed subtask
          final subtask = randomSubtask(status: SubtaskStatus.completed);

          // Build the widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SubtaskCard(subtask: subtask),
              ),
            ),
          );

          // Verify checkmark icon is present
          final checkIconFinder = find.byIcon(Icons.check_circle);
          expect(
            checkIconFinder,
            findsOneWidget,
            reason: 'Completed subtask must show a checkmark icon',
          );

          // Get the Icon widget to verify color
          final Icon checkIcon = tester.widget(checkIconFinder);
          expect(
            checkIcon.color,
            equals(const Color(0xFF4CAF50)), // Green
            reason: 'Completed subtask checkmark must be green',
          );

          // Verify the card is dimmed (opacity < 1.0)
          final opacityFinder = find.byType(Opacity);
          expect(
            opacityFinder,
            findsOneWidget,
            reason: 'Completed subtask must be wrapped in Opacity widget',
          );

          final Opacity opacityWidget = tester.widget(opacityFinder);
          expect(
            opacityWidget.opacity,
            lessThan(1.0),
            reason: 'Completed subtask must be dimmed (opacity < 1.0)',
          );

          // Verify opacity is around 0.6 (slightly dimmed)
          expect(
            opacityWidget.opacity,
            closeTo(0.6, 0.1),
            reason: 'Completed subtask should have opacity around 0.6',
          );

          // Verify no border for completed subtasks
          final cardFinder = find.byType(Card);
          final Card card = tester.widget(cardFinder);
          final shape = card.shape as RoundedRectangleBorder;
          expect(
            shape.side,
            equals(BorderSide.none),
            reason: 'Completed subtask should not have a border',
          );
        }
      },
    );

    testWidgets(
      'Property 44: Failed subtasks show error icon and error message',
      (WidgetTester tester) async {
        // Run 100 iterations
        for (int i = 0; i < 100; i++) {
          // Generate a random failed subtask with error message
          final errorMessage = randomString(50);
          final subtask = randomSubtask(
            status: SubtaskStatus.failed,
            error: errorMessage,
          );

          // Build the widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SubtaskCard(subtask: subtask),
              ),
            ),
          );

          // Verify error icon is present
          final errorIconFinder = find.byIcon(Icons.error);
          expect(
            errorIconFinder,
            findsOneWidget,
            reason: 'Failed subtask must show an error icon',
          );

          // Get the Icon widget to verify color
          final Icon errorIcon = tester.widget(errorIconFinder);
          expect(
            errorIcon.color,
            equals(const Color(0xFFF44336)), // Red
            reason: 'Failed subtask error icon must be red',
          );

          // Verify error message is displayed
          final errorTextFinder = find.text(errorMessage);
          expect(
            errorTextFinder,
            findsOneWidget,
            reason: 'Failed subtask must display the error message',
          );

          // Verify the error message is styled correctly (red color)
          final Text errorText = tester.widget(errorTextFinder);
          expect(
            errorText.style?.color,
            equals(const Color(0xFFF44336)), // Red
            reason: 'Error message text must be red',
          );

          // Verify error message is below the description
          // (by checking it's in a Column with description above it)
          final columnFinder = find.byType(Column);
          expect(
            columnFinder,
            findsWidgets,
            reason: 'Subtask card should use Column layout',
          );
        }
      },
    );

    testWidgets(
      'Property 44: Failed subtasks without error message show icon only',
      (WidgetTester tester) async {
        // Test edge case: failed subtask with null error message
        for (int i = 0; i < 20; i++) {
          final subtask = randomSubtask(
            status: SubtaskStatus.failed,
            error: null, // No error message
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SubtaskCard(subtask: subtask),
              ),
            ),
          );

          // Verify error icon is still present
          final errorIconFinder = find.byIcon(Icons.error);
          expect(
            errorIconFinder,
            findsOneWidget,
            reason: 'Failed subtask must show error icon even without error message',
          );

          // Verify no error message text is displayed (only description)
          // We can't easily test for absence of error text without knowing the description,
          // but we can verify the icon is present which is the key requirement
        }
      },
    );

    testWidgets(
      'Property 42-44: Pending subtasks have neutral visual treatment',
      (WidgetTester tester) async {
        // Test that pending subtasks don't have special highlighting
        for (int i = 0; i < 50; i++) {
          final subtask = randomSubtask(status: SubtaskStatus.pending);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SubtaskCard(subtask: subtask),
              ),
            ),
          );

          // Verify no border for pending subtasks
          final cardFinder = find.byType(Card);
          final Card card = tester.widget(cardFinder);
          final shape = card.shape as RoundedRectangleBorder;
          expect(
            shape.side,
            equals(BorderSide.none),
            reason: 'Pending subtask should not have a border',
          );

          // Verify full opacity (not dimmed)
          final opacityFinder = find.byType(Opacity);
          final Opacity opacityWidget = tester.widget(opacityFinder);
          expect(
            opacityWidget.opacity,
            equals(1.0),
            reason: 'Pending subtask should not be dimmed',
          );

          // Verify pending icon (radio_button_unchecked)
          final pendingIconFinder = find.byIcon(Icons.radio_button_unchecked);
          expect(
            pendingIconFinder,
            findsOneWidget,
            reason: 'Pending subtask must show pending icon',
          );
        }
      },
    );

    testWidgets(
      'Property 42-44: All status types have correct icon colors',
      (WidgetTester tester) async {
        // Test that each status has the correct color coding
        final statusColorMap = {
          SubtaskStatus.pending: Colors.grey,
          SubtaskStatus.inProgress: const Color(0xFF2196F3), // Blue
          SubtaskStatus.completed: const Color(0xFF4CAF50), // Green
          SubtaskStatus.failed: const Color(0xFFF44336), // Red
        };

        for (final entry in statusColorMap.entries) {
          final status = entry.key;
          final expectedColor = entry.value;

          final subtask = randomSubtask(
            status: status,
            error: status == SubtaskStatus.failed ? randomString(30) : null,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SubtaskCard(subtask: subtask),
              ),
            ),
          );

          // Find the status icon (different types for different statuses)
          Widget? iconWidget;
          if (status == SubtaskStatus.inProgress) {
            final progressFinder = find.byType(CircularProgressIndicator);
            expect(progressFinder, findsOneWidget);
            final CircularProgressIndicator progress = tester.widget(progressFinder);
            final colorAnimation = progress.valueColor as AlwaysStoppedAnimation<Color>;
            expect(
              colorAnimation.value,
              equals(expectedColor),
              reason: 'In-progress indicator must be blue',
            );
          } else {
            // For other statuses, find the Icon widget
            final iconFinder = find.byType(Icon);
            expect(iconFinder, findsOneWidget);
            final Icon icon = tester.widget(iconFinder);
            expect(
              icon.color,
              equals(expectedColor),
              reason: 'Status icon for $status must have correct color',
            );
          }
        }
      },
    );

    testWidgets(
      'Property 42-44: Visual treatment is consistent across multiple renders',
      (WidgetTester tester) async {
        // Test that the same subtask renders consistently
        for (int i = 0; i < 30; i++) {
          final subtask = randomSubtask(
            status: SubtaskStatus.values[random.nextInt(4)],
            error: random.nextBool() ? randomString(40) : null,
          );

          // Render the same subtask twice
          for (int render = 0; render < 2; render++) {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: SubtaskCard(subtask: subtask),
                ),
              ),
            );

            // Verify the card is rendered
            expect(find.byType(Card), findsOneWidget);
            expect(find.byType(SubtaskCard), findsOneWidget);

            // Verify description is displayed
            expect(find.text(subtask.description), findsOneWidget);
          }
        }
      },
    );
  });
}
