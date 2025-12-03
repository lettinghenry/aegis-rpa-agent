import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/widgets/subtask_card.dart';
import 'package:aegis_front/models/subtask.dart';

void main() {
  group('SubtaskCard Widget Tests', () {
    testWidgets('displays subtask description', (WidgetTester tester) async {
      final subtask = Subtask(
        id: 'test-1',
        description: 'Test subtask description',
        status: SubtaskStatus.pending,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskCard(subtask: subtask),
          ),
        ),
      );

      expect(find.text('Test subtask description'), findsOneWidget);
    });

    testWidgets('displays checkmark icon for completed status',
        (WidgetTester tester) async {
      final subtask = Subtask(
        id: 'test-2',
        description: 'Completed task',
        status: SubtaskStatus.completed,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskCard(subtask: subtask),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays error icon for failed status',
        (WidgetTester tester) async {
      final subtask = Subtask(
        id: 'test-3',
        description: 'Failed task',
        status: SubtaskStatus.failed,
        error: 'Something went wrong',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskCard(subtask: subtask),
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('displays spinner for in-progress status',
        (WidgetTester tester) async {
      final subtask = Subtask(
        id: 'test-4',
        description: 'In progress task',
        status: SubtaskStatus.inProgress,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskCard(subtask: subtask),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when subtask fails',
        (WidgetTester tester) async {
      final subtask = Subtask(
        id: 'test-5',
        description: 'Failed task',
        status: SubtaskStatus.failed,
        error: 'Network error occurred',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskCard(subtask: subtask),
          ),
        ),
      );

      expect(find.text('Network error occurred'), findsOneWidget);
    });

    testWidgets('does not display error message for non-failed status',
        (WidgetTester tester) async {
      final subtask = Subtask(
        id: 'test-6',
        description: 'Completed task',
        status: SubtaskStatus.completed,
        error: 'This should not be displayed',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskCard(subtask: subtask),
          ),
        ),
      );

      expect(find.text('This should not be displayed'), findsNothing);
    });

    testWidgets('displays timestamp', (WidgetTester tester) async {
      final subtask = Subtask(
        id: 'test-7',
        description: 'Test task',
        status: SubtaskStatus.pending,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskCard(subtask: subtask),
          ),
        ),
      );

      // Should display "Just now" for recent timestamps
      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('applies Material 3 Card styling',
        (WidgetTester tester) async {
      final subtask = Subtask(
        id: 'test-8',
        description: 'Test task',
        status: SubtaskStatus.pending,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskCard(subtask: subtask),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, equals(1));
      expect(card.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('applies highlighting for in-progress subtasks',
        (WidgetTester tester) async {
      final subtask = Subtask(
        id: 'test-9',
        description: 'In progress task',
        status: SubtaskStatus.inProgress,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskCard(subtask: subtask),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.side.width, equals(2.0));
    });

    testWidgets('applies dimming for completed subtasks',
        (WidgetTester tester) async {
      final subtask = Subtask(
        id: 'test-10',
        description: 'Completed task',
        status: SubtaskStatus.completed,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtaskCard(subtask: subtask),
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, equals(0.6));
    });
  });
}
