# Project Structure

## Directory Organization

```
aegis-front/
├── lib/
│   ├── main.dart                    # Application entry point with Provider setup
│   ├── config/
│   │   └── app_config.dart          # Backend URL, timeouts, environment config
│   ├── models/
│   │   ├── task_instruction.dart    # Request/response models
│   │   ├── subtask.dart             # Subtask model with status enum
│   │   ├── execution_session.dart   # Session model with status enum
│   │   ├── status_update.dart       # WebSocket update model
│   │   └── session_summary.dart     # History summary model
│   ├── services/
│   │   ├── backend_api_service.dart # HTTP API client (REST endpoints)
│   │   ├── websocket_service.dart   # WebSocket client with reconnection
│   │   └── storage_service.dart     # Local storage (SharedPreferences)
│   ├── state/
│   │   ├── app_state.dart           # App-level state (onboarding)
│   │   ├── execution_state.dart     # Execution state (task progress)
│   │   └── history_state.dart       # History state (session list)
│   ├── screens/
│   │   ├── onboarding_screen.dart   # First-time user onboarding
│   │   ├── landing_screen.dart      # Main task input screen
│   │   ├── task_execution_screen.dart # Execution progress display
│   │   ├── history_view.dart        # Execution history list
│   │   └── session_detail_view.dart # Session details view
│   ├── widgets/
│   │   ├── subtask_card.dart        # Subtask display card
│   │   └── session_summary_card.dart # History item card
│   ├── theme/
│   │   └── app_theme.dart           # Material 3 theme (light/dark)
│   └── routes/
│       └── app_router.dart          # Navigation routing
├── test/
│   ├── unit/                        # Unit tests for models, services, state
│   ├── widget/                      # Widget tests for screens and widgets
│   ├── integration/                 # Integration tests for complete flows
│   └── property/                    # Property-based tests (dart_check)
├── assets/                          # Images, fonts, static resources
├── .kiro/
│   ├── specs/                       # Feature specifications
│   └── steering/                    # AI assistant guidance (this file)
├── pubspec.yaml                     # Dependencies and project metadata
└── README.md                        # Project documentation
```

## Architecture Layers

### Presentation Layer
- **Screens**: Full-page views (onboarding, landing, execution, history)
- **Widgets**: Reusable UI components (cards, buttons, indicators)
- **Theme**: Material 3 styling and color schemes

### State Management Layer
- **Provider/Riverpod**: Reactive state propagation
- **State Notifiers**: AppState, ExecutionState, HistoryState
- **State Preservation**: Maintained across navigation

### Service Layer
- **BackendApiService**: HTTP REST API communication
- **WebSocketService**: Real-time status updates
- **StorageService**: Local persistence (onboarding flag, etc.)

## Key Conventions

### Models
- All models include `fromJson()` and `toJson()` methods
- Use enums for status fields (SubtaskStatus, SessionStatus)
- Match backend Pydantic models for type safety

### State Management
- Extend `ChangeNotifier` for state classes
- Call `notifyListeners()` after state changes
- Use `Consumer` or `Provider.of` in widgets

### Services
- Services are stateless and injected via Provider
- All async operations return `Future<T>`
- Comprehensive error handling with typed exceptions

### Testing
- Unit tests for all models, services, and state classes
- Widget tests for all screens and reusable widgets
- Property-based tests for critical invariants
- Integration tests for complete user flows
- Target: 75% code coverage

### Navigation
- Centralized routing in `app_router.dart`
- Initial route determined by onboarding status
- State preserved across navigation transitions
