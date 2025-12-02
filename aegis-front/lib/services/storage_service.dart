import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling local storage operations using SharedPreferences.
/// 
/// This service manages persistent app preferences, including the onboarding
/// completion flag.
class StorageService {
  static const String _onboardingKey = 'onboarding_completed';

  /// Retrieves the onboarding completion status from local storage.
  /// 
  /// Returns `true` if the user has completed onboarding, `false` otherwise.
  /// Defaults to `false` if the key is not found.
  /// 
  /// Throws [StorageException] if there's an error accessing storage.
  static Future<bool> getOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
    } catch (e) {
      throw StorageException(
        'Failed to retrieve onboarding status: ${e.toString()}',
      );
    }
  }

  /// Sets the onboarding completion status in local storage.
  /// 
  /// [value] - The completion status to store (true = completed, false = not completed)
  /// 
  /// Throws [StorageException] if there's an error writing to storage.
  static Future<void> setOnboardingCompleted(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, value);
    } catch (e) {
      throw StorageException(
        'Failed to save onboarding status: ${e.toString()}',
      );
    }
  }

  /// Clears all stored preferences.
  /// 
  /// This is primarily useful for testing or resetting the app state.
  /// 
  /// Throws [StorageException] if there's an error clearing storage.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw StorageException(
        'Failed to clear storage: ${e.toString()}',
      );
    }
  }
}

/// Exception thrown when storage operations fail.
class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
