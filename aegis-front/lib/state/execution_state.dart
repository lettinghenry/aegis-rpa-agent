import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/execution_session.dart';
import '../models/subtask.dart';
import '../models/status_update.dart';
import '../services/backend_api_service.dart';
import '../services/websocket_service.dart';
import '../services/window_service.dart';

/// Connection status for WebSocket
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// Execution state notifier for managing task execution lifecycle
/// 
/// Handles:
/// - Starting execution by submitting tasks to the backend
/// - Connecting to WebSocket for real-time updates
/// - Processing status updates including window state transitions
/// - Cancelling execution and cleaning up resources
/// - Managing window mode state (normal/minimal)
/// - App lifecycle management (backgrounding/foregrounding)
/// - WebSocket persistence and reconnection
class ExecutionStateNotifier extends ChangeNotifier with WidgetsBindingObserver {
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
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  bool _isAppInBackground = false;
  List<StatusUpdate> _pendingUpdates = [];

  ExecutionStateNotifier({
    required BackendApiService apiService,
    required WebSocketService wsService,
    required WindowService windowService,
  })  : _apiService = apiService,
        _wsService = wsService,
        _windowService = windowService {
    // Register as lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  // Getters
  String? get sessionId => _sessionId;
  String? get instruction => _instruction;
  SessionStatus get status => _status;
  List<Subtask> get subtasks => List.unmodifiable(_subtasks);
  bool get isConnected => _isConnected;
  bool get isMinimalMode => _isMinimalMode;
  String? get errorMessage => _errorMessage;
  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isAppInBackground => _isAppInBackground;

  /// Start execution by submitting task and connecting WebSocket
  /// 
  /// Validates: Requirements 2.3, 2.4, 3.1, 7.2
  Future<void> startExecution(String instruction) async {
    try {
      _instruction = instruction;
      _status = SessionStatus.pending;
      _errorMessage = null;
      _subtasks = [];
      _pendingUpdates = [];
      _connectionStatus = ConnectionStatus.connecting;
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
      _connectionStatus = ConnectionStatus.connected;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = SessionStatus.failed;
      _connectionStatus = ConnectionStatus.failed;
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
  /// - Queuing updates when app is backgrounded
  /// 
  /// Validates: Requirements 3.2, 3.3, 3.4, 3.5, 9.3, 9.4, 9.5, 13.1, 13.2, 13.3, 13.4, 13.5
  void onStatusUpdate(StatusUpdate update) {
    try {
      // If app is backgrounded, queue the update for later processing
      if (_isAppInBackground) {
        _pendingUpdates.add(update);
        return;
      }

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
        
        // Update connection status
        _connectionStatus = ConnectionStatus.disconnected;
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
      _connectionStatus = ConnectionStatus.disconnected;

      // Restore window if in minimal mode
      if (_isMinimalMode) {
        await _windowService.exitMinimalMode();
        _isMinimalMode = false;
      }

      // Update status
      _status = SessionStatus.cancelled;
      
      // Clear pending updates
      _pendingUpdates.clear();
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to cancel execution: $e';
      _connectionStatus = ConnectionStatus.failed;
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
  /// 
  /// Validates: Requirements 7.2, 7.3
  void _handleWebSocketError(dynamic error) {
    print('WebSocket error: $error');
    _isConnected = false;
    
    // Update connection status based on reconnection state
    if (_wsService.isConnected) {
      _connectionStatus = ConnectionStatus.connected;
    } else {
      // Check if we're still trying to reconnect
      final isReconnecting = _sessionId != null && 
                            _status == SessionStatus.inProgress;
      _connectionStatus = isReconnecting 
          ? ConnectionStatus.reconnecting 
          : ConnectionStatus.failed;
    }
    
    // Only show error if not reconnecting
    if (_connectionStatus == ConnectionStatus.failed) {
      _errorMessage = 'Connection error: $error';
    }
    
    notifyListeners();
  }

  /// Handle WebSocket connection closure
  /// 
  /// Validates: Requirements 7.2, 7.3, 9.4
  void _handleWebSocketDone() {
    print('WebSocket connection closed');
    _isConnected = false;
    
    // Don't restore window or change status if app is backgrounded
    // The connection will be maintained and restored on foreground
    if (_isAppInBackground) {
      _connectionStatus = ConnectionStatus.disconnected;
      notifyListeners();
      return;
    }
    
    // Update connection status
    final isReconnecting = _sessionId != null && 
                          _status == SessionStatus.inProgress;
    _connectionStatus = isReconnecting 
        ? ConnectionStatus.reconnecting 
        : ConnectionStatus.disconnected;
    
    // Restore window if in minimal mode and execution is complete
    if (_isMinimalMode && 
        (_status == SessionStatus.completed || 
         _status == SessionStatus.failed || 
         _status == SessionStatus.cancelled)) {
      _windowService.exitMinimalMode();
      _isMinimalMode = false;
    }
    
    notifyListeners();
  }

  /// Handle app lifecycle state changes
  /// 
  /// Validates: Requirements 9.4, 9.5
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App is going to background
        _handleAppBackgrounded();
        break;
      case AppLifecycleState.resumed:
        // App is returning to foreground
        _handleAppForegrounded();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is being terminated or hidden
        break;
    }
  }

  /// Handle app going to background
  /// 
  /// Maintains WebSocket connection during backgrounding.
  /// Validates: Requirements 9.4
  void _handleAppBackgrounded() {
    print('App backgrounded - maintaining WebSocket connection');
    _isAppInBackground = true;
    
    // WebSocket connection is maintained
    // No need to disconnect or change state
    notifyListeners();
  }

  /// Handle app returning to foreground
  /// 
  /// Syncs UI with current execution state and processes pending updates.
  /// Validates: Requirements 9.5
  void _handleAppForegrounded() {
    print('App foregrounded - syncing UI state');
    _isAppInBackground = false;
    
    // Check WebSocket connection status
    if (_sessionId != null && _status == SessionStatus.inProgress) {
      if (!_wsService.isConnected) {
        // Connection was lost while backgrounded, attempt reconnection
        print('Reconnecting WebSocket after foreground');
        _connectionStatus = ConnectionStatus.reconnecting;
        _wsService.reconnect();
      } else {
        // Connection is still active
        _connectionStatus = ConnectionStatus.connected;
        _isConnected = true;
      }
      
      // Process any pending updates that arrived while backgrounded
      _processPendingUpdates();
    }
    
    notifyListeners();
  }

  /// Process pending updates that arrived while app was backgrounded
  void _processPendingUpdates() {
    if (_pendingUpdates.isEmpty) return;
    
    print('Processing ${_pendingUpdates.length} pending updates');
    for (final update in _pendingUpdates) {
      onStatusUpdate(update);
    }
    _pendingUpdates.clear();
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
    _connectionStatus = ConnectionStatus.disconnected;
    _isAppInBackground = false;
    _pendingUpdates.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Ensure window is restored on dispose
    if (_isMinimalMode) {
      _windowService.exitMinimalMode();
    }
    super.dispose();
  }
}
