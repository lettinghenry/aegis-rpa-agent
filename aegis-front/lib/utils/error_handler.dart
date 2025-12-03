import 'package:flutter/material.dart';
import '../services/backend_api_service.dart';

/// Utility class for handling errors and displaying user-friendly messages
/// 
/// Provides consistent error message formatting and display methods
/// across the application.
/// 
/// Validates: Requirements 7.1, 7.3, 7.4, 10.4
class ErrorHandler {
  /// Format an error into a user-friendly message
  /// 
  /// Categorizes errors and returns appropriate messages:
  /// - Network errors: Connection issues
  /// - Backend offline: Service unavailable
  /// - Validation errors: Specific validation message
  /// - Unknown errors: Generic fallback message
  static String formatErrorMessage(dynamic error) {
    final errorStr = error.toString();

    // Network errors
    if (error is NetworkException) {
      return error.message;
    }

    if (errorStr.contains('SocketException') ||
        errorStr.contains('Connection refused') ||
        errorStr.contains('Failed host lookup')) {
      return 'Unable to connect. Please check your internet connection.';
    }

    if (errorStr.contains('TimeoutException') ||
        errorStr.contains('timed out')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // Backend offline
    if (error is ApiException && error.statusCode != null) {
      if (error.statusCode! >= 500) {
        return 'The automation service is currently offline. Please try again later.';
      }
      if (error.statusCode == 404) {
        return 'Resource not found.';
      }
    }

    if (errorStr.contains('offline') || errorStr.contains('unreachable')) {
      return 'The automation service is currently offline. Please try again later.';
    }

    // Validation errors
    if (error is ValidationException) {
      return error.message;
    }

    if (errorStr.contains('ValidationException')) {
      return errorStr.replaceAll('ValidationException:', '').trim();
    }

    // API errors with details
    if (error is ApiException) {
      return error.message;
    }

    // Generic fallback
    return 'Something went wrong. Please try again.';
  }

  /// Show a SnackBar with an error message
  /// 
  /// Displays a transient error message at the bottom of the screen.
  /// Suitable for non-critical errors that don't require user action.
  /// 
  /// Validates: Requirements 10.4
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = formatErrorMessage(error);
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.errorContainer,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: colorScheme.onErrorContainer,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show an error dialog
  /// 
  /// Displays a modal dialog with an error message and action buttons.
  /// Suitable for critical errors that require user acknowledgment.
  /// 
  /// Validates: Requirements 10.4
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String title = 'Error',
    VoidCallback? onRetry,
  }) async {
    final message = formatErrorMessage(error);
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: colorScheme.error,
          size: 48,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Build an inline error widget
  /// 
  /// Returns a widget that displays an error message inline with other content.
  /// Suitable for form validation errors or section-specific errors.
  /// 
  /// Validates: Requirements 10.4
  static Widget buildInlineError(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: colorScheme.onErrorContainer,
              ),
              onPressed: onRetry,
              tooltip: 'Retry',
            ),
          ],
        ],
      ),
    );
  }

  /// Build a full-screen error widget
  /// 
  /// Returns a widget that displays an error message in the center of the screen.
  /// Suitable for errors that prevent the entire screen from loading.
  /// 
  /// Validates: Requirements 10.4
  static Widget buildFullScreenError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    final message = formatErrorMessage(error);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
