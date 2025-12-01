import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/models/session_summary.dart';

void main() {
  group('SessionSummary', () {
    final testCreatedAt = DateTime(2024, 12, 1, 10, 0, 0);
    final testCompletedAt = DateTime(2024, 12, 1, 10, 30, 0);

    test('fromJson deserializes session summary without completion time', () {
      final json = {
        'session_id': 'session-1',
        'instruction': 'Open Chrome and navigate to google.com',
        'status': 'in_progress',
        'created_at': testCreatedAt.toIso8601String(),
        'subtask_count': 3,
      };

      final summary = SessionSummary.fromJson(json);

      expect(summary.sessionId, 'session-1');
      expect(summary.instruction, 'Open Chrome and navigate to google.com');
      expect(summary.status, 'in_progress');
      expect(summary.createdAt, testCreatedAt);
      expect(summary.completedAt, isNull);
      expect(summary.subtaskCount, 3);
    });

    test('fromJson deserializes session summary with completion time', () {
      final json = {
        'session_id': 'session-2',
        'instruction': 'Complete automation task',
        'status': 'completed',
        'created_at': testCreatedAt.toIso8601String(),
        'completed_at': testCompletedAt.toIso8601String(),
        'subtask_count': 5,
      };

      final summary = SessionSummary.fromJson(json);

      expect(summary.sessionId, 'session-2');
      expect(summary.instruction, 'Complete automation task');
      expect(summary.status, 'completed');
      expect(summary.createdAt, testCreatedAt);
      expect(summary.completedAt, testCompletedAt);
      expect(summary.subtaskCount, 5);
    });

    test('toJson serializes session summary without completion time', () {
      final summary = SessionSummary(
        sessionId: 'session-3',
        instruction: 'Test instruction',
        status: 'pending',
        createdAt: testCreatedAt,
        subtaskCount: 0,
      );

      final json = summary.toJson();

      expect(json['session_id'], 'session-3');
      expect(json['instruction'], 'Test instruction');
      expect(json['status'], 'pending');
      expect(json['created_at'], testCreatedAt.toIso8601String());
      expect(json['completed_at'], isNull);
      expect(json['subtask_count'], 0);
    });

    test('toJson serializes session summary with completion time', () {
      final summary = SessionSummary(
        sessionId: 'session-4',
        instruction: 'Completed task',
        status: 'completed',
        createdAt: testCreatedAt,
        completedAt: testCompletedAt,
        subtaskCount: 7,
      );

      final json = summary.toJson();

      expect(json['session_id'], 'session-4');
      expect(json['instruction'], 'Completed task');
      expect(json['status'], 'completed');
      expect(json['created_at'], testCreatedAt.toIso8601String());
      expect(json['completed_at'], testCompletedAt.toIso8601String());
      expect(json['subtask_count'], 7);
    });

    test('fromJson and toJson round trip without completion', () {
      final originalJson = {
        'session_id': 'session-5',
        'instruction': 'Round trip test',
        'status': 'in_progress',
        'created_at': testCreatedAt.toIso8601String(),
        'subtask_count': 2,
      };

      final summary = SessionSummary.fromJson(originalJson);
      final serializedJson = summary.toJson();

      expect(serializedJson['session_id'], originalJson['session_id']);
      expect(serializedJson['instruction'], originalJson['instruction']);
      expect(serializedJson['status'], originalJson['status']);
      expect(serializedJson['created_at'], originalJson['created_at']);
      expect(serializedJson['completed_at'], isNull);
      expect(serializedJson['subtask_count'], originalJson['subtask_count']);
    });

    test('fromJson and toJson round trip with completion', () {
      final originalJson = {
        'session_id': 'session-6',
        'instruction': 'Complete round trip',
        'status': 'completed',
        'created_at': testCreatedAt.toIso8601String(),
        'completed_at': testCompletedAt.toIso8601String(),
        'subtask_count': 10,
      };

      final summary = SessionSummary.fromJson(originalJson);
      final serializedJson = summary.toJson();

      expect(serializedJson['session_id'], originalJson['session_id']);
      expect(serializedJson['instruction'], originalJson['instruction']);
      expect(serializedJson['status'], originalJson['status']);
      expect(serializedJson['created_at'], originalJson['created_at']);
      expect(serializedJson['completed_at'], originalJson['completed_at']);
      expect(serializedJson['subtask_count'], originalJson['subtask_count']);
    });

    test('fromJson handles all status types', () {
      final statuses = ['pending', 'in_progress', 'completed', 'failed', 'cancelled'];

      for (final status in statuses) {
        final json = {
          'session_id': 'test',
          'instruction': 'Test',
          'status': status,
          'created_at': testCreatedAt.toIso8601String(),
          'subtask_count': 1,
        };

        final summary = SessionSummary.fromJson(json);
        expect(summary.status, status);
      }
    });

    test('fromJson handles zero subtask count', () {
      final json = {
        'session_id': 'session-7',
        'instruction': 'No subtasks yet',
        'status': 'pending',
        'created_at': testCreatedAt.toIso8601String(),
        'subtask_count': 0,
      };

      final summary = SessionSummary.fromJson(json);
      expect(summary.subtaskCount, 0);
    });

    test('fromJson handles large subtask count', () {
      final json = {
        'session_id': 'session-8',
        'instruction': 'Complex task',
        'status': 'completed',
        'created_at': testCreatedAt.toIso8601String(),
        'completed_at': testCompletedAt.toIso8601String(),
        'subtask_count': 100,
      };

      final summary = SessionSummary.fromJson(json);
      expect(summary.subtaskCount, 100);
    });

    test('fromJson handles long instruction text', () {
      final longInstruction = 'This is a very long instruction that contains '
          'multiple sentences and describes a complex automation task that '
          'involves many steps and requires detailed explanation of what '
          'needs to be accomplished during the execution process.';

      final json = {
        'session_id': 'session-9',
        'instruction': longInstruction,
        'status': 'completed',
        'created_at': testCreatedAt.toIso8601String(),
        'completed_at': testCompletedAt.toIso8601String(),
        'subtask_count': 15,
      };

      final summary = SessionSummary.fromJson(json);
      expect(summary.instruction, longInstruction);
      expect(summary.instruction.length, greaterThan(100));
    });

    test('fromJson handles special characters in instruction', () {
      final specialInstruction = 'Test with "quotes", \'apostrophes\', '
          'and special chars: @#\$%^&*()';

      final json = {
        'session_id': 'session-10',
        'instruction': specialInstruction,
        'status': 'completed',
        'created_at': testCreatedAt.toIso8601String(),
        'completed_at': testCompletedAt.toIso8601String(),
        'subtask_count': 1,
      };

      final summary = SessionSummary.fromJson(json);
      expect(summary.instruction, specialInstruction);
    });

    test('fromJson handles null completed_at field explicitly', () {
      final json = {
        'session_id': 'session-11',
        'instruction': 'In progress task',
        'status': 'in_progress',
        'created_at': testCreatedAt.toIso8601String(),
        'completed_at': null,
        'subtask_count': 3,
      };

      final summary = SessionSummary.fromJson(json);
      expect(summary.completedAt, isNull);
    });

    test('fromJson handles failed status with completion time', () {
      final json = {
        'session_id': 'session-12',
        'instruction': 'Failed task',
        'status': 'failed',
        'created_at': testCreatedAt.toIso8601String(),
        'completed_at': testCompletedAt.toIso8601String(),
        'subtask_count': 4,
      };

      final summary = SessionSummary.fromJson(json);
      expect(summary.status, 'failed');
      expect(summary.completedAt, testCompletedAt);
    });

    test('fromJson handles cancelled status with completion time', () {
      final json = {
        'session_id': 'session-13',
        'instruction': 'Cancelled task',
        'status': 'cancelled',
        'created_at': testCreatedAt.toIso8601String(),
        'completed_at': testCompletedAt.toIso8601String(),
        'subtask_count': 2,
      };

      final summary = SessionSummary.fromJson(json);
      expect(summary.status, 'cancelled');
      expect(summary.completedAt, testCompletedAt);
    });
  });
}
