import 'package:flutter/material.dart';
import '../screens/onboarding_screen.dart';
import '../screens/landing_screen.dart';
import '../screens/task_execution_screen.dart';
import '../screens/history_view.dart';
import '../screens/session_detail_view.dart';

/// Application router that defines all routes and navigation logic.
/// 
/// This class provides:
/// - Named routes for all screens
/// - Route generation with parameter passing
/// - Initial route logic based on onboarding status
/// - Navigation guards if needed
/// 
/// Validates: Requirements 1.4, 2.4, 4.5, 5.4, 6.4
class AppRouter {
  /// Route names
  static const String onboarding = '/onboarding';
  static const String landing = '/landing';
  static const String execution = '/execution';
  static const String history = '/history';
  static const String sessionDetail = '/session-detail';

  /// Determines the initial route based on onboarding status.
  /// 
  /// Returns:
  /// - '/onboarding' if onboarding is not completed
  /// - '/landing' if onboarding is completed
  /// 
  /// Validates: Requirements 1.4
  static String getInitialRoute(bool onboardingCompleted) {
    return onboardingCompleted ? landing : onboarding;
  }

  /// Generates routes based on route settings.
  /// 
  /// This method is called by MaterialApp's onGenerateRoute callback
  /// to create the appropriate screen widget for each route.
  /// 
  /// Supports:
  /// - Named routes without parameters
  /// - Routes with arguments (execution, session detail)
  /// - Fallback to landing screen for unknown routes
  /// 
  /// Validates: Requirements 2.4, 4.5, 5.4, 6.4
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );

      case landing:
        return MaterialPageRoute(
          builder: (_) => const LandingScreen(),
          settings: settings,
        );

      case execution:
        // Extract session ID from arguments if provided
        final sessionId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => const TaskExecutionScreen(),
          settings: settings,
        );

      case history:
        return MaterialPageRoute(
          builder: (_) => const HistoryView(),
          settings: settings,
        );

      case sessionDetail:
        // Session ID is required for this route
        final sessionId = settings.arguments as String?;
        if (sessionId == null) {
          // If no session ID provided, navigate to history instead
          return MaterialPageRoute(
            builder: (_) => const HistoryView(),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => SessionDetailView(sessionId: sessionId),
          settings: settings,
        );

      default:
        // Fallback to landing screen for unknown routes
        return MaterialPageRoute(
          builder: (_) => const LandingScreen(),
          settings: settings,
        );
    }
  }

  /// Navigation helper methods for type-safe navigation
  
  /// Navigate to onboarding screen
  static Future<void> navigateToOnboarding(BuildContext context) {
    return Navigator.of(context).pushReplacementNamed(onboarding);
  }

  /// Navigate to landing screen
  /// 
  /// Uses pushReplacementNamed to prevent back navigation to onboarding
  static Future<void> navigateToLanding(BuildContext context) {
    return Navigator.of(context).pushReplacementNamed(landing);
  }

  /// Navigate to task execution screen
  /// 
  /// Validates: Requirements 2.4
  static Future<void> navigateToExecution(
    BuildContext context, {
    String? sessionId,
  }) {
    return Navigator.of(context).pushNamed(
      execution,
      arguments: sessionId,
    );
  }

  /// Navigate to history view
  /// 
  /// Validates: Requirements 6.1
  static Future<void> navigateToHistory(BuildContext context) {
    return Navigator.of(context).pushNamed(history);
  }

  /// Navigate to session detail view
  /// 
  /// Validates: Requirements 6.4
  static Future<void> navigateToSessionDetail(
    BuildContext context,
    String sessionId,
  ) {
    return Navigator.of(context).pushNamed(
      sessionDetail,
      arguments: sessionId,
    );
  }

  /// Navigate back to previous screen
  /// 
  /// Validates: Requirements 4.5, 5.4
  static void navigateBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Navigate back to landing screen (clearing navigation stack)
  /// 
  /// This is useful after completing or cancelling an execution
  /// to return to the main screen without keeping the execution
  /// screen in the navigation stack.
  /// 
  /// Validates: Requirements 4.5, 5.4
  static Future<void> navigateBackToLanding(BuildContext context) {
    return Navigator.of(context).pushNamedAndRemoveUntil(
      landing,
      (route) => false,
    );
  }

  /// Check if can navigate back
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }
}
