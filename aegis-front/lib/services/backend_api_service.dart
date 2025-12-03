import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/task_instruction.dart';
import '../models/execution_session.dart';
import '../models/session_summary.dart';
import '../models/error_response.dart';
import '../utils/json_parser.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() {
    if (details != null) {
      return 'ApiException: $message (Status: $statusCode) - $details';
    }
    return 'ApiException: $message (Status: $statusCode)';
  }
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  final String message;
  final dynamic details;

  ValidationException(this.message, {this.details});

  @override
  String toString() => 'ValidationException: $message';
}

/// Custom exception for network errors
class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Backend API service for HTTP communication with AEGIS Backend
class BackendApiService {
  final http.Client _client;
  final String _baseUrl;

  /// Create a BackendApiService with optional custom client and base URL
  BackendApiService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.backendUrl;

  /// Start a new task execution
  ///
  /// Sends a POST request to /api/start_task with the task instruction.
  /// Returns a [TaskInstructionResponse] containing the session ID.
  ///
  /// Throws:
  /// - [ValidationException] if the instruction is invalid (422)
  /// - [ApiException] for other API errors
  /// - [NetworkException] for network connectivity issues
  /// - [TimeoutException] if the request times out
  Future<TaskInstructionResponse> startTask(String instruction) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/start_task');
      final request = TaskInstructionRequest(instruction: instruction);

      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(AppConfig.requestTimeout);

      return _handleResponse<TaskInstructionResponse>(
        response,
        (json) => TaskInstructionResponse.fromJson(json),
      );
    } on SocketException catch (e) {
      throw NetworkException(
          'Unable to connect to backend. Please check your internet connection.');
    } on TimeoutException {
      throw NetworkException(
          'Request timed out. Please check your connection and try again.');
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    }
  }

  /// Get execution history
  ///
  /// Sends a GET request to /api/history to retrieve past execution sessions.
  /// Returns a [HistoryResponse] containing the list of sessions.
  ///
  /// Throws:
  /// - [ApiException] for API errors
  /// - [NetworkException] for network connectivity issues
  /// - [TimeoutException] if the request times out
  Future<HistoryResponse> getHistory() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/history');

      final response = await _client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(AppConfig.requestTimeout);

      return _handleResponse<HistoryResponse>(
        response,
        (json) => HistoryResponse.fromJson(json),
      );
    } on SocketException catch (e) {
      throw NetworkException(
          'Unable to connect to backend. Please check your internet connection.');
    } on TimeoutException {
      throw NetworkException(
          'Request timed out. Please check your connection and try again.');
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    }
  }

  /// Get session details
  ///
  /// Sends a GET request to /api/history/{session_id} to retrieve
  /// complete details of a specific execution session.
  /// Returns an [ExecutionSession] with all subtasks and results.
  ///
  /// Throws:
  /// - [ApiException] for API errors (including 404 if session not found)
  /// - [NetworkException] for network connectivity issues
  /// - [TimeoutException] if the request times out
  Future<ExecutionSession> getSessionDetails(String sessionId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/history/$sessionId');

      final response = await _client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(AppConfig.requestTimeout);

      return _handleResponse<ExecutionSession>(
        response,
        (json) => ExecutionSession.fromJson(json),
      );
    } on SocketException catch (e) {
      throw NetworkException(
          'Unable to connect to backend. Please check your internet connection.');
    } on TimeoutException {
      throw NetworkException(
          'Request timed out. Please check your connection and try again.');
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    }
  }

  /// Cancel an ongoing execution session
  ///
  /// Sends a DELETE request to /api/execution/{session_id} to cancel
  /// the specified execution session.
  ///
  /// Throws:
  /// - [ApiException] for API errors (including 404 if session not found)
  /// - [NetworkException] for network connectivity issues
  /// - [TimeoutException] if the request times out
  Future<void> cancelSession(String sessionId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/execution/$sessionId');

      final response = await _client
          .delete(
            uri,
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        return;
      }

      // Handle error responses
      _handleErrorResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
          'Unable to connect to backend. Please check your internet connection.');
    } on TimeoutException {
      throw NetworkException(
          'Request timed out. Please check your connection and try again.');
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    }
  }

  /// Handle HTTP response and parse JSON
  T _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return fromJson(json);
      } on FormatException catch (e) {
        // Invalid JSON format
        developer.log(
          'Invalid JSON in response: ${response.body}',
          name: 'BackendApiService',
          error: e,
        );
        throw ApiException(
          'Received invalid data from server. Please try again.',
          statusCode: response.statusCode,
          details: 'Invalid JSON format',
        );
      } on ParsingException catch (e) {
        // Model parsing error
        developer.log(
          'Failed to parse response model: $e',
          name: 'BackendApiService',
          error: e,
        );
        throw ApiException(
          'Received unexpected data from server. Please try again.',
          statusCode: response.statusCode,
          details: e.toString(),
        );
      } catch (e) {
        // Unknown parsing error
        developer.log(
          'Unexpected error parsing response: $e',
          name: 'BackendApiService',
          error: e,
        );
        throw ApiException(
          'Failed to process server response. Please try again.',
          statusCode: response.statusCode,
          details: e.toString(),
        );
      }
    }

    _handleErrorResponse(response);
  }

  /// Handle error responses from the backend
  Never _handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;

    // Try to parse error response
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (statusCode == 422) {
        // Validation error
        final errorMsg = json['detail'] ?? 'Validation error';
        throw ValidationException(
          errorMsg is String ? errorMsg : 'Validation error',
          details: json['detail'],
        );
      }

      // Try to parse as ErrorResponse
      try {
        final errorResponse = ErrorResponse.fromJson(json);
        throw ApiException(
          errorResponse.error,
          statusCode: statusCode,
          details: errorResponse.details,
        );
      } on ParsingException catch (e) {
        // Failed to parse ErrorResponse, try generic fields
        developer.log(
          'Failed to parse error response: $e',
          name: 'BackendApiService',
          error: e,
        );
        final errorMsg = json['error'] ?? json['detail'] ?? 'Unknown error';
        throw ApiException(
          errorMsg is String ? errorMsg : 'Unknown error',
          statusCode: statusCode,
        );
      }
    } on FormatException catch (e) {
      // Invalid JSON in error response
      developer.log(
        'Invalid JSON in error response: ${response.body}',
        name: 'BackendApiService',
        error: e,
      );
      // Fall through to generic error handling
    } catch (e) {
      if (e is ValidationException || e is ApiException) {
        rethrow;
      }
      // Log unexpected error
      developer.log(
        'Unexpected error parsing error response: $e',
        name: 'BackendApiService',
        error: e,
      );
    }

    // If we can't parse the error, provide a generic message based on status code
    if (statusCode == 404) {
      throw ApiException(
        'Resource not found',
        statusCode: statusCode,
      );
    } else if (statusCode == 500) {
      throw ApiException(
        'Internal server error. Please try again later.',
        statusCode: statusCode,
      );
    } else if (statusCode >= 500) {
      throw ApiException(
        'The automation service is currently offline. Please try again later.',
        statusCode: statusCode,
      );
    } else {
      throw ApiException(
        'Request failed with status $statusCode',
        statusCode: statusCode,
      );
    }
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}
