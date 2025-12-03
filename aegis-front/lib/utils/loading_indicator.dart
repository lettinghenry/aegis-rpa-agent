import 'package:flutter/material.dart';

/// Utility class for displaying loading indicators
/// 
/// Provides consistent loading indicator widgets and overlays
/// across the application.
/// 
/// Validates: Requirements 10.1, 10.3
class LoadingIndicator {
  /// Build a centered loading indicator
  /// 
  /// Returns a widget that displays a circular progress indicator
  /// in the center of the available space.
  /// 
  /// Validates: Requirements 10.3
  static Widget buildCentered(
    BuildContext context, {
    String? message,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build a small inline loading indicator
  /// 
  /// Returns a small circular progress indicator suitable for
  /// displaying inline with other content (e.g., in buttons).
  /// 
  /// Validates: Requirements 10.1
  static Widget buildSmall(
    BuildContext context, {
    Color? color,
    double size = 20,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? colorScheme.onPrimary,
        ),
      ),
    );
  }

  /// Build a loading overlay
  /// 
  /// Returns a semi-transparent overlay with a loading indicator
  /// that can be placed on top of other content.
  /// 
  /// Validates: Requirements 10.3
  static Widget buildOverlay(
    BuildContext context, {
    String? message,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface.withValues(alpha: 0.8),
      child: Center(
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show a loading dialog
  /// 
  /// Displays a modal dialog with a loading indicator.
  /// Suitable for blocking operations that require user to wait.
  /// 
  /// Returns a function that can be called to dismiss the dialog.
  /// 
  /// Validates: Requirements 10.3
  static VoidCallback showLoadingDialog(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => PopScope(
        canPop: barrierDismissible,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message),
              ],
            ],
          ),
        ),
      ),
    );

    return () {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    };
  }
}
