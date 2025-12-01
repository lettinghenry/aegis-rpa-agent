/// Subtask status enumeration
enum SubtaskStatus {
  pending,
  inProgress,
  completed,
  failed;

  /// Convert string to SubtaskStatus enum
  static SubtaskStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return SubtaskStatus.pending;
      case 'in_progress':
        return SubtaskStatus.inProgress;
      case 'completed':
        return SubtaskStatus.completed;
      case 'failed':
        return SubtaskStatus.failed;
      default:
        throw ArgumentError('Invalid subtask status: $value');
    }
  }

  /// Convert SubtaskStatus enum to string
  String toJsonString() {
    switch (this) {
      case SubtaskStatus.pending:
        return 'pending';
      case SubtaskStatus.inProgress:
        return 'in_progress';
      case SubtaskStatus.completed:
        return 'completed';
      case SubtaskStatus.failed:
        return 'failed';
    }
  }
}

/// Subtask model representing a single step in execution
class Subtask {
  final String id;
  final String description;
  final SubtaskStatus status;
  final String? toolName;
  final Map<String, dynamic>? toolArgs;
  final Map<String, dynamic>? result;
  final String? error;
  final DateTime timestamp;

  Subtask({
    required this.id,
    required this.description,
    required this.status,
    this.toolName,
    this.toolArgs,
    this.result,
    this.error,
    required this.timestamp,
  });

  /// Create Subtask from JSON
  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as String,
      description: json['description'] as String,
      status: SubtaskStatus.fromString(json['status'] as String),
      toolName: json['tool_name'] as String?,
      toolArgs: json['tool_args'] as Map<String, dynamic>?,
      result: json['result'] as Map<String, dynamic>?,
      error: json['error'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert Subtask to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'status': status.toJsonString(),
      'tool_name': toolName,
      'tool_args': toolArgs,
      'result': result,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
