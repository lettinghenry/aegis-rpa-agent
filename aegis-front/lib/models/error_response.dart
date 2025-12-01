/// Error response model for API errors
class ErrorResponse {
  final String error;
  final String? details;
  final String? sessionId;

  ErrorResponse({
    required this.error,
    this.details,
    this.sessionId,
  });

  /// Create ErrorResponse from JSON
  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      error: json['error'] as String,
      details: json['details'] as String?,
      sessionId: json['session_id'] as String?,
    );
  }

  /// Convert ErrorResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'details': details,
      'session_id': sessionId,
    };
  }
}
