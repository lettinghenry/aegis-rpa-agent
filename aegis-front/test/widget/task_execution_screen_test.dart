import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aegis_front/screens/task_execution_screen.dart';
import 'package:aegis_front/state/execution_state.dart';
import 'package:aegis_front/services/backend_api_service.dart';
import 'package:aegis_front/services/websocket_service.dart';
import 'package:aegis_front/services/window_service.dart';
import 'package:aegis_front/models/execution_session.dart';
import 'package:aegis_front/models/subtask.dart';
import 'package:aegis_front/models/status_update.dart';
import 'package:aegis_front/models/task_instruction.dart';

/// Mock BackendApiService for testing
class MockBackendApiService implements BackendApiService {
  bool shouldFailCancel = false;
  String sessionIdToReturn = 'test-session-123';

  @override
  Future<void> cancelSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (shouldFailCancel) {
      throw Exception('Failed to cancel session');
    }
  }

  @override
  Future<TaskInstructionResponse> startTask(String instruction) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return TaskInstructionResponse(
      sessionId: sessionIdToReturn,
      status: 'pending',
      message: 'Task started successfully',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock WebSocketService for testing
class MockWebSocketService implements WebSocketService {
  @override
  Future<void> connect(
    String sessionId, {
    required Function(StatusUpdate) onUpdate,
    Function(dynamic)? onError,
    Function()? onDone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<void> disconnect() async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock WindowService for testing
class MockWindowService implements WindowService {
  bool _isMinimalMode = false;

  @override
  Future<void> enterMinimalMode() async {
    _isMinimalMode = true;
  }

  @override
  Future<void> exitMinimalMode() async {
    _isMinimalMode = false;
  }

  @override
  bool get isMinimalMode => _isMinimalMode;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskExecutionScreen Widget Tests', () {
    late MockBackendApiService mockApiService;
    late MockWebSocketService mockWsService;
    late MockWindowService mockWindowService;
    late ExecutionStateNotifier executionState;

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

    /// Helper function to build the TaskExecutionScreen with Provider
    Widget buildTaskExecutionScreen() {
      return ChangeNotifierProvider<ExecutionStateNotifier>.value(
        value: executionState,
        child: MaterialApp(
          home: const TaskExecutionScreen(),
          routes: {
            '/landing': (context) => Scaffold(
                  appBar: AppBar(title: const Text('Landing Screen')),
                  body: const Center(child: Text('Landing Screen')),
                ),
          },
        ),
      );
    }

    /// Helper function to set up execution state with test data
    /// Simulates the execution flow by calling startExecution and sending status updates
    Future<void> setupExecutionState(
      WidgetTester tester, {
      String? sessionId,
      String? instruction,
      SessionStatus? status,
      List<Subtask>? subtasks,
      ConnectionStatus? connectionStatus,
      bool? isMinimalMode,
    }) async {
      // If we have an instruction, start execution (this sets sessionId and instruction)
      if (instruction != null) {
        try {
          await executionState.startExecution(instruction);
          await tester.pumpAndSettle(); // Wait for async operations
        } catch (e) {
          // Ignore errors from mock service
        }
      }
      
      // Now send status updates to simulate state changes
      if (status != null || subtasks != null || connectionStatus != null || isMinimalMode != null) {
        // Send status updates for each subtask
        if (subtasks != null) {
          for (final subtask in subtasks) {
            final update = StatusUpdate(
              sessionId: sessionId ?? executionState.sessionId ?? 'test-session',
              subtask: subtask,
              overallStatus: status?.toString().split('.').last ?? 'in_progress',
              message: 'Processing',
              windowState: isMinimalMode == true ? 'minimal' : (isMinimalMode == false ? 'normal' : null),
              timestamp: DateTime.now(),
            );
            executionState.onStatusUpdate(update);
            await tester.pump(); // Update UI after each status update
          }
        } else if (status != null) {
          // Send a status update without subtask
          final update = StatusUpdate(
            sessionId: sessionId ?? executionState.sessionId ?? 'test-session',
            subtask: null,
            overallStatus: status.toString().split('.').last,
            message: 'Status update',
            windowState: isMinimalMode == true ? 'minimal' : (isMinimalMode == false ? 'normal' : null),
            timestamp: DateTime.now(),
          );
          executionState.onStatusUpdate(update);
          await tester.pump(); // Update UI after status update
        }
      }
    }

    group('UI Elements Presence', () {
      testWidgets('displays app bar with session ID', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildTaskExecutionScreen());
        await setupExecutionState(
          tester,
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
        );

        // Act
        await tester.pump();

        // Assert
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Execution: test-session-123'), findsOneWidget);
      });

      testWidgets('displays cancel button during active execution',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.byTooltip('Cancel Execution'), findsOneWidget);
      });

      testWidgets('does not display cancel button when completed',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.completed,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.byIcon(Icons.cancel), findsNothing);
      });

      testWidgets('displays instruction card', (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Open Chrome and navigate to example.com',
          status: SessionStatus.inProgress,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Task Instruction'), findsOneWidget);
        expect(find.text('Open Chrome and navigate to example.com'), findsOneWidget);
      });

      testWidgets('displays overall status indicator',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('In Progress'), findsOneWidget);
        expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
      });

      testWidgets('displays connection status indicator',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
          connectionStatus: ConnectionStatus.connected,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      });

      testWidgets('displays empty state when no subtasks',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Waiting for subtasks...'), findsOneWidget);
        expect(find.byIcon(Icons.pending_actions), findsOneWidget);
      });

      testWidgets('displays Done button when completed successfully',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.completed,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Done'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('displays Back button when failed',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.failed,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Back'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });
    });

    group('Subtask Card Display', () {
      testWidgets('displays subtask cards in list', (WidgetTester tester) async {
        // Arrange
        final subtasks = [
          Subtask(
            id: '1',
            description: 'Opening Chrome',
            status: SubtaskStatus.completed,
            timestamp: DateTime.now(),
          ),
          Subtask(
            id: '2',
            description: 'Navigating to example.com',
            status: SubtaskStatus.inProgress,
            timestamp: DateTime.now(),
          ),
        ];

        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
          subtasks: subtasks,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Opening Chrome'), findsOneWidget);
        expect(find.text('Navigating to example.com'), findsOneWidget);
      });

      testWidgets('displays multiple subtask cards', (WidgetTester tester) async {
        // Arrange
        final subtasks = [
          Subtask(
            id: '1',
            description: 'Subtask 1',
            status: SubtaskStatus.completed,
            timestamp: DateTime.now(),
          ),
          Subtask(
            id: '2',
            description: 'Subtask 2',
            status: SubtaskStatus.completed,
            timestamp: DateTime.now(),
          ),
          Subtask(
            id: '3',
            description: 'Subtask 3',
            status: SubtaskStatus.inProgress,
            timestamp: DateTime.now(),
          ),
        ];

        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
          subtasks: subtasks,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Subtask 1'), findsOneWidget);
        expect(find.text('Subtask 2'), findsOneWidget);
        expect(find.text('Subtask 3'), findsOneWidget);
      });

      testWidgets('subtasks are displayed in chronological order',
          (WidgetTester tester) async {
        // Arrange
        final now = DateTime.now();
        final subtasks = [
          Subtask(
            id: '1',
            description: 'First subtask',
            status: SubtaskStatus.completed,
            timestamp: now.subtract(const Duration(minutes: 2)),
          ),
          Subtask(
            id: '2',
            description: 'Second subtask',
            status: SubtaskStatus.completed,
            timestamp: now.subtract(const Duration(minutes: 1)),
          ),
          Subtask(
            id: '3',
            description: 'Third subtask',
            status: SubtaskStatus.inProgress,
            timestamp: now,
          ),
        ];

        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
          subtasks: subtasks,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert - Find all subtask descriptions
        final firstSubtask = find.text('First subtask');
        final secondSubtask = find.text('Second subtask');
        final thirdSubtask = find.text('Third subtask');

        expect(firstSubtask, findsOneWidget);
        expect(secondSubtask, findsOneWidget);
        expect(thirdSubtask, findsOneWidget);

        // Verify order by checking y-coordinates
        final firstY = tester.getTopLeft(firstSubtask).dy;
        final secondY = tester.getTopLeft(secondSubtask).dy;
        final thirdY = tester.getTopLeft(thirdSubtask).dy;

        expect(firstY < secondY, isTrue);
        expect(secondY < thirdY, isTrue);
      });
    });

    group('Status Indicators', () {
      testWidgets('displays pending status correctly',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.pending,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Pending'), findsOneWidget);
        expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      });

      testWidgets('displays in-progress status correctly',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('In Progress'), findsOneWidget);
        expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
      });

      testWidgets('displays completed status correctly',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.completed,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Completed'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('displays failed status correctly',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.failed,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Failed'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('displays cancelled status correctly',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.cancelled,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Cancelled'), findsOneWidget);
        expect(find.byIcon(Icons.cancel), findsAtLeastNWidgets(1));
      });

      testWidgets('displays completed subtask with checkmark',
          (WidgetTester tester) async {
        // Arrange
        final subtasks = [
          Subtask(
            id: '1',
            description: 'Completed task',
            status: SubtaskStatus.completed,
            timestamp: DateTime.now(),
          ),
        ];

        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
          subtasks: subtasks,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(1));
      });

      testWidgets('displays in-progress subtask with spinner',
          (WidgetTester tester) async {
        // Arrange
        final subtasks = [
          Subtask(
            id: '1',
            description: 'In progress task',
            status: SubtaskStatus.inProgress,
            timestamp: DateTime.now(),
          ),
        ];

        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
          subtasks: subtasks,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      });

      testWidgets('displays failed subtask with error icon',
          (WidgetTester tester) async {
        // Arrange
        final subtasks = [
          Subtask(
            id: '1',
            description: 'Failed task',
            status: SubtaskStatus.failed,
            error: 'Element not found',
            timestamp: DateTime.now(),
          ),
        ];

        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
          subtasks: subtasks,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.byIcon(Icons.error), findsAtLeastNWidgets(1));
        expect(find.text('Element not found'), findsOneWidget);
      });

      testWidgets('displays connection status - connected',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
          connectionStatus: ConnectionStatus.connected,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      });

      testWidgets('displays connection status - disconnected',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
          connectionStatus: ConnectionStatus.disconnected,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      });

      testWidgets('displays connection status - reconnecting',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
          connectionStatus: ConnectionStatus.reconnecting,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.byIcon(Icons.cloud_sync), findsOneWidget);
      });
    });

    group('Cancel Button and Dialog', () {
      testWidgets('tapping cancel button shows confirmation dialog',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
        );

        await tester.pumpWidget(buildTaskExecutionScreen());

        // Act - Tap cancel button
        await tester.tap(find.byIcon(Icons.cancel));
        await tester.pumpAndSettle();

        // Assert - Dialog should be displayed
        expect(find.text('Cancel Execution'), findsOneWidget);
        expect(
          find.text(
            'Are you sure you want to cancel this execution? '
            'This action cannot be undone.',
          ),
          findsOneWidget,
        );
        expect(find.text('No'), findsOneWidget);
        expect(find.text('Yes, Cancel'), findsOneWidget);
      });

      testWidgets('tapping No in dialog dismisses it without cancelling',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
        );

        await tester.pumpWidget(buildTaskExecutionScreen());

        // Act - Tap cancel button and then No
        await tester.tap(find.byIcon(Icons.cancel));
        await tester.pumpAndSettle();
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        // Assert - Dialog should be dismissed, still on execution screen
        expect(find.text('Cancel Execution'), findsNothing);
        expect(find.text('Execution: test-session-123'), findsOneWidget);
        expect(executionState.status, SessionStatus.inProgress);
      });

      testWidgets('tapping Yes in dialog cancels execution',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
        );

        await tester.pumpWidget(buildTaskExecutionScreen());

        // Act - Tap cancel button and then Yes
        await tester.tap(find.byIcon(Icons.cancel));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes, Cancel'));
        await tester.pumpAndSettle();

        // Assert - Should navigate away
        expect(find.text('Landing Screen'), findsOneWidget);
      });

      testWidgets('cancel button is not shown when execution is complete',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.completed,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.byIcon(Icons.cancel), findsNothing);
      });

      testWidgets('cancel button is not shown when execution failed',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.failed,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.byIcon(Icons.cancel), findsNothing);
      });
    });

    group('Completion UI', () {
      testWidgets('displays Done button when execution completes successfully',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.completed,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Done'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Done'), findsOneWidget);
      });

      testWidgets('displays Back button when execution fails',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.failed,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Back'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Back'), findsOneWidget);
      });

      testWidgets('displays Back button when execution is cancelled',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.cancelled,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Back'), findsOneWidget);
      });

      testWidgets('tapping Done button navigates back',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.completed,
        );

        await tester.pumpWidget(buildTaskExecutionScreen());

        // Act - Tap Done button
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // Assert - Should navigate back (screen should be popped)
        // Since we're in a test environment, we can't verify navigation directly,
        // but we can verify the button is tappable
        expect(find.text('Done'), findsNothing);
      });

      testWidgets('tapping Back button navigates back',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.failed,
        );

        await tester.pumpWidget(buildTaskExecutionScreen());

        // Act - Tap Back button
        await tester.tap(find.text('Back'));
        await tester.pumpAndSettle();

        // Assert - Should navigate back
        expect(find.text('Back'), findsNothing);
      });

      testWidgets('does not display completion button during execution',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Done'), findsNothing);
        expect(find.text('Back'), findsNothing);
      });

      testWidgets('displays success status with completed button',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.completed,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('displays failed status with back button',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.failed,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Failed'), findsOneWidget);
        expect(find.text('Back'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });
    });

    group('Minimal Mode UI', () {
      testWidgets('displays minimal mode UI when isMinimalMode is true',
          (WidgetTester tester) async {
        // Arrange
        final subtasks = [
          Subtask(
            id: '1',
            description: 'Clicking Submit button',
            status: SubtaskStatus.inProgress,
            timestamp: DateTime.now(),
          ),
        ];

        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
          subtasks: subtasks,
          isMinimalMode: true,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert - Should show minimal UI
        expect(find.text('Clicking Submit button'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        // Should not show full UI elements
        expect(find.text('Task Instruction'), findsNothing);
      });

      testWidgets('displays normal mode UI when isMinimalMode is false',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
          isMinimalMode: false,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert - Should show normal UI
        expect(find.text('Task Instruction'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('minimal mode shows current subtask description',
          (WidgetTester tester) async {
        // Arrange
        final subtasks = [
          Subtask(
            id: '1',
            description: 'Opening Chrome browser',
            status: SubtaskStatus.inProgress,
            timestamp: DateTime.now(),
          ),
        ];

        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
          subtasks: subtasks,
          isMinimalMode: true,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.text('Opening Chrome browser'), findsOneWidget);
      });

      testWidgets('minimal mode shows progress indicator',
          (WidgetTester tester) async {
        // Arrange
        setupExecutionState(
          sessionId: 'test-session-123',
          instruction: 'Test instruction',
          status: SessionStatus.inProgress,
          isMinimalMode: true,
        );

        // Act
        await tester.pumpWidget(buildTaskExecutionScreen());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    });
  });
}
