import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/models/task_instruction.dart';

void main() {
  group('TaskInstructionRequest', () {
    test('toJson serializes correctly', () {
      final request = TaskInstructionRequest(
        instruction: 'Open Chrome and navigate to google.com',
      );

      final json = request.toJson();

      expect(json, {
        'instruction': 'Open Chrome and navigate to google.com',
      });
    });

    test('toJson handles empty instruction', () {
      final request = TaskInstructionRequest(instruction: '');

      final json = request.toJson();

      expect(json, {'instruction': ''});
    });

    test('toJson handles special characters', () {
      final request = TaskInstructionRequest(
        instruction: 'Test with "quotes" and \'apostrophes\' and \n newlines',
      );

      final json = request.toJson();

      expect(json['instruction'], contains('quotes'));
      expect(json['instruction'], contains('apostrophes'));
    });
  });

  group('TaskInstructionResponse', () {
    test('fromJson deserializes correctly', () {
      final json = {
        'session_id': 'abc123',
        'status': 'pending',
        'message': 'Task received',
      };

      final response = TaskInstructionResponse.fromJson(json);

      expect(response.sessionId, 'abc123');
      expect(response.status, 'pending');
      expect(response.message, 'Task received');
    });

    test('toJson serializes correctly', () {
      final response = TaskInstructionResponse(
        sessionId: 'xyz789',
        status: 'in_progress',
        message: 'Executing task',
      );

      final json = response.toJson();

      expect(json, {
        'session_id': 'xyz789',
        'status': 'in_progress',
        'message': 'Executing task',
      });
    });

    test('fromJson and toJson round trip', () {
      final originalJson = {
        'session_id': 'test-session-123',
        'status': 'completed',
        'message': 'Task completed successfully',
      };

      final response = TaskInstructionResponse.fromJson(originalJson);
      final serializedJson = response.toJson();

      expect(serializedJson, originalJson);
    });

    test('fromJson handles all status types', () {
      final statuses = ['pending', 'in_progress', 'completed', 'failed', 'cancelled'];

      for (final status in statuses) {
        final json = {
          'session_id': 'test',
          'status': status,
          'message': 'Test message',
        };

        final response = TaskInstructionResponse.fromJson(json);
        expect(response.status, status);
      }
    });
  });
}
