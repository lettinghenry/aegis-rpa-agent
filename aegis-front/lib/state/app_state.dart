import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

/// App-level state management for global application state.
/// 
/// This class manages the onboarding status and other app-wide state.
/// It extends [ChangeNotifier] to provide reactive state updates to the UI.
class AppState extends ChangeNotifier {
  bool _onboardingCompleted = false;
  bool _isLoading = false;
  String? _errorMessage;

  /// Whether the user has completed the onboarding flow.
  bool get onboardingCompleted => _onboardingCompleted;

  /// Whether the state is currently loading.
  bool get isLoading => _isLoading;

  /// Error message if any operation failed.
  String? get errorMessage => _errorMessage;

  /// Loads the onboarding completion status from local storage.
  /// 
  /// This should be called when the app starts to determine whether
  /// to show the onboarding screen or the landing screen.
  /// 
  /// Updates [onboardingCompleted] with the stored value and notifies listeners.
  Future<void> loadOnboardingStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _onboardingCompleted = await StorageService.getOnboardingCompleted();
    } catch (e) {
      _errorMessage = 'Failed to load onboarding status: ${e.toString()}';
      // Default to false if loading fails
      _onboardingCompleted = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks the onboarding as completed and persists the status.
  /// 
  /// This should be called when the user completes the onboarding flow.
  /// Updates local storage and the in-memory state, then notifies listeners.
  Future<void> completeOnboarding() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await StorageService.setOnboardingCompleted(true);
      _onboardingCompleted = true;
    } catch (e) {
      _errorMessage = 'Failed to save onboarding status: ${e.toString()}';
      // Keep the current state if saving fails
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resets the onboarding status (primarily for testing).
  /// 
  /// This marks onboarding as incomplete and persists the change.
  Future<void> resetOnboarding() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await StorageService.setOnboardingCompleted(false);
      _onboardingCompleted = false;
    } catch (e) {
      _errorMessage = 'Failed to reset onboarding status: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears any error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
