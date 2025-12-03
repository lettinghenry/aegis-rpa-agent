import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../routes/app_router.dart';

/// Onboarding screen shown to first-time users.
/// 
/// This screen introduces users to AEGIS RPA capabilities and provides
/// a "Get Started" button to proceed to the main application.
/// 
/// Requirements: 1.1, 1.2, 1.3, 1.5
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero image/animation
              Expanded(
                flex: 2,
                child: Center(
                  child: Icon(
                    Icons.smart_toy_outlined,
                    size: 120,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Welcome to AEGIS RPA',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Your intelligent automation assistant',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Feature highlights
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FeatureHighlight(
                      icon: Icons.chat_bubble_outline,
                      title: 'Natural Language Commands',
                      description: 'Simply describe what you want to automate in plain English',
                    ),
                    const SizedBox(height: 24),
                    _FeatureHighlight(
                      icon: Icons.visibility_outlined,
                      title: 'Real-Time Monitoring',
                      description: 'Watch your automation execute step-by-step with live updates',
                    ),
                    const SizedBox(height: 24),
                    _FeatureHighlight(
                      icon: Icons.apps_outlined,
                      title: 'Multi-App Orchestration',
                      description: 'Automate tasks across multiple desktop applications seamlessly',
                    ),
                    const SizedBox(height: 24),
                    _FeatureHighlight(
                      icon: Icons.history_outlined,
                      title: 'Execution History',
                      description: 'Review and learn from past automation sessions',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Get Started button
              FilledButton(
                onPressed: () => _handleGetStarted(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Skip option
              TextButton(
                onPressed: () => _handleGetStarted(context),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles the "Get Started" or "Skip" button press.
  /// 
  /// Marks onboarding as complete and navigates to the landing screen.
  /// 
  /// Validates: Requirements 1.4
  void _handleGetStarted(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Mark onboarding as completed
    await appState.completeOnboarding();
    
    // Navigate to landing screen using router
    if (context.mounted) {
      await AppRouter.navigateToLanding(context);
    }
  }
}

/// Widget for displaying a feature highlight with icon, title, and description.
class _FeatureHighlight extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureHighlight({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 28,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Title and description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
