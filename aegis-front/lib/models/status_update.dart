import 'subtask.dart';

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

  /// Create StatusUpdate from JSON
  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    return StatusUpdate(
      sessionId: json['session_id'] as String,
      subtask: json['subtask'] != null
          ? Subtask.fromJson(json['subtask'] as Map<String, dynamic>)
          : null,
      overallStatus: json['overall_status'] as String,
      message: json['message'] as String,
      windowState: json['window_state'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
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
