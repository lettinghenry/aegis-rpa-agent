import 'package:flutter/material.dart';
import '../models/session_summary.dart';
import 'package:intl/intl.dart';

/// A Material 3 card widget that displays a session summary in the history view
/// 
/// Displays:
/// - Instruction (truncated if too long)
/// - Status badge (completed/failed/cancelled)
/// - Timestamp
/// - Subtask count
/// 
/// The card is tappable to navigate to session details.
/// 
/// Validates: Requirements 6.3
class SessionSummaryCard extends StatelessWidget {
  final SessionSummary session;
  final VoidCallback onTap;

  const SessionSummaryCard({
    super.key,
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusInfo = _getStatusInfo();
    final accessibilityLabel = '${statusInfo.label} session. ${_truncateInstruction(session.instruction)}. ${session.subtaskCount} subtask${session.subtaskCount != 1 ? 's' : ''}. ${_formatTimestamp(session.createdAt)}';

    return Semantics(
      button: true,
      label: accessibilityLabel,
      hint: 'Tap to view session details',
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with status badge
                  Row(
                    children: [
                      // Status badge
                      _buildStatusBadge(theme, colorScheme),
                      const Spacer(),
                      // Timestamp
                      Text(
                        _formatTimestamp(session.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              
                  const SizedBox(height: 12.0),
                  
                  // Instruction (truncated)
                  Text(
                    _truncateInstruction(session.instruction),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8.0),
                  
                  // Subtask count
                  Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 16.0,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '${session.subtaskCount} subtask${session.subtaskCount != 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build status badge with appropriate color and icon
  Widget _buildStatusBadge(ThemeData theme, ColorScheme colorScheme) {
    final statusInfo = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo.icon,
            size: 16.0,
            color: statusInfo.color,
          ),
          const SizedBox(width: 6.0),
          Text(
            statusInfo.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: statusInfo.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Get status information (color, icon, label) based on session status
  _StatusInfo _getStatusInfo() {
    final status = session.status.toLowerCase();

    switch (status) {
      case 'completed':
        return _StatusInfo(
          color: const Color(0xFF4CAF50), // Green
          icon: Icons.check_circle,
          label: 'Completed',
        );
      case 'failed':
        return _StatusInfo(
          color: const Color(0xFFF44336), // Red
          icon: Icons.error,
          label: 'Failed',
        );
      case 'cancelled':
        return _StatusInfo(
          color: const Color(0xFF9E9E9E), // Grey
          icon: Icons.cancel,
          label: 'Cancelled',
        );
      case 'in_progress':
        return _StatusInfo(
          color: const Color(0xFF2196F3), // Blue
          icon: Icons.pending,
          label: 'In Progress',
        );
      default:
        return _StatusInfo(
          color: Colors.grey,
          icon: Icons.help_outline,
          label: status,
        );
    }
  }

  /// Truncate instruction if too long
  String _truncateInstruction(String instruction) {
    const maxLength = 100;
    if (instruction.length <= maxLength) {
      return instruction;
    }
    return '${instruction.substring(0, maxLength)}...';
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }
}

/// Helper class to hold status information
class _StatusInfo {
  final Color color;
  final IconData icon;
  final String label;

  _StatusInfo({
    required this.color,
    required this.icon,
    required this.label,
  });
}
