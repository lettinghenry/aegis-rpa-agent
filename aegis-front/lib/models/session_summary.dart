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

  /// Create SessionSummary from JSON
  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      sessionId: json['session_id'] as String,
      instruction: json['instruction'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      subtaskCount: json['subtask_count'] as int,
    );
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

  /// Create HistoryResponse from JSON
  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    return HistoryResponse(
      sessions: (json['sessions'] as List<dynamic>)
          .map((s) => SessionSummary.fromJson(s as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }

  /// Convert HistoryResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'total': total,
    };
  }
}
