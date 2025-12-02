import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/state/history_state.dart';
import 'package:aegis_front/services/backend_api_service.dart';
import 'package:aegis_front/models/session_summary.dart';
import 'package:aegis_front/models/task_instruction.dart';
import 'package:aegis_front/models/execution_session.dart';

/// Mock BackendApiService for testing
class MockBackendApiService implements BackendApiService {
  HistoryResponse? mockHistoryResponse;
  Exception? mockException;
  bool shouldThrowException = false;

  @override
  Future<HistoryResponse> getHistory() async {
    if (shouldThrowException && mockException != null) {
      throw mockException!;
    }
    return mockHistoryResponse ?? HistoryResponse(sessions: [], total: 0);
  }

  // Unused methods for this test
  @override
  Future<TaskInstructionResponse> startTask(String instruction) async {
    throw UnimplementedError();
  }

  @override
  Future<ExecutionSession> getSessionDetails(String sessionId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelSession(String sessionId) async {
    throw UnimplementedError();
  }

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryStateNotifier', () {
    late HistoryStateNotifier historyState;
    late MockBackendApiService mockApiService;

    setUp(() {
      mockApiService = MockBackendApiService();
      historyState = HistoryStateNotifier(apiService: mockApiService);
    });

    group('initial state', () {
      test('sessions list is empty by default', () {
        expect(historyState.sessions, isEmpty);
      });

      test('isLoading is false by default', () {
        expect(historyState.isLoading, false);
      });

      test('errorMessage is null by default', () {
        expect(historyState.errorMessage, null);
      });
    });

    group('loadHistory', () {
      test('loads sessions successfully', () async {
        // Arrange
        final mockSessions = [
          SessionSummary(
            sessionId: 'session-1',
            instruction: 'Test instruction 1',
            status: 'completed',
            createdAt: DateTime(2024, 1, 1, 10, 0),
            completedAt: DateTime(2024, 1, 1, 10, 5),
            subtaskCount: 3,
          ),
          SessionSummary(
            sessionId: 'session-2',
            instruction: 'Test instruction 2',
            status: 'failed',
            createdAt: DateTime(2024, 1, 2, 14, 30),
            completedAt: DateTime(2024, 1, 2, 14, 35),
            subtaskCount: 5,
          ),
        ];

        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: mockSessions,
          total: 2,
        );

        // Act
        await historyState.loadHistory();

        // Assert
        expect(historyState.sessions.length, 2);
        expect(historyState.sessions[0].sessionId, 'session-1');
        expect(historyState.sessions[1].sessionId, 'session-2');
        expect(historyState.isLoading, false);
        expect(historyState.errorMessage, null);
      });

      test('loads empty history successfully', () async {
        // Arrange
        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: [],
          total: 0,
        );

        // Act
        await historyState.loadHistory();

        // Assert
        expect(historyState.sessions, isEmpty);
        expect(historyState.isLoading, false);
        expect(historyState.errorMessage, null);
      });

      test('sets isLoading to true during loading', () async {
        // Arrange
        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: [],
          total: 0,
        );

        bool wasLoadingDuringExecution = false;

        // Listen to state changes
        historyState.addListener(() {
          if (historyState.isLoading) {
            wasLoadingDuringExecution = true;
          }
        });

        // Act
        await historyState.loadHistory();

        // Assert
        expect(wasLoadingDuringExecution, true);
        expect(historyState.isLoading, false); // Should be false after completion
      });

      test('clears error message before loading', () async {
        // Arrange
        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: [],
          total: 0,
        );

        // Simulate a previous error
        mockApiService.shouldThrowException = true;
        mockApiService.mockException = NetworkException('Network error');
        await historyState.loadHistory();
        expect(historyState.errorMessage, isNotNull);

        // Reset for successful load
        mockApiService.shouldThrowException = false;

        // Act
        await historyState.loadHistory();

        // Assert
        expect(historyState.errorMessage, null);
      });

      test('handles network error', () async {
        // Arrange
        mockApiService.shouldThrowException = true;
        mockApiService.mockException = NetworkException('Network error');

        // Act
        await historyState.loadHistory();

        // Assert
        expect(historyState.errorMessage, contains('NetworkException'));
        expect(historyState.isLoading, false);
        expect(historyState.sessions, isEmpty);
      });

      test('handles API error', () async {
        // Arrange
        mockApiService.shouldThrowException = true;
        mockApiService.mockException = ApiException(
          'Server error',
          statusCode: 500,
        );

        // Act
        await historyState.loadHistory();

        // Assert
        expect(historyState.errorMessage, contains('ApiException'));
        expect(historyState.isLoading, false);
        expect(historyState.sessions, isEmpty);
      });

      test('keeps existing sessions on error', () async {
        // Arrange - First load successfully
        final mockSessions = [
          SessionSummary(
            sessionId: 'session-1',
            instruction: 'Test instruction',
            status: 'completed',
            createdAt: DateTime(2024, 1, 1),
            subtaskCount: 3,
          ),
        ];

        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: mockSessions,
          total: 1,
        );

        await historyState.loadHistory();
        expect(historyState.sessions.length, 1);

        // Now simulate an error
        mockApiService.shouldThrowException = true;
        mockApiService.mockException = NetworkException('Network error');

        // Act
        await historyState.loadHistory();

        // Assert - Sessions should be preserved
        expect(historyState.sessions.length, 1);
        expect(historyState.sessions[0].sessionId, 'session-1');
        expect(historyState.errorMessage, isNotNull);
      });

      test('can be called multiple times', () async {
        // Arrange
        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: [],
          total: 0,
        );

        // Act
        await historyState.loadHistory();
        await historyState.loadHistory();
        await historyState.loadHistory();

        // Assert
        expect(historyState.errorMessage, null);
        expect(historyState.isLoading, false);
      });

      test('updates sessions on subsequent loads', () async {
        // Arrange - First load
        final firstSessions = [
          SessionSummary(
            sessionId: 'session-1',
            instruction: 'First instruction',
            status: 'completed',
            createdAt: DateTime(2024, 1, 1),
            subtaskCount: 2,
          ),
        ];

        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: firstSessions,
          total: 1,
        );

        await historyState.loadHistory();
        expect(historyState.sessions.length, 1);

        // Second load with different data
        final secondSessions = [
          SessionSummary(
            sessionId: 'session-1',
            instruction: 'First instruction',
            status: 'completed',
            createdAt: DateTime(2024, 1, 1),
            subtaskCount: 2,
          ),
          SessionSummary(
            sessionId: 'session-2',
            instruction: 'Second instruction',
            status: 'in_progress',
            createdAt: DateTime(2024, 1, 2),
            subtaskCount: 4,
          ),
        ];

        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: secondSessions,
          total: 2,
        );

        // Act
        await historyState.loadHistory();

        // Assert
        expect(historyState.sessions.length, 2);
        expect(historyState.sessions[1].sessionId, 'session-2');
      });
    });

    group('clearError', () {
      test('clears error message', () async {
        // Arrange - Create an error
        mockApiService.shouldThrowException = true;
        mockApiService.mockException = NetworkException('Network error');
        await historyState.loadHistory();
        expect(historyState.errorMessage, isNotNull);

        // Act
        historyState.clearError();

        // Assert
        expect(historyState.errorMessage, null);
      });

      test('notifies listeners when clearing error', () async {
        // Arrange - Create an error
        mockApiService.shouldThrowException = true;
        mockApiService.mockException = NetworkException('Network error');
        await historyState.loadHistory();

        int notificationCount = 0;
        historyState.addListener(() {
          notificationCount++;
        });

        // Act
        historyState.clearError();

        // Assert
        expect(notificationCount, 1);
      });

      test('can be called when no error exists', () {
        // Act & Assert - Should not throw
        expect(() => historyState.clearError(), returnsNormally);
        expect(historyState.errorMessage, null);
      });
    });

    group('reset', () {
      test('clears all state', () async {
        // Arrange - Load some data
        final mockSessions = [
          SessionSummary(
            sessionId: 'session-1',
            instruction: 'Test instruction',
            status: 'completed',
            createdAt: DateTime(2024, 1, 1),
            subtaskCount: 3,
          ),
        ];

        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: mockSessions,
          total: 1,
        );

        await historyState.loadHistory();
        expect(historyState.sessions.length, 1);

        // Act
        historyState.reset();

        // Assert
        expect(historyState.sessions, isEmpty);
        expect(historyState.isLoading, false);
        expect(historyState.errorMessage, null);
      });

      test('notifies listeners when resetting', () {
        // Arrange
        int notificationCount = 0;
        historyState.addListener(() {
          notificationCount++;
        });

        // Act
        historyState.reset();

        // Assert
        expect(notificationCount, 1);
      });

      test('can be called on initial state', () {
        // Act & Assert - Should not throw
        expect(() => historyState.reset(), returnsNormally);
        expect(historyState.sessions, isEmpty);
        expect(historyState.isLoading, false);
        expect(historyState.errorMessage, null);
      });
    });

    group('state change notifications', () {
      test('notifies listeners when loading history', () async {
        // Arrange
        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: [],
          total: 0,
        );

        int notificationCount = 0;
        historyState.addListener(() {
          notificationCount++;
        });

        // Act
        await historyState.loadHistory();

        // Assert - Should notify at least twice: start loading and finish loading
        expect(notificationCount, greaterThanOrEqualTo(2));
      });

      test('notifies listeners on error', () async {
        // Arrange
        mockApiService.shouldThrowException = true;
        mockApiService.mockException = NetworkException('Network error');

        int notificationCount = 0;
        historyState.addListener(() {
          notificationCount++;
        });

        // Act
        await historyState.loadHistory();

        // Assert - Should notify at least twice: start loading and finish with error
        expect(notificationCount, greaterThanOrEqualTo(2));
      });

      test('listener receives correct state during loadHistory', () async {
        // Arrange
        final mockSessions = [
          SessionSummary(
            sessionId: 'session-1',
            instruction: 'Test',
            status: 'completed',
            createdAt: DateTime(2024, 1, 1),
            subtaskCount: 1,
          ),
        ];

        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: mockSessions,
          total: 1,
        );

        List<bool> loadingStates = [];
        List<int> sessionCounts = [];

        historyState.addListener(() {
          loadingStates.add(historyState.isLoading);
          sessionCounts.add(historyState.sessions.length);
        });

        // Act
        await historyState.loadHistory();

        // Assert
        // First notification: isLoading = true, sessions = 0 (initial)
        // Second notification: isLoading = false, sessions = 1 (loaded)
        expect(loadingStates.first, true);
        expect(loadingStates.last, false);
        expect(sessionCounts.last, 1);
      });

      test('multiple listeners all receive notifications', () async {
        // Arrange
        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: [],
          total: 0,
        );

        int listener1Count = 0;
        int listener2Count = 0;
        int listener3Count = 0;

        historyState.addListener(() => listener1Count++);
        historyState.addListener(() => listener2Count++);
        historyState.addListener(() => listener3Count++);

        // Act
        await historyState.loadHistory();

        // Assert - All listeners should be notified
        expect(listener1Count, greaterThanOrEqualTo(2));
        expect(listener2Count, greaterThanOrEqualTo(2));
        expect(listener3Count, greaterThanOrEqualTo(2));
      });

      test('removed listener does not receive notifications', () async {
        // Arrange
        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: [],
          total: 0,
        );

        int notificationCount = 0;
        void listener() {
          notificationCount++;
        }

        historyState.addListener(listener);
        historyState.removeListener(listener);

        // Act
        await historyState.loadHistory();

        // Assert - Listener was removed, should not be notified
        expect(notificationCount, 0);
      });
    });

    group('sessions immutability', () {
      test('returned sessions list is unmodifiable', () async {
        // Arrange
        final mockSessions = [
          SessionSummary(
            sessionId: 'session-1',
            instruction: 'Test',
            status: 'completed',
            createdAt: DateTime(2024, 1, 1),
            subtaskCount: 1,
          ),
        ];

        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: mockSessions,
          total: 1,
        );

        await historyState.loadHistory();

        // Act & Assert - Attempting to modify should throw
        expect(
          () => historyState.sessions.add(
            SessionSummary(
              sessionId: 'session-2',
              instruction: 'Test 2',
              status: 'completed',
              createdAt: DateTime(2024, 1, 2),
              subtaskCount: 1,
            ),
          ),
          throwsUnsupportedError,
        );
      });

      test('modifying returned list does not affect internal state', () async {
        // Arrange
        final mockSessions = [
          SessionSummary(
            sessionId: 'session-1',
            instruction: 'Test',
            status: 'completed',
            createdAt: DateTime(2024, 1, 1),
            subtaskCount: 1,
          ),
        ];

        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: mockSessions,
          total: 1,
        );

        await historyState.loadHistory();

        // Act - Try to get a reference (though it's unmodifiable)
        final sessionsList = historyState.sessions;

        // Assert - Getting the list again should return the same data
        expect(historyState.sessions.length, 1);
        expect(historyState.sessions[0].sessionId, 'session-1');
      });
    });

    group('edge cases', () {
      test('handles very large session list', () async {
        // Arrange - Create 1000 sessions
        final largeSessions = List.generate(
          1000,
          (index) => SessionSummary(
            sessionId: 'session-$index',
            instruction: 'Instruction $index',
            status: 'completed',
            createdAt: DateTime(2024, 1, 1).add(Duration(hours: index)),
            subtaskCount: index % 10,
          ),
        );

        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: largeSessions,
          total: 1000,
        );

        // Act
        await historyState.loadHistory();

        // Assert
        expect(historyState.sessions.length, 1000);
        expect(historyState.errorMessage, null);
      });

      test('handles sessions with null completedAt', () async {
        // Arrange
        final mockSessions = [
          SessionSummary(
            sessionId: 'session-1',
            instruction: 'In progress task',
            status: 'in_progress',
            createdAt: DateTime(2024, 1, 1),
            completedAt: null, // Still in progress
            subtaskCount: 2,
          ),
        ];

        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: mockSessions,
          total: 1,
        );

        // Act
        await historyState.loadHistory();

        // Assert
        expect(historyState.sessions.length, 1);
        expect(historyState.sessions[0].completedAt, null);
      });

      test('handles mixed session statuses', () async {
        // Arrange
        final mockSessions = [
          SessionSummary(
            sessionId: 'session-1',
            instruction: 'Completed task',
            status: 'completed',
            createdAt: DateTime(2024, 1, 1),
            completedAt: DateTime(2024, 1, 1, 1, 0),
            subtaskCount: 3,
          ),
          SessionSummary(
            sessionId: 'session-2',
            instruction: 'Failed task',
            status: 'failed',
            createdAt: DateTime(2024, 1, 2),
            completedAt: DateTime(2024, 1, 2, 1, 0),
            subtaskCount: 2,
          ),
          SessionSummary(
            sessionId: 'session-3',
            instruction: 'Cancelled task',
            status: 'cancelled',
            createdAt: DateTime(2024, 1, 3),
            completedAt: DateTime(2024, 1, 3, 0, 30),
            subtaskCount: 1,
          ),
          SessionSummary(
            sessionId: 'session-4',
            instruction: 'In progress task',
            status: 'in_progress',
            createdAt: DateTime(2024, 1, 4),
            completedAt: null,
            subtaskCount: 5,
          ),
        ];

        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: mockSessions,
          total: 4,
        );

        // Act
        await historyState.loadHistory();

        // Assert
        expect(historyState.sessions.length, 4);
        expect(historyState.sessions[0].status, 'completed');
        expect(historyState.sessions[1].status, 'failed');
        expect(historyState.sessions[2].status, 'cancelled');
        expect(historyState.sessions[3].status, 'in_progress');
      });

      test('state remains consistent after error then success', () async {
        // Arrange - First cause an error
        mockApiService.shouldThrowException = true;
        mockApiService.mockException = NetworkException('Network error');

        await historyState.loadHistory();
        expect(historyState.errorMessage, isNotNull);
        expect(historyState.sessions, isEmpty);

        // Now succeed
        mockApiService.shouldThrowException = false;
        final mockSessions = [
          SessionSummary(
            sessionId: 'session-1',
            instruction: 'Test',
            status: 'completed',
            createdAt: DateTime(2024, 1, 1),
            subtaskCount: 1,
          ),
        ];

        mockApiService.mockHistoryResponse = HistoryResponse(
          sessions: mockSessions,
          total: 1,
        );

        // Act
        await historyState.loadHistory();

        // Assert
        expect(historyState.sessions.length, 1);
        expect(historyState.errorMessage, null);
        expect(historyState.isLoading, false);
      });
    });
  });
}
