import 'subtask.dart';

/// Session status enumeration
enum SessionStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled;

  /// Convert string to SessionStatus enum
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
        throw ArgumentError('Invalid session status: $value');
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

  /// Create ExecutionSession from JSON
  factory ExecutionSession.fromJson(Map<String, dynamic> json) {
    return ExecutionSession(
      sessionId: json['session_id'] as String,
      instruction: json['instruction'] as String,
      status: SessionStatus.fromString(json['status'] as String),
      subtasks: (json['subtasks'] as List<dynamic>)
          .map((s) => Subtask.fromJson(s as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
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
