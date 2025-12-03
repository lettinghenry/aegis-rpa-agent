import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/history_state.dart';
import '../widgets/session_summary_card.dart';
import '../routes/app_router.dart';
import '../utils/error_handler.dart';
import '../utils/loading_indicator.dart';
import '../utils/button_feedback.dart';

/// History view screen that displays past execution sessions
/// 
/// Features:
/// - Scrollable list of session summary cards
/// - Pull-to-refresh functionality
/// - Empty state message when no history
/// - Error handling with retry option
/// - Navigation to session detail view on tap
/// 
/// Validates: Requirements 6.1, 6.2, 6.3, 6.4
class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  @override
  void initState() {
    super.initState();
    // Load history when screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  /// Load history from backend
  /// 
  /// Validates: Requirements 6.2
  Future<void> _loadHistory() async {
    final historyState = Provider.of<HistoryStateNotifier>(
      context,
      listen: false,
    );
    await historyState.loadHistory();
  }

  /// Handle pull-to-refresh
  /// 
  /// Validates: Requirements 6.2
  Future<void> _onRefresh() async {
    await _loadHistory();
  }

  /// Handle session tap - navigate to session detail view
  /// 
  /// Validates: Requirements 6.4
  void _onSessionTapped(String sessionId) {
    AppRouter.navigateToSessionDetail(context, sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Execution History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.navigateBack(context),
        ),
      ),
      body: Consumer<HistoryStateNotifier>(
        builder: (context, historyState, child) {
          // Show loading indicator on initial load
          if (historyState.isLoading && historyState.sessions.isEmpty) {
            return LoadingIndicator.buildCentered(
              context,
              message: 'Loading history...',
            );
          }

          // Show error state with retry option
          if (historyState.errorMessage != null &&
              historyState.sessions.isEmpty) {
            return ErrorHandler.buildFullScreenError(
              context,
              historyState.errorMessage!,
              onRetry: _loadHistory,
            );
          }

          // Show empty state when no sessions
          if (historyState.sessions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No execution history',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your automation sessions will appear here',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Show session list with pull-to-refresh
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: historyState.sessions.length,
              itemBuilder: (context, index) {
                final session = historyState.sessions[index];
                return SessionSummaryCard(
                  session: session,
                  onTap: () => _onSessionTapped(session.sessionId),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
