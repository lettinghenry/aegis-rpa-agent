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

  /// Create TaskInstructionResponse from JSON
  factory TaskInstructionResponse.fromJson(Map<String, dynamic> json) {
    return TaskInstructionResponse(
      sessionId: json['session_id'] as String,
      status: json['status'] as String,
      message: json['message'] as String,
    );
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
