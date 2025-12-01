# Technology Stack

## Framework & Language

- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **Design System**: Material 3

## Core Dependencies

- **State Management**: Provider (or Riverpod)
- **Networking**: http package
- **WebSocket**: web_socket_channel
- **Local Storage**: shared_preferences
- **Testing**: flutter_test, dart_check (property-based testing)

## Backend Integration

- **REST API**: HTTP client for task submission, history retrieval, cancellation
- **WebSocket**: Real-time execution status updates
- **Backend URL**: Configurable via `lib/config/app_config.dart` or environment variables

## Common Commands

### Development

```bash
# Run on Windows
flutter run -d windows

# Run on macOS
flutter run -d macos

# Run on Linux
flutter run -d linux

# Run with custom backend URL
flutter run -d windows --dart-define=BACKEND_URL=http://192.168.1.100:8000

# Hot reload (during development)
# Press 'r' in terminal
```

### Testing

```bash
# Run all tests
flutter test

# Run unit tests only
flutter test test/unit/

# Run widget tests
flutter test test/widget/

# Run property-based tests
flutter test test/property/ --reporter expanded

# Run with coverage
flutter test --coverage
```

### Code Quality

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Install dependencies
flutter pub get

# Clean build artifacts
flutter clean
```

### Building

```bash
# Windows release build
flutter build windows --release

# macOS release build
flutter build macos --release

# Linux release build
flutter build linux --release
```

## Configuration

Backend connection settings in `lib/config/app_config.dart`:
- `backendUrl`: HTTP API endpoint (default: http://localhost:8000)
- `wsUrl`: WebSocket endpoint (default: ws://localhost:8000)
- `requestTimeout`: API request timeout (default: 30s)
- `wsReconnectAttempts`: WebSocket reconnection attempts (default: 3)
