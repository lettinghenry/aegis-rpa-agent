import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/models/subtask.dart';

void main() {
  group('SubtaskStatus', () {
    test('fromString converts valid status strings', () {
      expect(SubtaskStatus.fromString('pending'), SubtaskStatus.pending);
      expect(SubtaskStatus.fromString('in_progress'), SubtaskStatus.inProgress);
      expect(SubtaskStatus.fromString('completed'), SubtaskStatus.completed);
      expect(SubtaskStatus.fromString('failed'), SubtaskStatus.failed);
    });

    test('fromString throws on invalid status', () {
      expect(
        () => SubtaskStatus.fromString('invalid'),
        throwsArgumentError,
      );
    });

    test('toString returns correct string representation', () {
      expect(SubtaskStatus.pending.toString(), 'SubtaskStatus.pending');
      expect(SubtaskStatus.inProgress.toString(), 'SubtaskStatus.inProgress');
      expect(SubtaskStatus.completed.toString(), 'SubtaskStatus.completed');
      expect(SubtaskStatus.failed.toString(), 'SubtaskStatus.failed');
    });
  });

  group('Subtask', () {
    final testTimestamp = DateTime(2024, 12, 1, 10, 30, 0);

    test('fromJson deserializes minimal subtask', () {
      final json = {
        'id': 'subtask-1',
        'description': 'Click submit button',
        'status': 'pending',
        'timestamp': testTimestamp.toIso8601String(),
      };

      final subtask = Subtask.fromJson(json);

      expect(subtask.id, 'subtask-1');
      expect(subtask.description, 'Click submit button');
      expect(subtask.status, SubtaskStatus.pending);
      expect(subtask.timestamp, testTimestamp);
      expect(subtask.toolName, isNull);
      expect(subtask.toolArgs, isNull);
      expect(subtask.result, isNull);
      expect(subtask.error, isNull);
    });

    test('fromJson deserializes complete subtask', () {
      final json = {
        'id': 'subtask-2',
        'description': 'Type text into field',
        'status': 'completed',
        'tool_name': 'type_text',
        'tool_args': {'text': 'Hello World', 'field': 'input'},
        'result': {'success': true},
        'error': null,
        'timestamp': testTimestamp.toIso8601String(),
      };

      final subtask = Subtask.fromJson(json);

      expect(subtask.id, 'subtask-2');
      expect(subtask.description, 'Type text into field');
      expect(subtask.status, SubtaskStatus.completed);
      expect(subtask.toolName, 'type_text');
      expect(subtask.toolArgs, {'text': 'Hello World', 'field': 'input'});
      expect(subtask.result, {'success': true});
      expect(subtask.error, isNull);
      expect(subtask.timestamp, testTimestamp);
    });

    test('fromJson deserializes failed subtask with error', () {
      final json = {
        'id': 'subtask-3',
        'description': 'Click element',
        'status': 'failed',
        'tool_name': 'click_element',
        'tool_args': {'element': 'button'},
        'result': null,
        'error': 'Element not found',
        'timestamp': testTimestamp.toIso8601String(),
      };

      final subtask = Subtask.fromJson(json);

      expect(subtask.id, 'subtask-3');
      expect(subtask.status, SubtaskStatus.failed);
      expect(subtask.error, 'Element not found');
      expect(subtask.result, isNull);
    });

    test('toJson serializes minimal subtask', () {
      final subtask = Subtask(
        id: 'subtask-4',
        description: 'Launch application',
        status: SubtaskStatus.inProgress,
        timestamp: testTimestamp,
      );

      final json = subtask.toJson();

      expect(json['id'], 'subtask-4');
      expect(json['description'], 'Launch application');
      expect(json['status'], 'in_progress');
      expect(json['timestamp'], testTimestamp.toIso8601String());
      expect(json['tool_name'], isNull);
      expect(json['tool_args'], isNull);
      expect(json['result'], isNull);
      expect(json['error'], isNull);
    });

    test('toJson serializes complete subtask', () {
      final subtask = Subtask(
        id: 'subtask-5',
        description: 'Execute command',
        status: SubtaskStatus.completed,
        toolName: 'execute_cmd',
        toolArgs: {'command': 'ls -la'},
        result: {'output': 'file1.txt\nfile2.txt'},
        timestamp: testTimestamp,
      );

      final json = subtask.toJson();

      expect(json['id'], 'subtask-5');
      expect(json['description'], 'Execute command');
      expect(json['status'], 'completed');
      expect(json['tool_name'], 'execute_cmd');
      expect(json['tool_args'], {'command': 'ls -la'});
      expect(json['result'], {'output': 'file1.txt\nfile2.txt'});
      expect(json['error'], isNull);
    });

    test('fromJson and toJson round trip', () {
      final originalJson = {
        'id': 'subtask-6',
        'description': 'Test round trip',
        'status': 'completed',
        'tool_name': 'test_tool',
        'tool_args': {'arg1': 'value1', 'arg2': 42},
        'result': {'success': true, 'data': [1, 2, 3]},
        'error': null,
        'timestamp': testTimestamp.toIso8601String(),
      };

      final subtask = Subtask.fromJson(originalJson);
      final serializedJson = subtask.toJson();

      expect(serializedJson['id'], originalJson['id']);
      expect(serializedJson['description'], originalJson['description']);
      expect(serializedJson['status'], originalJson['status']);
      expect(serializedJson['tool_name'], originalJson['tool_name']);
      expect(serializedJson['tool_args'], originalJson['tool_args']);
      expect(serializedJson['result'], originalJson['result']);
      expect(serializedJson['error'], originalJson['error']);
      expect(serializedJson['timestamp'], originalJson['timestamp']);
    });

    test('fromJson handles all status types', () {
      final statuses = ['pending', 'in_progress', 'completed', 'failed'];

      for (final status in statuses) {
        final json = {
          'id': 'test',
          'description': 'Test',
          'status': status,
          'timestamp': testTimestamp.toIso8601String(),
        };

        final subtask = Subtask.fromJson(json);
        expect(subtask.status, SubtaskStatus.fromString(status));
      }
    });

    test('fromJson handles complex nested data structures', () {
      final json = {
        'id': 'subtask-7',
        'description': 'Complex data test',
        'status': 'completed',
        'tool_args': {
          'nested': {
            'level1': {
              'level2': ['a', 'b', 'c']
            }
          }
        },
        'result': {
          'items': [
            {'id': 1, 'name': 'Item 1'},
            {'id': 2, 'name': 'Item 2'}
          ]
        },
        'timestamp': testTimestamp.toIso8601String(),
      };

      final subtask = Subtask.fromJson(json);

      expect(subtask.toolArgs?['nested']['level1']['level2'], ['a', 'b', 'c']);
      expect(subtask.result?['items'][0]['name'], 'Item 1');
    });
  });
}
