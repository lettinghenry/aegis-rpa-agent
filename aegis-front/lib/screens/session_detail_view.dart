import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/execution_session.dart';
import '../services/backend_api_service.dart';
import '../widgets/subtask_card.dart';
import '../routes/app_router.dart';
import '../utils/error_handler.dart';
import '../utils/loading_indicator.dart';
import 'package:intl/intl.dart';

/// Session detail view screen that displays complete details of a past execution session
/// 
/// Features:
/// - Displays original instruction
/// - Shows overall session status
/// - Lists all subtasks with results
/// - Shows timestamps (created, updated, completed)
/// - Loads session details on screen init
/// - Error handling with retry option
/// 
/// Validates: Requirements 6.4, 6.5
class SessionDetailView extends StatefulWidget {
  final String sessionId;

  const SessionDetailView({
    super.key,
    required this.sessionId,
  });

  @override
  State<SessionDetailView> createState() => _SessionDetailViewState();
}

class _SessionDetailViewState extends State<SessionDetailView> {
  ExecutionSession? _session;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Load session details when screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessionDetails();
    });
  }

  /// Load session details from backend
  /// 
  /// Validates: Requirements 6.4
  Future<void> _loadSessionDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<BackendApiService>(
        context,
        listen: false,
      );
      final session = await apiService.getSessionDetails(widget.sessionId);

      if (mounted) {
        setState(() {
          _session = session;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Get status badge color based on session status
  Color _getStatusColor(ColorScheme colorScheme) {
    if (_session == null) return Colors.grey;

    switch (_session!.status) {
      case SessionStatus.completed:
        return const Color(0xFF4CAF50); // Green
      case SessionStatus.failed:
        return const Color(0xFFF44336); // Red
      case SessionStatus.cancelled:
        return Colors.orange;
      case SessionStatus.inProgress:
        return const Color(0xFF2196F3); // Blue
      case SessionStatus.pending:
        return Colors.grey;
    }
  }

  /// Get status text
  String _getStatusText() {
    if (_session == null) return '';

    switch (_session!.status) {
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.failed:
        return 'Failed';
      case SessionStatus.cancelled:
        return 'Cancelled';
      case SessionStatus.inProgress:
        return 'In Progress';
      case SessionStatus.pending:
        return 'Pending';
    }
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('MMM d, yyyy • h:mm a').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.navigateBack(context),
        ),
      ),
      body: _buildBody(theme, colorScheme),
    );
  }

  /// Build the main body content
  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    // Show loading indicator
    if (_isLoading) {
      return LoadingIndicator.buildCentered(
        context,
        message: 'Loading session details...',
      );
    }

    // Show error state with retry option
    if (_errorMessage != null) {
      return ErrorHandler.buildFullScreenError(
        context,
        _errorMessage!,
        onRetry: _loadSessionDetails,
      );
    }

    // Show session details
    if (_session == null) {
      return Center(
        child: Text(
          'No session data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with instruction and status
          _buildHeaderSection(theme, colorScheme),
          const SizedBox(height: 16),
          // Timestamps section
          _buildTimestampsSection(theme, colorScheme),
          const SizedBox(height: 24),
          // Subtasks section
          _buildSubtasksSection(theme, colorScheme),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Build header section with instruction and status
  /// 
  /// Validates: Requirements 6.5
  Widget _buildHeaderSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 6.0,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(colorScheme).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: _getStatusColor(colorScheme),
                width: 1.5,
              ),
            ),
            child: Text(
              _getStatusText(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: _getStatusColor(colorScheme),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Instruction
          Text(
            'Task Instruction',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _session!.instruction,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Build timestamps section
  /// 
  /// Validates: Requirements 6.5
  Widget _buildTimestampsSection(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildTimestampRow(
            icon: Icons.play_circle_outline,
            label: 'Started',
            timestamp: _session!.createdAt,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          _buildTimestampRow(
            icon: Icons.update,
            label: 'Last Updated',
            timestamp: _session!.updatedAt,
            theme: theme,
            colorScheme: colorScheme,
          ),
          if (_session!.completedAt != null) ...[
            const SizedBox(height: 8),
            _buildTimestampRow(
              icon: Icons.check_circle_outline,
              label: 'Completed',
              timestamp: _session!.completedAt!,
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
        ],
      ),
    );
  }

  /// Build a single timestamp row
  Widget _buildTimestampRow({
    required IconData icon,
    required String label,
    required DateTime timestamp,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatTimestamp(timestamp),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build subtasks section
  /// 
  /// Validates: Requirements 6.5
  Widget _buildSubtasksSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Text(
                'Subtasks',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '${_session!.subtasks.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Display subtasks
        if (_session!.subtasks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No subtasks recorded',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ..._session!.subtasks.map(
            (subtask) => SubtaskCard(
              subtask: subtask,
            ),
          ),
      ],
    );
  }
}
