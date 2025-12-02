import 'package:flutter/foundation.dart';
import '../models/session_summary.dart';
import '../services/backend_api_service.dart';

/// History state notifier for managing execution history
/// 
/// Handles:
/// - Loading execution history from the backend
/// - Tracking sessions list, loading state, and errors
/// - Providing reactive updates to the UI
/// 
/// Validates: Requirements 6.2, 6.3
class HistoryStateNotifier extends ChangeNotifier {
  final BackendApiService _apiService;

  List<SessionSummary> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  HistoryStateNotifier({
    required BackendApiService apiService,
  }) : _apiService = apiService;

  // Getters
  List<SessionSummary> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load execution history from the backend
  /// 
  /// Fetches the list of past execution sessions and updates the state.
  /// Sets loading state during the request and handles errors gracefully.
  /// 
  /// Validates: Requirements 6.2
  Future<void> loadHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getHistory();
      _sessions = response.sessions;
    } catch (e) {
      _errorMessage = e.toString();
      // Keep existing sessions on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear any error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset state (useful for testing)
  void reset() {
    _sessions = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
