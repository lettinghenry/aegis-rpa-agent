import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/state/execution_state.dart';
import 'package:aegis_front/models/execution_session.dart';
import 'package:aegis_front/models/subtask.dart';
import 'package:aegis_front/models/status_update.dart';
import 'package:aegis_front/models/task_instruction.dart';
import 'package:aegis_front/services/backend_api_service.dart';
import 'package:aegis_front/services/websocket_service.dart';
import 'package:aegis_front/services/window_service.dart';
import 'dart:math';

/// Property-based tests for ExecutionStateNotifier
/// 
/// **Feature: rpa-frontend**
/// **Property 6: WebSocket Connection Establishment**
/// **Property 7: Subtask Card Addition**
/// **Property 19: Cancellation Cleanup**
/// **Validates: Requirements 3.1, 3.2, 5.4**

// Mock classes for services
class MockBackendApiService implements BackendApiService {
  TaskInstructionResponse? mockStartTaskResponse;
  Exception? mockStartTaskException;
  Exception? mockCancelSessionException;
  bool cancelSessionCalled = false;
  List<String> cancelledSessionIds = [];

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
    cancelledSessionIds.add(sessionId);
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
  int connectCallCount = 0;
  int disconnectCallCount = 0;

  @override
  Future<void> connect(
    String sessionId, {
    required Function(StatusUpdate) onUpdate,
    Function(dynamic)? onError,
    Function()? onDone,
  }) async {
    connectCalled = true;
    connectCallCount++;
    connectedSessionId = sessionId;
    onUpdateCallback = onUpdate;
    onErrorCallback = onError;
    onDoneCallback = onDone;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
    disconnectCallCount++;
  }

  void simulateUpdate(StatusUpdate update) {
    onUpdateCallback?.call(update);
  }

  void reset() {
    connectCalled = false;
    disconnectCalled = false;
    connectedSessionId = null;
    onUpdateCallback = null;
    onErrorCallback = null;
    onDoneCallback = null;
    connectCallCount = 0;
    disconnectCallCount = 0;
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

  void reset() {
    enterMinimalModeCalled = false;
    exitMinimalModeCalled = false;
    enterMinimalModeCallCount = 0;
    exitMinimalModeCallCount = 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Execution State Properties', () {
    final random = Random();

    // Helper to generate random session ID
    String randomSessionId() {
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789-';
      return List.generate(20, (_) => chars[random.nextInt(chars.length)]).join();
    }

    // Helper to generate random instruction
    String randomInstruction() {
      final instructions = [
        'Open calculator',
        'Click the submit button',
        'Type hello world',
        'Launch notepad',
        'Close the window',
        'Navigate to settings',
        'Search for files',
        'Open browser',
        'Maximize window',
        'Minimize application',
      ];
      return instructions[random.nextInt(instructions.length)];
    }

    // Helper to generate random subtask
    Subtask randomSubtask() {
      final descriptions = [
        'Click button',
        'Type text',
        'Launch app',
        'Close window',
        'Navigate to page',
      ];
      final statuses = [
        SubtaskStatus.pending,
        SubtaskStatus.inProgress,
        SubtaskStatus.completed,
        SubtaskStatus.failed,
      ];

      return Subtask(
        id: randomSessionId(),
        description: descriptions[random.nextInt(descriptions.length)],
        status: statuses[random.nextInt(statuses.length)],
        timestamp: DateTime.now(),
      );
    }

    test('Property 6: WebSocket Connection Establishment', () async {
      // **Feature: rpa-frontend, Property 6: WebSocket Connection Establishment**
      // **Validates: Requirements 3.1**
      //
      // *For any* Task Execution Screen display, a WebSocket connection must be 
      // established to /ws/execution/{session_id} where session_id matches the current session.
      
      // Run 100 iterations as specified in design
      for (int i = 0; i < 100; i++) {
        final mockApiService = MockBackendApiService();
        final mockWsService = MockWebSocketService();
        final mockWindowService = MockWindowService();
        
        final executionState = ExecutionStateNotifier(
          apiService: mockApiService,
          wsService: mockWsService,
          windowService: mockWindowService,
        );

        // Generate random instruction and session ID
        final instruction = randomInstruction();
        final sessionId = randomSessionId();

        // Set up mock response
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: sessionId,
          status: 'pending',
          message: 'Task started',
        );

        // Start execution and wait for it to complete
        await executionState.startExecution(instruction);
        
        // Verify WebSocket connection was established
        expect(mockWsService.connectCalled, isTrue,
            reason: 'WebSocket connect must be called when execution starts');
        
        // Verify the session ID matches
        expect(mockWsService.connectedSessionId, equals(sessionId),
            reason: 'WebSocket must connect to the correct session ID');
        
        // Verify connection state is tracked
        expect(executionState.isConnected, isTrue,
            reason: 'isConnected must be true after WebSocket connection');

        // Clean up
        executionState.dispose();
        mockWsService.reset();
        mockWindowService.reset();
      }
    });

    test('Property 7: Subtask Card Addition', () async {
      // **Feature: rpa-frontend, Property 7: Subtask Card Addition**
      // **Validates: Requirements 3.2**
      //
      // *For any* WebSocket status update containing a new subtask, a new Subtask Card 
      // must be added to the display list.
      
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        final mockApiService = MockBackendApiService();
        final mockWsService = MockWebSocketService();
        final mockWindowService = MockWindowService();
        
        final executionState = ExecutionStateNotifier(
          apiService: mockApiService,
          wsService: mockWsService,
          windowService: mockWindowService,
        );

        // Set up session
        final sessionId = randomSessionId();
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: sessionId,
          status: 'pending',
          message: 'Task started',
        );

        await executionState.startExecution(randomInstruction());
        
        // Generate random number of subtasks (1-10)
        final numSubtasks = random.nextInt(10) + 1;
        final subtasks = List.generate(numSubtasks, (_) => randomSubtask());

        // Send status updates with new subtasks
        for (int j = 0; j < subtasks.length; j++) {
          final update = StatusUpdate(
            sessionId: sessionId,
            subtask: subtasks[j],
            overallStatus: 'in_progress',
            message: 'Processing subtask ${j + 1}',
            timestamp: DateTime.now(),
          );

          executionState.onStatusUpdate(update);

          // Verify subtask was added
          expect(executionState.subtasks.length, equals(j + 1),
              reason: 'Each new subtask must be added to the list');
          
          // Verify the subtask is in the list
          expect(
            executionState.subtasks.any((s) => s.id == subtasks[j].id),
            isTrue,
            reason: 'The new subtask must be present in the subtasks list',
          );
        }

        // Verify final count
        expect(executionState.subtasks.length, equals(numSubtasks),
            reason: 'All subtasks must be added to the list');

        // Clean up
        executionState.dispose();
        mockWsService.reset();
        mockWindowService.reset();
      }
    });

    test('Property 19: Cancellation Cleanup', () async {
      // **Feature: rpa-frontend, Property 19: Cancellation Cleanup**
      // **Validates: Requirements 5.4**
      //
      // *For any* successful cancellation response from the backend, the WebSocket 
      // connection must be closed and the app must navigate to the Landing Screen.
      
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        final mockApiService = MockBackendApiService();
        final mockWsService = MockWebSocketService();
        final mockWindowService = MockWindowService();
        
        final executionState = ExecutionStateNotifier(
          apiService: mockApiService,
          wsService: mockWsService,
          windowService: mockWindowService,
        );

        // Set up session
        final sessionId = randomSessionId();
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: sessionId,
          status: 'pending',
          message: 'Task started',
        );

        await executionState.startExecution(randomInstruction());
        
        // Verify WebSocket is connected
        expect(executionState.isConnected, isTrue);
        expect(mockWsService.connectCalled, isTrue);

        // Optionally enter minimal mode (50% chance)
        final shouldEnterMinimalMode = random.nextBool();
        if (shouldEnterMinimalMode) {
          final minimalUpdate = StatusUpdate(
            sessionId: sessionId,
            overallStatus: 'in_progress',
            message: 'Starting RPA action',
            windowState: 'minimal',
            timestamp: DateTime.now(),
          );
          executionState.onStatusUpdate(minimalUpdate);
          expect(executionState.isMinimalMode, isTrue);
        }

        // Cancel execution
        await executionState.cancelExecution();
        
        // Verify cancellation request was sent
        expect(mockApiService.cancelSessionCalled, isTrue,
            reason: 'Cancellation request must be sent to backend');
        
        expect(mockApiService.cancelledSessionIds.contains(sessionId), isTrue,
            reason: 'Correct session ID must be sent for cancellation');

        // Verify WebSocket was disconnected
        expect(mockWsService.disconnectCalled, isTrue,
            reason: 'WebSocket must be disconnected on cancellation');
        
        expect(executionState.isConnected, isFalse,
            reason: 'isConnected must be false after cancellation');

        // Verify window was restored if in minimal mode
        if (shouldEnterMinimalMode) {
          expect(mockWindowService.exitMinimalModeCalled, isTrue,
              reason: 'Window must be restored if in minimal mode');
          
          expect(executionState.isMinimalMode, isFalse,
              reason: 'isMinimalMode must be false after cancellation');
        }

        // Verify status is cancelled
        expect(executionState.status, equals(SessionStatus.cancelled),
            reason: 'Status must be set to cancelled');

        // Clean up
        executionState.dispose();
        mockWsService.reset();
        mockWindowService.reset();
      }
    });

    test('Property 19: Cancellation cleanup with window restoration', () async {
      // Additional test focusing on window restoration during cancellation
      // This ensures that regardless of window state, cancellation always cleans up properly
      
      for (int i = 0; i < 100; i++) {
        final mockApiService = MockBackendApiService();
        final mockWsService = MockWebSocketService();
        final mockWindowService = MockWindowService();
        
        final executionState = ExecutionStateNotifier(
          apiService: mockApiService,
          wsService: mockWsService,
          windowService: mockWindowService,
        );

        final sessionId = randomSessionId();
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: sessionId,
          status: 'pending',
          message: 'Task started',
        );

        await executionState.startExecution(randomInstruction());
        
        // Always enter minimal mode for this test
        final minimalUpdate = StatusUpdate(
          sessionId: sessionId,
          overallStatus: 'in_progress',
          message: 'Starting RPA action',
          windowState: 'minimal',
          timestamp: DateTime.now(),
        );
        executionState.onStatusUpdate(minimalUpdate);
        
        final wasInMinimalMode = executionState.isMinimalMode;
        expect(wasInMinimalMode, isTrue);

        // Cancel execution
        await executionState.cancelExecution();
        
        // Verify cleanup happened
        expect(mockWsService.disconnectCalled, isTrue);
        expect(executionState.isConnected, isFalse);
        
        // Verify window was restored
        expect(mockWindowService.exitMinimalModeCalled, isTrue,
            reason: 'Window must always be restored on cancellation if in minimal mode');
        
        expect(executionState.isMinimalMode, isFalse,
            reason: 'Window must be in normal mode after cancellation');

        executionState.dispose();
        mockWsService.reset();
        mockWindowService.reset();
      }
    });

    test('Property 6: WebSocket connection with various instructions', () async {
      // Test that WebSocket connection is established regardless of instruction content
      
      for (int i = 0; i < 100; i++) {
        final mockApiService = MockBackendApiService();
        final mockWsService = MockWebSocketService();
        final mockWindowService = MockWindowService();
        
        final executionState = ExecutionStateNotifier(
          apiService: mockApiService,
          wsService: mockWsService,
          windowService: mockWindowService,
        );

        // Generate various types of instructions
        final instructions = [
          'Simple task',
          'Complex task with multiple steps and detailed requirements',
          'Task with special chars: @#\$%^&*()',
          'Task with numbers: 123 456 789',
          'Very short',
          'A' * 500, // Very long instruction
        ];
        
        final instruction = instructions[random.nextInt(instructions.length)];
        final sessionId = randomSessionId();

        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: sessionId,
          status: 'pending',
          message: 'Task started',
        );

        await executionState.startExecution(instruction);
        
        // Verify WebSocket connection regardless of instruction
        expect(mockWsService.connectCalled, isTrue,
            reason: 'WebSocket must connect for any valid instruction');
        
        expect(mockWsService.connectedSessionId, equals(sessionId),
            reason: 'Session ID must match for any instruction');
        
        expect(executionState.isConnected, isTrue,
            reason: 'Connection state must be tracked for any instruction');

        executionState.dispose();
        mockWsService.reset();
        mockWindowService.reset();
      }
    });

    test('Property 7: Subtask addition preserves order', () async {
      // Test that subtasks are added in the order they are received
      
      for (int i = 0; i < 100; i++) {
        final mockApiService = MockBackendApiService();
        final mockWsService = MockWebSocketService();
        final mockWindowService = MockWindowService();
        
        final executionState = ExecutionStateNotifier(
          apiService: mockApiService,
          wsService: mockWsService,
          windowService: mockWindowService,
        );

        final sessionId = randomSessionId();
        mockApiService.mockStartTaskResponse = TaskInstructionResponse(
          sessionId: sessionId,
          status: 'pending',
          message: 'Task started',
        );

        await executionState.startExecution(randomInstruction());
        
        // Generate ordered subtasks
        final numSubtasks = random.nextInt(10) + 1;
        final subtaskIds = List.generate(numSubtasks, (j) => 'subtask-$j');

        // Send updates in order
        for (int j = 0; j < numSubtasks; j++) {
          final subtask = Subtask(
            id: subtaskIds[j],
            description: 'Subtask ${j + 1}',
            status: SubtaskStatus.inProgress,
            timestamp: DateTime.now().add(Duration(milliseconds: j)),
          );

          final update = StatusUpdate(
            sessionId: sessionId,
            subtask: subtask,
            overallStatus: 'in_progress',
            message: 'Processing',
            timestamp: DateTime.now(),
          );

          executionState.onStatusUpdate(update);
        }

        // Verify order is preserved
        for (int j = 0; j < numSubtasks; j++) {
          expect(executionState.subtasks[j].id, equals(subtaskIds[j]),
              reason: 'Subtasks must be added in the order received');
        }

        executionState.dispose();
        mockWsService.reset();
        mockWindowService.reset();
      }
    });
  });
}
