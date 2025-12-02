import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aegis_front/services/storage_service.dart';

// Generate mocks using build_runner
@GenerateMocks([SharedPreferences])
import 'storage_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService', () {
    group('getOnboardingCompleted', () {
      test('returns true when onboarding is completed', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });

        // Act
        final result = await StorageService.getOnboardingCompleted();

        // Assert
        expect(result, true);
      });

      test('returns false when onboarding is not completed', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': false,
        });

        // Act
        final result = await StorageService.getOnboardingCompleted();

        // Assert
        expect(result, false);
      });

      test('returns false when key does not exist (default value)', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        final result = await StorageService.getOnboardingCompleted();

        // Assert
        expect(result, false);
      });
    });

    group('setOnboardingCompleted', () {
      test('sets onboarding completed to true', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        await StorageService.setOnboardingCompleted(true);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_completed'), true);
      });

      test('sets onboarding completed to false', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });

        // Act
        await StorageService.setOnboardingCompleted(false);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_completed'), false);
      });

      test('overwrites existing value', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': false,
        });

        // Act
        await StorageService.setOnboardingCompleted(true);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_completed'), true);
      });

      test('persists value across multiple reads', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        await StorageService.setOnboardingCompleted(true);

        // Assert - Read multiple times
        final result1 = await StorageService.getOnboardingCompleted();
        final result2 = await StorageService.getOnboardingCompleted();
        final result3 = await StorageService.getOnboardingCompleted();

        expect(result1, true);
        expect(result2, true);
        expect(result3, true);
      });
    });

    group('clear', () {
      test('clears all stored preferences', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
          'other_key': 'some_value',
        });

        // Act
        await StorageService.clear();

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_completed'), null);
        expect(prefs.getString('other_key'), null);
      });

      test('clears storage even when empty', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act & Assert - Should not throw
        await StorageService.clear();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getKeys().isEmpty, true);
      });

      test('after clear, getOnboardingCompleted returns false', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });

        // Act
        await StorageService.clear();

        // Assert
        final result = await StorageService.getOnboardingCompleted();
        expect(result, false);
      });
    });

    group('round trip operations', () {
      test('set then get returns same value for true', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        await StorageService.setOnboardingCompleted(true);
        final result = await StorageService.getOnboardingCompleted();

        // Assert
        expect(result, true);
      });

      test('set then get returns same value for false', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        await StorageService.setOnboardingCompleted(false);
        final result = await StorageService.getOnboardingCompleted();

        // Assert
        expect(result, false);
      });

      test('multiple set operations preserve last value', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        await StorageService.setOnboardingCompleted(true);
        await StorageService.setOnboardingCompleted(false);
        await StorageService.setOnboardingCompleted(true);

        // Assert
        final result = await StorageService.getOnboardingCompleted();
        expect(result, true);
      });
    });

    group('StorageException', () {
      test('has correct message', () {
        final exception = StorageException('Test error message');
        expect(exception.message, 'Test error message');
      });

      test('toString includes message', () {
        final exception = StorageException('Test error');
        expect(exception.toString(), 'StorageException: Test error');
      });
    });
  });
}
