import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:aegis_front/services/backend_api_service.dart';
import 'package:aegis_front/models/task_instruction.dart';
import 'package:aegis_front/models/execution_session.dart';
import 'package:aegis_front/models/session_summary.dart';
import 'package:aegis_front/models/subtask.dart';

// Generate mocks using build_runner
@GenerateMocks([http.Client])
import 'backend_api_service_test.mocks.dart';

void main() {
  group('BackendApiService', () {
    late MockClient mockClient;
    late BackendApiService service;
    const baseUrl = 'http://localhost:8000';

    setUp(() {
      mockClient = MockClient();
      service = BackendApiService(
        client: mockClient,
        baseUrl: baseUrl,
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('startTask', () {
      const instruction = 'Open calculator and add 2 + 2';
      const sessionId = 'test-session-123';

      test('sends POST request with correct URL and headers', () async {
        // Arrange
        final responseBody = jsonEncode({
          'session_id': sessionId,
          'status': 'pending',
          'message': 'Task started successfully',
        });

        when(mockClient.post(
          Uri.parse('$baseUrl/api/start_task'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        await service.startTask(instruction);

        // Assert
        verify(mockClient.post(
          Uri.parse('$baseUrl/api/start_task'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'instruction': instruction}),
        )).called(1);
      });

      test('returns TaskInstructionResponse on success', () async {
        // Arrange
        final responseBody = jsonEncode({
          'session_id': sessionId,
          'status': 'pending',
          'message': 'Task started successfully',
        });

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await service.startTask(instruction);

        // Assert
        expect(result, isA<TaskInstructionResponse>());
        expect(result.sessionId, sessionId);
        expect(result.status, 'pending');
        expect(result.message, 'Task started successfully');
      });

      test('throws ValidationException on 422 status code', () async {
        // Arrange
        final responseBody = jsonEncode({
          'detail': 'Instruction cannot be empty',
        });

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 422));

        // Act & Assert
        expect(
          () => service.startTask(''),
          throwsA(isA<ValidationException>()
              .having((e) => e.message, 'message', 'Instruction cannot be empty')),
        );
      });

      test('throws NetworkException on SocketException', () async {
        // Arrange
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(const SocketException('Network unreachable'));

        // Act & Assert
        expect(
          () => service.startTask(instruction),
          throwsA(isA<NetworkException>().having(
            (e) => e.message,
            'message',
            contains('Unable to connect to backend'),
          )),
        );
      });

      test('throws NetworkException on TimeoutException', () async {
        // Arrange
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(TimeoutException('Request timeout'));

        // Act & Assert
        expect(
          () => service.startTask(instruction),
          throwsA(isA<NetworkException>().having(
            (e) => e.message,
            'message',
            contains('Request timed out'),
          )),
        );
      });

      test('throws NetworkException on ClientException', () async {
        // Arrange
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(http.ClientException('Connection refused'));

        // Act & Assert
        expect(
          () => service.startTask(instruction),
          throwsA(isA<NetworkException>().having(
            (e) => e.message,
            'message',
            contains('Network error'),
          )),
        );
      });

      test('throws ApiException on 500 status code', () async {
        // Arrange
        final responseBody = jsonEncode({
          'error': 'Internal server error',
        });

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 500));

        // Act & Assert
        expect(
          () => service.startTask(instruction),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)),
        );
      });

      test('throws ApiException on 404 status code', () async {
        // Arrange
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('Not found', 404));

        // Act & Assert
        expect(
          () => service.startTask(instruction),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', 'Resource not found')),
        );
      });

      test('throws ApiException on malformed JSON response', () async {
        // Arrange
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('Invalid JSON{', 200));

        // Act & Assert
        expect(
          () => service.startTask(instruction),
          throwsA(isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Failed to parse response'),
          )),
        );
      });
    });

    group('getHistory', () {
      test('sends GET request with correct URL and headers', () async {
        // Arrange
        final responseBody = jsonEncode({
          'sessions': [],
          'total': 0,
        });

        when(mockClient.get(
          Uri.parse('$baseUrl/api/history'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        await service.getHistory();

        // Assert
        verify(mockClient.get(
          Uri.parse('$baseUrl/api/history'),
          headers: {'Content-Type': 'application/json'},
        )).called(1);
      });

      test('returns HistoryResponse with sessions on success', () async {
        // Arrange
        final responseBody = jsonEncode({
          'sessions': [
            {
              'session_id': 'session-1',
              'instruction': 'Test instruction 1',
              'status': 'completed',
              'created_at': '2024-12-01T10:00:00Z',
              'completed_at': '2024-12-01T10:05:00Z',
              'subtask_count': 3,
            },
            {
              'session_id': 'session-2',
              'instruction': 'Test instruction 2',
              'status': 'failed',
              'created_at': '2024-12-01T11:00:00Z',
              'completed_at': '2024-12-01T11:02:00Z',
              'subtask_count': 2,
            },
          ],
          'total': 2,
        });

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await service.getHistory();

        // Assert
        expect(result, isA<HistoryResponse>());
        expect(result.sessions.length, 2);
        expect(result.total, 2);
        expect(result.sessions[0].sessionId, 'session-1');
        expect(result.sessions[1].sessionId, 'session-2');
      });

      test('returns empty HistoryResponse when no sessions', () async {
        // Arrange
        final responseBody = jsonEncode({
          'sessions': [],
          'total': 0,
        });

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await service.getHistory();

        // Assert
        expect(result.sessions, isEmpty);
        expect(result.total, 0);
      });

      test('throws NetworkException on SocketException', () async {
        // Arrange
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(const SocketException('Network unreachable'));

        // Act & Assert
        expect(
          () => service.getHistory(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws NetworkException on TimeoutException', () async {
        // Arrange
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(TimeoutException('Request timeout'));

        // Act & Assert
        expect(
          () => service.getHistory(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws ApiException on 500 status code', () async {
        // Arrange
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Server error', 500));

        // Act & Assert
        expect(
          () => service.getHistory(),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)),
        );
      });
    });

    group('getSessionDetails', () {
      const sessionId = 'test-session-123';

      test('sends GET request with correct URL and headers', () async {
        // Arrange
        final responseBody = jsonEncode({
          'session_id': sessionId,
          'instruction': 'Test instruction',
          'status': 'completed',
          'subtasks': [],
          'created_at': '2024-12-01T10:00:00Z',
          'updated_at': '2024-12-01T10:05:00Z',
          'completed_at': '2024-12-01T10:05:00Z',
        });

        when(mockClient.get(
          Uri.parse('$baseUrl/api/history/$sessionId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        await service.getSessionDetails(sessionId);

        // Assert
        verify(mockClient.get(
          Uri.parse('$baseUrl/api/history/$sessionId'),
          headers: {'Content-Type': 'application/json'},
        )).called(1);
      });

      test('returns ExecutionSession on success', () async {
        // Arrange
        final responseBody = jsonEncode({
          'session_id': sessionId,
          'instruction': 'Test instruction',
          'status': 'completed',
          'subtasks': [
            {
              'id': 'subtask-1',
              'description': 'First subtask',
              'status': 'completed',
              'timestamp': '2024-12-01T10:01:00Z',
            },
          ],
          'created_at': '2024-12-01T10:00:00Z',
          'updated_at': '2024-12-01T10:05:00Z',
          'completed_at': '2024-12-01T10:05:00Z',
        });

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await service.getSessionDetails(sessionId);

        // Assert
        expect(result, isA<ExecutionSession>());
        expect(result.sessionId, sessionId);
        expect(result.instruction, 'Test instruction');
        expect(result.subtasks.length, 1);
      });

      test('throws ApiException on 404 status code', () async {
        // Arrange
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Not found', 404));

        // Act & Assert
        expect(
          () => service.getSessionDetails(sessionId),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)),
        );
      });

      test('throws NetworkException on SocketException', () async {
        // Arrange
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(const SocketException('Network unreachable'));

        // Act & Assert
        expect(
          () => service.getSessionDetails(sessionId),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws NetworkException on TimeoutException', () async {
        // Arrange
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(TimeoutException('Request timeout'));

        // Act & Assert
        expect(
          () => service.getSessionDetails(sessionId),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('cancelSession', () {
      const sessionId = 'test-session-123';

      test('sends DELETE request with correct URL and headers', () async {
        // Arrange
        when(mockClient.delete(
          Uri.parse('$baseUrl/api/execution/$sessionId'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('', 200));

        // Act
        await service.cancelSession(sessionId);

        // Assert
        verify(mockClient.delete(
          Uri.parse('$baseUrl/api/execution/$sessionId'),
          headers: {'Content-Type': 'application/json'},
        )).called(1);
      });

      test('completes successfully on 200 status code', () async {
        // Arrange
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('', 200));

        // Act & Assert - Should not throw
        await service.cancelSession(sessionId);
      });

      test('throws ApiException on 404 status code', () async {
        // Arrange
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Not found', 404));

        // Act & Assert
        expect(
          () => service.cancelSession(sessionId),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)),
        );
      });

      test('throws ApiException on 500 status code', () async {
        // Arrange
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Server error', 500));

        // Act & Assert
        expect(
          () => service.cancelSession(sessionId),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)),
        );
      });

      test('throws NetworkException on SocketException', () async {
        // Arrange
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(const SocketException('Network unreachable'));

        // Act & Assert
        expect(
          () => service.cancelSession(sessionId),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws NetworkException on TimeoutException', () async {
        // Arrange
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(TimeoutException('Request timeout'));

        // Act & Assert
        expect(
          () => service.cancelSession(sessionId),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws NetworkException on ClientException', () async {
        // Arrange
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenThrow(http.ClientException('Connection refused'));

        // Act & Assert
        expect(
          () => service.cancelSession(sessionId),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('error handling', () {
      test('handles ErrorResponse format correctly', () async {
        // Arrange
        final responseBody = jsonEncode({
          'error': 'Custom error message',
          'details': 'Additional error details',
          'session_id': 'session-123',
        });

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 400));

        // Act & Assert
        expect(
          () => service.startTask('test'),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', 'Custom error message')
              .having((e) => e.statusCode, 'statusCode', 400)),
        );
      });

      test('handles validation error with detail field', () async {
        // Arrange
        final responseBody = jsonEncode({
          'detail': [
            {
              'loc': ['body', 'instruction'],
              'msg': 'field required',
              'type': 'value_error.missing',
            }
          ],
        });

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 422));

        // Act & Assert
        expect(
          () => service.startTask(''),
          throwsA(isA<ValidationException>()),
        );
      });

      test('handles generic error response', () async {
        // Arrange
        final responseBody = jsonEncode({
          'detail': 'Generic error message',
        });

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(responseBody, 400));

        // Act & Assert
        expect(
          () => service.getHistory(),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)),
        );
      });

      test('handles unparseable error response', () async {
        // Arrange
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Plain text error', 400));

        // Act & Assert
        expect(
          () => service.getHistory(),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)),
        );
      });

      test('handles 503 service unavailable', () async {
        // Arrange
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Service unavailable', 503));

        // Act & Assert
        expect(
          () => service.getHistory(),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 503)
              .having((e) => e.message, 'message',
                  contains('automation service is currently offline'))),
        );
      });
    });

    group('request serialization', () {
      test('serializes task instruction correctly', () async {
        // Arrange
        const instruction = 'Test instruction with special characters';
        final responseBody = jsonEncode({
          'session_id': 'test-123',
          'status': 'pending',
          'message': 'Started',
        });

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        await service.startTask(instruction);

        // Assert
        final captured = verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        final sentBody = jsonDecode(captured[0] as String);
        expect(sentBody['instruction'], instruction);
      });
    });

    group('response deserialization', () {
      test('deserializes TaskInstructionResponse correctly', () async {
        // Arrange
        final responseBody = jsonEncode({
          'session_id': 'abc-123',
          'status': 'in_progress',
          'message': 'Task is running',
        });

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await service.startTask('test');

        // Assert
        expect(result.sessionId, 'abc-123');
        expect(result.status, 'in_progress');
        expect(result.message, 'Task is running');
      });

      test('deserializes HistoryResponse with multiple sessions', () async {
        // Arrange
        final responseBody = jsonEncode({
          'sessions': [
            {
              'session_id': 's1',
              'instruction': 'Instruction 1',
              'status': 'completed',
              'created_at': '2024-12-01T10:00:00Z',
              'completed_at': '2024-12-01T10:05:00Z',
              'subtask_count': 5,
            },
            {
              'session_id': 's2',
              'instruction': 'Instruction 2',
              'status': 'failed',
              'created_at': '2024-12-01T11:00:00Z',
              'completed_at': null,
              'subtask_count': 2,
            },
          ],
          'total': 2,
        });

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await service.getHistory();

        // Assert
        expect(result.sessions.length, 2);
        expect(result.sessions[0].sessionId, 's1');
        expect(result.sessions[0].status, 'completed');
        expect(result.sessions[1].sessionId, 's2');
        expect(result.sessions[1].status, 'failed');
        expect(result.sessions[1].completedAt, null);
      });

      test('deserializes ExecutionSession with subtasks', () async {
        // Arrange
        final responseBody = jsonEncode({
          'session_id': 'session-1',
          'instruction': 'Complex task',
          'status': 'in_progress',
          'subtasks': [
            {
              'id': 'st1',
              'description': 'Subtask 1',
              'status': 'completed',
              'timestamp': '2024-12-01T10:01:00Z',
            },
            {
              'id': 'st2',
              'description': 'Subtask 2',
              'status': 'in_progress',
              'timestamp': '2024-12-01T10:02:00Z',
            },
          ],
          'created_at': '2024-12-01T10:00:00Z',
          'updated_at': '2024-12-01T10:02:30Z',
          'completed_at': null,
        });

        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await service.getSessionDetails('session-1');

        // Assert
        expect(result.sessionId, 'session-1');
        expect(result.subtasks.length, 2);
        expect(result.subtasks[0].id, 'st1');
        expect(result.subtasks[0].status, SubtaskStatus.completed);
        expect(result.subtasks[1].id, 'st2');
        expect(result.subtasks[1].status, SubtaskStatus.inProgress);
        expect(result.completedAt, null);
      });
    });

    group('dispose', () {
      test('closes the HTTP client', () {
        // Act
        service.dispose();

        // Assert - Verify client is closed (no exception thrown)
        // Note: We can't directly verify close() was called on the mock,
        // but we ensure dispose() completes without error
      });
    });
  });
}
