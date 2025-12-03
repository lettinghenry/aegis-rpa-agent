import 'subtask.dart';
import '../utils/json_parser.dart';

/// Status update model for WebSocket messages
class StatusUpdate {
  final String sessionId;
  final Subtask? subtask;
  final String overallStatus;
  final String message;
  final String? windowState;
  final DateTime timestamp;

  StatusUpdate({
    required this.sessionId,
    this.subtask,
    required this.overallStatus,
    required this.message,
    this.windowState,
    required this.timestamp,
  });

  /// Create StatusUpdate from JSON with error handling
  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    try {
      Subtask? parsedSubtask;
      final subtaskJson = JsonParser.parseOptionalMap(json, 'subtask');
      if (subtaskJson != null) {
        try {
          parsedSubtask = Subtask.fromJson(subtaskJson);
        } catch (e) {
          // Log error but continue - subtask is optional
          print('Warning: Failed to parse subtask in StatusUpdate: $e');
        }
      }

      return StatusUpdate(
        sessionId: JsonParser.parseString(json, 'session_id'),
        subtask: parsedSubtask,
        overallStatus: JsonParser.parseString(json, 'overall_status'),
        message: JsonParser.parseString(json, 'message'),
        windowState: JsonParser.parseOptionalString(json, 'window_state'),
        timestamp: JsonParser.parseDateTime(json, 'timestamp'),
      );
    } catch (e) {
      throw ParsingException(
        'Failed to parse StatusUpdate',
        originalError: e,
      );
    }
  }

  /// Convert StatusUpdate to JSON
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'subtask': subtask?.toJson(),
      'overall_status': overallStatus,
      'message': message,
      'window_state': windowState,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
