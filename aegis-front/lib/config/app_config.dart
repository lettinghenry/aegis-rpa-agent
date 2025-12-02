/// Application configuration for backend connection and timeouts
class AppConfig {
  /// Backend HTTP API base URL
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Backend WebSocket URL
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:8000',
  );

  /// HTTP request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);

  /// WebSocket reconnection attempts
  static const int wsReconnectAttempts = 3;

  /// WebSocket reconnection delay
  static const Duration wsReconnectDelay = Duration(seconds: 2);
}
