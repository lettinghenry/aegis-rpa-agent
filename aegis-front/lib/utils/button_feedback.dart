import 'package:flutter/material.dart';

/// Utility class for button visual feedback
/// 
/// Provides consistent button styling and feedback behavior
/// across the application.
/// 
/// Validates: Requirements 8.3, 10.2, 10.5
class ButtonFeedback {
  /// Build a primary button with loading state support
  /// 
  /// Returns a FilledButton that:
  /// - Shows a loading indicator when isLoading is true
  /// - Is disabled when isLoading is true or onPressed is null
  /// - Provides Material 3 ripple effects
  /// 
  /// Validates: Requirements 8.3, 10.1, 10.2, 10.5
  static Widget buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double height = 56,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return SizedBox(
          width: width,
          height: height,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                : icon != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
          ),
        );
      },
    );
  }

  /// Build a secondary button with loading state support
  /// 
  /// Returns an OutlinedButton that:
  /// - Shows a loading indicator when isLoading is true
  /// - Is disabled when isLoading is true or onPressed is null
  /// - Provides Material 3 ripple effects
  /// 
  /// Validates: Requirements 8.3, 10.2, 10.5
  static Widget buildSecondaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
    double height = 56,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return SizedBox(
          width: width,
          height: height,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  )
                : icon != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
          ),
        );
      },
    );
  }

  /// Build a text button with loading state support
  /// 
  /// Returns a TextButton that:
  /// - Shows a loading indicator when isLoading is true
  /// - Is disabled when isLoading is true or onPressed is null
  /// - Provides Material 3 ripple effects
  /// 
  /// Validates: Requirements 8.3, 10.2, 10.5
  static Widget buildTextButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                )
              : icon != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon),
                        const SizedBox(width: 8),
                        Text(label),
                      ],
                    )
                  : Text(label),
        );
      },
    );
  }

  /// Build an icon button with loading state support
  /// 
  /// Returns an IconButton that:
  /// - Shows a loading indicator when isLoading is true
  /// - Is disabled when isLoading is true or onPressed is null
  /// - Provides Material 3 ripple effects
  /// 
  /// Validates: Requirements 8.3, 10.2, 10.5
  static Widget buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
    String? tooltip,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return IconButton(
          icon: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                )
              : Icon(icon),
          onPressed: isLoading ? null : onPressed,
          tooltip: tooltip,
        );
      },
    );
  }
}
