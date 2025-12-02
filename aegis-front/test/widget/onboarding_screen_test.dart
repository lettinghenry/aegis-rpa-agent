import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aegis_front/screens/onboarding_screen.dart';
import 'package:aegis_front/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingScreen Widget Tests', () {
    late AppState appState;

    setUp(() {
      // Initialize mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      appState = AppState();
    });

    /// Helper function to build the OnboardingScreen with Provider
    Widget buildOnboardingScreen() {
      return ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          home: const OnboardingScreen(),
          routes: {
            '/landing': (context) => Scaffold(
                  appBar: AppBar(title: const Text('Landing Screen')),
                  body: const Center(child: Text('Landing Screen')),
                ),
          },
        ),
      );
    }

    group('UI Elements Presence', () {
      testWidgets('displays welcome title', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildOnboardingScreen());

        // Assert
        expect(find.text('Welcome to AEGIS RPA'), findsOneWidget);
      });

      testWidgets('displays subtitle', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildOnboardingScreen());

        // Assert
        expect(
          find.text('Your intelligent automation assistant'),
          findsOneWidget,
        );
      });

      testWidgets('displays hero icon', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildOnboardingScreen());

        // Assert
        expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
      });

      testWidgets('displays "Get Started" button', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildOnboardingScreen());

        // Assert
        expect(find.text('Get Started'), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, 'Get Started'),
          findsOneWidget,
        );
      });

      testWidgets('displays "Skip" button', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildOnboardingScreen());

        // Assert
        expect(find.text('Skip'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);
      });

      testWidgets('displays all four feature highlights',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildOnboardingScreen());

        // Assert - Check for all feature titles
        expect(find.text('Natural Language Commands'), findsOneWidget);
        expect(find.text('Real-Time Monitoring'), findsOneWidget);
        expect(find.text('Multi-App Orchestration'), findsOneWidget);
        expect(find.text('Execution History'), findsOneWidget);
      });

      testWidgets('displays feature highlight icons',
          (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildOnboardingScreen());

        // Assert - Check for feature icons
        expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
        expect(find.byIcon(Icons.apps_outlined), findsOneWidget);
        expect(find.byIcon(Icons.history_outlined), findsOneWidget);
      });
    });

    group('"Get Started" Button Navigation', () {
      testWidgets('tapping "Get Started" calls completeOnboarding',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildOnboardingScreen());
        expect(appState.onboardingCompleted, false);

        // Act
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();

        // Assert
        expect(appState.onboardingCompleted, true);
      });

      testWidgets('tapping "Get Started" navigates to landing screen',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildOnboardingScreen());

        // Act
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();

        // Assert - Check that we navigated to the landing screen
        expect(find.text('Landing Screen'), findsOneWidget);
        expect(find.text('Welcome to AEGIS RPA'), findsNothing);
      });

      testWidgets('"Get Started" button is tappable',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildOnboardingScreen());

        // Act - Find the button
        final button = find.widgetWithText(FilledButton, 'Get Started');

        // Assert - Button should be enabled
        expect(button, findsOneWidget);
        final filledButton = tester.widget<FilledButton>(button);
        expect(filledButton.onPressed, isNotNull);
      });
    });

    group('"Skip" Button Navigation', () {
      testWidgets('tapping "Skip" calls completeOnboarding',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildOnboardingScreen());
        expect(appState.onboardingCompleted, false);

        // Act
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        // Assert
        expect(appState.onboardingCompleted, true);
      });

      testWidgets('tapping "Skip" navigates to landing screen',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildOnboardingScreen());

        // Act
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        // Assert - Check that we navigated to the landing screen
        expect(find.text('Landing Screen'), findsOneWidget);
        expect(find.text('Welcome to AEGIS RPA'), findsNothing);
      });

      testWidgets('"Skip" button is tappable', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildOnboardingScreen());

        // Act - Find the button
        final button = find.widgetWithText(TextButton, 'Skip');

        // Assert - Button should be enabled
        expect(button, findsOneWidget);
        final textButton = tester.widget<TextButton>(button);
        expect(textButton.onPressed, isNotNull);
      });
    });

    group('Onboarding Completion', () {
      testWidgets('onboarding status is persisted to storage',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildOnboardingScreen());

        // Act
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();

        // Assert - Verify persistence
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_completed'), true);
      });

      testWidgets('onboarding completion updates app state',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(buildOnboardingScreen());
        expect(appState.onboardingCompleted, false);

        // Act
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();

        // Assert
        expect(appState.onboardingCompleted, true);
        expect(appState.isLoading, false);
        expect(appState.errorMessage, null);
      });
    });
  });
}
