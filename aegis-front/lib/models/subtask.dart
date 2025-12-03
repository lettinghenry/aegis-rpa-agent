import '../utils/json_parser.dart';

/// Subtask status enumeration
enum SubtaskStatus {
  pending,
  inProgress,
  completed,
  failed;

  /// Convert string to SubtaskStatus enum with error handling
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
        // Default to pending for unknown status values
        return SubtaskStatus.pending;
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

  /// Create Subtask from JSON with error handling
  factory Subtask.fromJson(Map<String, dynamic> json) {
    try {
      return Subtask(
        id: JsonParser.parseString(json, 'id'),
        description: JsonParser.parseString(json, 'description'),
        status: SubtaskStatus.fromString(
          JsonParser.parseString(json, 'status'),
        ),
        toolName: JsonParser.parseOptionalString(json, 'tool_name'),
        toolArgs: JsonParser.parseOptionalMap(json, 'tool_args'),
        result: JsonParser.parseOptionalMap(json, 'result'),
        error: JsonParser.parseOptionalString(json, 'error'),
        timestamp: JsonParser.parseDateTime(json, 'timestamp'),
      );
    } catch (e) {
      throw ParsingException(
        'Failed to parse Subtask',
        originalError: e,
      );
    }
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
