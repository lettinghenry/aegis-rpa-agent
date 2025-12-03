import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aegis_front/screens/session_detail_view.dart';
import 'package:aegis_front/services/backend_api_service.dart';
import 'package:aegis_front/models/execution_session.dart';
import 'package:aegis_front/models/subtask.dart';

/// Mock BackendApiService for testing
class MockBackendApiService implements BackendApiService {
  bool shouldFail = false;
  String? failureMessage;
  ExecutionSession? sessionToReturn;

  @override
  Future<ExecutionSession> getSessionDetails(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (shouldFail) {
      throw Exception(failureMessage ?? 'Failed to load session');
    }
    
    if (sessionToReturn == null) {
      throw Exception('No session data');
    }
    
    return sessionToReturn!;
  }

  // Implement other methods as no-ops for this test
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionDetailView Widget Tests', () {
    late MockBackendApiService mockApiService;

    setUp(() {
      mockApiService = MockBackendApiService();
    });

    /// Helper function to build the SessionDetailView with Provider
    Widget buildSessionDetailView(String sessionId) {
      return Provider<BackendApiService>.value(
        value: mockApiService,
        child: MaterialApp(
          home: SessionDetailView(sessionId: sessionId),
        ),
      );
    }

    /// Helper function to create a test execution session
    ExecutionSession createTestSession({
      String sessionId = 'test-session-123',
      String instruction = 'Test instruction',
      SessionStatus status = SessionStatus.completed,
      List<Subtask>? subtasks,
      DateTime? completedAt,
    }) {
      return ExecutionSession(
        sessionId: sessionId,
        instruction: instruction,
        status: status,
        subtasks: subtasks ?? [],
        createdAt: DateTime(2024, 1, 1, 10, 0),
        updatedAt: DateTime(2024, 1, 1, 10, 30),
        completedAt: completedAt,
      );
    }

    /// Helper function to create test subtasks
    List<Subtask> createTestSubtasks(int count) {
      return List.generate(count, (index) {
        return Subtask(
          id: 'subtask-$index',
          description: 'Subtask $index description',
          status: index % 3 == 0
              ? SubtaskStatus.completed
              : (index % 3 == 1 ? SubtaskStatus.failed : SubtaskStatus.inProgress),
          timestamp: DateTime(2024, 1, 1, 10, index),
          error: index % 3 == 1 ? 'Error message $index' : null,
        );
      });
    }

    group('UI Elements Presence', () {
      testWidgets('displays app bar with title', (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession();
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Session Details'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('displays back button in app bar', (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession();
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });

      testWidgets('back button pops the screen', (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession();
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Assert - Screen should be popped (no longer visible)
        expect(find.text('Session Details'), findsNothing);
      });

      testWidgets('displays loading indicator on initial load',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession();
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        // Don't settle yet - we want to see the loading state
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading session details...'), findsOneWidget);
        
        // Clean up - let the async operation complete
        await tester.pumpAndSettle();
      });

      testWidgets('displays error state with retry button on failure',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.shouldFail = true;
        mockApiService.failureMessage = 'Network error';
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });
    });

    group('Session Details Display', () {
      testWidgets('displays session instruction', (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession(
          instruction: 'Open Chrome and navigate to Google',
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Task Instruction'), findsOneWidget);
        expect(find.text('Open Chrome and navigate to Google'), findsOneWidget);
      });

      testWidgets('displays session status badge - completed',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession(
          status: SessionStatus.completed,
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Completed'), findsOneWidget);
      });

      testWidgets('displays session status badge - failed',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession(
          status: SessionStatus.failed,
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Failed'), findsOneWidget);
      });

      testWidgets('displays session status badge - cancelled',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession(
          status: SessionStatus.cancelled,
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Cancelled'), findsOneWidget);
      });

      testWidgets('displays session status badge - in progress',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession(
          status: SessionStatus.inProgress,
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('In Progress'), findsOneWidget);
      });

      testWidgets('displays timeline section', (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession();
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Timeline'), findsOneWidget);
      });

      testWidgets('displays started timestamp', (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession();
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Started'), findsOneWidget);
        expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
      });

      testWidgets('displays last updated timestamp', (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession();
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Last Updated'), findsOneWidget);
        expect(find.byIcon(Icons.update), findsOneWidget);
      });

      testWidgets('displays completed timestamp when session is completed',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession(
          status: SessionStatus.completed,
          completedAt: DateTime(2024, 1, 1, 11, 0),
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Completed'), findsNWidgets(2)); // Status badge + timestamp label
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      });

      testWidgets('does not display completed timestamp when session is not completed',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession(
          status: SessionStatus.inProgress,
          completedAt: null,
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      });
    });

    group('Subtask List Display', () {
      testWidgets('displays subtasks section header', (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession(
          subtasks: createTestSubtasks(3),
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        // Assert
        expect(find.text('Subtasks'), findsOneWidget);
      });

      testWidgets('displays subtask count badge', (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession(
          subtasks: createTestSubtasks(5),
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        // Assert
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('displays all subtasks', (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession(
          subtasks: createTestSubtasks(3),
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        // Assert
        expect(find.text('Subtask 0 description'), findsOneWidget);
        expect(find.text('Subtask 1 description'), findsOneWidget);
        expect(find.text('Subtask 2 description'), findsOneWidget);
      });

      testWidgets('displays empty state when no subtasks',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession(
          subtasks: [],
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('No subtasks recorded'), findsOneWidget);
      });

      testWidgets('displays subtasks with different statuses',
          (WidgetTester tester) async {
        // Arrange
        final subtasks = [
          Subtask(
            id: 'subtask-1',
            description: 'Completed subtask',
            status: SubtaskStatus.completed,
            timestamp: DateTime(2024, 1, 1, 10, 0),
          ),
          Subtask(
            id: 'subtask-2',
            description: 'Failed subtask',
            status: SubtaskStatus.failed,
            timestamp: DateTime(2024, 1, 1, 10, 1),
            error: 'Test error',
          ),
          Subtask(
            id: 'subtask-3',
            description: 'In progress subtask',
            status: SubtaskStatus.inProgress,
            timestamp: DateTime(2024, 1, 1, 10, 2),
          ),
        ];
        mockApiService.sessionToReturn = createTestSession(
          subtasks: subtasks,
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        // Assert
        expect(find.text('Completed subtask'), findsOneWidget);
        expect(find.text('Failed subtask'), findsOneWidget);
        expect(find.text('In progress subtask'), findsOneWidget);
      });

      testWidgets('subtask list is scrollable', (WidgetTester tester) async {
        // Arrange - Create many subtasks
        mockApiService.sessionToReturn = createTestSession(
          subtasks: createTestSubtasks(20),
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        // Assert - Should find SingleChildScrollView
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        
        // Verify we can scroll
        final scrollView = find.byType(SingleChildScrollView);
        await tester.drag(scrollView, const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 200));
        
        // Should still be able to find the scroll view after scrolling
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message when loading fails',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.shouldFail = true;
        mockApiService.failureMessage = 'Network error';
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Something went wrong'), findsOneWidget);
      });

      testWidgets('retry button reloads session details',
          (WidgetTester tester) async {
        // Arrange - Start with error
        mockApiService.shouldFail = true;
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();
        
        // Fix the mock to return data
        mockApiService.shouldFail = false;
        mockApiService.sessionToReturn = createTestSession(
          instruction: 'Test instruction after retry',
        );

        // Act - Tap retry button
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Assert - Should now show session details
        expect(find.text('Test instruction after retry'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });

      testWidgets('error state does not show session details',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.shouldFail = true;
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Task Instruction'), findsNothing);
        expect(find.text('Timeline'), findsNothing);
        expect(find.text('Subtasks'), findsNothing);
      });
    });

    group('Loading State', () {
      testWidgets('shows loading indicator during initial load',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession();
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pump(); // Don't settle - check loading state
        await tester.pump(const Duration(milliseconds: 50));

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading session details...'), findsOneWidget);
        
        // Clean up - let the async operation complete
        await tester.pumpAndSettle();
      });

      testWidgets('hides loading indicator after data loads',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession();
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Loading session details...'), findsNothing);
      });

      testWidgets('loads session details automatically on screen init',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession(
          instruction: 'Auto-loaded instruction',
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('test-session-123'));
        await tester.pumpAndSettle();

        // Assert - Session details should be loaded
        expect(find.text('Auto-loaded instruction'), findsOneWidget);
      });
    });

    group('Session ID Handling', () {
      testWidgets('loads correct session based on session ID',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionToReturn = createTestSession(
          sessionId: 'specific-session-456',
          instruction: 'Specific session instruction',
        );
        
        // Act
        await tester.pumpWidget(buildSessionDetailView('specific-session-456'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Specific session instruction'), findsOneWidget);
      });
    });
  });
}
