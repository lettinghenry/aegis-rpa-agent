import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/status_update.dart';
import '../config/app_config.dart';
import '../utils/json_parser.dart';

/// Service for managing WebSocket connections to receive real-time execution updates.
/// 
/// Handles connection establishment, message parsing, automatic reconnection,
/// and connection state tracking.
class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  String? _currentSessionId;
  Function(StatusUpdate)? _onUpdate;
  Function(dynamic)? _onError;
  Function()? _onDone;

  /// Maximum number of reconnection attempts
  static const int maxReconnectAttempts = 3;
  
  /// Delay between reconnection attempts
  static const Duration reconnectDelay = Duration(seconds: 2);

  /// Whether the WebSocket is currently connected
  bool get isConnected => _isConnected;

  /// Current session ID
  String? get currentSessionId => _currentSessionId;

  /// Connect to the WebSocket endpoint for a specific session
  /// 
  /// Establishes a WebSocket connection to receive real-time status updates
  /// for the given session ID.
  /// 
  /// [sessionId] - The execution session ID to monitor
  /// [onUpdate] - Callback invoked when a status update is received
  /// [onError] - Optional callback invoked when an error occurs
  /// [onDone] - Optional callback invoked when the connection closes
  Future<void> connect(
    String sessionId, {
    required Function(StatusUpdate) onUpdate,
    Function(dynamic)? onError,
    Function()? onDone,
  }) async {
    try {
      // Store callbacks and session ID
      _currentSessionId = sessionId;
      _onUpdate = onUpdate;
      _onError = onError;
      _onDone = onDone;

      // Build WebSocket URL
      final wsUrl = '${AppConfig.wsUrl}/ws/execution/$sessionId';
      
      // Create WebSocket channel
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to the stream
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      
      print('WebSocket connected to session: $sessionId');
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _isConnected = false;
      if (_onError != null) {
        _onError!(e);
      }
      rethrow;
    }
  }

  /// Disconnect from the WebSocket
  /// 
  /// Closes the WebSocket connection and cleans up resources.
  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      await _channel?.sink.close();
      
      _channel = null;
      _subscription = null;
      _isConnected = false;
      _currentSessionId = null;
      _reconnectAttempts = 0;
      
      print('WebSocket disconnected');
    } catch (e) {
      print('Error disconnecting WebSocket: $e');
    }
  }

  /// Reconnect to the WebSocket with retry logic
  /// 
  /// Attempts to reconnect up to [maxReconnectAttempts] times with
  /// [reconnectDelay] between attempts.
  Future<void> reconnect() async {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      if (_onError != null) {
        _onError!(Exception('Failed to reconnect after $maxReconnectAttempts attempts'));
      }
      return;
    }

    if (_currentSessionId == null || _onUpdate == null) {
      print('Cannot reconnect: missing session ID or callback');
      return;
    }

    _reconnectAttempts++;
    print('Reconnection attempt $_reconnectAttempts of $maxReconnectAttempts');

    try {
      // Disconnect first
      await disconnect();
      
      // Wait before reconnecting
      await Future.delayed(reconnectDelay);
      
      // Attempt to reconnect
      await connect(
        _currentSessionId!,
        onUpdate: _onUpdate!,
        onError: _onError,
        onDone: _onDone,
      );
      
      print('Reconnection successful');
    } catch (e) {
      print('Reconnection attempt $_reconnectAttempts failed: $e');
      
      // Try again if we haven't reached max attempts
      if (_reconnectAttempts < maxReconnectAttempts) {
        await reconnect();
      } else {
        if (_onError != null) {
          _onError!(Exception('Failed to reconnect after $maxReconnectAttempts attempts'));
        }
      }
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      // Parse JSON message
      final Map<String, dynamic> json = jsonDecode(message as String);
      
      // DEBUG: Log the raw message
      print('WebSocket received: $json');
      
      // Deserialize to StatusUpdate
      final update = StatusUpdate.fromJson(json);
      
      // DEBUG: Log parsed update
      print('Parsed StatusUpdate - subtask: ${update.subtask?.id}, status: ${update.overallStatus}');
      
      // Invoke callback
      if (_onUpdate != null) {
        _onUpdate!(update);
      }
    } on FormatException catch (e) {
      // Invalid JSON format
      developer.log(
        'Invalid JSON in WebSocket message: $message',
        name: 'WebSocketService',
        error: e,
      );
      print('Error: Received invalid JSON from WebSocket');
      if (_onError != null) {
        _onError!(Exception('Invalid message format from server'));
      }
    } on ParsingException catch (e) {
      // Model parsing error
      developer.log(
        'Failed to parse WebSocket message: $e',
        name: 'WebSocketService',
        error: e,
      );
      print('Error: Failed to parse WebSocket message: $e');
      if (_onError != null) {
        _onError!(Exception('Unexpected message format from server'));
      }
    } catch (e) {
      // Unknown error
      developer.log(
        'Unexpected error parsing WebSocket message: $e',
        name: 'WebSocketService',
        error: e,
      );
      print('Error parsing WebSocket message: $e');
      if (_onError != null) {
        _onError!(e);
      }
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    print('WebSocket error: $error');
    _isConnected = false;
    
    if (_onError != null) {
      _onError!(error);
    }
    
    // Attempt to reconnect on error
    reconnect();
  }

  /// Handle WebSocket connection closure
  void _handleDone() {
    print('WebSocket connection closed');
    _isConnected = false;
    
    if (_onDone != null) {
      _onDone!();
    }
    
    // Attempt to reconnect if connection was closed unexpectedly
    if (_reconnectAttempts < maxReconnectAttempts) {
      reconnect();
    }
  }

  /// Reset the service state (useful for testing)
  void reset() {
    _channel = null;
    _subscription = null;
    _isConnected = false;
    _reconnectAttempts = 0;
    _currentSessionId = null;
    _onUpdate = null;
    _onError = null;
    _onDone = null;
  }
}
