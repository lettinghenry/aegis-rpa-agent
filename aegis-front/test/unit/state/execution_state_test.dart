import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/state/execution_state.dart';
import 'package:aegis_front/models/execution_session.dart';
import 'package:aegis_front/models/subtask.dart';
import 'package:aegis_front/models/status_update.dart';
import 'package:aegis_front/models/task_instruction.dart';
import 'package:aegis_front/services/backend_api_service.dart';
import 'package:aegis_front/services/websocket_service.dart';
import 'package:aegis_front/services/window_service.dart';

// Import ConnectionStatus enum
export 'package:aegis_front/state/execution_state.dart' show ConnectionStatus;

// Mock classes for services
class MockBackendApiService implements BackendApiService {
  TaskInstructionResponse? mockStartTaskResponse;
  Exception? mockStartTaskException;
  Exception? mockCancelSessionException;
  bool cancelSessionCalled = false;

  @override
  Future<TaskInstructionResponse> startTask(String instruction) async {
    if (mockStartTaskException != null) {
      throw mockStartTaskException!;
    }
    return mockStartTaskResponse!;
  }

  @override
  Future<void> cancelSession(String sessionId) async {
    cancelSessionCalled = true;
    if (mockCancelSessionException != null) {
      throw mockCancelSessionException!;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWebSocketService implements WebSocketService {
  bool connectCalled = false;
  bool disconnectCalled = false;
  String? connectedSessionId;
  Function(StatusUpdate)? onUpdateCallback;
  Function(dynamic)? onErrorCallback;
  Function()? onDoneCallback;
  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect(
    String sessionId, {
    required Function(StatusUpdate) onUpdate,
    Function(dynamic)? onError,
    Function()? onDone,
  }) async {
    connectCalled = true;
    connectedSessionId = sessionId;
    onUpdateCallback = onUpdate;
    onErrorCallback = onError;
    onDoneCallback = onDone;
    _isConnected = true;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
    _isConnected = false;
  }

  void simulateUpdate(StatusUpdate update) {
    onUpdateCallback?.call(update);
  }

  void simulateError(dynamic error) {
    _isConnected = false;
    onErrorCallback?.call(error);
  }

  void simulateDone() {
    _isConnected = false;
    onDoneCallback?.call();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWindowService implements WindowService {
  bool enterMinimalModeCalled = false;
  bool exitMinimalModeCalled = false;
  int enterMinimalModeCallCount = 0;
  int exitMinimalModeCallCount = 0;

  @override
  Future<void> enterMinimalMode() async {
    enterMinimalModeCalled = true;
    enterMinimalModeCallCount++;
  }

  @override
  Future<void> exitMinimalMode() async {
    exitMinimalModeCalled = true;
    exitMinimalModeCallCount++;
  }

  @override
  bool get isMinimalMode => enterMinimalModeCalled && !exitMinimalModeCalled;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExecutionStateNotifier', () {
    late ExecutionStateNotifier executionState;
    late MockBackendApiService mockApiService;
    late MockWebSocketService mockWsService;
    late MockWindowService mockWindowService;

    setUp(() {
      mockApiService = MockBackendApiService();
      mockWsService = MockWebSocketService();
      mockWindowService = MockWindowService();
      executionState = ExecutionStateNotifier(
        apiService: mockApiService,
        wsService: mockWsService,
        windowService: mockWindowService,
      );
    });

    group('initial state', () {
      test('sessionId is null by default', () {
        expect(executionState.sessionId, null);
      });

      test('instruction is null by default', () {
        expect(executionState.instruction, null);
      });

      test('status is pending by default', () {
        expect(executionState.status, SessionStatus.pending);
      });

      test('subtasks list is empty by default', () {
        expect(executionState.subtasks, isEmpty);
      });

      test('isConnected is false by default', () {
        expect(executionState.isConnected, false);
      });

      test('isMinimalMode is false by default', () {
        expect(executionState.isMinimalMode, false);
      });

      test('errorMessage is null by default', () {
        expect(executionState.errorMessage, null);
      });
    });

    group('startExecution', () {
      test('submits task to backend and connects WebSocket', () async {
        // Arrange
        const instruction = 'Open calculator';
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );

        // Act
        await executionState.startExecution(instruction);

        // Assert
        expect(executionState.instruction, instruction);
        expect(executionState.sessionId, 'test-session-123');
        expect(executionState.status, SessionStatus.inProgress);
        expect(executionState.isConnected, true);
        expect(mockWsService.connectCalled, true);
        expect(mockWsService.connectedSessionId, 'test-session-123');
      });

      test('sets status to pending initially', () async {
        // Arrange
        const instruction = 'Open calculator';
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );

        List<SessionStatus> statusChanges = [];
        executionState.addListener(() {
          statusChanges.add(executionState.status);
        });

        // Act
        await executionState.startExecution(instruction);

        // Assert
        expect(statusChanges.first, SessionStatus.pending);
      });

      test('clears previous subtasks on new execution', () async {
        // Arrange
        const instruction = 'Open calculator';
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );

        // Add a subtask manually to simulate previous state
        final update = StatusUpdate(
          sessionId: 'old-session',
          subtask: Subtask(
            id: 'subtask-1',
            description: 'Old subtask',
            status: SubtaskStatus.completed,
            timestamp: DateTime.now(),
          ),
          overallStatus: 'in_progress',
          message: 'Processing',
          timestamp: DateTime.now(),
        );
        executionState.onStatusUpdate(update);
        expect(executionState.subtasks, isNotEmpty);

        // Act
        await executionState.startExecution(instruction);

        // Assert
        expect(executionState.subtasks, isEmpty);
      });

      test('clears error message on new execution', () async {
        // Arrange
        const instruction = 'Open calculator';
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );

        // Simulate previous error
        mockApiService.mockStartTaskException = Exception('Previous error');
        try {
          await executionState.startExecution('Previous instruction');
        } catch (_) {}
        expect(executionState.errorMessage, isNotNull);

        // Reset for new execution
        mockApiService.mockStartTaskException = null;

        // Act
        await executionState.startExecution(instruction);

        // Assert
        expect(executionState.errorMessage, null);
      });

      test('handles backend error and sets status to failed', () async {
        // Arrange
        const instruction = 'Open calculator';
        mockApiService.mockStartTaskException = Exception('Backend error');

        // Act & Assert
        expect(
          () => executionState.startExecution(instruction),
          throwsException,
        );

        await Future.delayed(Duration.zero); // Allow state to update

        expect(executionState.status, SessionStatus.failed);
        expect(executionState.errorMessage, contains('Backend error'));
      });

      test('notifies listeners during execution start', () async {
        // Arrange
        const instruction = 'Open calculator';
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );

        int notificationCount = 0;
        executionState.addListener(() {
          notificationCount++;
        });

        // Act
        await executionState.startExecution(instruction);

        // Assert - Should notify multiple times during the flow
        expect(notificationCount, greaterThanOrEqualTo(3));
      });
    });

    group('onStatusUpdate', () {
      setUp(() async {
        // Set up a session first
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );
        await executionState.startExecution('Test instruction');
      });

      test('adds new subtask to list', () {
        // Arrange
        final update = StatusUpdate(
          sessionId: 'test-session-123',
          subtask: Subtask(
            id: 'subtask-1',
            description: 'Click button',
            status: SubtaskStatus.inProgress,
            timestamp: DateTime.now(),
          ),
          overallStatus: 'in_progress',
          message: 'Processing',
          timestamp: DateTime.now(),
        );

        // Act
        executionState.onStatusUpdate(update);

        // Assert
        expect(executionState.subtasks.length, 1);
        expect(executionState.subtasks.first.id, 'subtask-1');
        expect(executionState.subtasks.first.description, 'Click button');
      });

      test('updates existing subtask', () {
        // Arrange
        final initialUpdate = StatusUpdate(
          sessionId: 'test-session-123',
          subtask: Subtask(
            id: 'subtask-1',
            description: 'Click button',
            status: SubtaskStatus.inProgress,
            timestamp: DateTime.now(),
          ),
          overallStatus: 'in_progress',
          message: 'Processing',
          timestamp: DateTime.now(),
        );
        executionState.onStatusUpdate(initialUpdate);

        final updatedSubtask = StatusUpdate(
          sessionId: 'test-session-123',
          subtask: Subtask(
            id: 'subtask-1',
            description: 'Click button',
            status: SubtaskStatus.completed,
            timestamp: DateTime.now(),
          ),
          overallStatus: 'in_progress',
          message: 'Completed',
          timestamp: DateTime.now(),
        );

        // Act
        executionState.onStatusUpdate(updatedSubtask);

        // Assert
        expect(executionState.subtasks.length, 1);
        expect(executionState.subtasks.first.status, SubtaskStatus.completed);
      });

      test('updates overall status', () {
        // Arrange
        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'completed',
          message: 'All done',
          timestamp: DateTime.now(),
        );

        // Act
        executionState.onStatusUpdate(update);

        // Assert
        expect(executionState.status, SessionStatus.completed);
      });

      test('enters minimal mode on window_state minimal command', () {
        // Arrange
        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Starting RPA action',
          windowState: 'minimal',
          timestamp: DateTime.now(),
        );

        // Act
        executionState.onStatusUpdate(update);

        // Assert
        expect(executionState.isMinimalMode, true);
        expect(mockWindowService.enterMinimalModeCalled, true);
      });

      test('exits minimal mode on window_state normal command', () {
        // Arrange - First enter minimal mode
        final enterUpdate = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Starting RPA action',
          windowState: 'minimal',
          timestamp: DateTime.now(),
        );
        executionState.onStatusUpdate(enterUpdate);
        expect(executionState.isMinimalMode, true);

        final exitUpdate = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'RPA action complete',
          windowState: 'normal',
          timestamp: DateTime.now(),
        );

        // Act
        executionState.onStatusUpdate(exitUpdate);

        // Assert
        expect(executionState.isMinimalMode, false);
        expect(mockWindowService.exitMinimalModeCalled, true);
      });

      test('restores window on completion', () {
        // Arrange - Enter minimal mode first
        final minimalUpdate = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Starting RPA action',
          windowState: 'minimal',
          timestamp: DateTime.now(),
        );
        executionState.onStatusUpdate(minimalUpdate);
        expect(executionState.isMinimalMode, true);

        final completionUpdate = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'completed',
          message: 'All done',
          timestamp: DateTime.now(),
        );

        // Act
        executionState.onStatusUpdate(completionUpdate);

        // Assert
        expect(executionState.isMinimalMode, false);
        expect(mockWindowService.exitMinimalModeCalled, true);
      });

      test('restores window on failure', () {
        // Arrange - Enter minimal mode first
        final minimalUpdate = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Starting RPA action',
          windowState: 'minimal',
          timestamp: DateTime.now(),
        );
        executionState.onStatusUpdate(minimalUpdate);
        expect(executionState.isMinimalMode, true);

        final failureUpdate = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'failed',
          message: 'Error occurred',
          timestamp: DateTime.now(),
        );

        // Act
        executionState.onStatusUpdate(failureUpdate);

        // Assert
        expect(executionState.isMinimalMode, false);
        expect(mockWindowService.exitMinimalModeCalled, true);
      });

      test('restores window on cancellation', () {
        // Arrange - Enter minimal mode first
        final minimalUpdate = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Starting RPA action',
          windowState: 'minimal',
          timestamp: DateTime.now(),
        );
        executionState.onStatusUpdate(minimalUpdate);
        expect(executionState.isMinimalMode, true);

        final cancelUpdate = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'cancelled',
          message: 'Cancelled by user',
          timestamp: DateTime.now(),
        );

        // Act
        executionState.onStatusUpdate(cancelUpdate);

        // Assert
        expect(executionState.isMinimalMode, false);
        expect(mockWindowService.exitMinimalModeCalled, true);
      });

      test('does not enter minimal mode if already in minimal mode', () {
        // Arrange - Enter minimal mode first
        final firstUpdate = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Starting RPA action',
          windowState: 'minimal',
          timestamp: DateTime.now(),
        );
        executionState.onStatusUpdate(firstUpdate);
        expect(mockWindowService.enterMinimalModeCallCount, 1);

        final secondUpdate = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Continuing RPA action',
          windowState: 'minimal',
          timestamp: DateTime.now(),
        );

        // Act
        executionState.onStatusUpdate(secondUpdate);

        // Assert - Should not call enterMinimalMode again
        expect(mockWindowService.enterMinimalModeCallCount, 1);
      });

      test('does not exit minimal mode if not in minimal mode', () {
        // Arrange - Don't enter minimal mode
        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Processing',
          windowState: 'normal',
          timestamp: DateTime.now(),
        );

        // Act
        executionState.onStatusUpdate(update);

        // Assert - Should not call exitMinimalMode
        expect(mockWindowService.exitMinimalModeCalled, false);
      });

      test('notifies listeners on status update', () {
        // Arrange
        int notificationCount = 0;
        executionState.addListener(() {
          notificationCount++;
        });

        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Processing',
          timestamp: DateTime.now(),
        );

        // Act
        executionState.onStatusUpdate(update);

        // Assert
        expect(notificationCount, 1);
      });
    });

    group('cancelExecution', () {
      setUp(() async {
        // Set up a session first
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );
        await executionState.startExecution('Test instruction');
      });

      test('sends cancellation request to backend', () async {
        // Act
        await executionState.cancelExecution();

        // Assert
        expect(mockApiService.cancelSessionCalled, true);
      });

      test('disconnects WebSocket', () async {
        // Act
        await executionState.cancelExecution();

        // Assert
        expect(mockWsService.disconnectCalled, true);
        expect(executionState.isConnected, false);
      });

      test('sets status to cancelled', () async {
        // Act
        await executionState.cancelExecution();

        // Assert
        expect(executionState.status, SessionStatus.cancelled);
      });

      test('restores window if in minimal mode', () async {
        // Arrange - Enter minimal mode
        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Starting RPA action',
          windowState: 'minimal',
          timestamp: DateTime.now(),
        );
        executionState.onStatusUpdate(update);
        expect(executionState.isMinimalMode, true);

        // Act
        await executionState.cancelExecution();

        // Assert
        expect(executionState.isMinimalMode, false);
        expect(mockWindowService.exitMinimalModeCalled, true);
      });

      test('does not restore window if not in minimal mode', () async {
        // Arrange - Ensure not in minimal mode
        expect(executionState.isMinimalMode, false);

        // Act
        await executionState.cancelExecution();

        // Assert
        expect(mockWindowService.exitMinimalModeCalled, false);
      });

      test('handles cancellation error', () async {
        // Arrange
        mockApiService.mockCancelSessionException = Exception('Cancel failed');

        // Act & Assert
        expect(
          () => executionState.cancelExecution(),
          throwsException,
        );

        await Future.delayed(Duration.zero); // Allow state to update

        expect(executionState.errorMessage, contains('Failed to cancel execution'));
      });

      test('does nothing if no session exists', () async {
        // Arrange - Reset to clear session
        executionState.reset();
        expect(executionState.sessionId, null);

        // Act
        await executionState.cancelExecution();

        // Assert - Should not call any services
        expect(mockApiService.cancelSessionCalled, false);
      });

      test('notifies listeners on cancellation', () async {
        // Arrange
        int notificationCount = 0;
        executionState.addListener(() {
          notificationCount++;
        });

        // Act
        await executionState.cancelExecution();

        // Assert - Should notify at least once
        expect(notificationCount, greaterThanOrEqualTo(1));
      });
    });

    group('state change notifications', () {
      test('notifies listeners when starting execution', () async {
        // Arrange
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );

        int notificationCount = 0;
        executionState.addListener(() {
          notificationCount++;
        });

        // Act
        await executionState.startExecution('Test instruction');

        // Assert
        expect(notificationCount, greaterThanOrEqualTo(3));
      });

      test('notifies listeners when receiving status updates', () async {
        // Arrange
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );
        await executionState.startExecution('Test instruction');

        int notificationCount = 0;
        executionState.addListener(() {
          notificationCount++;
        });

        final update = StatusUpdate(
          sessionId: 'test-session-123',
          subtask: Subtask(
            id: 'subtask-1',
            description: 'Click button',
            status: SubtaskStatus.inProgress,
            timestamp: DateTime.now(),
          ),
          overallStatus: 'in_progress',
          message: 'Processing',
          timestamp: DateTime.now(),
        );

        // Act
        executionState.onStatusUpdate(update);

        // Assert
        expect(notificationCount, 1);
      });

      test('notifies listeners when cancelling execution', () async {
        // Arrange
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );
        await executionState.startExecution('Test instruction');

        int notificationCount = 0;
        executionState.addListener(() {
          notificationCount++;
        });

        // Act
        await executionState.cancelExecution();

        // Assert
        expect(notificationCount, greaterThanOrEqualTo(1));
      });

      test('multiple listeners all receive notifications', () async {
        // Arrange
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );

        int listener1Count = 0;
        int listener2Count = 0;
        int listener3Count = 0;

        executionState.addListener(() => listener1Count++);
        executionState.addListener(() => listener2Count++);
        executionState.addListener(() => listener3Count++);

        // Act
        await executionState.startExecution('Test instruction');

        // Assert - All listeners should be notified
        expect(listener1Count, greaterThanOrEqualTo(3));
        expect(listener2Count, greaterThanOrEqualTo(3));
        expect(listener3Count, greaterThanOrEqualTo(3));
      });
    });

    group('WebSocket callbacks', () {
      setUp(() async {
        // Set up a session first
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );
        await executionState.startExecution('Test instruction');
      });

      test('handles WebSocket error', () {
        // Act
        mockWsService.simulateError('Connection lost');

        // Assert
        expect(executionState.isConnected, false);
        // Error message is only set if connection status is failed (not reconnecting)
        // Since the session is still in progress, it will try to reconnect
        expect(executionState.connectionStatus, ConnectionStatus.reconnecting);
      });

      test('handles WebSocket done', () {
        // Arrange - Enter minimal mode first
        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Starting RPA action',
          windowState: 'minimal',
          timestamp: DateTime.now(),
        );
        executionState.onStatusUpdate(update);
        expect(executionState.isMinimalMode, true);

        // Act
        mockWsService.simulateDone();

        // Assert
        expect(executionState.isConnected, false);
        // Window should remain in minimal mode during active execution
        // It will be restored when execution completes
        expect(executionState.isMinimalMode, true);
      });

      test('notifies listeners on WebSocket error', () {
        // Arrange
        int notificationCount = 0;
        executionState.addListener(() {
          notificationCount++;
        });

        // Act
        mockWsService.simulateError('Connection lost');

        // Assert
        expect(notificationCount, 1);
      });

      test('notifies listeners on WebSocket done', () {
        // Arrange
        int notificationCount = 0;
        executionState.addListener(() {
          notificationCount++;
        });

        // Act
        mockWsService.simulateDone();

        // Assert
        expect(notificationCount, 1);
      });
    });

    group('reset', () {
      test('clears all state', () async {
        // Arrange - Set up a session with some state
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );
        await executionState.startExecution('Test instruction');

        final update = StatusUpdate(
          sessionId: 'test-session-123',
          subtask: Subtask(
            id: 'subtask-1',
            description: 'Click button',
            status: SubtaskStatus.inProgress,
            timestamp: DateTime.now(),
          ),
          overallStatus: 'in_progress',
          message: 'Processing',
          timestamp: DateTime.now(),
        );
        executionState.onStatusUpdate(update);

        // Act
        executionState.reset();

        // Assert
        expect(executionState.sessionId, null);
        expect(executionState.instruction, null);
        expect(executionState.status, SessionStatus.pending);
        expect(executionState.subtasks, isEmpty);
        expect(executionState.isConnected, false);
        expect(executionState.isMinimalMode, false);
        expect(executionState.errorMessage, null);
      });

      test('notifies listeners on reset', () {
        // Arrange
        int notificationCount = 0;
        executionState.addListener(() {
          notificationCount++;
        });

        // Act
        executionState.reset();

        // Assert
        expect(notificationCount, 1);
      });
    });

    group('dispose', () {
      test('restores window if in minimal mode', () async {
        // Arrange - Set up session and enter minimal mode
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );
        await executionState.startExecution('Test instruction');

        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Starting RPA action',
          windowState: 'minimal',
          timestamp: DateTime.now(),
        );
        executionState.onStatusUpdate(update);
        expect(executionState.isMinimalMode, true);

        // Act
        executionState.dispose();

        // Assert
        expect(mockWindowService.exitMinimalModeCalled, true);
      });
    });

    group('edge cases', () {
      test('handles multiple subtasks correctly', () async {
        // Arrange
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );
        await executionState.startExecution('Test instruction');

        // Act - Add multiple subtasks
        for (int i = 1; i <= 5; i++) {
          final update = StatusUpdate(
            sessionId: 'test-session-123',
            subtask: Subtask(
              id: 'subtask-$i',
              description: 'Subtask $i',
              status: SubtaskStatus.inProgress,
              timestamp: DateTime.now(),
            ),
            overallStatus: 'in_progress',
            message: 'Processing subtask $i',
            timestamp: DateTime.now(),
          );
          executionState.onStatusUpdate(update);
        }

        // Assert
        expect(executionState.subtasks.length, 5);
        expect(executionState.subtasks[0].id, 'subtask-1');
        expect(executionState.subtasks[4].id, 'subtask-5');
      });

      test('handles status update without subtask', () async {
        // Arrange
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );
        await executionState.startExecution('Test instruction');

        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Processing',
          timestamp: DateTime.now(),
        );

        // Act
        executionState.onStatusUpdate(update);

        // Assert - Should update status without adding subtask
        expect(executionState.status, SessionStatus.inProgress);
        expect(executionState.subtasks, isEmpty);
      });

      test('handles status update without window state', () async {
        // Arrange
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: 'test-session-123',
          status: 'pending',
          message: 'Task started',
        );
        await executionState.startExecution('Test instruction');

        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Processing',
          timestamp: DateTime.now(),
        );

        // Act
        executionState.onStatusUpdate(update);

        // Assert - Should not change window mode
        expect(executionState.isMinimalMode, false);
        expect(mockWindowService.enterMinimalModeCalled, false);
      });
    });
  });
}
