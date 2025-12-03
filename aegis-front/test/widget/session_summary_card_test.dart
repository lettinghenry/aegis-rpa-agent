import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/widgets/session_summary_card.dart';
import 'package:aegis_front/models/session_summary.dart';

void main() {
  group('SessionSummaryCard Widget Tests', () {
    testWidgets('displays session instruction', (WidgetTester tester) async {
      final session = SessionSummary(
        sessionId: 'test-1',
        instruction: 'Open calculator and add 2 + 2',
        status: 'completed',
        createdAt: DateTime.now(),
        subtaskCount: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Open calculator and add 2 + 2'), findsOneWidget);
    });

    testWidgets('truncates long instruction', (WidgetTester tester) async {
      final longInstruction = 'A' * 150; // 150 characters
      final session = SessionSummary(
        sessionId: 'test-2',
        instruction: longInstruction,
        status: 'completed',
        createdAt: DateTime.now(),
        subtaskCount: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should truncate to 100 characters + '...'
      expect(find.text(longInstruction), findsNothing);
      expect(find.textContaining('...'), findsOneWidget);
    });

    testWidgets('displays completed status badge with green color',
        (WidgetTester tester) async {
      final session = SessionSummary(
        sessionId: 'test-3',
        instruction: 'Test instruction',
        status: 'completed',
        createdAt: DateTime.now(),
        subtaskCount: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Completed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Verify green color is used
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Completed'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF4CAF50).withOpacity(0.15)));
    });

    testWidgets('displays failed status badge with red color',
        (WidgetTester tester) async {
      final session = SessionSummary(
        sessionId: 'test-4',
        instruction: 'Test instruction',
        status: 'failed',
        createdAt: DateTime.now(),
        subtaskCount: 4,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Failed'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Verify red color is used
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Failed'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFFF44336).withOpacity(0.15)));
    });

    testWidgets('displays cancelled status badge with grey color',
        (WidgetTester tester) async {
      final session = SessionSummary(
        sessionId: 'test-5',
        instruction: 'Test instruction',
        status: 'cancelled',
        createdAt: DateTime.now(),
        subtaskCount: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);

      // Verify grey color is used
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Cancelled'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF9E9E9E).withOpacity(0.15)));
    });

    testWidgets('displays in_progress status badge with blue color',
        (WidgetTester tester) async {
      final session = SessionSummary(
        sessionId: 'test-6',
        instruction: 'Test instruction',
        status: 'in_progress',
        createdAt: DateTime.now(),
        subtaskCount: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('In Progress'), findsOneWidget);
      expect(find.byIcon(Icons.pending), findsOneWidget);

      // Verify blue color is used
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('In Progress'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF2196F3).withOpacity(0.15)));
    });

    testWidgets('displays subtask count', (WidgetTester tester) async {
      final session = SessionSummary(
        sessionId: 'test-7',
        instruction: 'Test instruction',
        status: 'completed',
        createdAt: DateTime.now(),
        subtaskCount: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('5 subtasks'), findsOneWidget);
      expect(find.byIcon(Icons.list_alt), findsOneWidget);
    });

    testWidgets('displays singular subtask for count of 1',
        (WidgetTester tester) async {
      final session = SessionSummary(
        sessionId: 'test-8',
        instruction: 'Test instruction',
        status: 'completed',
        createdAt: DateTime.now(),
        subtaskCount: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('1 subtask'), findsOneWidget);
    });

    testWidgets('displays "Just now" for recent timestamp',
        (WidgetTester tester) async {
      final session = SessionSummary(
        sessionId: 'test-9',
        instruction: 'Test instruction',
        status: 'completed',
        createdAt: DateTime.now(),
        subtaskCount: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('displays minutes ago for timestamp within an hour',
        (WidgetTester tester) async {
      final session = SessionSummary(
        sessionId: 'test-10',
        instruction: 'Test instruction',
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        subtaskCount: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('30m ago'), findsOneWidget);
    });

    testWidgets('displays hours ago for timestamp within a day',
        (WidgetTester tester) async {
      final session = SessionSummary(
        sessionId: 'test-11',
        instruction: 'Test instruction',
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        subtaskCount: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('5h ago'), findsOneWidget);
    });

    testWidgets('displays days ago for timestamp within a week',
        (WidgetTester tester) async {
      final session = SessionSummary(
        sessionId: 'test-12',
        instruction: 'Test instruction',
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        subtaskCount: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('3d ago'), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped',
        (WidgetTester tester) async {
      bool tapped = false;
      final session = SessionSummary(
        sessionId: 'test-13',
        instruction: 'Test instruction',
        status: 'completed',
        createdAt: DateTime.now(),
        subtaskCount: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SessionSummaryCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('applies Material 3 Card styling',
        (WidgetTester tester) async {
      final session = SessionSummary(
        sessionId: 'test-14',
        instruction: 'Test instruction',
        status: 'completed',
        createdAt: DateTime.now(),
        subtaskCount: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, equals(1));
      expect(card.shape, isA<RoundedRectangleBorder>());

      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, equals(BorderRadius.circular(12.0)));
    });

    testWidgets('has InkWell for tap feedback', (WidgetTester tester) async {
      final session = SessionSummary(
        sessionId: 'test-15',
        instruction: 'Test instruction',
        status: 'completed',
        createdAt: DateTime.now(),
        subtaskCount: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.borderRadius, equals(BorderRadius.circular(12.0)));
    });
  });
}
