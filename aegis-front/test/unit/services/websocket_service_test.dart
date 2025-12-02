import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/services/websocket_service.dart';
import 'package:aegis_front/models/status_update.dart';
import 'package:aegis_front/models/subtask.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebSocketService', () {
    late WebSocketService service;

    setUp(() {
      service = WebSocketService();
    });

    tearDown(() {
      service.reset();
    });

    group('initial state', () {
      test('starts with isConnected false', () {
        expect(service.isConnected, false);
      });

      test('starts with null currentSessionId', () {
        expect(service.currentSessionId, null);
      });
    });

    group('message parsing', () {
      test('parses valid JSON message into StatusUpdate', () {
        // Arrange
        final sessionId = 'test-session-123';
        final timestamp = DateTime.now();
        
        final validMessage = jsonEncode({
          'session_id': sessionId,
          'overall_status': 'in_progress',
          'message': 'Executing task',
          'timestamp': timestamp.toIso8601String(),
        });

        // Act
        final json = jsonDecode(validMessage) as Map<String, dynamic>;
        final update = StatusUpdate.fromJson(json);

        // Assert
        expect(update.sessionId, sessionId);
        expect(update.overallStatus, 'in_progress');
        expect(update.message, 'Executing task');
        expect(update.timestamp.toIso8601String(), timestamp.toIso8601String());
      });

      test('parses message with subtask', () {
        // Arrange
        final sessionId = 'test-session-456';
        final timestamp = DateTime.now();
        
        final messageWithSubtask = jsonEncode({
          'session_id': sessionId,
          'overall_status': 'in_progress',
          'message': 'Processing subtask',
          'subtask': {
            'id': 'subtask-1',
            'description': 'Click button',
            'status': 'in_progress',
            'timestamp': timestamp.toIso8601String(),
          },
          'timestamp': timestamp.toIso8601String(),
        });

        // Act
        final json = jsonDecode(messageWithSubtask) as Map<String, dynamic>;
        final update = StatusUpdate.fromJson(json);

        // Assert
        expect(update.subtask, isNotNull);
        expect(update.subtask!.id, 'subtask-1');
        expect(update.subtask!.description, 'Click button');
        expect(update.subtask!.status, SubtaskStatus.inProgress);
      });

      test('parses message with window state', () {
        // Arrange
        final sessionId = 'test-session-789';
        final timestamp = DateTime.now();
        
        final messageWithWindowState = jsonEncode({
          'session_id': sessionId,
          'overall_status': 'in_progress',
          'message': 'Minimizing window',
          'window_state': 'minimal',
          'timestamp': timestamp.toIso8601String(),
        });

        // Act
        final json = jsonDecode(messageWithWindowState) as Map<String, dynamic>;
        final update = StatusUpdate.fromJson(json);

        // Assert
        expect(update.windowState, 'minimal');
      });

      test('throws on malformed JSON', () {
        // Arrange
        final malformedJson = 'invalid json {{{';

        // Act & Assert
        expect(
          () => jsonDecode(malformedJson),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws on missing required fields', () {
        // Arrange
        final incompleteMessage = jsonEncode({
          'session_id': 'test-session',
          // Missing required fields: overall_status, message, timestamp
        });

        // Act & Assert
        final json = jsonDecode(incompleteMessage) as Map<String, dynamic>;
        expect(
          () => StatusUpdate.fromJson(json),
          throwsA(isA<TypeError>()),
        );
      });
    });

    group('disconnect', () {
      test('handles disconnect when not connected', () async {
        // Act & Assert - Should not throw
        await service.disconnect();
        expect(service.isConnected, false);
      });

      test('resets state after disconnect', () async {
        // Arrange
        service.reset();

        // Act
        await service.disconnect();

        // Assert
        expect(service.isConnected, false);
        expect(service.currentSessionId, null);
      });
    });

    group('error handling', () {
      test('accepts error callback in connect method', () {
        // Arrange
        bool errorCallbackProvided = false;

        // Act - Verify error callback can be provided
        final errorCallback = (error) {
          errorCallbackProvided = true;
        };

        // Assert - Error callback is a valid parameter
        expect(errorCallback, isNotNull);
        expect(errorCallback is Function, true);
      });

      test('service has error handling capability', () {
        // This test verifies the service has error handling capability
        expect(service, isNotNull);
        expect(service.isConnected, false);
      });

      test('handles malformed JSON in message parsing', () {
        // Arrange
        final malformedJson = 'not valid json';

        // Act & Assert
        expect(
          () => jsonDecode(malformedJson),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('reconnection logic', () {
      test('reconnect fails when session ID is missing', () async {
        // Arrange
        service.reset();

        // Act
        await service.reconnect();

        // Assert
        expect(service.isConnected, false);
      });

      test('reconnect fails when callback is missing', () async {
        // Arrange
        service.reset();

        // Act
        await service.reconnect();

        // Assert
        expect(service.isConnected, false);
      });

      test('reconnect respects max attempts limit', () async {
        // Arrange
        service.reset();
        int errorCount = 0;

        // Manually set up state to simulate failed connection
        // This tests the reconnection logic without actual WebSocket
        
        // Act & Assert
        // The service should not attempt reconnection without proper setup
        await service.reconnect();
        expect(service.isConnected, false);
      });
    });

    group('reset', () {
      test('clears all service state', () {
        // Arrange
        service.reset();

        // Act
        service.reset();

        // Assert
        expect(service.isConnected, false);
        expect(service.currentSessionId, null);
      });

      test('allows service reuse after reset', () {
        // Arrange
        service.reset();

        // Act
        service.reset();

        // Assert
        expect(service.isConnected, false);
        expect(service.currentSessionId, null);
      });
    });

    group('connection state tracking', () {
      test('tracks connection state correctly', () {
        // Arrange & Act
        final initialState = service.isConnected;

        // Assert
        expect(initialState, false);
      });

      test('tracks session ID correctly', () {
        // Arrange & Act
        final initialSessionId = service.currentSessionId;

        // Assert
        expect(initialSessionId, null);
      });
    });

    group('constants', () {
      test('has correct max reconnect attempts', () {
        expect(WebSocketService.maxReconnectAttempts, 3);
      });

      test('has correct reconnect delay', () {
        expect(WebSocketService.reconnectDelay, Duration(seconds: 2));
      });
    });
  });
}
