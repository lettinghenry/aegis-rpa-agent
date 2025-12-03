import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aegis_front/services/backend_api_service.dart';
import 'package:aegis_front/models/models.dart';
import 'dart:convert';
import 'dart:math';

/// Property-based tests for API requests
/// 
/// **Feature: rpa-frontend, Property 3: Task Submission Request**
/// **Feature: rpa-frontend, Property 18: Cancellation Request**
/// **Feature: rpa-frontend, Property 21: History Request**
/// **Feature: rpa-frontend, Property 23: Session Detail Request**
/// **Validates: Requirements 2.3, 5.3, 6.2, 6.4**

void main() {
  group('API Request Properties', () {
    final random = Random();

    // Helper to generate random strings
    String randomString([int maxLength = 50]) {
      final length = random.nextInt(maxLength) + 1;
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
      return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
    }

    // Helper to generate random session IDs (no spaces for URL safety)
    String randomSessionId([int maxLength = 30]) {
      final length = random.nextInt(maxLength) + 10;
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_';
      return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
    }

    // Helper to generate random DateTime
    DateTime randomDateTime() {
      final now = DateTime.now();
      final offset = random.nextInt(365 * 24 * 60 * 60); // Up to 1 year in seconds
      return now.subtract(Duration(seconds: offset));
    }

    test('Property 3: Task Submission Request - POST to /api/start_task with instruction', () async {
      // Run 100 iterations as specified in design
      for (int i = 0; i < 100; i++) {
        final instruction = randomString();
        String? capturedMethod;
        String? capturedPath;
        Map<String, String>? capturedHeaders;
        String? capturedBody;

        // Create mock client that captures request details
        final mockClient = MockClient((request) async {
          capturedMethod = request.method;
          capturedPath = request.url.path;
          capturedHeaders = request.headers;
          capturedBody = request.body;

          // Return a valid response
          final response = TaskInstructionResponse(
            sessionId: 'test-session-${random.nextInt(1000)}',
            status: 'pending',
            message: 'Task started',
          );

          return http.Response(
            jsonEncode(response.toJson()),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = BackendApiService(
          client: mockClient,
          baseUrl: 'http://localhost:8000',
        );

        // Execute the request
        await service.startTask(instruction);

        // Verify POST request was sent
        expect(capturedMethod, equals('POST'));
        
        // Verify correct endpoint
        expect(capturedPath, equals('/api/start_task'));
        
        // Verify Content-Type header
        expect(capturedHeaders?['Content-Type'], equals('application/json'));
        
        // Verify instruction is in request body
        expect(capturedBody, isNotNull);
        final bodyJson = jsonDecode(capturedBody!);
        expect(bodyJson['instruction'], equals(instruction));
        
        service.dispose();
      }
    });

    test('Property 18: Cancellation Request - DELETE to /api/execution/{session_id}', () async {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        final sessionId = randomSessionId();
        String? capturedMethod;
        String? capturedPath;
        Map<String, String>? capturedHeaders;

        // Create mock client that captures request details
        final mockClient = MockClient((request) async {
          capturedMethod = request.method;
          capturedPath = request.url.path;
          capturedHeaders = request.headers;

          // Return success response
          return http.Response('', 200);
        });

        final service = BackendApiService(
          client: mockClient,
          baseUrl: 'http://localhost:8000',
        );

        // Execute the cancellation request
        await service.cancelSession(sessionId);

        // Verify DELETE request was sent
        expect(capturedMethod, equals('DELETE'));
        
        // Verify correct endpoint with session_id
        expect(capturedPath, equals('/api/execution/$sessionId'));
        
        // Verify Content-Type header
        expect(capturedHeaders?['Content-Type'], equals('application/json'));
        
        service.dispose();
      }
    });

    test('Property 21: History Request - GET to /api/history', () async {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        String? capturedMethod;
        String? capturedPath;
        Map<String, String>? capturedHeaders;

        // Create mock client that captures request details
        final mockClient = MockClient((request) async {
          capturedMethod = request.method;
          capturedPath = request.url.path;
          capturedHeaders = request.headers;

          // Return a valid history response
          final response = HistoryResponse(
            sessions: [],
            total: 0,
          );

          return http.Response(
            jsonEncode(response.toJson()),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = BackendApiService(
          client: mockClient,
          baseUrl: 'http://localhost:8000',
        );

        // Execute the history request
        await service.getHistory();

        // Verify GET request was sent
        expect(capturedMethod, equals('GET'));
        
        // Verify correct endpoint
        expect(capturedPath, equals('/api/history'));
        
        // Verify Content-Type header
        expect(capturedHeaders?['Content-Type'], equals('application/json'));
        
        service.dispose();
      }
    });

    test('Property 23: Session Detail Request - GET to /api/history/{session_id}', () async {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        final sessionId = randomSessionId();
        String? capturedMethod;
        String? capturedPath;
        Map<String, String>? capturedHeaders;

        // Create mock client that captures request details
        final mockClient = MockClient((request) async {
          capturedMethod = request.method;
          capturedPath = request.url.path;
          capturedHeaders = request.headers;

          // Return a valid session response
          final response = ExecutionSession(
            sessionId: sessionId,
            instruction: randomString(),
            status: SessionStatus.completed,
            subtasks: [],
            createdAt: randomDateTime(),
            updatedAt: randomDateTime(),
          );

          return http.Response(
            jsonEncode(response.toJson()),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = BackendApiService(
          client: mockClient,
          baseUrl: 'http://localhost:8000',
        );

        // Execute the session detail request
        await service.getSessionDetails(sessionId);

        // Verify GET request was sent
        expect(capturedMethod, equals('GET'));
        
        // Verify correct endpoint with session_id
        expect(capturedPath, equals('/api/history/$sessionId'));
        
        // Verify Content-Type header
        expect(capturedHeaders?['Content-Type'], equals('application/json'));
        
        service.dispose();
      }
    });
  });
}
