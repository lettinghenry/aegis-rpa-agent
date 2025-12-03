import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aegis_front/services/storage_service.dart';
import 'package:aegis_front/state/app_state.dart';
import 'dart:math';

/// Property-based test for onboarding flag storage
/// 
/// **Feature: rpa-frontend, Property 1: Onboarding Flag Storage**
/// **Validates: Requirements 1.3**
/// 
/// Property: For any completion of the onboarding flow, the local storage
/// must contain the onboarding_completed flag set to true.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Flag Storage Property', () {
    final random = Random();

    setUp(() async {
      // Clear storage before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('Property 1: Onboarding completion persists flag to storage', () async {
      // Run 100 iterations as specified in design
      for (int i = 0; i < 100; i++) {
        // Clear storage for each iteration
        SharedPreferences.setMockInitialValues({});

        // Create a new AppState instance
        final appState = AppState();

        // Verify initial state is false
        await appState.loadOnboardingStatus();
        expect(
          appState.onboardingCompleted,
          isFalse,
          reason: 'Initial onboarding status should be false',
        );

        // Complete onboarding
        await appState.completeOnboarding();

        // Verify the flag is set to true in storage
        final storedValue = await StorageService.getOnboardingCompleted();
        expect(
          storedValue,
          isTrue,
          reason: 'After completing onboarding (iteration $i), '
              'storage must contain onboarding_completed flag set to true',
        );

        // Verify the app state also reflects completion
        expect(
          appState.onboardingCompleted,
          isTrue,
          reason: 'AppState should reflect onboarding completion',
        );
      }
    });

    test('Property 1: Storage persists across multiple reads', () async {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        // Clear storage for each iteration
        SharedPreferences.setMockInitialValues({});

        // Complete onboarding
        final appState = AppState();
        await appState.completeOnboarding();

        // Read the flag multiple times to ensure persistence
        final numReads = random.nextInt(10) + 1; // 1-10 reads
        for (int j = 0; j < numReads; j++) {
          final storedValue = await StorageService.getOnboardingCompleted();
          expect(
            storedValue,
            isTrue,
            reason: 'Storage should persist onboarding flag across multiple reads '
                '(iteration $i, read $j)',
          );
        }
      }
    });

    test('Property 1: Multiple completions maintain true state', () async {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        // Clear storage for each iteration
        SharedPreferences.setMockInitialValues({});

        final appState = AppState();

        // Complete onboarding multiple times
        final numCompletions = random.nextInt(5) + 1; // 1-5 completions
        for (int j = 0; j < numCompletions; j++) {
          await appState.completeOnboarding();

          // Verify flag is still true after each completion
          final storedValue = await StorageService.getOnboardingCompleted();
          expect(
            storedValue,
            isTrue,
            reason: 'Storage should maintain true state after multiple completions '
                '(iteration $i, completion $j)',
          );
        }
      }
    });

    test('Property 1: Storage survives app state recreation', () async {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        // Clear storage for each iteration
        SharedPreferences.setMockInitialValues({});

        // Complete onboarding with first app state instance
        final appState1 = AppState();
        await appState1.completeOnboarding();

        // Create a new app state instance (simulating app restart)
        final appState2 = AppState();
        await appState2.loadOnboardingStatus();

        // Verify the new instance loads the persisted flag
        expect(
          appState2.onboardingCompleted,
          isTrue,
          reason: 'Onboarding flag should persist across app state recreation '
              '(iteration $i)',
        );

        // Verify storage still contains the flag
        final storedValue = await StorageService.getOnboardingCompleted();
        expect(
          storedValue,
          isTrue,
          reason: 'Storage should maintain flag after app state recreation '
              '(iteration $i)',
        );
      }
    });

    test('Property 1: Direct storage service call persists flag', () async {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        // Clear storage for each iteration
        SharedPreferences.setMockInitialValues({});

        // Set onboarding completed directly via storage service
        await StorageService.setOnboardingCompleted(true);

        // Verify the flag is persisted
        final storedValue = await StorageService.getOnboardingCompleted();
        expect(
          storedValue,
          isTrue,
          reason: 'Direct storage service call should persist flag (iteration $i)',
        );

        // Verify app state can load the persisted flag
        final appState = AppState();
        await appState.loadOnboardingStatus();
        expect(
          appState.onboardingCompleted,
          isTrue,
          reason: 'AppState should load persisted flag from storage (iteration $i)',
        );
      }
    });

    test('Property 1: Round trip - complete, load, verify', () async {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        // Clear storage for each iteration
        SharedPreferences.setMockInitialValues({});

        // Step 1: Complete onboarding
        final appState1 = AppState();
        await appState1.completeOnboarding();

        // Step 2: Load status in new instance
        final appState2 = AppState();
        await appState2.loadOnboardingStatus();

        // Step 3: Verify both storage and app state show completion
        final storedValue = await StorageService.getOnboardingCompleted();
        expect(
          storedValue,
          isTrue,
          reason: 'Round trip: storage should contain true (iteration $i)',
        );
        expect(
          appState2.onboardingCompleted,
          isTrue,
          reason: 'Round trip: app state should reflect true (iteration $i)',
        );
      }
    });

    test('Property 1: Completion after initial false state', () async {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        // Start with explicit false state
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': false,
        });

        final appState = AppState();
        await appState.loadOnboardingStatus();

        // Verify initial state is false
        expect(appState.onboardingCompleted, isFalse);

        // Complete onboarding
        await appState.completeOnboarding();

        // Verify transition to true
        final storedValue = await StorageService.getOnboardingCompleted();
        expect(
          storedValue,
          isTrue,
          reason: 'Completion should transition storage from false to true '
              '(iteration $i)',
        );
      }
    });

    test('Property 1: Concurrent completions maintain consistency', () async {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        // Clear storage for each iteration
        SharedPreferences.setMockInitialValues({});

        // Create multiple app state instances
        final appState1 = AppState();
        final appState2 = AppState();
        final appState3 = AppState();

        // Complete onboarding from multiple instances concurrently
        await Future.wait([
          appState1.completeOnboarding(),
          appState2.completeOnboarding(),
          appState3.completeOnboarding(),
        ]);

        // Verify storage contains true
        final storedValue = await StorageService.getOnboardingCompleted();
        expect(
          storedValue,
          isTrue,
          reason: 'Concurrent completions should result in true storage state '
              '(iteration $i)',
        );

        // Verify all instances reflect completion
        expect(appState1.onboardingCompleted, isTrue);
        expect(appState2.onboardingCompleted, isTrue);
        expect(appState3.onboardingCompleted, isTrue);
      }
    });
  });
}
