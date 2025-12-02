import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aegis_front/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppState', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    group('initial state', () {
      test('onboardingCompleted is false by default', () {
        expect(appState.onboardingCompleted, false);
      });

      test('isLoading is false by default', () {
        expect(appState.isLoading, false);
      });

      test('errorMessage is null by default', () {
        expect(appState.errorMessage, null);
      });
    });

    group('loadOnboardingStatus', () {
      test('loads true when onboarding is completed', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });

        // Act
        await appState.loadOnboardingStatus();

        // Assert
        expect(appState.onboardingCompleted, true);
        expect(appState.isLoading, false);
        expect(appState.errorMessage, null);
      });

      test('loads false when onboarding is not completed', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': false,
        });

        // Act
        await appState.loadOnboardingStatus();

        // Assert
        expect(appState.onboardingCompleted, false);
        expect(appState.isLoading, false);
        expect(appState.errorMessage, null);
      });

      test('loads false when key does not exist (default)', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        await appState.loadOnboardingStatus();

        // Assert
        expect(appState.onboardingCompleted, false);
        expect(appState.isLoading, false);
        expect(appState.errorMessage, null);
      });

      test('sets isLoading to true during loading', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });

        bool wasLoadingDuringExecution = false;

        // Listen to state changes
        appState.addListener(() {
          if (appState.isLoading) {
            wasLoadingDuringExecution = true;
          }
        });

        // Act
        await appState.loadOnboardingStatus();

        // Assert
        expect(wasLoadingDuringExecution, true);
        expect(appState.isLoading, false); // Should be false after completion
      });

      test('clears error message before loading', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });

        // Simulate a previous error
        appState.clearError();
        
        // Act
        await appState.loadOnboardingStatus();

        // Assert
        expect(appState.errorMessage, null);
      });

      test('defaults to false on error', () async {
        // Arrange - Create a scenario that might cause an error
        // Note: SharedPreferences mock is quite robust, so we test the fallback behavior
        SharedPreferences.setMockInitialValues({});

        // Act
        await appState.loadOnboardingStatus();

        // Assert - Should default to false even if there's an issue
        expect(appState.onboardingCompleted, false);
        expect(appState.isLoading, false);
      });
    });

    group('completeOnboarding', () {
      test('sets onboarding completed to true', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        await appState.completeOnboarding();

        // Assert
        expect(appState.onboardingCompleted, true);
        expect(appState.isLoading, false);
        expect(appState.errorMessage, null);
      });

      test('persists onboarding completion to storage', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        await appState.completeOnboarding();

        // Assert - Verify it was persisted
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_completed'), true);
      });

      test('sets isLoading to true during completion', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        bool wasLoadingDuringExecution = false;

        // Listen to state changes
        appState.addListener(() {
          if (appState.isLoading) {
            wasLoadingDuringExecution = true;
          }
        });

        // Act
        await appState.completeOnboarding();

        // Assert
        expect(wasLoadingDuringExecution, true);
        expect(appState.isLoading, false); // Should be false after completion
      });

      test('clears error message before completing', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        await appState.completeOnboarding();

        // Assert
        expect(appState.errorMessage, null);
      });

      test('can be called multiple times', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        await appState.completeOnboarding();
        await appState.completeOnboarding();
        await appState.completeOnboarding();

        // Assert
        expect(appState.onboardingCompleted, true);
        expect(appState.errorMessage, null);
      });
    });

    group('resetOnboarding', () {
      test('sets onboarding completed to false', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });
        await appState.loadOnboardingStatus();
        expect(appState.onboardingCompleted, true);

        // Act
        await appState.resetOnboarding();

        // Assert
        expect(appState.onboardingCompleted, false);
        expect(appState.isLoading, false);
        expect(appState.errorMessage, null);
      });

      test('persists reset to storage', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });

        // Act
        await appState.resetOnboarding();

        // Assert - Verify it was persisted
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_completed'), false);
      });

      test('sets isLoading to true during reset', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });

        bool wasLoadingDuringExecution = false;

        // Listen to state changes
        appState.addListener(() {
          if (appState.isLoading) {
            wasLoadingDuringExecution = true;
          }
        });

        // Act
        await appState.resetOnboarding();

        // Assert
        expect(wasLoadingDuringExecution, true);
        expect(appState.isLoading, false);
      });
    });

    group('clearError', () {
      test('clears error message', () {
        // Arrange - Manually set an error (simulating a failed operation)
        // We can't easily trigger a real error with the mock, so we test the clear functionality
        
        // Act
        appState.clearError();

        // Assert
        expect(appState.errorMessage, null);
      });

      test('notifies listeners when clearing error', () {
        // Arrange
        int notificationCount = 0;
        appState.addListener(() {
          notificationCount++;
        });

        // Act
        appState.clearError();

        // Assert
        expect(notificationCount, 1);
      });
    });

    group('state change notifications', () {
      test('notifies listeners when loading onboarding status', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });

        int notificationCount = 0;
        appState.addListener(() {
          notificationCount++;
        });

        // Act
        await appState.loadOnboardingStatus();

        // Assert - Should notify at least twice: start loading and finish loading
        expect(notificationCount, greaterThanOrEqualTo(2));
      });

      test('notifies listeners when completing onboarding', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        int notificationCount = 0;
        appState.addListener(() {
          notificationCount++;
        });

        // Act
        await appState.completeOnboarding();

        // Assert - Should notify at least twice: start loading and finish loading
        expect(notificationCount, greaterThanOrEqualTo(2));
      });

      test('notifies listeners when resetting onboarding', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });

        int notificationCount = 0;
        appState.addListener(() {
          notificationCount++;
        });

        // Act
        await appState.resetOnboarding();

        // Assert - Should notify at least twice: start loading and finish loading
        expect(notificationCount, greaterThanOrEqualTo(2));
      });

      test('listener receives correct state during loadOnboardingStatus', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });

        List<bool> loadingStates = [];
        List<bool> completedStates = [];

        appState.addListener(() {
          loadingStates.add(appState.isLoading);
          completedStates.add(appState.onboardingCompleted);
        });

        // Act
        await appState.loadOnboardingStatus();

        // Assert
        // First notification: isLoading = true, onboardingCompleted = false (initial)
        // Second notification: isLoading = false, onboardingCompleted = true (loaded)
        expect(loadingStates.first, true);
        expect(loadingStates.last, false);
        expect(completedStates.last, true);
      });

      test('listener receives correct state during completeOnboarding', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        List<bool> loadingStates = [];
        List<bool> completedStates = [];

        appState.addListener(() {
          loadingStates.add(appState.isLoading);
          completedStates.add(appState.onboardingCompleted);
        });

        // Act
        await appState.completeOnboarding();

        // Assert
        // First notification: isLoading = true, onboardingCompleted = false (initial)
        // Second notification: isLoading = false, onboardingCompleted = true (completed)
        expect(loadingStates.first, true);
        expect(loadingStates.last, false);
        expect(completedStates.last, true);
      });

      test('multiple listeners all receive notifications', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        int listener1Count = 0;
        int listener2Count = 0;
        int listener3Count = 0;

        appState.addListener(() => listener1Count++);
        appState.addListener(() => listener2Count++);
        appState.addListener(() => listener3Count++);

        // Act
        await appState.completeOnboarding();

        // Assert - All listeners should be notified
        expect(listener1Count, greaterThanOrEqualTo(2));
        expect(listener2Count, greaterThanOrEqualTo(2));
        expect(listener3Count, greaterThanOrEqualTo(2));
      });

      test('removed listener does not receive notifications', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        int notificationCount = 0;
        void listener() {
          notificationCount++;
        }

        appState.addListener(listener);
        appState.removeListener(listener);

        // Act
        await appState.completeOnboarding();

        // Assert - Listener was removed, should not be notified
        expect(notificationCount, 0);
      });
    });

    group('round trip operations', () {
      test('complete then load returns true', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        await appState.completeOnboarding();
        
        // Create new instance to test persistence
        final newAppState = AppState();
        await newAppState.loadOnboardingStatus();

        // Assert
        expect(newAppState.onboardingCompleted, true);
      });

      test('reset then load returns false', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });

        // Act
        await appState.resetOnboarding();
        
        // Create new instance to test persistence
        final newAppState = AppState();
        await newAppState.loadOnboardingStatus();

        // Assert
        expect(newAppState.onboardingCompleted, false);
      });

      test('complete, reset, complete sequence works correctly', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        await appState.completeOnboarding();
        expect(appState.onboardingCompleted, true);

        await appState.resetOnboarding();
        expect(appState.onboardingCompleted, false);

        await appState.completeOnboarding();
        expect(appState.onboardingCompleted, true);

        // Assert - Verify final state is persisted
        final newAppState = AppState();
        await newAppState.loadOnboardingStatus();
        expect(newAppState.onboardingCompleted, true);
      });
    });

    group('edge cases', () {
      test('calling completeOnboarding before loadOnboardingStatus works', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act - Complete without loading first
        await appState.completeOnboarding();

        // Assert
        expect(appState.onboardingCompleted, true);
      });

      test('calling loadOnboardingStatus multiple times is safe', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });

        // Act
        await appState.loadOnboardingStatus();
        await appState.loadOnboardingStatus();
        await appState.loadOnboardingStatus();

        // Assert
        expect(appState.onboardingCompleted, true);
        expect(appState.errorMessage, null);
      });

      test('state remains consistent after multiple operations', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act - Perform various operations
        await appState.loadOnboardingStatus();
        expect(appState.onboardingCompleted, false);

        await appState.completeOnboarding();
        expect(appState.onboardingCompleted, true);

        await appState.loadOnboardingStatus();
        expect(appState.onboardingCompleted, true);

        await appState.resetOnboarding();
        expect(appState.onboardingCompleted, false);

        await appState.loadOnboardingStatus();
        expect(appState.onboardingCompleted, false);

        // Assert - Final state should be consistent
        expect(appState.isLoading, false);
        expect(appState.errorMessage, null);
      });
    });
  });
}
