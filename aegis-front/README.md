# AEGIS RPA Frontend

A Flutter-based desktop application that provides an intuitive interface for commanding and monitoring the AEGIS RPA Backend's cognitive automation engine.

## Overview

AEGIS RPA Frontend is a Material 3-designed Flutter application that allows users to submit natural language task instructions and monitor real-time execution progress. The app features a clean, three-screen flow with WebSocket-based live updates and comprehensive execution history.

### Key Features

- **🎯 Simple Task Input**: Submit automation tasks using natural language
- **📊 Real-Time Progress**: Live WebSocket updates showing execution progress
- **📜 Execution History**: Review past automation sessions with detailed results
- **🎨 Material 3 Design**: Modern, beautiful UI following Material Design 3 guidelines
- **🌓 Dark Mode Support**: Automatic light/dark theme based on system preferences
- **🔄 Smart State Management**: Reactive UI using Provider/Riverpod
- **⚡ Responsive**: Fast, fluid animations and transitions
- **🛡️ Robust Error Handling**: User-friendly error messages and automatic retry logic

## Architecture

```
┌─────────────────────────────────────────────┐
│           Flutter Application               │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │         Presentation Layer            │ │
│  │  - Onboarding Screen                  │ │
│  │  - Landing Screen                     │ │
│  │  - Task Execution Screen              │ │
│  │  - History View                       │ │
│  └───────────────┬───────────────────────┘ │
│                  │                          │
│  ┌───────────────▼───────────────────────┐ │
│  │      State Management (Provider)     │ │
│  │  - ExecutionState                    │ │
│  │  - HistoryState                      │ │
│  │  - AppState                          │ │
│  └───────────────┬───────────────────────┘ │
│                  │                          │
│  ┌───────────────▼───────────────────────┐ │
│  │         Service Layer                │ │
│  │  - BackendApiService                 │ │
│  │  - WebSocketService                  │ │
│  │  - StorageService                    │ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
         │
         │ HTTP / WebSocket
         ▼
┌─────────────────────────────────────────────┐
│         AEGIS Backend (FastAPI)             │
└─────────────────────────────────────────────┘
```

## Technology Stack

- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: Provider (or Riverpod)
- **Networking**: http package
- **WebSocket**: web_socket_channel
- **Local Storage**: shared_preferences
- **Design System**: Material 3
- **Testing**: flutter_test, dart_check (property-based testing)

## Prerequisites

- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Windows, macOS, or Linux for desktop development
- AEGIS Backend running (see aegis-back/README.md)

## Installation

### 1. Install Flutter

Follow the official Flutter installation guide:
- https://docs.flutter.dev/get-started/install

Verify installation:
```bash
flutter doctor
```

### 2. Clone the Repository

```bash
git clone <repository-url>
cd aegis-rpa-agent/aegis-front
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Configure Backend URL

Edit `lib/config/app_config.dart` or set environment variables:

```dart
class AppConfig {
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8000',
  );
  
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:8000',
  );
}
```

## Running the Application

### Development Mode

**Windows:**
```bash
flutter run -d windows
```

**macOS:**
```bash
flutter run -d macos
```

**Linux:**
```bash
flutter run -d linux
```

### With Custom Backend URL

```bash
flutter run -d windows --dart-define=BACKEND_URL=http://192.168.1.100:8000
```

### Release Build

**Windows:**
```bash
flutter build windows --release
```

The executable will be in `build/windows/runner/Release/`

**macOS:**
```bash
flutter build macos --release
```

**Linux:**
```bash
flutter build linux --release
```

## Testing

### Run All Tests

```bash
flutter test
```

### Run Unit Tests Only

```bash
flutter test test/unit/
```

### Run Widget Tests

```bash
flutter test test/widget/
```

### Run Property-Based Tests

```bash
flutter test test/property/ --reporter expanded
```

### Run with Coverage

```bash
flutter test --coverage
```

View coverage report:
```bash
# Install lcov (if not already installed)
# Windows: choco install lcov
# macOS: brew install lcov
# Linux: apt-get install lcov

genhtml coverage/lcov.info -o coverage/html
# Open coverage/html/index.html in browser
```

### Run Specific Test

```bash
flutter test test/unit/models/task_instruction_test.dart
```

## Project Structure

```
aegis-front/
├── lib/
│   ├── main.dart                    # Application entry point
│   ├── config/
│   │   └── app_config.dart          # Configuration
│   ├── models/
│   │   ├── task_instruction.dart    # Request/response models
│   │   ├── subtask.dart             # Subtask model
│   │   ├── execution_session.dart   # Session model
│   │   ├── status_update.dart       # WebSocket update model
│   │   └── session_summary.dart     # History summary model
│   ├── services/
│   │   ├── backend_api_service.dart # HTTP API client
│   │   ├── websocket_service.dart   # WebSocket client
│   │   └── storage_service.dart     # Local storage
│   ├── state/
│   │   ├── app_state.dart           # App-level state
│   │   ├── execution_state.dart     # Execution state
│   │   └── history_state.dart       # History state
│   ├── screens/
│   │   ├── onboarding_screen.dart   # First-time user onboarding
│   │   ├── landing_screen.dart      # Main task input screen
│   │   ├── task_execution_screen.dart # Execution progress
│   │   ├── history_view.dart        # Execution history
│   │   └── session_detail_view.dart # Session details
│   ├── widgets/
│   │   ├── subtask_card.dart        # Subtask display card
│   │   └── session_summary_card.dart # History item card
│   ├── theme/
│   │   └── app_theme.dart           # Material 3 theme
│   └── routes/
│       └── app_router.dart          # Navigation routing
├── test/
│   ├── unit/                        # Unit tests
│   ├── widget/                      # Widget tests
│   ├── integration/                 # Integration tests
│   └── property/                    # Property-based tests
├── assets/                          # Images, fonts, etc.
├── pubspec.yaml                     # Dependencies
└── README.md                        # This file
```

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

Follow the implementation tasks in `.kiro/specs/rpa-frontend/tasks.md`

### 3. Run Tests

```bash
flutter test
```

### 4. Check Code Quality

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/
```

### 5. Commit Changes

```bash
git add .
git commit -m "feat: your feature description"
```

### 6. Push and Create PR

```bash
git push origin feature/your-feature-name
```

## User Guide

### First Launch

1. **Onboarding**: On first launch, you'll see an onboarding screen explaining AEGIS capabilities
2. **Get Started**: Tap "Get Started" to proceed to the main screen

### Submitting a Task

1. **Enter Instruction**: Type your automation task in natural language
   - Example: "Open Notepad and type 'Hello World'"
   - Example: "Check my Outlook inbox and download any PDFs"
2. **Submit**: Tap the submit button
3. **Monitor Progress**: Watch real-time execution progress with subtask updates

### Viewing History

1. **Open History**: Tap the history icon on the landing screen
2. **Browse Sessions**: Scroll through past automation sessions
3. **View Details**: Tap any session to see complete execution details

### Canceling Execution

1. **Tap Cancel**: During execution, tap the "Cancel" button
2. **Confirm**: Confirm cancellation in the dialog
3. **Return**: You'll be returned to the landing screen

## Configuration

### Backend Connection

Edit `lib/config/app_config.dart`:

```dart
static const String backendUrl = 'http://your-backend-url:8000';
static const String wsUrl = 'ws://your-backend-url:8000';
```

### WebSocket Settings

```dart
static const int wsReconnectAttempts = 3;
static const Duration wsReconnectDelay = Duration(seconds: 2);
```

### Request Timeout

```dart
static const Duration requestTimeout = Duration(seconds: 30);
```

## Troubleshooting

### Common Issues

**Issue**: "Unable to connect to backend"
- **Solution**: Ensure AEGIS Backend is running at the configured URL
- Check `lib/config/app_config.dart` for correct backend URL

**Issue**: WebSocket connection keeps dropping
- **Solution**: Check network stability and firewall settings
- Verify backend WebSocket endpoint is accessible

**Issue**: App crashes on startup
- **Solution**: Run `flutter clean && flutter pub get`
- Check Flutter and Dart SDK versions

**Issue**: UI not updating during execution
- **Solution**: Verify WebSocket connection is established
- Check browser console for WebSocket errors

### Debug Mode

Run with verbose logging:

```bash
flutter run -d windows -v
```

### Hot Reload

During development, use hot reload for faster iteration:
- Press `r` in the terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

## Building for Production

### Windows

```bash
flutter build windows --release
```

Create installer (using Inno Setup or similar):
```bash
# Install Inno Setup
# Create installer script
iscc installer_script.iss
```

### macOS

```bash
flutter build macos --release
```

Create DMG:
```bash
# Use create-dmg or similar tool
create-dmg build/macos/Build/Products/Release/aegis_front.app
```

### Linux

```bash
flutter build linux --release
```

Create AppImage or Snap package as needed.

## Contributing

1. Review the design document: `.kiro/specs/rpa-frontend/design.md`
2. Check the requirements: `.kiro/specs/rpa-frontend/requirements.md`
3. Follow the task list: `.kiro/specs/rpa-frontend/tasks.md`
4. Write tests for new features
5. Ensure all tests pass before submitting PR
6. Follow Dart style guidelines

## Performance Optimization

### Tips for Better Performance

- Use `const` constructors where possible
- Avoid rebuilding widgets unnecessarily
- Use `ListView.builder` for long lists
- Optimize image assets
- Profile with Flutter DevTools

### Profiling

```bash
flutter run --profile -d windows
```

Open DevTools:
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

## Accessibility

The app follows accessibility best practices:
- Semantic labels on all interactive elements
- Proper focus order
- Screen reader support
- High contrast mode support
- Keyboard navigation

Test with screen readers:
- **Windows**: NVDA or Narrator
- **macOS**: VoiceOver
- **Linux**: Orca

## License

[License](aegis-back/LICENSE)

## Support

For issues and questions:
- Create an issue in the GitHub repository
- Contact the development team
- Check the documentation in `.kiro/specs/`

## Roadmap

- [ ] Offline mode with cached sessions
- [ ] Voice input for task instructions
- [ ] Favorites for frequently used instructions
- [ ] Push notifications for completed tasks
- [ ] Custom color themes
- [ ] Multi-language support (i18n)
- [ ] Mobile support (Android/iOS)
- [ ] Advanced animations and micro-interactions
