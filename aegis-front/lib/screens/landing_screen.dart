import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/execution_state.dart';
import '../routes/app_router.dart';

/// Landing screen where users input task instructions.
/// 
/// This is the main entry point after onboarding, allowing users to:
/// - Input natural language task instructions
/// - Submit tasks for execution
/// - Navigate to execution history
/// 
/// Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 6.1
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final TextEditingController _instructionController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _instructionController.addListener(_onInstructionChanged);
  }

  @override
  void dispose() {
    _instructionController.removeListener(_onInstructionChanged);
    _instructionController.dispose();
    super.dispose();
  }

  /// Called when instruction text changes
  void _onInstructionChanged() {
    setState(() {
      // Clear error when user starts typing
      if (_errorMessage != null) {
        _errorMessage = null;
      }
    });
  }

  /// Check if submit button should be enabled
  /// 
  /// Property 2: Submit button enabled only for non-empty input
  /// Validates: Requirements 2.2
  bool get _isSubmitEnabled {
    return _instructionController.text.trim().isNotEmpty && !_isSubmitting;
  }

  /// Handle task submission
  /// 
  /// Validates: Requirements 2.3, 2.4, 2.5, 10.1
  Future<void> _onSubmit() async {
    if (!_isSubmitEnabled) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final executionState = Provider.of<ExecutionStateNotifier>(
        context,
        listen: false,
      );

      // Start execution
      await executionState.startExecution(_instructionController.text.trim());

      // Navigate to Task Execution Screen on success
      if (mounted) {
        await AppRouter.navigateToExecution(
          context,
          sessionId: executionState.sessionId,
        );
      }
    } catch (e) {
      // Display error without navigating
      setState(() {
        _errorMessage = _formatErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Format error message for user display
  /// 
  /// Validates: Requirements 7.1, 7.4
  String _formatErrorMessage(dynamic error) {
    final errorStr = error.toString();
    
    if (errorStr.contains('SocketException') ||
        errorStr.contains('Connection refused') ||
        errorStr.contains('Failed host lookup')) {
      return 'Unable to connect. Please check your internet connection.';
    } else if (errorStr.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else if (errorStr.contains('offline') || errorStr.contains('unreachable')) {
      return 'The automation service is currently offline. Please try again later.';
    } else if (errorStr.contains('ValidationException')) {
      // Extract validation message if available
      return errorStr.replaceAll('ValidationException:', '').trim();
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Navigate to history view
  /// 
  /// Validates: Requirements 6.1
  void _onHistoryTapped() {
    AppRouter.navigateToHistory(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AEGIS RPA'),
        actions: [
          // History icon button
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: _onHistoryTapped,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'What would you like to automate?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Describe your task in natural language',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Text input field
              TextField(
                controller: _instructionController,
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'Example: Open Chrome, navigate to example.com, and take a screenshot',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: theme.textTheme.bodyLarge,
                enabled: !_isSubmitting,
              ),
              
              const SizedBox(height: 16),
              
              // Error message display area
              if (_errorMessage != null)
                Container(
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
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (_errorMessage != null) const SizedBox(height: 16),
              
              // Submit button with loading indicator
              FilledButton(
                onPressed: _isSubmitEnabled ? _onSubmit : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
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
                    : const Text(
                        'Start Automation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              
              const Spacer(),
              
              // Help text
              Center(
                child: Text(
                  'Tip: Be specific about the applications and actions you want to automate',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
