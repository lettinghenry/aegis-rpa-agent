import '../utils/json_parser.dart';

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

  /// Create ErrorResponse from JSON with error handling
  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    try {
      return ErrorResponse(
        error: JsonParser.parseString(json, 'error'),
        details: JsonParser.parseOptionalString(json, 'details'),
        sessionId: JsonParser.parseOptionalString(json, 'session_id'),
      );
    } catch (e) {
      throw ParsingException(
        'Failed to parse ErrorResponse',
        originalError: e,
      );
    }
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
