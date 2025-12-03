import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/utils/error_handler.dart';
import 'package:aegis_front/services/backend_api_service.dart';

void main() {
  group('ErrorHandler', () {
    group('formatErrorMessage', () {
      test('formats NetworkException correctly', () {
        final error = NetworkException('Connection failed');
        final message = ErrorHandler.formatErrorMessage(error);
        expect(message, equals('Connection failed'));
      });

      test('formats SocketException correctly', () {
        final error = Exception('SocketException: Connection refused');
        final message = ErrorHandler.formatErrorMessage(error);
        expect(
          message,
          equals('Unable to connect. Please check your internet connection.'),
        );
      });

      test('formats TimeoutException correctly', () {
        final error = Exception('TimeoutException: Request timed out');
        final message = ErrorHandler.formatErrorMessage(error);
        expect(
          message,
          contains('timed out'),
        );
      });

      test('formats ValidationException correctly', () {
        final error = ValidationException('Invalid input');
        final message = ErrorHandler.formatErrorMessage(error);
        expect(message, equals('Invalid input'));
      });

      test('formats ApiException with 500 status correctly', () {
        final error = ApiException('Server error', statusCode: 500);
        final message = ErrorHandler.formatErrorMessage(error);
        expect(
          message,
          equals(
            'The automation service is currently offline. Please try again later.',
          ),
        );
      });

      test('formats ApiException with 404 status correctly', () {
        final error = ApiException('Not found', statusCode: 404);
        final message = ErrorHandler.formatErrorMessage(error);
        expect(message, equals('Resource not found.'));
      });

      test('formats unknown errors with generic message', () {
        final error = Exception('Unknown error');
        final message = ErrorHandler.formatErrorMessage(error);
        expect(message, equals('Something went wrong. Please try again.'));
      });
    });
  });
}
