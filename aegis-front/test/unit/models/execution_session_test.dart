import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/models/execution_session.dart';
import 'package:aegis_front/models/subtask.dart';

void main() {
  group('SessionStatus', () {
    test('fromString converts valid status strings', () {
      expect(SessionStatus.fromString('pending'), SessionStatus.pending);
      expect(SessionStatus.fromString('in_progress'), SessionStatus.inProgress);
      expect(SessionStatus.fromString('completed'), SessionStatus.completed);
      expect(SessionStatus.fromString('failed'), SessionStatus.failed);
      expect(SessionStatus.fromString('cancelled'), SessionStatus.cancelled);
    });

    test('fromString returns pending for invalid status', () {
      // With error handling, invalid status defaults to pending
      expect(
        SessionStatus.fromString('invalid'),
        SessionStatus.pending,
      );
    });

    test('toString returns correct string representation', () {
      expect(SessionStatus.pending.toString(), 'SessionStatus.pending');
      expect(SessionStatus.inProgress.toString(), 'SessionStatus.inProgress');
      expect(SessionStatus.completed.toString(), 'SessionStatus.completed');
      expect(SessionStatus.failed.toString(), 'SessionStatus.failed');
      expect(SessionStatus.cancelled.toString(), 'SessionStatus.cancelled');
    });
  });

  group('ExecutionSession', () {
    final testCreatedAt = DateTime(2024, 12, 1, 10, 0, 0);
    final testUpdatedAt = DateTime(2024, 12, 1, 10, 30, 0);
    final testCompletedAt = DateTime(2024, 12, 1, 10, 45, 0);

    test('fromJson deserializes session without completion time', () {
      final json = {
        'session_id': 'session-1',
        'instruction': 'Open Chrome',
        'status': 'in_progress',
        'subtasks': [],
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
      };

      final session = ExecutionSession.fromJson(json);

      expect(session.sessionId, 'session-1');
      expect(session.instruction, 'Open Chrome');
      expect(session.status, SessionStatus.inProgress);
      expect(session.subtasks, isEmpty);
      expect(session.createdAt, testCreatedAt);
      expect(session.updatedAt, testUpdatedAt);
      expect(session.completedAt, isNull);
    });

    test('fromJson deserializes session with completion time', () {
      final json = {
        'session_id': 'session-2',
        'instruction': 'Complete task',
        'status': 'completed',
        'subtasks': [],
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
        'completed_at': testCompletedAt.toIso8601String(),
      };

      final session = ExecutionSession.fromJson(json);

      expect(session.sessionId, 'session-2');
      expect(session.status, SessionStatus.completed);
      expect(session.completedAt, testCompletedAt);
    });

    test('fromJson deserializes session with subtasks', () {
      final json = {
        'session_id': 'session-3',
        'instruction': 'Multi-step task',
        'status': 'completed',
        'subtasks': [
          {
            'id': 'subtask-1',
            'description': 'Step 1',
            'status': 'completed',
            'timestamp': testCreatedAt.toIso8601String(),
          },
          {
            'id': 'subtask-2',
            'description': 'Step 2',
            'status': 'completed',
            'timestamp': testUpdatedAt.toIso8601String(),
          },
        ],
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
        'completed_at': testCompletedAt.toIso8601String(),
      };

      final session = ExecutionSession.fromJson(json);

      expect(session.subtasks.length, 2);
      expect(session.subtasks[0].id, 'subtask-1');
      expect(session.subtasks[0].description, 'Step 1');
      expect(session.subtasks[1].id, 'subtask-2');
      expect(session.subtasks[1].description, 'Step 2');
    });

    test('toJson serializes session without completion time', () {
      final session = ExecutionSession(
        sessionId: 'session-4',
        instruction: 'Test instruction',
        status: SessionStatus.pending,
        subtasks: [],
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      final json = session.toJson();

      expect(json['session_id'], 'session-4');
      expect(json['instruction'], 'Test instruction');
      expect(json['status'], 'pending');
      expect(json['subtasks'], isEmpty);
      expect(json['created_at'], testCreatedAt.toIso8601String());
      expect(json['updated_at'], testUpdatedAt.toIso8601String());
      expect(json['completed_at'], isNull);
    });

    test('toJson serializes session with completion time', () {
      final session = ExecutionSession(
        sessionId: 'session-5',
        instruction: 'Completed task',
        status: SessionStatus.completed,
        subtasks: [],
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
        completedAt: testCompletedAt,
      );

      final json = session.toJson();

      expect(json['completed_at'], testCompletedAt.toIso8601String());
    });

    test('toJson serializes session with subtasks', () {
      final subtask1 = Subtask(
        id: 'subtask-1',
        description: 'First step',
        status: SubtaskStatus.completed,
        timestamp: testCreatedAt,
      );

      final subtask2 = Subtask(
        id: 'subtask-2',
        description: 'Second step',
        status: SubtaskStatus.inProgress,
        timestamp: testUpdatedAt,
      );

      final session = ExecutionSession(
        sessionId: 'session-6',
        instruction: 'Multi-step task',
        status: SessionStatus.inProgress,
        subtasks: [subtask1, subtask2],
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      final json = session.toJson();

      expect(json['subtasks'].length, 2);
      expect(json['subtasks'][0]['id'], 'subtask-1');
      expect(json['subtasks'][1]['id'], 'subtask-2');
    });

    test('fromJson and toJson round trip without completion', () {
      final originalJson = {
        'session_id': 'session-7',
        'instruction': 'Round trip test',
        'status': 'in_progress',
        'subtasks': [
          {
            'id': 'subtask-1',
            'description': 'Test subtask',
            'status': 'completed',
            'timestamp': testCreatedAt.toIso8601String(),
          }
        ],
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
      };

      final session = ExecutionSession.fromJson(originalJson);
      final serializedJson = session.toJson();

      expect(serializedJson['session_id'], originalJson['session_id']);
      expect(serializedJson['instruction'], originalJson['instruction']);
      expect(serializedJson['status'], originalJson['status']);
      expect(serializedJson['subtasks'].length, 1);
      expect(serializedJson['created_at'], originalJson['created_at']);
      expect(serializedJson['updated_at'], originalJson['updated_at']);
      expect(serializedJson['completed_at'], isNull);
    });

    test('fromJson and toJson round trip with completion', () {
      final originalJson = {
        'session_id': 'session-8',
        'instruction': 'Complete round trip',
        'status': 'completed',
        'subtasks': [],
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
        'completed_at': testCompletedAt.toIso8601String(),
      };

      final session = ExecutionSession.fromJson(originalJson);
      final serializedJson = session.toJson();

      expect(serializedJson['session_id'], originalJson['session_id']);
      expect(serializedJson['completed_at'], originalJson['completed_at']);
    });

    test('fromJson handles all status types', () {
      final statuses = ['pending', 'in_progress', 'completed', 'failed', 'cancelled'];

      for (final status in statuses) {
        final json = {
          'session_id': 'test',
          'instruction': 'Test',
          'status': status,
          'subtasks': [],
          'created_at': testCreatedAt.toIso8601String(),
          'updated_at': testUpdatedAt.toIso8601String(),
        };

        final session = ExecutionSession.fromJson(json);
        expect(session.status, SessionStatus.fromString(status));
      }
    });

    test('fromJson handles empty subtasks list', () {
      final json = {
        'session_id': 'session-9',
        'instruction': 'No subtasks',
        'status': 'pending',
        'subtasks': [],
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
      };

      final session = ExecutionSession.fromJson(json);
      expect(session.subtasks, isEmpty);
    });

    test('fromJson handles multiple subtasks with different statuses', () {
      final json = {
        'session_id': 'session-10',
        'instruction': 'Mixed status subtasks',
        'status': 'in_progress',
        'subtasks': [
          {
            'id': 'subtask-1',
            'description': 'Completed step',
            'status': 'completed',
            'timestamp': testCreatedAt.toIso8601String(),
          },
          {
            'id': 'subtask-2',
            'description': 'In progress step',
            'status': 'in_progress',
            'timestamp': testUpdatedAt.toIso8601String(),
          },
          {
            'id': 'subtask-3',
            'description': 'Pending step',
            'status': 'pending',
            'timestamp': testUpdatedAt.toIso8601String(),
          },
        ],
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
      };

      final session = ExecutionSession.fromJson(json);

      expect(session.subtasks.length, 3);
      expect(session.subtasks[0].status, SubtaskStatus.completed);
      expect(session.subtasks[1].status, SubtaskStatus.inProgress);
      expect(session.subtasks[2].status, SubtaskStatus.pending);
    });
  });
}
