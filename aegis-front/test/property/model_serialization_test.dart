import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/models/models.dart';
import 'dart:math';

/// Property-based tests for model serialization
/// 
/// **Feature: rpa-frontend, Property 46: Request Serialization**
/// **Feature: rpa-frontend, Property 47: Response Deserialization**
/// **Validates: Requirements 12.1, 12.2**

void main() {
  group('Model Serialization Properties', () {
    final random = Random();

    // Helper to generate random strings
    String randomString([int maxLength = 50]) {
      final length = random.nextInt(maxLength) + 1;
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
      return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
    }

    // Helper to generate random DateTime
    DateTime randomDateTime() {
      final now = DateTime.now();
      final offset = random.nextInt(365 * 24 * 60 * 60); // Up to 1 year in seconds
      return now.subtract(Duration(seconds: offset));
    }

    // Helper to generate random SubtaskStatus
    SubtaskStatus randomSubtaskStatus() {
      final statuses = SubtaskStatus.values;
      return statuses[random.nextInt(statuses.length)];
    }

    // Helper to generate random SessionStatus
    SessionStatus randomSessionStatus() {
      final statuses = SessionStatus.values;
      return statuses[random.nextInt(statuses.length)];
    }

    test('Property 46: Request Serialization - TaskInstructionRequest round trip', () {
      // Run 100 iterations as specified in design
      for (int i = 0; i < 100; i++) {
        final instruction = randomString();
        final request = TaskInstructionRequest(instruction: instruction);
        
        // Serialize to JSON
        final json = request.toJson();
        
        // Verify JSON structure matches backend Pydantic model
        expect(json, isA<Map<String, dynamic>>());
        expect(json['instruction'], equals(instruction));
        expect(json.keys.length, equals(1));
      }
    });

    test('Property 47: Response Deserialization - TaskInstructionResponse round trip', () {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        final sessionId = randomString(20);
        final status = randomString(20);
        final message = randomString();
        
        final response = TaskInstructionResponse(
          sessionId: sessionId,
          status: status,
          message: message,
        );
        
        // Serialize to JSON
        final json = response.toJson();
        
        // Deserialize back
        final deserialized = TaskInstructionResponse.fromJson(json);
        
        // Verify round trip preserves all data
        expect(deserialized.sessionId, equals(response.sessionId));
        expect(deserialized.status, equals(response.status));
        expect(deserialized.message, equals(response.message));
      }
    });

    test('Property 47: Response Deserialization - Subtask round trip', () {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        final id = randomString(20);
        final description = randomString();
        final status = randomSubtaskStatus();
        final toolName = random.nextBool() ? randomString(20) : null;
        final error = random.nextBool() ? randomString() : null;
        final timestamp = randomDateTime();
        
        final subtask = Subtask(
          id: id,
          description: description,
          status: status,
          toolName: toolName,
          toolArgs: random.nextBool() ? {'arg1': 'value1'} : null,
          result: random.nextBool() ? {'result': 'success'} : null,
          error: error,
          timestamp: timestamp,
        );
        
        // Serialize to JSON
        final json = subtask.toJson();
        
        // Deserialize back
        final deserialized = Subtask.fromJson(json);
        
        // Verify round trip preserves all data
        expect(deserialized.id, equals(subtask.id));
        expect(deserialized.description, equals(subtask.description));
        expect(deserialized.status, equals(subtask.status));
        expect(deserialized.toolName, equals(subtask.toolName));
        expect(deserialized.error, equals(subtask.error));
        // Timestamps should be equal within millisecond precision
        expect(
          deserialized.timestamp.difference(subtask.timestamp).inMilliseconds.abs(),
          lessThan(1),
        );
      }
    });

    test('Property 47: Response Deserialization - ExecutionSession round trip', () {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        final sessionId = randomString(20);
        final instruction = randomString();
        final status = randomSessionStatus();
        final createdAt = randomDateTime();
        final updatedAt = randomDateTime();
        final completedAt = random.nextBool() ? randomDateTime() : null;
        
        // Generate random subtasks
        final subtaskCount = random.nextInt(10) + 1;
        final subtasks = List.generate(subtaskCount, (index) {
          return Subtask(
            id: randomString(20),
            description: randomString(),
            status: randomSubtaskStatus(),
            timestamp: randomDateTime(),
          );
        });
        
        final session = ExecutionSession(
          sessionId: sessionId,
          instruction: instruction,
          status: status,
          subtasks: subtasks,
          createdAt: createdAt,
          updatedAt: updatedAt,
          completedAt: completedAt,
        );
        
        // Serialize to JSON
        final json = session.toJson();
        
        // Deserialize back
        final deserialized = ExecutionSession.fromJson(json);
        
        // Verify round trip preserves all data
        expect(deserialized.sessionId, equals(session.sessionId));
        expect(deserialized.instruction, equals(session.instruction));
        expect(deserialized.status, equals(session.status));
        expect(deserialized.subtasks.length, equals(session.subtasks.length));
        
        // Verify timestamps
        expect(
          deserialized.createdAt.difference(session.createdAt).inMilliseconds.abs(),
          lessThan(1),
        );
        expect(
          deserialized.updatedAt.difference(session.updatedAt).inMilliseconds.abs(),
          lessThan(1),
        );
        
        if (completedAt != null) {
          expect(deserialized.completedAt, isNotNull);
          expect(
            deserialized.completedAt!.difference(session.completedAt!).inMilliseconds.abs(),
            lessThan(1),
          );
        } else {
          expect(deserialized.completedAt, isNull);
        }
      }
    });

    test('Property 47: Response Deserialization - StatusUpdate round trip', () {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        final sessionId = randomString(20);
        final overallStatus = randomString(20);
        final message = randomString();
        final windowState = random.nextBool() ? (random.nextBool() ? 'minimal' : 'normal') : null;
        final timestamp = randomDateTime();
        
        // Optionally include a subtask
        final subtask = random.nextBool()
            ? Subtask(
                id: randomString(20),
                description: randomString(),
                status: randomSubtaskStatus(),
                timestamp: randomDateTime(),
              )
            : null;
        
        final update = StatusUpdate(
          sessionId: sessionId,
          subtask: subtask,
          overallStatus: overallStatus,
          message: message,
          windowState: windowState,
          timestamp: timestamp,
        );
        
        // Serialize to JSON
        final json = update.toJson();
        
        // Deserialize back
        final deserialized = StatusUpdate.fromJson(json);
        
        // Verify round trip preserves all data
        expect(deserialized.sessionId, equals(update.sessionId));
        expect(deserialized.overallStatus, equals(update.overallStatus));
        expect(deserialized.message, equals(update.message));
        expect(deserialized.windowState, equals(update.windowState));
        
        if (subtask != null) {
          expect(deserialized.subtask, isNotNull);
          expect(deserialized.subtask!.id, equals(subtask.id));
          expect(deserialized.subtask!.description, equals(subtask.description));
        } else {
          expect(deserialized.subtask, isNull);
        }
        
        expect(
          deserialized.timestamp.difference(update.timestamp).inMilliseconds.abs(),
          lessThan(1),
        );
      }
    });

    test('Property 47: Response Deserialization - SessionSummary round trip', () {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        final sessionId = randomString(20);
        final instruction = randomString();
        final status = randomString(20);
        final createdAt = randomDateTime();
        final completedAt = random.nextBool() ? randomDateTime() : null;
        final subtaskCount = random.nextInt(50);
        
        final summary = SessionSummary(
          sessionId: sessionId,
          instruction: instruction,
          status: status,
          createdAt: createdAt,
          completedAt: completedAt,
          subtaskCount: subtaskCount,
        );
        
        // Serialize to JSON
        final json = summary.toJson();
        
        // Deserialize back
        final deserialized = SessionSummary.fromJson(json);
        
        // Verify round trip preserves all data
        expect(deserialized.sessionId, equals(summary.sessionId));
        expect(deserialized.instruction, equals(summary.instruction));
        expect(deserialized.status, equals(summary.status));
        expect(deserialized.subtaskCount, equals(summary.subtaskCount));
        
        expect(
          deserialized.createdAt.difference(summary.createdAt).inMilliseconds.abs(),
          lessThan(1),
        );
        
        if (completedAt != null) {
          expect(deserialized.completedAt, isNotNull);
          expect(
            deserialized.completedAt!.difference(summary.completedAt!).inMilliseconds.abs(),
            lessThan(1),
          );
        } else {
          expect(deserialized.completedAt, isNull);
        }
      }
    });

    test('Property 47: Response Deserialization - ErrorResponse round trip', () {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        final error = randomString();
        final details = random.nextBool() ? randomString() : null;
        final sessionId = random.nextBool() ? randomString(20) : null;
        
        final errorResponse = ErrorResponse(
          error: error,
          details: details,
          sessionId: sessionId,
        );
        
        // Serialize to JSON
        final json = errorResponse.toJson();
        
        // Deserialize back
        final deserialized = ErrorResponse.fromJson(json);
        
        // Verify round trip preserves all data
        expect(deserialized.error, equals(errorResponse.error));
        expect(deserialized.details, equals(errorResponse.details));
        expect(deserialized.sessionId, equals(errorResponse.sessionId));
      }
    });
  });
}
