import 'package:flutter/foundation.dart';
import '../models/execution_session.dart';
import '../models/subtask.dart';
import '../models/status_update.dart';
import '../services/backend_api_service.dart';
import '../services/websocket_service.dart';
import '../services/window_service.dart';

/// Execution state notifier for managing task execution lifecycle
/// 
/// Handles:
/// - Starting execution by submitting tasks to the backend
/// - Connecting to WebSocket for real-time updates
/// - Processing status updates including window state transitions
/// - Cancelling execution and cleaning up resources
/// - Managing window mode state (normal/minimal)
class ExecutionStateNotifier extends ChangeNotifier {
  final BackendApiService _apiService;
  final WebSocketService _wsService;
  final WindowService _windowService;

  String? _sessionId;
  String? _instruction;
  SessionStatus _status = SessionStatus.pending;
  List<Subtask> _subtasks = [];
  bool _isConnected = false;
  bool _isMinimalMode = false;
  String? _errorMessage;

  ExecutionStateNotifier({
    required BackendApiService apiService,
    required WebSocketService wsService,
    required WindowService windowService,
  })  : _apiService = apiService,
        _wsService = wsService,
        _windowService = windowService;

  // Getters
  String? get sessionId => _sessionId;
  String? get instruction => _instruction;
  SessionStatus get status => _status;
  List<Subtask> get subtasks => List.unmodifiable(_subtasks);
  bool get isConnected => _isConnected;
  bool get isMinimalMode => _isMinimalMode;
  String? get errorMessage => _errorMessage;

  /// Start execution by submitting task and connecting WebSocket
  /// 
  /// Validates: Requirements 2.3, 2.4, 3.1
  Future<void> startExecution(String instruction) async {
    try {
      _instruction = instruction;
      _status = SessionStatus.pending;
      _errorMessage = null;
      _subtasks = [];
      notifyListeners();

      // Submit task to backend
      final response = await _apiService.startTask(instruction);
      _sessionId = response.sessionId;
      _status = SessionStatus.inProgress;
      notifyListeners();

      // Connect WebSocket for real-time updates
      await _wsService.connect(
        _sessionId!,
        onUpdate: onStatusUpdate,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
      );

      _isConnected = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = SessionStatus.failed;
      notifyListeners();
      rethrow;
    }
  }

  /// Handle status updates from WebSocket
  /// 
  /// Processes incoming status updates including:
  /// - Window state transitions (minimal/normal)
  /// - Subtask updates (new, completed, failed)
  /// - Overall session status changes
  /// 
  /// Validates: Requirements 3.2, 3.3, 3.4, 3.5, 13.1, 13.2, 13.3, 13.4, 13.5
  void onStatusUpdate(StatusUpdate update) {
    try {
      // Handle window state changes
      if (update.windowState != null) {
        if (update.windowState == 'minimal' && !_isMinimalMode) {
          _windowService.enterMinimalMode();
          _isMinimalMode = true;
        } else if (update.windowState == 'normal' && _isMinimalMode) {
          _windowService.exitMinimalMode();
          _isMinimalMode = false;
        }
      }

      // Handle subtask updates
      if (update.subtask != null) {
        _updateSubtask(update.subtask!);
      }

      // Update overall status
      _status = SessionStatus.fromString(update.overallStatus);

      // Restore window on completion
      if (_status == SessionStatus.completed ||
          _status == SessionStatus.failed ||
          _status == SessionStatus.cancelled) {
        if (_isMinimalMode) {
          _windowService.exitMinimalMode();
          _isMinimalMode = false;
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error handling status update: $e');
      _errorMessage = 'Error processing update: $e';
      notifyListeners();
    }
  }

  /// Cancel execution and restore window
  /// 
  /// Sends cancellation request to backend, disconnects WebSocket,
  /// and restores window to normal mode if in minimal mode.
  /// 
  /// Validates: Requirements 5.3, 5.4, 13.5
  Future<void> cancelExecution() async {
    if (_sessionId == null) return;

    try {
      // Send cancellation request to backend
      await _apiService.cancelSession(_sessionId!);

      // Disconnect WebSocket
      await _wsService.disconnect();
      _isConnected = false;

      // Restore window if in minimal mode
      if (_isMinimalMode) {
        await _windowService.exitMinimalMode();
        _isMinimalMode = false;
      }

      // Update status
      _status = SessionStatus.cancelled;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to cancel execution: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Update or add a subtask in the list
  void _updateSubtask(Subtask newSubtask) {
    final index = _subtasks.indexWhere((s) => s.id == newSubtask.id);
    if (index >= 0) {
      // Update existing subtask
      _subtasks[index] = newSubtask;
    } else {
      // Add new subtask
      _subtasks.add(newSubtask);
    }
  }

  /// Handle WebSocket errors
  void _handleWebSocketError(dynamic error) {
    print('WebSocket error: $error');
    _isConnected = false;
    _errorMessage = 'Connection error: $error';
    notifyListeners();
  }

  /// Handle WebSocket connection closure
  void _handleWebSocketDone() {
    print('WebSocket connection closed');
    _isConnected = false;
    
    // Restore window if in minimal mode
    if (_isMinimalMode) {
      _windowService.exitMinimalMode();
      _isMinimalMode = false;
    }
    
    notifyListeners();
  }

  /// Reset state (useful for testing)
  void reset() {
    _sessionId = null;
    _instruction = null;
    _status = SessionStatus.pending;
    _subtasks = [];
    _isConnected = false;
    _isMinimalMode = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Ensure window is restored on dispose
    if (_isMinimalMode) {
      _windowService.exitMinimalMode();
    }
    super.dispose();
  }
}
