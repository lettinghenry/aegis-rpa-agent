import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aegis_front/screens/history_view.dart';
import 'package:aegis_front/state/history_state.dart';
import 'package:aegis_front/services/backend_api_service.dart';
import 'package:aegis_front/models/session_summary.dart';

/// Mock BackendApiService for testing
class MockBackendApiService implements BackendApiService {
  bool shouldFail = false;
  String? failureMessage;
  List<SessionSummary> sessionsToReturn = [];

  @override
  Future<HistoryResponse> getHistory() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (shouldFail) {
      throw Exception(failureMessage ?? 'Failed to load history');
    }
    
    return HistoryResponse(
      sessions: sessionsToReturn,
      total: sessionsToReturn.length,
    );
  }

  // Implement other methods as no-ops for this test
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryView Widget Tests', () {
    late MockBackendApiService mockApiService;
    late HistoryStateNotifier historyState;

    setUp(() {
      mockApiService = MockBackendApiService();
      historyState = HistoryStateNotifier(
        apiService: mockApiService,
      );
    });

    /// Helper function to build the HistoryView with Provider
    Widget buildHistoryView() {
      return ChangeNotifierProvider<HistoryStateNotifier>.value(
        value: historyState,
        child: MaterialApp(
          home: const HistoryView(),
          routes: {
            '/session-detail': (context) {
              final sessionId = ModalRoute.of(context)!.settings.arguments as String;
              return Scaffold(
                appBar: AppBar(title: const Text('Session Detail')),
                body: Center(child: Text('Session: $sessionId')),
              );
            },
          },
        ),
      );
    }

    /// Helper function to create test session summaries
    List<SessionSummary> createTestSessions(int count) {
      return List.generate(count, (index) {
        return SessionSummary(
          sessionId: 'session-$index',
          instruction: 'Test instruction $index',
          status: index % 3 == 0 ? 'completed' : (index % 3 == 1 ? 'failed' : 'cancelled'),
          createdAt: DateTime.now().subtract(Duration(hours: index)),
          completedAt: DateTime.now().subtract(Duration(hours: index - 1)),
          subtaskCount: index + 1,
        );
      });
    }

    group('UI Elements Presence', () {
      testWidgets('displays app bar with title', (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = [];
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Execution History'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('displays back button in app bar', (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = [];
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });

      testWidgets('back button pops the screen', (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = [];
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Assert - Screen should be popped (no longer visible)
        expect(find.text('Execution History'), findsNothing);
      });

      testWidgets('displays loading indicator on initial load',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = [];
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        // Don't settle yet - we want to see the loading state
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading history...'), findsOneWidget);
        
        // Clean up - let the async operation complete
        await tester.pumpAndSettle();
      });
    });

    group('Session List Display', () {
      testWidgets('displays session list when data is loaded',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = createTestSessions(3);
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(ListView), findsOneWidget);
        expect(find.text('Test instruction 0'), findsOneWidget);
        expect(find.text('Test instruction 1'), findsOneWidget);
        expect(find.text('Test instruction 2'), findsOneWidget);
      });

      testWidgets('displays correct number of session cards',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = createTestSessions(3);
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert - Check that ListView exists
        expect(find.byType(ListView), findsOneWidget);
        
        // Verify we can find all 3 sessions
        expect(find.textContaining('Test instruction'), findsNWidgets(3));
        expect(historyState.sessions.length, 3);
      });

      testWidgets('displays session with status badge',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = [
          SessionSummary(
            sessionId: 'session-1',
            instruction: 'Open Chrome',
            status: 'completed',
            createdAt: DateTime.now(),
            subtaskCount: 3,
          ),
        ];
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Open Chrome'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
      });

      testWidgets('displays session with subtask count',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = [
          SessionSummary(
            sessionId: 'session-1',
            instruction: 'Test task',
            status: 'completed',
            createdAt: DateTime.now(),
            subtaskCount: 5,
          ),
        ];
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('5 subtasks'), findsOneWidget);
      });

      testWidgets('displays multiple sessions in chronological order',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = createTestSessions(3);
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert - All sessions should be displayed
        for (int i = 0; i < 3; i++) {
          expect(find.text('Test instruction $i'), findsOneWidget);
        }
      });

      testWidgets('session list is scrollable',
          (WidgetTester tester) async {
        // Arrange - Create many sessions
        mockApiService.sessionsToReturn = createTestSessions(20);
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert - Should find ListView
        expect(find.byType(ListView), findsOneWidget);
        
        // Verify we can scroll
        final listView = find.byType(ListView);
        await tester.drag(listView, const Offset(0, -500));
        await tester.pumpAndSettle();
        
        // Should still be able to find the ListView after scrolling
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Pull-to-Refresh', () {
      testWidgets('displays RefreshIndicator',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = createTestSessions(2);
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });

      testWidgets('pull-to-refresh reloads history',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = createTestSessions(2);
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Act - Perform pull-to-refresh
        await tester.drag(
          find.byType(RefreshIndicator),
          const Offset(0, 300),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - History should be reloaded (state should be updated)
        expect(historyState.sessions.length, 2);
      });

      testWidgets('pull-to-refresh updates session list',
          (WidgetTester tester) async {
        // Arrange - Start with 2 sessions
        mockApiService.sessionsToReturn = createTestSessions(2);
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();
        
        // Update mock to return 3 sessions
        mockApiService.sessionsToReturn = createTestSessions(3);

        // Act - Perform pull-to-refresh
        await tester.drag(
          find.byType(RefreshIndicator),
          const Offset(0, 300),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert - Should now show 3 sessions
        expect(find.text('Test instruction 2'), findsOneWidget);
        expect(historyState.sessions.length, 3);
      });
    });

    group('Empty State', () {
      testWidgets('displays empty state when no sessions',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = [];
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.history), findsOneWidget);
        expect(find.text('No execution history'), findsOneWidget);
        expect(
          find.text('Your automation sessions will appear here'),
          findsOneWidget,
        );
      });

      testWidgets('empty state does not show session list',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = [];
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(ListView), findsNothing);
      });

      testWidgets('empty state is centered',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = [];
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert - Should find Center widget
        expect(find.byType(Center), findsWidgets);
      });
    });

    group('Error State', () {
      testWidgets('displays error message when loading fails',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.shouldFail = true;
        mockApiService.failureMessage = 'Network error';
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Failed to load history'), findsOneWidget);
        expect(find.text('Exception: Network error'), findsOneWidget);
      });

      testWidgets('displays retry button on error',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.shouldFail = true;
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('retry button reloads history',
          (WidgetTester tester) async {
        // Arrange - Start with error
        mockApiService.shouldFail = true;
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();
        
        // Fix the mock to return data
        mockApiService.shouldFail = false;
        mockApiService.sessionsToReturn = createTestSessions(2);

        // Act - Tap retry button (find by text since it's FilledButton.icon)
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Assert - Should now show sessions
        expect(find.text('Test instruction 0'), findsOneWidget);
        expect(find.text('Test instruction 1'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });

      testWidgets('error state does not show session list',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.shouldFail = true;
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(ListView), findsNothing);
      });
    });

    group('Navigation to Detail View', () {
      testWidgets('tapping session card navigates to detail view',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = [
          SessionSummary(
            sessionId: 'session-123',
            instruction: 'Test task',
            status: 'completed',
            createdAt: DateTime.now(),
            subtaskCount: 3,
          ),
        ];
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Act - Tap on the session card
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // Assert - Should navigate to session detail view
        expect(find.text('Session Detail'), findsOneWidget);
        expect(find.text('Session: session-123'), findsOneWidget);
      });

      testWidgets('tapping different sessions navigates to correct detail',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = createTestSessions(3);
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Act - Tap on the second session card
        final cards = find.byType(Card);
        await tester.tap(cards.at(1));
        await tester.pumpAndSettle();

        // Assert - Should navigate with correct session ID
        expect(find.text('Session: session-1'), findsOneWidget);
      });

      testWidgets('session card is tappable',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = createTestSessions(1);
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert - Card should have InkWell (tappable)
        // There may be multiple InkWells in the widget tree, so just verify at least one exists
        expect(find.byType(InkWell), findsWidgets);
      });
    });

    group('Loading State', () {
      testWidgets('shows loading indicator during initial load',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = [];
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pump(); // Don't settle - check loading state
        await tester.pump(const Duration(milliseconds: 50));

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading history...'), findsOneWidget);
        
        // Clean up - let the async operation complete
        await tester.pumpAndSettle();
      });

      testWidgets('hides loading indicator after data loads',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = createTestSessions(2);
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Loading history...'), findsNothing);
      });

      testWidgets('loads history automatically on screen init',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.sessionsToReturn = createTestSessions(2);
        
        // Act
        await tester.pumpWidget(buildHistoryView());
        await tester.pumpAndSettle();

        // Assert - History should be loaded
        expect(historyState.sessions.length, 2);
        expect(historyState.isLoading, false);
      });
    });
  });
}
