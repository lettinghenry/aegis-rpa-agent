import 'subtask.dart';
import '../utils/json_parser.dart';

/// Session status enumeration
enum SessionStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled;

  /// Convert string to SessionStatus enum with error handling
  static SessionStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return SessionStatus.pending;
      case 'in_progress':
        return SessionStatus.inProgress;
      case 'completed':
        return SessionStatus.completed;
      case 'failed':
        return SessionStatus.failed;
      case 'cancelled':
        return SessionStatus.cancelled;
      default:
        // Default to pending for unknown status values
        return SessionStatus.pending;
    }
  }

  /// Convert SessionStatus enum to string
  String toJsonString() {
    switch (this) {
      case SessionStatus.pending:
        return 'pending';
      case SessionStatus.inProgress:
        return 'in_progress';
      case SessionStatus.completed:
        return 'completed';
      case SessionStatus.failed:
        return 'failed';
      case SessionStatus.cancelled:
        return 'cancelled';
    }
  }
}

/// Execution session model representing a complete automation run
class ExecutionSession {
  final String sessionId;
  final String instruction;
  final SessionStatus status;
  final List<Subtask> subtasks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  ExecutionSession({
    required this.sessionId,
    required this.instruction,
    required this.status,
    required this.subtasks,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  /// Create ExecutionSession from JSON with error handling
  factory ExecutionSession.fromJson(Map<String, dynamic> json) {
    try {
      return ExecutionSession(
        sessionId: JsonParser.parseString(json, 'session_id'),
        instruction: JsonParser.parseString(json, 'instruction'),
        status: SessionStatus.fromString(
          JsonParser.parseString(json, 'status'),
        ),
        subtasks: JsonParser.parseList(
          json,
          'subtasks',
          (item) => Subtask.fromJson(item as Map<String, dynamic>),
          defaultValue: [],
        ),
        createdAt: JsonParser.parseDateTime(json, 'created_at'),
        updatedAt: JsonParser.parseDateTime(json, 'updated_at'),
        completedAt: JsonParser.parseOptionalDateTime(json, 'completed_at'),
      );
    } catch (e) {
      throw ParsingException(
        'Failed to parse ExecutionSession',
        originalError: e,
      );
    }
  }

  /// Convert ExecutionSession to JSON
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'instruction': instruction,
      'status': status.toJsonString(),
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
