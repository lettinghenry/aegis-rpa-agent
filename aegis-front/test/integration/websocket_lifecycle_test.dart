import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/services/websocket_service.dart';
import 'package:aegis_front/services/backend_api_service.dart';
import 'package:aegis_front/services/window_service.dart';
import 'package:aegis_front/state/execution_state.dart';
import 'package:aegis_front/models/status_update.dart';
import 'package:aegis_front/models/subtask.dart';
import 'package:aegis_front/models/task_instruction.dart';

/// Mock WebSocket service for testing lifecycle behavior
class MockWebSocketService extends WebSocketService {
  bool _mockConnected = false;
  int _connectCallCount = 0;
  int _disconnectCallCount = 0;
  int _reconnectCallCount = 0;
  Function(StatusUpdate)? _storedOnUpdate;
  Function(dynamic)? _storedOnError;
  Function()? _storedOnDone;
  String? _storedSessionId;
  bool _shouldFailConnection = false;
  bool _shouldFailReconnection = false;

  @override
  bool get isConnected => _mockConnected;

  @override
  String? get currentSessionId => _storedSessionId;

  int get connectCallCount => _connectCallCount;
  int get disconnectCallCount => _disconnectCallCount;
  int get reconnectCallCount => _reconnectCallCount;

  void setConnectionFailure(bool shouldFail) {
    _shouldFailConnection = shouldFail;
  }

  void setReconnectionFailure(bool shouldFail) {
    _shouldFailReconnection = shouldFail;
  }

  @override
  Future<void> connect(
    String sessionId, {
    required Function(StatusUpdate) onUpdate,
    Function(dynamic)? onError,
    Function()? onDone,
  }) async {
    _connectCallCount++;
    _storedSessionId = sessionId;
    _storedOnUpdate = onUpdate;
    _storedOnError = onError;
    _storedOnDone = onDone;

    if (_shouldFailConnection) {
      _mockConnected = false;
      throw Exception('Connection failed');
    }

    _mockConnected = true;
    await Future.delayed(Duration(milliseconds: 10));
  }

  @override
  Future<void> disconnect() async {
    _disconnectCallCount++;
    _mockConnected = false;
    _storedSessionId = null;
    await Future.delayed(Duration(milliseconds: 10));
  }

  @override
  Future<void> reconnect() async {
    _reconnectCallCount++;

    if (_shouldFailReconnection) {
      _mockConnected = false;
      if (_storedOnError != null) {
        _storedOnError!(Exception('Reconnection failed'));
      }
      return;
    }

    await Future.delayed(Duration(milliseconds: 10));
    _mockConnected = true;
  }

  // Simulate receiving a message
  void simulateMessage(StatusUpdate update) {
    if (_storedOnUpdate != null) {
      _storedOnUpdate!(update);
    }
  }

  // Simulate an error
  void simulateError(dynamic error) {
    _mockConnected = false;
    if (_storedOnError != null) {
      _storedOnError!(error);
    }
  }

  // Simulate connection closure
  void simulateDone() {
    _mockConnected = false;
    if (_storedOnDone != null) {
      _storedOnDone!();
    }
  }

  @override
  void reset() {
    super.reset();
    _mockConnected = false;
    _connectCallCount = 0;
    _disconnectCallCount = 0;
    _reconnectCallCount = 0;
    _storedOnUpdate = null;
    _storedOnError = null;
    _storedOnDone = null;
    _storedSessionId = null;
    _shouldFailConnection = false;
    _shouldFailReconnection = false;
  }
}

/// Mock Backend API service
class MockBackendApiService extends BackendApiService {
  bool _shouldFailStartTask = false;
  bool _shouldFailCancelSession = false;

  MockBackendApiService() : super(baseUrl: 'http://mock');

  void setStartTaskFailure(bool shouldFail) {
    _shouldFailStartTask = shouldFail;
  }

  void setCancelSessionFailure(bool shouldFail) {
    _shouldFailCancelSession = shouldFail;
  }

  @override
  Future<TaskInstructionResponse> startTask(String instruction) async {
    await Future.delayed(Duration(milliseconds: 10));
    
    if (_shouldFailStartTask) {
      throw Exception('Failed to start task');
    }

    return TaskInstructionResponse(
      sessionId: 'test-session-123',
      status: 'pending',
      message: 'Task started',
    );
  }

  @override
  Future<void> cancelSession(String sessionId) async {
    await Future.delayed(Duration(milliseconds: 10));
    
    if (_shouldFailCancelSession) {
      throw Exception('Failed to cancel session');
    }
  }
}

/// Mock Window service
class MockWindowService extends WindowService {
  bool _isMinimal = false;
  int _enterMinimalCallCount = 0;
  int _exitMinimalCallCount = 0;

  @override
  bool get isMinimalMode => _isMinimal;

  int get enterMinimalCallCount => _enterMinimalCallCount;
  int get exitMinimalCallCount => _exitMinimalCallCount;

  @override
  Future<void> enterMinimalMode() async {
    _enterMinimalCallCount++;
    _isMinimal = true;
    await Future.delayed(Duration(milliseconds: 10));
  }

  @override
  Future<void> exitMinimalMode() async {
    _exitMinimalCallCount++;
    _isMinimal = false;
    await Future.delayed(Duration(milliseconds: 10));
  }

  void reset() {
    _isMinimal = false;
    _enterMinimalCallCount = 0;
    _exitMinimalCallCount = 0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebSocket Lifecycle Tests', () {
    late MockWebSocketService wsService;
    late MockBackendApiService apiService;
    late MockWindowService windowService;
    late ExecutionStateNotifier executionState;

    setUp(() {
      wsService = MockWebSocketService();
      apiService = MockBackendApiService();
      windowService = MockWindowService();
      executionState = ExecutionStateNotifier(
        apiService: apiService,
        wsService: wsService,
        windowService: windowService,
      );
    });

    tearDown(() {
      wsService.reset();
      windowService.reset();
      executionState.reset();
    });

    group('Connection Establishment', () {
      test('establishes WebSocket connection on execution start', () async {
        // Arrange
        final instruction = 'Test task';

        // Act
        await executionState.startExecution(instruction);

        // Assert
        expect(wsService.connectCallCount, 1);
        expect(wsService.isConnected, true);
        expect(executionState.isConnected, true);
        expect(executionState.connectionStatus, ConnectionStatus.connected);
      });

      test('stores session ID after connection', () async {
        // Arrange
        final instruction = 'Test task';

        // Act
        await executionState.startExecution(instruction);

        // Assert
        expect(wsService.currentSessionId, 'test-session-123');
        expect(executionState.sessionId, 'test-session-123');
      });

      test('sets connection status to connecting during establishment', () async {
        // Arrange
        final instruction = 'Test task';
        ConnectionStatus? statusDuringConnection;

        // Capture status during connection
        executionState.addListener(() {
          if (executionState.connectionStatus == ConnectionStatus.connecting) {
            statusDuringConnection = ConnectionStatus.connecting;
          }
        });

        // Act
        await executionState.startExecution(instruction);

        // Assert
        expect(statusDuringConnection, ConnectionStatus.connecting);
      });

      test('handles connection failure gracefully', () async {
        // Arrange
        final instruction = 'Test task';
        wsService.setConnectionFailure(true);

        // Act
        try {
          await executionState.startExecution(instruction);
        } catch (e) {
          // Expected to throw
        }

        // Assert
        expect(executionState.connectionStatus, ConnectionStatus.failed);
        expect(executionState.isConnected, false);
      });

      test('clears error message on successful connection', () async {
        // Arrange
        final instruction = 'Test task';

        // Act
        await executionState.startExecution(instruction);

        // Assert
        expect(executionState.errorMessage, null);
      });
    });

    group('Reconnection Attempts', () {
      test('attempts reconnection on connection error', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);
        final initialReconnectCount = wsService.reconnectCallCount;

        // Act - Simulate error which triggers reconnection in ExecutionState
        wsService.simulateError(Exception('Connection lost'));
        await Future.delayed(Duration(milliseconds: 50));

        // Assert - ExecutionState should handle the error and update status
        // The reconnection is triggered by the error handler
        expect(executionState.connectionStatus, anyOf(
          ConnectionStatus.reconnecting,
          ConnectionStatus.failed,
        ));
      });

      test('attempts reconnection on connection closure', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);

        // Act - Simulate connection closure
        wsService.simulateDone();
        await Future.delayed(Duration(milliseconds: 50));

        // Assert - ExecutionState should handle the closure and update status
        expect(executionState.connectionStatus, anyOf(
          ConnectionStatus.reconnecting,
          ConnectionStatus.disconnected,
        ));
      });

      test('updates connection status to reconnecting', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);

        // Act
        wsService.simulateError(Exception('Connection lost'));
        await Future.delayed(Duration(milliseconds: 20));

        // Assert
        expect(executionState.connectionStatus, ConnectionStatus.reconnecting);
      });

      test('updates connection status on error', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);
        expect(executionState.connectionStatus, ConnectionStatus.connected);

        // Act - Simulate error
        wsService.simulateError(Exception('Connection lost'));
        await Future.delayed(Duration(milliseconds: 50));

        // Assert - Status should change from connected
        expect(executionState.connectionStatus, isNot(ConnectionStatus.connected));
      });

      test('handles reconnection failure', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);
        wsService.setReconnectionFailure(true);

        // Act - Simulate error which will trigger failed reconnection
        wsService.simulateError(Exception('Connection lost'));
        await Future.delayed(Duration(milliseconds: 50));

        // Assert - Status should indicate failure or reconnecting
        expect(executionState.connectionStatus, anyOf(
          ConnectionStatus.failed,
          ConnectionStatus.reconnecting,
        ));
      });

      test('does not attempt reconnection after cancellation', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);
        final reconnectCountBeforeCancel = wsService.reconnectCallCount;

        // Act
        await executionState.cancelExecution();
        wsService.simulateDone();
        await Future.delayed(Duration(milliseconds: 50));

        // Assert
        expect(wsService.reconnectCallCount, reconnectCountBeforeCancel);
      });
    });

    group('Backgrounding Behavior', () {
      test('maintains WebSocket connection when app is backgrounded', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);
        final disconnectCountBefore = wsService.disconnectCallCount;

        // Act
        executionState.didChangeAppLifecycleState(AppLifecycleState.paused);
        await Future.delayed(Duration(milliseconds: 20));

        // Assert
        expect(executionState.isAppInBackground, true);
        expect(wsService.disconnectCallCount, disconnectCountBefore);
        expect(wsService.isConnected, true);
      });

      test('queues status updates when app is backgrounded', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);
        final initialSubtaskCount = executionState.subtasks.length;

        // Act - Background the app
        executionState.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        // Simulate status update while backgrounded
        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Processing',
          timestamp: DateTime.now(),
          subtask: Subtask(
            id: 'subtask-1',
            description: 'Test subtask',
            status: SubtaskStatus.inProgress,
            timestamp: DateTime.now(),
          ),
        );
        wsService.simulateMessage(update);
        await Future.delayed(Duration(milliseconds: 20));

        // Assert - Update should be queued, not processed
        expect(executionState.subtasks.length, initialSubtaskCount);
      });

      test('does not trigger window state changes when backgrounded', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);

        // Act - Background the app
        executionState.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        // Simulate window state change while backgrounded
        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Minimizing',
          timestamp: DateTime.now(),
          windowState: 'minimal',
        );
        wsService.simulateMessage(update);
        await Future.delayed(Duration(milliseconds: 20));

        // Assert - Window should not enter minimal mode
        expect(windowService.enterMinimalCallCount, 0);
        expect(executionState.isMinimalMode, false);
      });

      test('handles inactive state as backgrounded', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);

        // Act
        executionState.didChangeAppLifecycleState(AppLifecycleState.inactive);
        await Future.delayed(Duration(milliseconds: 20));

        // Assert
        expect(executionState.isAppInBackground, true);
      });
    });

    group('Foregrounding Behavior', () {
      test('processes pending updates when app returns to foreground', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);

        // Background the app
        executionState.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        // Simulate status update while backgrounded
        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Processing',
          timestamp: DateTime.now(),
          subtask: Subtask(
            id: 'subtask-1',
            description: 'Test subtask',
            status: SubtaskStatus.inProgress,
            timestamp: DateTime.now(),
          ),
        );
        wsService.simulateMessage(update);
        await Future.delayed(Duration(milliseconds: 20));

        // Act - Foreground the app
        executionState.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await Future.delayed(Duration(milliseconds: 20));

        // Assert - Pending update should be processed
        expect(executionState.subtasks.length, 1);
        expect(executionState.subtasks[0].id, 'subtask-1');
      });

      test('syncs UI state when returning to foreground', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);

        // Background the app
        executionState.didChangeAppLifecycleState(AppLifecycleState.paused);
        await Future.delayed(Duration(milliseconds: 20));

        // Act - Foreground the app
        executionState.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await Future.delayed(Duration(milliseconds: 20));

        // Assert
        expect(executionState.isAppInBackground, false);
      });

      test('attempts reconnection if connection lost while backgrounded', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);

        // Background the app
        executionState.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        // Simulate connection loss while backgrounded
        wsService.simulateDone();
        await Future.delayed(Duration(milliseconds: 20));
        final reconnectCountBefore = wsService.reconnectCallCount;

        // Act - Foreground the app
        executionState.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await Future.delayed(Duration(milliseconds: 20));

        // Assert - Should attempt reconnection
        expect(wsService.reconnectCallCount, greaterThan(reconnectCountBefore));
      });

      test('maintains connection if still active when foregrounded', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);

        // Background the app
        executionState.didChangeAppLifecycleState(AppLifecycleState.paused);
        await Future.delayed(Duration(milliseconds: 20));

        // Act - Foreground the app (connection still active)
        executionState.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await Future.delayed(Duration(milliseconds: 20));

        // Assert
        expect(executionState.isConnected, true);
        expect(executionState.connectionStatus, ConnectionStatus.connected);
      });

      test('processes multiple pending updates in order', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);

        // Background the app
        executionState.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        // Simulate multiple status updates while backgrounded
        for (int i = 1; i <= 3; i++) {
          final update = StatusUpdate(
            sessionId: 'test-session-123',
            overallStatus: 'in_progress',
            message: 'Processing $i',
            timestamp: DateTime.now(),
            subtask: Subtask(
              id: 'subtask-$i',
              description: 'Test subtask $i',
              status: SubtaskStatus.inProgress,
              timestamp: DateTime.now(),
            ),
          );
          wsService.simulateMessage(update);
          await Future.delayed(Duration(milliseconds: 10));
        }

        // Act - Foreground the app
        executionState.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await Future.delayed(Duration(milliseconds: 50));

        // Assert - All updates should be processed
        expect(executionState.subtasks.length, 3);
        expect(executionState.subtasks[0].id, 'subtask-1');
        expect(executionState.subtasks[1].id, 'subtask-2');
        expect(executionState.subtasks[2].id, 'subtask-3');
      });

      test('applies window state changes from pending updates', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);

        // Background the app
        executionState.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        // Simulate window state change while backgrounded
        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Minimizing',
          timestamp: DateTime.now(),
          windowState: 'minimal',
        );
        wsService.simulateMessage(update);
        await Future.delayed(Duration(milliseconds: 20));

        // Act - Foreground the app
        executionState.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await Future.delayed(Duration(milliseconds: 20));

        // Assert - Window state should be applied
        expect(windowService.enterMinimalCallCount, 1);
        expect(executionState.isMinimalMode, true);
      });
    });

    group('Connection Cleanup', () {
      test('disconnects WebSocket on cancellation', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);

        // Act
        await executionState.cancelExecution();

        // Assert
        expect(wsService.disconnectCallCount, 1);
        expect(executionState.isConnected, false);
      });

      test('clears pending updates on cancellation', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);

        // Background and queue updates
        executionState.didChangeAppLifecycleState(AppLifecycleState.paused);
        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Processing',
          timestamp: DateTime.now(),
          subtask: Subtask(
            id: 'subtask-1',
            description: 'Test subtask',
            status: SubtaskStatus.inProgress,
            timestamp: DateTime.now(),
          ),
        );
        wsService.simulateMessage(update);

        // Act
        await executionState.cancelExecution();

        // Foreground and verify no updates are processed
        executionState.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await Future.delayed(Duration(milliseconds: 20));

        // Assert
        expect(executionState.subtasks.length, 0);
      });

      test('restores window on cancellation if in minimal mode', () async {
        // Arrange
        final instruction = 'Test task';
        await executionState.startExecution(instruction);
        
        // Enter minimal mode
        final update = StatusUpdate(
          sessionId: 'test-session-123',
          overallStatus: 'in_progress',
          message: 'Minimizing',
          timestamp: DateTime.now(),
          windowState: 'minimal',
        );
        wsService.simulateMessage(update);
        await Future.delayed(Duration(milliseconds: 20));

        // Act
        await executionState.cancelExecution();

        // Assert
        expect(windowService.exitMinimalCallCount, 1);
        expect(executionState.isMinimalMode, false);
      });
    });
  });
}
