import '../utils/json_parser.dart';

/// Task instruction request model
class TaskInstructionRequest {
  final String instruction;

  TaskInstructionRequest({required this.instruction});

  /// Convert TaskInstructionRequest to JSON
  Map<String, dynamic> toJson() {
    return {
      'instruction': instruction,
    };
  }
}

/// Task instruction response model
class TaskInstructionResponse {
  final String sessionId;
  final String status;
  final String message;

  TaskInstructionResponse({
    required this.sessionId,
    required this.status,
    required this.message,
  });

  /// Create TaskInstructionResponse from JSON with error handling
  factory TaskInstructionResponse.fromJson(Map<String, dynamic> json) {
    try {
      return TaskInstructionResponse(
        sessionId: JsonParser.parseString(json, 'session_id'),
        status: JsonParser.parseString(json, 'status'),
        message: JsonParser.parseString(json, 'message'),
      );
    } catch (e) {
      throw ParsingException(
        'Failed to parse TaskInstructionResponse',
        originalError: e,
      );
    }
  }

  /// Convert TaskInstructionResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'status': status,
      'message': message,
    };
  }
}
