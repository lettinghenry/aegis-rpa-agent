/// Application configuration for AEGIS RPA Frontend
/// 
/// Provides centralized configuration for backend URLs, timeouts,
/// retry attempts, and window management settings.
class AppConfig {
  // Backend Configuration
  static const String defaultBackendUrl = 'http://localhost:8000';
  static const String defaultWsUrl = 'ws://localhost:8000';
  
  /// Backend HTTP API base URL
  /// Can be overridden via --dart-define=BACKEND_URL=<url>
  static String get backendUrl {
    const url = String.fromEnvironment('BACKEND_URL', defaultValue: defaultBackendUrl);
    _validateUrl(url, 'BACKEND_URL');
    return url;
  }
  
  /// Backend WebSocket URL
  /// Can be overridden via --dart-define=WS_URL=<url>
  static String get wsUrl {
    const url = String.fromEnvironment('WS_URL', defaultValue: defaultWsUrl);
    _validateUrl(url, 'WS_URL');
    return url;
  }
  
  // Timeout Configuration
  
  /// HTTP request timeout in seconds
  static const int requestTimeoutSeconds = 30;
  
  /// HTTP request timeout as Duration
  static Duration get requestTimeout => Duration(seconds: requestTimeoutSeconds);
  
  /// WebSocket ping interval in seconds
  static const int wsPingIntervalSeconds = 30;
  
  /// WebSocket ping interval as Duration
  static Duration get wsPingInterval => Duration(seconds: wsPingIntervalSeconds);
  
  // Retry Configuration
  
  /// Maximum number of WebSocket reconnection attempts
  static const int wsReconnectAttempts = 3;
  
  /// Delay between WebSocket reconnection attempts in seconds
  static const int wsReconnectDelaySeconds = 2;
  
  /// WebSocket reconnection delay as Duration
  static Duration get wsReconnectDelay => Duration(seconds: wsReconnectDelaySeconds);
  
  /// Maximum number of HTTP request retry attempts
  static const int httpRetryAttempts = 2;
  
  /// Delay between HTTP retry attempts in seconds
  static const int httpRetryDelaySeconds = 1;
  
  /// HTTP retry delay as Duration
  static Duration get httpRetryDelay => Duration(seconds: httpRetryDelaySeconds);
  
  // Validation
  
  /// Validates all required configuration on app startup
  /// Throws [ConfigurationException] if validation fails
  static void validate() {
    try {
      // Validate URLs
      _validateUrl(backendUrl, 'BACKEND_URL');
      _validateUrl(wsUrl, 'WS_URL');
      
      // Validate timeouts
      if (requestTimeoutSeconds <= 0) {
        throw ConfigurationException('Request timeout must be positive');
      }
      if (wsPingIntervalSeconds <= 0) {
        throw ConfigurationException('WebSocket ping interval must be positive');
      }
      
      // Validate retry attempts
      if (wsReconnectAttempts < 0) {
        throw ConfigurationException('WebSocket reconnect attempts must be non-negative');
      }
      if (httpRetryAttempts < 0) {
        throw ConfigurationException('HTTP retry attempts must be non-negative');
      }
      
      // Validate retry delays
      if (wsReconnectDelaySeconds < 0) {
        throw ConfigurationException('WebSocket reconnect delay must be non-negative');
      }
      if (httpRetryDelaySeconds < 0) {
        throw ConfigurationException('HTTP retry delay must be non-negative');
      }
      
      // Validate window config
      WindowConfig.validate();
    } catch (e) {
      throw ConfigurationException('Configuration validation failed: $e');
    }
  }
  
  /// Validates a URL string
  static void _validateUrl(String url, String name) {
    if (url.isEmpty) {
      throw ConfigurationException('$name cannot be empty');
    }
    
    // Basic URL validation
    if (!url.startsWith('http://') && 
        !url.startsWith('https://') && 
        !url.startsWith('ws://') && 
        !url.startsWith('wss://')) {
      throw ConfigurationException(
        '$name must start with http://, https://, ws://, or wss://'
      );
    }
  }
}

/// Window management configuration for minimal mode during RPA execution
class WindowConfig {
  // Minimal Window Size
  
  /// Width of minimal window in pixels
  static const double minimalWidth = 300.0;
  
  /// Height of minimal window in pixels
  static const double minimalHeight = 100.0;
  
  // Transition Configuration
  
  /// Duration of window transition animation in milliseconds
  static const int transitionDurationMs = 250;
  
  /// Window transition duration as Duration
  static Duration get transitionDuration => Duration(milliseconds: transitionDurationMs);
  
  // Position Configuration
  
  /// Horizontal offset from right edge of screen in pixels
  static const double minimalOffsetX = 20.0;
  
  /// Vertical offset from top edge of screen in pixels
  static const double minimalOffsetY = 20.0;
  
  // Window Behavior
  
  /// Whether to enable automatic window minimization during RPA execution
  static const bool enableAutoMinimize = true;
  
  /// Whether to allow user to drag minimal window
  static const bool allowDragInMinimalMode = true;
  
  /// Whether to show cancel button in minimal mode
  static const bool showCancelInMinimalMode = true;
  
  // Validation
  
  /// Validates window configuration
  /// Throws [ConfigurationException] if validation fails
  static void validate() {
    if (minimalWidth <= 0) {
      throw ConfigurationException('Minimal window width must be positive');
    }
    if (minimalHeight <= 0) {
      throw ConfigurationException('Minimal window height must be positive');
    }
    if (transitionDurationMs < 0) {
      throw ConfigurationException('Transition duration must be non-negative');
    }
    if (minimalOffsetX < 0) {
      throw ConfigurationException('Minimal offset X must be non-negative');
    }
    if (minimalOffsetY < 0) {
      throw ConfigurationException('Minimal offset Y must be non-negative');
    }
  }
}

/// Exception thrown when configuration validation fails
class ConfigurationException implements Exception {
  final String message;
  
  ConfigurationException(this.message);
  
  @override
  String toString() => 'ConfigurationException: $message';
}
