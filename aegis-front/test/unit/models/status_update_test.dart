import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/models/status_update.dart';
import 'package:aegis_front/models/subtask.dart';

void main() {
  group('StatusUpdate', () {
    final testTimestamp = DateTime(2024, 12, 1, 10, 30, 0);

    test('fromJson deserializes minimal status update', () {
      final json = {
        'session_id': 'session-1',
        'overall_status': 'in_progress',
        'message': 'Executing task',
        'timestamp': testTimestamp.toIso8601String(),
      };

      final update = StatusUpdate.fromJson(json);

      expect(update.sessionId, 'session-1');
      expect(update.overallStatus, 'in_progress');
      expect(update.message, 'Executing task');
      expect(update.timestamp, testTimestamp);
      expect(update.subtask, isNull);
      expect(update.windowState, isNull);
    });

    test('fromJson deserializes status update with subtask', () {
      final json = {
        'session_id': 'session-2',
        'subtask': {
          'id': 'subtask-1',
          'description': 'Click button',
          'status': 'completed',
          'timestamp': testTimestamp.toIso8601String(),
        },
        'overall_status': 'in_progress',
        'message': 'Subtask completed',
        'timestamp': testTimestamp.toIso8601String(),
      };

      final update = StatusUpdate.fromJson(json);

      expect(update.sessionId, 'session-2');
      expect(update.subtask, isNotNull);
      expect(update.subtask!.id, 'subtask-1');
      expect(update.subtask!.description, 'Click button');
      expect(update.subtask!.status, SubtaskStatus.completed);
    });

    test('fromJson deserializes status update with window state', () {
      final json = {
        'session_id': 'session-3',
        'overall_status': 'in_progress',
        'message': 'Minimizing window',
        'window_state': 'minimal',
        'timestamp': testTimestamp.toIso8601String(),
      };

      final update = StatusUpdate.fromJson(json);

      expect(update.sessionId, 'session-3');
      expect(update.windowState, 'minimal');
      expect(update.message, 'Minimizing window');
    });

    test('fromJson deserializes complete status update', () {
      final json = {
        'session_id': 'session-4',
        'subtask': {
          'id': 'subtask-2',
          'description': 'Type text',
          'status': 'in_progress',
          'tool_name': 'type_text',
          'tool_args': {'text': 'Hello'},
          'timestamp': testTimestamp.toIso8601String(),
        },
        'overall_status': 'in_progress',
        'message': 'Typing text',
        'window_state': 'minimal',
        'timestamp': testTimestamp.toIso8601String(),
      };

      final update = StatusUpdate.fromJson(json);

      expect(update.sessionId, 'session-4');
      expect(update.subtask, isNotNull);
      expect(update.subtask!.toolName, 'type_text');
      expect(update.overallStatus, 'in_progress');
      expect(update.windowState, 'minimal');
    });

    test('toJson serializes minimal status update', () {
      final update = StatusUpdate(
        sessionId: 'session-5',
        overallStatus: 'pending',
        message: 'Task queued',
        timestamp: testTimestamp,
      );

      final json = update.toJson();

      expect(json['session_id'], 'session-5');
      expect(json['overall_status'], 'pending');
      expect(json['message'], 'Task queued');
      expect(json['timestamp'], testTimestamp.toIso8601String());
      expect(json['subtask'], isNull);
      expect(json['window_state'], isNull);
    });

    test('toJson serializes status update with subtask', () {
      final subtask = Subtask(
        id: 'subtask-3',
        description: 'Launch app',
        status: SubtaskStatus.completed,
        timestamp: testTimestamp,
      );

      final update = StatusUpdate(
        sessionId: 'session-6',
        subtask: subtask,
        overallStatus: 'in_progress',
        message: 'App launched',
        timestamp: testTimestamp,
      );

      final json = update.toJson();

      expect(json['subtask'], isNotNull);
      expect(json['subtask']['id'], 'subtask-3');
      expect(json['subtask']['description'], 'Launch app');
    });

    test('toJson serializes status update with window state', () {
      final update = StatusUpdate(
        sessionId: 'session-7',
        overallStatus: 'in_progress',
        message: 'Restoring window',
        windowState: 'normal',
        timestamp: testTimestamp,
      );

      final json = update.toJson();

      expect(json['window_state'], 'normal');
    });

    test('fromJson and toJson round trip without optional fields', () {
      final originalJson = {
        'session_id': 'session-8',
        'overall_status': 'completed',
        'message': 'Task finished',
        'timestamp': testTimestamp.toIso8601String(),
      };

      final update = StatusUpdate.fromJson(originalJson);
      final serializedJson = update.toJson();

      expect(serializedJson['session_id'], originalJson['session_id']);
      expect(serializedJson['overall_status'], originalJson['overall_status']);
      expect(serializedJson['message'], originalJson['message']);
      expect(serializedJson['timestamp'], originalJson['timestamp']);
      expect(serializedJson['subtask'], isNull);
      expect(serializedJson['window_state'], isNull);
    });

    test('fromJson and toJson round trip with all fields', () {
      final originalJson = {
        'session_id': 'session-9',
        'subtask': {
          'id': 'subtask-4',
          'description': 'Complete action',
          'status': 'completed',
          'tool_name': 'click',
          'tool_args': {'x': 100, 'y': 200},
          'result': {'success': true},
          'timestamp': testTimestamp.toIso8601String(),
        },
        'overall_status': 'in_progress',
        'message': 'Action completed',
        'window_state': 'minimal',
        'timestamp': testTimestamp.toIso8601String(),
      };

      final update = StatusUpdate.fromJson(originalJson);
      final serializedJson = update.toJson();

      expect(serializedJson['session_id'], originalJson['session_id']);
      expect(serializedJson['overall_status'], originalJson['overall_status']);
      expect(serializedJson['message'], originalJson['message']);
      expect(serializedJson['window_state'], originalJson['window_state']);
      
      final serializedSubtask = serializedJson['subtask'] as Map<String, dynamic>;
      final originalSubtask = originalJson['subtask'] as Map<String, dynamic>;
      expect(serializedSubtask['id'], originalSubtask['id']);
      expect(serializedSubtask['tool_name'], originalSubtask['tool_name']);
    });

    test('fromJson handles window state values', () {
      final windowStates = ['minimal', 'normal'];

      for (final state in windowStates) {
        final json = {
          'session_id': 'test',
          'overall_status': 'in_progress',
          'message': 'Test',
          'window_state': state,
          'timestamp': testTimestamp.toIso8601String(),
        };

        final update = StatusUpdate.fromJson(json);
        expect(update.windowState, state);
      }
    });

    test('fromJson handles all overall status values', () {
      final statuses = ['pending', 'in_progress', 'completed', 'failed', 'cancelled'];

      for (final status in statuses) {
        final json = {
          'session_id': 'test',
          'overall_status': status,
          'message': 'Test',
          'timestamp': testTimestamp.toIso8601String(),
        };

        final update = StatusUpdate.fromJson(json);
        expect(update.overallStatus, status);
      }
    });

    test('fromJson handles null subtask field', () {
      final json = {
        'session_id': 'session-10',
        'subtask': null,
        'overall_status': 'pending',
        'message': 'Starting',
        'timestamp': testTimestamp.toIso8601String(),
      };

      final update = StatusUpdate.fromJson(json);
      expect(update.subtask, isNull);
    });

    test('fromJson handles null window_state field', () {
      final json = {
        'session_id': 'session-11',
        'overall_status': 'in_progress',
        'message': 'Processing',
        'window_state': null,
        'timestamp': testTimestamp.toIso8601String(),
      };

      final update = StatusUpdate.fromJson(json);
      expect(update.windowState, isNull);
    });

    test('fromJson handles subtask with error', () {
      final json = {
        'session_id': 'session-12',
        'subtask': {
          'id': 'subtask-5',
          'description': 'Failed action',
          'status': 'failed',
          'error': 'Element not found',
          'timestamp': testTimestamp.toIso8601String(),
        },
        'overall_status': 'failed',
        'message': 'Task failed',
        'timestamp': testTimestamp.toIso8601String(),
      };

      final update = StatusUpdate.fromJson(json);

      expect(update.subtask, isNotNull);
      expect(update.subtask!.status, SubtaskStatus.failed);
      expect(update.subtask!.error, 'Element not found');
      expect(update.overallStatus, 'failed');
    });
  });
}
