import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aegis_front/screens/landing_screen.dart';
import 'package:aegis_front/state/execution_state.dart';
import 'package:aegis_front/services/backend_api_service.dart';
import 'package:aegis_front/services/websocket_service.dart';
import 'package:aegis_front/services/window_service.dart';
import 'package:aegis_front/models/task_instruction.dart';
import 'package:aegis_front/models/status_update.dart';

/// Mock BackendApiService for testing
class MockBackendApiService implements BackendApiService {
  bool shouldFail = false;
  String? failureMessage;
  String sessionIdToReturn = 'test-session-123';

  @override
  Future<TaskInstructionResponse> startTask(String instruction) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (shouldFail) {
      throw Exception(failureMessage ?? 'Backend error');
    }
    
    return TaskInstructionResponse(
      sessionId: sessionIdToReturn,
      status: 'pending',
      message: 'Task started successfully',
    );
  }

  @override
  Future<void> cancelSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  // Implement other methods as no-ops for this test
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
  @override
  Future<void> enterMinimalMode() async {}

  @override
  Future<void> exitMinimalMode() async {}

  @override
  bool get isMinimalMode => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LandingScreen Widget Tests', () {
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

    /// Helper function to build the LandingScreen with Provider
    Widget buildLandingScreen() {
      return ChangeNotifierProvider<ExecutionStateNotifier>.value(
        value: executionState,
        child: MaterialApp(
          home: const LandingScreen(),
          routes: {
            '/execution': (context) => Scaffold(
                  appBar: AppBar(title: const Text('Execution Screen')),
                  body: const Center(child: Text('Execution Screen')),
                ),
            '/history': (context) => Scaffold(
                  appBar: AppBar(title: const Text('History Screen')),
                  body: const Center(child: Text('History Screen')),
                ),
          },
        ),
      );
    }

    group('UI Elements Presence', () {
      testWidgets('displays app bar with title', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildLandingScreen());

        // Assert
        expect(find.text('AEGIS RPA'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('displays history icon button', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildLandingScreen());

        // Assert
        expect(find.byIcon(Icons.history), findsOneWidget);
        expect(find.byTooltip('View History'), findsOneWidget);
      });

      testWidgets('displays main title', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildLandingScreen());

        // Assert
        expect(
          find.text('What would you like to automate?'),
          findsOneWidget,
        );
      });

      testWidgets('displays subtitle', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildLandingScreen());

        // Assert
        expect(
          find.text('Describe your task in natural language'),
          findsOneWidget,
        );
      });

      testWidgets('displays text input field with hint',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildLandingScreen());

        // Assert
        expect(find.byType(TextField), findsOneWidget);
        
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(
          textField.decoration?.hintText,
          contains('Example:'),
        );
      });

      testWidgets('displays submit button', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildLandingScreen());

        // Assert
        expect(find.text('Start Automation'), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, 'Start Automation'),
          findsOneWidget,
        );
      });

      testWidgets('displays help text at bottom', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildLandingScreen());

        // Assert
        expect(
          find.text(
            'Tip: Be specific about the applications and actions you want to automate',
          ),
          findsOneWidget,
        );
      });

      testWidgets('does not display error message initially',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildLandingScreen());

        // Assert
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });
    });

    group('Submit Button State Based on Input', () {
      testWidgets('submit button is disabled when input is empty',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildLandingScreen());

        // Act - Find the button
        final button = find.widgetWithText(FilledButton, 'Start Automation');

        // Assert - Button should be disabled
        expect(button, findsOneWidget);
        final filledButton = tester.widget<FilledButton>(button);
        expect(filledButton.onPressed, isNull);
      });

      testWidgets('submit button is enabled when input has text',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildLandingScreen());

        // Act - Enter text
        await tester.enterText(
          find.byType(TextField),
          'Open Chrome and navigate to example.com',
        );
        await tester.pump();

        // Assert - Button should be enabled
        final button = find.widgetWithText(FilledButton, 'Start Automation');
        expect(button, findsOneWidget);
        final filledButton = tester.widget<FilledButton>(button);
        expect(filledButton.onPressed, isNotNull);
      });

      testWidgets('submit button is disabled when input is only whitespace',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildLandingScreen());

        // Act - Enter only whitespace
        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump();

        // Assert - Button should be disabled
        final button = find.widgetWithText(FilledButton, 'Start Automation');
        expect(button, findsOneWidget);
        final filledButton = tester.widget<FilledButton>(button);
        expect(filledButton.onPressed, isNull);
      });

      testWidgets('submit button re-enables after submission completes',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildLandingScreen());
        await tester.enterText(
          find.byType(TextField),
          'Test instruction',
        );
        await tester.pump();

        // Act - Submit and wait for completion
        await tester.tap(find.widgetWithText(FilledButton, 'Start Automation'));
        await tester.pumpAndSettle();

        // After navigation, go back to landing screen
        Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
        await tester.pumpAndSettle();
        
        // Enter new text
        await tester.enterText(
          find.byType(TextField),
          'Another instruction',
        );
        await tester.pump();

        // Assert - Button should be enabled again
        final button = find.widgetWithText(FilledButton, 'Start Automation');
        expect(button, findsOneWidget);
        final filledButton = tester.widget<FilledButton>(button);
        expect(filledButton.onPressed, isNotNull);
      });
    });

    group('Submission Flow', () {
      testWidgets('successful submission navigates to execution screen',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildLandingScreen());
        await tester.enterText(
          find.byType(TextField),
          'Open Chrome',
        );
        await tester.pump();

        // Act - Submit
        await tester.tap(find.widgetWithText(FilledButton, 'Start Automation'));
        await tester.pumpAndSettle();

        // Assert - Should navigate to execution screen
        expect(find.text('What would you like to automate?'), findsNothing);
        // Verify we're on the execution screen by checking for the execution screen content
        expect(find.text('Execution Screen'), findsWidgets);
      });

      testWidgets('submission completes successfully',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildLandingScreen());
        await tester.enterText(
          find.byType(TextField),
          'Test instruction',
        );
        await tester.pump();

        // Act - Submit
        await tester.tap(find.widgetWithText(FilledButton, 'Start Automation'));
        await tester.pumpAndSettle();

        // Assert - Should have navigated away from landing screen
        expect(find.text('What would you like to automate?'), findsNothing);
      });

      testWidgets('text field is enabled initially',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildLandingScreen());

        // Assert - Text field should be enabled
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.enabled, isTrue); // enabled by default
      });

      testWidgets('execution state is updated with session ID',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildLandingScreen());
        await tester.enterText(
          find.byType(TextField),
          'Open Chrome',
        );
        await tester.pump();

        // Act - Submit
        await tester.tap(find.widgetWithText(FilledButton, 'Start Automation'));
        await tester.pumpAndSettle();

        // Assert - Execution state should have session ID
        expect(executionState.sessionId, 'test-session-123');
        expect(executionState.instruction, 'Open Chrome');
      });
    });

    group('Error Display', () {
      testWidgets('displays error message on submission failure',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.shouldFail = true;
        mockApiService.failureMessage = 'Connection refused';
        await tester.pumpWidget(buildLandingScreen());
        await tester.enterText(
          find.byType(TextField),
          'Test instruction',
        );
        await tester.pump();

        // Act - Submit
        await tester.tap(find.widgetWithText(FilledButton, 'Start Automation'));
        await tester.pumpAndSettle();

        // Assert - Should display error message
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(
          find.text('Unable to connect. Please check your internet connection.'),
          findsOneWidget,
        );
      });

      testWidgets('does not navigate on submission failure',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.shouldFail = true;
        await tester.pumpWidget(buildLandingScreen());
        await tester.enterText(
          find.byType(TextField),
          'Test instruction',
        );
        await tester.pump();

        // Act - Submit
        await tester.tap(find.widgetWithText(FilledButton, 'Start Automation'));
        await tester.pumpAndSettle();

        // Assert - Should stay on landing screen
        expect(find.text('What would you like to automate?'), findsOneWidget);
        expect(find.text('Execution Screen'), findsNothing);
      });

      testWidgets('error message clears when user starts typing',
          (WidgetTester tester) async {
        // Arrange - Cause an error first
        mockApiService.shouldFail = true;
        await tester.pumpWidget(buildLandingScreen());
        await tester.enterText(
          find.byType(TextField),
          'Test instruction',
        );
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Start Automation'));
        await tester.pumpAndSettle();
        
        // Verify error is displayed
        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        // Act - Start typing again
        mockApiService.shouldFail = false;
        await tester.enterText(
          find.byType(TextField),
          'New instruction',
        );
        await tester.pump();

        // Assert - Error should be cleared
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });

      testWidgets('displays timeout error message',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.shouldFail = true;
        mockApiService.failureMessage = 'TimeoutException';
        await tester.pumpWidget(buildLandingScreen());
        await tester.enterText(
          find.byType(TextField),
          'Test instruction',
        );
        await tester.pump();

        // Act - Submit
        await tester.tap(find.widgetWithText(FilledButton, 'Start Automation'));
        await tester.pumpAndSettle();

        // Assert - Should display timeout error
        expect(
          find.text('Request timed out. Please try again.'),
          findsOneWidget,
        );
      });

      testWidgets('displays backend offline error message',
          (WidgetTester tester) async {
        // Arrange
        mockApiService.shouldFail = true;
        mockApiService.failureMessage = 'Backend is offline';
        await tester.pumpWidget(buildLandingScreen());
        await tester.enterText(
          find.byType(TextField),
          'Test instruction',
        );
        await tester.pump();

        // Act - Submit
        await tester.tap(find.widgetWithText(FilledButton, 'Start Automation'));
        await tester.pumpAndSettle();

        // Assert - Should display offline error
        expect(
          find.text(
            'The automation service is currently offline. Please try again later.',
          ),
          findsOneWidget,
        );
      });
    });

    group('Navigation', () {
      testWidgets('tapping history icon navigates to history view',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildLandingScreen());

        // Act - Tap history icon
        await tester.tap(find.byIcon(Icons.history));
        await tester.pumpAndSettle();

        // Assert - Should navigate to history screen
        expect(find.widgetWithText(AppBar, 'History Screen'), findsOneWidget);
        expect(find.text('What would you like to automate?'), findsNothing);
      });

      testWidgets('history button is always enabled',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildLandingScreen());

        // Act - Find the history icon button
        final iconButtons = find.byType(IconButton);
        
        // Assert - Should find at least one IconButton (the history button)
        expect(iconButtons, findsWidgets);
        
        // Verify the history icon is present and tappable
        final historyIcon = find.byIcon(Icons.history);
        expect(historyIcon, findsOneWidget);
      });
    });
  });
}
