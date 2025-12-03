import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/execution_session.dart';
import '../models/subtask.dart';
import '../state/execution_state.dart';
import '../routes/app_router.dart';
import '../utils/error_handler.dart';
import '../utils/button_feedback.dart';

/// Task Execution Screen displays real-time progress of automation execution
/// 
/// Features:
/// - Normal mode: Full screen with scrollable subtask list
/// - Minimal mode: Compact 300x100 floating panel
/// - Real-time updates via WebSocket
/// - Cancel button with confirmation dialog
/// - Overall status indicator
/// - Done/Back button when complete
/// 
/// Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 13.2
class TaskExecutionScreen extends StatelessWidget {
  const TaskExecutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExecutionStateNotifier>(
      builder: (context, executionState, child) {
        // Switch between normal and minimal layouts based on window mode
        if (executionState.isMinimalMode) {
          return _buildMinimalModeUI(context, executionState);
        } else {
          return _buildNormalModeUI(context, executionState);
        }
      },
    );
  }

  /// Build normal mode UI (full screen)
  Widget _buildNormalModeUI(
    BuildContext context,
    ExecutionStateNotifier executionState,
  ) {
    final theme = Theme.of(context);
    final isComplete = executionState.status == SessionStatus.completed ||
        executionState.status == SessionStatus.failed ||
        executionState.status == SessionStatus.cancelled;

    return Scaffold(
      appBar: AppBar(
        title: Text('Execution: ${executionState.sessionId ?? 'Unknown'}'),
        actions: [
          // Cancel button (shown during active execution)
          if (executionState.status == SessionStatus.inProgress)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => _showCancelDialog(context, executionState),
              tooltip: 'Cancel Execution',
            ),
        ],
      ),
      body: Column(
        children: [
          // Original instruction display card at top
          _buildInstructionCard(context, executionState),

          // Overall status indicator
          _buildStatusIndicator(context, executionState),

          // Scrollable list of subtask cards
          Expanded(
            child: _buildSubtaskList(context, executionState),
          ),

          // Done/Back button (shown when complete)
          if (isComplete) _buildCompletionButton(context, executionState),
        ],
      ),
    );
  }

  /// Build minimal mode UI (compact 300x100 floating panel)
  Widget _buildMinimalModeUI(
    BuildContext context,
    ExecutionStateNotifier executionState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Get current subtask (last in-progress or most recent)
    final currentSubtask = _getCurrentSubtask(executionState);
    final description = currentSubtask?.description ?? 'Processing...';

    return Material(
      color: colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Current subtask description (truncated)
            Expanded(
              child: Row(
                children: [
                  // Progress indicator
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Description
                  Expanded(
                    child: Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar
            const SizedBox(height: 8),
            LinearProgressIndicator(
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// Build instruction display card
  Widget _buildInstructionCard(
    BuildContext context,
    ExecutionStateNotifier executionState,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Instruction',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              executionState.instruction ?? 'No instruction',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  /// Build overall status indicator with connection status
  /// 
  /// Validates: Requirements 7.2, 7.3, 9.3
  Widget _buildStatusIndicator(
    BuildContext context,
    ExecutionStateNotifier executionState,
  ) {
    final theme = Theme.of(context);
    final status = executionState.status;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case SessionStatus.pending:
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pending';
        break;
      case SessionStatus.inProgress:
        statusColor = const Color(0xFF2196F3); // Blue
        statusIcon = Icons.play_circle_outline;
        statusText = 'In Progress';
        break;
      case SessionStatus.completed:
        statusColor = const Color(0xFF4CAF50); // Green
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case SessionStatus.failed:
        statusColor = const Color(0xFFF44336); // Red
        statusIcon = Icons.error;
        statusText = 'Failed';
        break;
      case SessionStatus.cancelled:
        statusColor = Colors.orange;
        statusIcon = Icons.cancel;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: statusColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: theme.textTheme.titleMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (executionState.status == SessionStatus.inProgress) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            ),
          ],
          const Spacer(),
          // Connection status indicator
          _buildConnectionStatusIndicator(context, executionState),
        ],
      ),
    );
  }

  /// Build connection status indicator
  /// 
  /// Shows WebSocket connection state with appropriate icon and color.
  /// Validates: Requirements 7.2, 7.3
  Widget _buildConnectionStatusIndicator(
    BuildContext context,
    ExecutionStateNotifier executionState,
  ) {
    final connectionStatus = executionState.connectionStatus;
    final theme = Theme.of(context);

    IconData icon;
    Color color;
    String tooltip;

    switch (connectionStatus) {
      case ConnectionStatus.disconnected:
        icon = Icons.cloud_off;
        color = Colors.grey;
        tooltip = 'Disconnected';
        break;
      case ConnectionStatus.connecting:
        icon = Icons.cloud_sync;
        color = Colors.orange;
        tooltip = 'Connecting...';
        break;
      case ConnectionStatus.connected:
        icon = Icons.cloud_done;
        color = const Color(0xFF4CAF50); // Green
        tooltip = 'Connected';
        break;
      case ConnectionStatus.reconnecting:
        icon = Icons.cloud_sync;
        color = Colors.orange;
        tooltip = 'Reconnecting...';
        break;
      case ConnectionStatus.failed:
        icon = Icons.cloud_off;
        color = const Color(0xFFF44336); // Red
        tooltip = 'Connection Failed';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          if (connectionStatus == ConnectionStatus.connecting ||
              connectionStatus == ConnectionStatus.reconnecting) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build scrollable subtask list
  Widget _buildSubtaskList(
    BuildContext context,
    ExecutionStateNotifier executionState,
  ) {
    final subtasks = executionState.subtasks;

    if (subtasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pending_actions,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Waiting for subtasks...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: subtasks.length,
      itemBuilder: (context, index) {
        return _buildSubtaskCard(context, subtasks[index]);
      },
    );
  }

  /// Build individual subtask card
  Widget _buildSubtaskCard(BuildContext context, Subtask subtask) {
    final theme = Theme.of(context);

    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    bool isHighlighted = false;
    bool isDimmed = false;

    switch (subtask.status) {
      case SubtaskStatus.pending:
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_empty;
        break;
      case SubtaskStatus.inProgress:
        statusColor = const Color(0xFF2196F3); // Blue
        statusIcon = Icons.sync;
        isHighlighted = true;
        break;
      case SubtaskStatus.completed:
        statusColor = const Color(0xFF4CAF50); // Green
        statusIcon = Icons.check_circle;
        isDimmed = true;
        break;
      case SubtaskStatus.failed:
        statusColor = const Color(0xFFF44336); // Red
        statusIcon = Icons.error;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: isHighlighted ? 3 : 1,
      color: isHighlighted
          ? statusColor.withValues(alpha: 0.05)
          : (isDimmed ? Colors.grey.withValues(alpha: 0.05) : null),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isHighlighted
            ? BorderSide(color: statusColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status icon
            subtask.status == SubtaskStatus.inProgress
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: statusColor,
                    ),
                  )
                : Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    subtask.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDimmed ? Colors.grey[600] : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Timestamp
                  Text(
                    _formatTimestamp(subtask.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  // Error message (if failed)
                  if (subtask.status == SubtaskStatus.failed &&
                      subtask.error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subtask.error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build completion button (Done/Back)
  /// 
  /// Validates: Requirements 4.5
  Widget _buildCompletionButton(
    BuildContext context,
    ExecutionStateNotifier executionState,
  ) {
    final isSuccess = executionState.status == SessionStatus.completed;
    final buttonText = isSuccess ? 'Done' : 'Back';
    final buttonIcon = isSuccess ? Icons.check : Icons.arrow_back;

    return Container(
      padding: const EdgeInsets.all(16),
      child: ButtonFeedback.buildPrimaryButton(
        label: buttonText,
        icon: buttonIcon,
        onPressed: () => AppRouter.navigateBack(context),
        width: double.infinity,
        height: 48,
      ),
    );
  }

  /// Show cancel confirmation dialog
  /// 
  /// Validates: Requirements 5.2, 5.3, 5.4
  Future<void> _showCancelDialog(
    BuildContext context,
    ExecutionStateNotifier executionState,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Execution'),
        content: const Text(
          'Are you sure you want to cancel this execution? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await executionState.cancelExecution();
        if (context.mounted) {
          await AppRouter.navigateBackToLanding(context);
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showErrorSnackBar(context, e);
        }
      }
    }
  }

  /// Get current subtask (in-progress or most recent)
  Subtask? _getCurrentSubtask(ExecutionStateNotifier executionState) {
    final subtasks = executionState.subtasks;
    if (subtasks.isEmpty) return null;

    // Find in-progress subtask
    final inProgress = subtasks.firstWhere(
      (s) => s.status == SubtaskStatus.inProgress,
      orElse: () => subtasks.last,
    );

    return inProgress;
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
