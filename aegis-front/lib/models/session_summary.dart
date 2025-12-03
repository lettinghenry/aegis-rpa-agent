import '../utils/json_parser.dart';

/// Session summary model for history display
class SessionSummary {
  final String sessionId;
  final String instruction;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int subtaskCount;

  SessionSummary({
    required this.sessionId,
    required this.instruction,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.subtaskCount,
  });

  /// Create SessionSummary from JSON with error handling
  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    try {
      return SessionSummary(
        sessionId: JsonParser.parseString(json, 'session_id'),
        instruction: JsonParser.parseString(json, 'instruction'),
        status: JsonParser.parseString(json, 'status'),
        createdAt: JsonParser.parseDateTime(json, 'created_at'),
        completedAt: JsonParser.parseOptionalDateTime(json, 'completed_at'),
        subtaskCount: JsonParser.parseInt(json, 'subtask_count', defaultValue: 0),
      );
    } catch (e) {
      throw ParsingException(
        'Failed to parse SessionSummary',
        originalError: e,
      );
    }
  }

  /// Convert SessionSummary to JSON
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'instruction': instruction,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'subtask_count': subtaskCount,
    };
  }
}

/// History response model
class HistoryResponse {
  final List<SessionSummary> sessions;
  final int total;

  HistoryResponse({
    required this.sessions,
    required this.total,
  });

  /// Create HistoryResponse from JSON with error handling
  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    try {
      return HistoryResponse(
        sessions: JsonParser.parseList(
          json,
          'sessions',
          (item) => SessionSummary.fromJson(item as Map<String, dynamic>),
          defaultValue: [],
        ),
        total: JsonParser.parseInt(json, 'total', defaultValue: 0),
      );
    } catch (e) {
      throw ParsingException(
        'Failed to parse HistoryResponse',
        originalError: e,
      );
    }
  }

  /// Convert HistoryResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'total': total,
    };
  }
}
