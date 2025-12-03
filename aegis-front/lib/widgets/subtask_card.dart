import 'package:flutter/material.dart';
import '../models/subtask.dart';
import 'package:intl/intl.dart';

/// A Material 3 card widget that displays a subtask with status indicators
class SubtaskCard extends StatelessWidget {
  final Subtask subtask;

  const SubtaskCard({
    super.key,
    required this.subtask,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine visual treatment based on status
    final isInProgress = subtask.status == SubtaskStatus.inProgress;
    final isCompleted = subtask.status == SubtaskStatus.completed;
    final isFailed = subtask.status == SubtaskStatus.failed;

    // Status colors
    final statusColor = _getStatusColor(colorScheme);
    final backgroundColor = _getBackgroundColor(colorScheme);
    final opacity = isCompleted ? 0.6 : 1.0;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isInProgress
            ? BorderSide(color: statusColor, width: 2.0)
            : BorderSide.none,
      ),
      color: backgroundColor,
      child: Opacity(
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status icon
              _buildStatusIcon(statusColor),
              const SizedBox(width: 16.0),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      subtask.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isInProgress ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    // Timestamp
                    Text(
                      _formatTimestamp(subtask.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    // Error message (if failed)
                    if (isFailed && subtask.error != null) ...[
                      const SizedBox(height: 8.0),
                      Text(
                        subtask.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getErrorColor(colorScheme),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build status icon based on subtask status
  Widget _buildStatusIcon(Color statusColor) {
    switch (subtask.status) {
      case SubtaskStatus.pending:
        return Icon(
          Icons.radio_button_unchecked,
          size: 24.0,
          color: statusColor,
        );
      case SubtaskStatus.inProgress:
        return SizedBox(
          width: 24.0,
          height: 24.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        );
      case SubtaskStatus.completed:
        return Icon(
          Icons.check_circle,
          size: 24.0,
          color: statusColor,
        );
      case SubtaskStatus.failed:
        return Icon(
          Icons.error,
          size: 24.0,
          color: statusColor,
        );
    }
  }

  /// Get status color based on subtask status
  Color _getStatusColor(ColorScheme colorScheme) {
    switch (subtask.status) {
      case SubtaskStatus.pending:
        return Colors.grey;
      case SubtaskStatus.inProgress:
        return const Color(0xFF2196F3); // Blue
      case SubtaskStatus.completed:
        return const Color(0xFF4CAF50); // Green
      case SubtaskStatus.failed:
        return const Color(0xFFF44336); // Red
    }
  }

  /// Get background color based on subtask status
  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (subtask.status == SubtaskStatus.inProgress) {
      // Subtle highlight for in-progress
      return colorScheme.primaryContainer.withOpacity(0.1);
    }
    return colorScheme.surface;
  }

  /// Get error color
  Color _getErrorColor(ColorScheme colorScheme) {
    return const Color(0xFFF44336); // Red
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }
}
