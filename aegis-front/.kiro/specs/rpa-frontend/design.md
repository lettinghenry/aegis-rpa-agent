# Design Document

## Overview

The AEGIS RPA Frontend is a Flutter application that provides an intuitive, Material 3-based interface for commanding and monitoring the AEGIS RPA Backend. The application follows a simple three-screen flow: Onboarding → Landing → Task Execution, with an additional History view accessible from the landing screen.

The frontend focuses on clarity and real-time feedback, using WebSockets to stream execution progress from the backend and displaying subtask status through visual cards. State management is handled using Provider/Riverpod for reactive UI updates, and all backend communication uses typed Dart models that mirror the backend's Pydantic schemas.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────┐
│           Flutter Application               │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │         Presentation Layer            │ │
│  │  ┌─────────────────────────────────┐  │ │
│  │  │  Onboarding Screen              │  │ │
│  │  │  Landing Screen                 │  │ │
│  │  │  Task Execution Screen          │  │ │
│  │  │  History View                   │  │ │
│  │  └─────────────────────────────────┘  │ │
│  └───────────────┬───────────────────────┘ │
│                  │                          │
│  ┌───────────────▼───────────────────────┐ │
│  │      State Management Layer          │ │
│  │  (Provider / Riverpod)               │ │
│  │  ┌─────────────────────────────────┐ │ │
│  │  │  ExecutionState                 │ │ │
│  │  │  HistoryState                   │ │ │
│  │  │  AppState                       │ │ │
│  │  └─────────────────────────────────┘ │ │
│  └───────────────┬───────────────────────┘ │
│                  │                          │
│  ┌───────────────▼───────────────────────┐ │
│  │         Service Layer                │ │
│  │  ┌─────────────────────────────────┐ │ │
│  │  │  BackendApiService              │ │ │
│  │  │  WebSocketService               │ │ │
│  │  │  StorageService                 │ │ │
│  │  └─────────────────────────────────┘ │ │
│  └───────────────┬───────────────────────┘ │
│                  │                          │
│  ┌───────────────▼───────────────────────┐ │
│  │         Data Layer                   │ │
│  │  ┌─────────────────────────────────┐ │ │
│  │  │  API Models (Dart classes)      │ │ │
│  │  │  Local Storage                  │ │ │
│  │  └─────────────────────────────────┘ │ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
         │
         │ HTTP / WebSocket
         ▼
┌─────────────────────────────────────────────┐
│         AEGIS Backend (FastAPI)             │
└─────────────────────────────────────────────┘
```

### Navigation Flow

```
App Launch
    │
    ▼
[First Time?] ──Yes──> Onboarding Screen ──> Landing Screen
    │                                              │
    No                                             │
    │                                              │
    └──────────────────────────────────────────────┘
                                                   │
                                    ┌──────────────┴──────────────┐
                                    │                             │
                              Submit Task                    View History
                                    │                             │
                                    ▼                             ▼
                          Task Execution Screen            History View
                                    │                             │
                              [Complete/Cancel]            [Select Session]
                                    │                             │
                                    ▼                             ▼
                              Landing Screen              Session Detail View
```

## Components and Interfaces

### 1. Screens

#### OnboardingScreen

**Purpose**: Introduce first-time users to AEGIS capabilities

**UI Elements:**
- Hero image/animation showing RPA in action
- 3-4 feature highlights with icons
- "Get Started" button
- "Skip" option

**State:**
- No complex state, just navigation

**Navigation:**
- On "Get Started" → Landing Screen
- Sets `onboarding_completed` flag in local storage

#### LandingScreen

**Purpose**: Main entry point for submitting task instructions

**UI Elements:**
- App bar with title and history icon
- Large text input field with hint text
- Submit button (enabled only when input is non-empty)
- Error message display area
- Loading indicator during submission

**State:**
```dart
class LandingState {
  String instruction;
  bool isSubmitting;
  String? errorMessage;
}
```

**Actions:**
- `onInstructionChanged(String text)` - Update instruction
- `onSubmit()` - Send instruction to backend
- `onHistoryTapped()` - Navigate to history view

**Navigation:**
- On successful submission → Task Execution Screen
- On history tap → History View

#### TaskExecutionScreen

**Purpose**: Display real-time execution progress

**UI Modes:**

The screen has two display modes based on window state:

**Normal Mode (Default):**
- App bar with session info and cancel button
- Original instruction display (card at top)
- Scrollable list of subtask cards
- Overall status indicator
- "Done" / "Back" button (shown when complete)

**Minimal Mode (During RPA Execution):**
- Compact floating panel (300x100)
- Current subtask description (truncated)
- Progress indicator (spinner or progress bar)
- Small cancel button (optional)
- No scrolling, shows only active subtask

Example minimal mode layout:
```
┌─────────────────────────────────┐
│ 🔄 Clicking "Submit" button...  │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
└─────────────────────────────────┘
```

**Subtask Card:**
- Subtask description
- Status icon (loading spinner, checkmark, error icon)
- Error message (if failed)
- Timestamp

**State:**
```dart
class ExecutionState {
  String sessionId;
  String instruction;
  SessionStatus overallStatus;
  List<SubtaskDisplay> subtasks;
  bool isConnected;
  bool isMinimalMode;  // Controls UI layout
  String? errorMessage;
}
```

**Actions:**
- `onCancel()` - Show confirmation dialog, then cancel session
- `onDone()` - Return to landing screen
- `onWebSocketMessage(StatusUpdate update)` - Update subtask list and handle window state changes

**Navigation:**
- On cancel/complete → Landing Screen

#### HistoryView

**Purpose**: Display past execution sessions

**UI Elements:**
- App bar with back button
- Scrollable list of session summary cards
- Pull-to-refresh
- Empty state message

**Session Summary Card:**
- Instruction (truncated)
- Status badge (completed/failed/cancelled)
- Timestamp
- Subtask count
- Tap to view details

**State:**
```dart
class HistoryState {
  List<SessionSummary> sessions;
  bool isLoading;
  String? errorMessage;
}
```

**Actions:**
- `onRefresh()` - Reload history from backend
- `onSessionTapped(String sessionId)` - Navigate to detail view

**Navigation:**
- On session tap → Session Detail View
- On back → Landing Screen

#### SessionDetailView

**Purpose**: Show complete details of a past session

**UI Elements:**
- App bar with back button
- Original instruction
- Overall status
- Complete list of subtasks with results
- Timestamps

**State:**
```dart
class SessionDetailState {
  ExecutionSession? session;
  bool isLoading;
  String? errorMessage;
}
```

### 2. State Management

Using **Provider** (or Riverpod for more advanced features):

```dart
// App-level state
class AppState extends ChangeNotifier {
  bool onboardingCompleted = false;
  
  Future<void> loadOnboardingStatus() async {
    onboardingCompleted = await StorageService.getOnboardingCompleted();
    notifyListeners();
  }
  
  Future<void> completeOnboarding() async {
    await StorageService.setOnboardingCompleted(true);
    onboardingCompleted = true;
    notifyListeners();
  }
}

// Execution state
class ExecutionStateNotifier extends ChangeNotifier {
  String? sessionId;
  String? instruction;
  SessionStatus status = SessionStatus.pending;
  List<SubtaskDisplay> subtasks = [];
  bool isConnected = false;
  bool isMinimalMode = false;
  
  final WindowService _windowService;
  
  ExecutionStateNotifier(this._windowService);
  
  Future<void> startExecution(String instruction) async {
    this.instruction = instruction;
    final response = await BackendApiService.startTask(instruction);
    sessionId = response.sessionId;
    status = SessionStatus.inProgress;
    notifyListeners();
    
    // Connect WebSocket
    await WebSocketService.connect(sessionId!);
  }
  
  void onStatusUpdate(StatusUpdate update) {
    // Handle window state changes
    if (update.windowState == 'minimal' && !isMinimalMode) {
      _windowService.enterMinimalMode();
      isMinimalMode = true;
    } else if (update.windowState == 'normal' && isMinimalMode) {
      _windowService.exitMinimalMode();
      isMinimalMode = false;
    }
    
    // Handle subtask updates
    if (update.subtask != null) {
      _updateSubtask(update.subtask!);
    }
    status = _parseStatus(update.overallStatus);
    notifyListeners();
  }
  
  Future<void> cancelExecution() async {
    if (sessionId != null) {
      await BackendApiService.cancelSession(sessionId!);
      await WebSocketService.disconnect();
      
      // Restore window if in minimal mode
      if (isMinimalMode) {
        await _windowService.exitMinimalMode();
        isMinimalMode = false;
      }
      
      status = SessionStatus.cancelled;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    // Ensure window is restored on dispose
    if (isMinimalMode) {
      _windowService.exitMinimalMode();
    }
    super.dispose();
  }
}

// History state
class HistoryStateNotifier extends ChangeNotifier {
  List<SessionSummary> sessions = [];
  bool isLoading = false;
  String? errorMessage;
  
  Future<void> loadHistory() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    try {
      final response = await BackendApiService.getHistory();
      sessions = response.sessions;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
```

### 3. Services

#### WindowService

**Purpose**: Manage window state transitions for RPA execution

```dart
class WindowService {
  Size? _savedSize;
  Offset? _savedPosition;
  bool _isMinimalMode = false;
  
  bool get isMinimalMode => _isMinimalMode;
  
  Future<void> enterMinimalMode() async {
    if (_isMinimalMode) return;
    
    // Save current state
    _savedSize = await windowManager.getSize();
    _savedPosition = await windowManager.getPosition();
    
    // Get screen dimensions
    final screen = await windowManager.getScreen();
    final screenWidth = screen.visibleFrame.width;
    
    // Enter minimal mode (300x100 at top-right)
    await windowManager.setSize(Size(300, 100));
    await windowManager.setPosition(Offset(
      screenWidth - 320,  // 20px from right edge
      20,  // 20px from top
    ));
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setResizable(false);
    
    _isMinimalMode = true;
  }
  
  Future<void> exitMinimalMode() async {
    if (!_isMinimalMode) return;
    
    // Restore original state
    if (_savedSize != null) {
      await windowManager.setSize(_savedSize!);
    }
    if (_savedPosition != null) {
      await windowManager.setPosition(_savedPosition!);
    }
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setResizable(true);
    
    _isMinimalMode = false;
  }
}
```

#### BackendApiService

**Purpose**: Handle HTTP communication with backend

```dart
class BackendApiService {
  static const String baseUrl = 'http://localhost:8000';
  final http.Client client;
  
  Future<TaskInstructionResponse> startTask(String instruction) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/start_task'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'instruction': instruction}),
    );
    
    if (response.statusCode == 200) {
      return TaskInstructionResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 422) {
      throw ValidationException(jsonDecode(response.body)['detail']);
    } else {
      throw ApiException('Failed to start task: ${response.statusCode}');
    }
  }
  
  Future<HistoryResponse> getHistory() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/history'),
    );
    
    if (response.statusCode == 200) {
      return HistoryResponse.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to load history: ${response.statusCode}');
    }
  }
  
  Future<ExecutionSession> getSessionDetails(String sessionId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/history/$sessionId'),
    );
    
    if (response.statusCode == 200) {
      return ExecutionSession.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to load session: ${response.statusCode}');
    }
  }
  
  Future<void> cancelSession(String sessionId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/execution/$sessionId'),
    );
    
    if (response.statusCode != 200) {
      throw ApiException('Failed to cancel session: ${response.statusCode}');
    }
  }
}
```

#### WebSocketService

**Purpose**: Manage WebSocket connection for real-time updates

```dart
class WebSocketService {
  static const String wsUrl = 'ws://localhost:8000';
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  Future<void> connect(String sessionId, Function(StatusUpdate) onUpdate) async {
    _channel = WebSocketChannel.connect(
      Uri.parse('$wsUrl/ws/execution/$sessionId'),
    );
    
    _subscription = _channel!.stream.listen(
      (message) {
        final update = StatusUpdate.fromJson(jsonDecode(message));
        onUpdate(update);
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket connection closed');
      },
    );
  }
  
  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _subscription = null;
  }
  
  Future<void> reconnect(String sessionId, Function(StatusUpdate) onUpdate) async {
    await disconnect();
    await Future.delayed(Duration(seconds: 2));
    await connect(sessionId, onUpdate);
  }
}
```

#### StorageService

**Purpose**: Handle local storage for app preferences

```dart
class StorageService {
  static const String _onboardingKey = 'onboarding_completed';
  
  static Future<bool> getOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }
  
  static Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, value);
  }
}
```

## Data Models

### Dart Models (matching backend Pydantic models)

```dart
// Request models
class TaskInstructionRequest {
  final String instruction;
  
  TaskInstructionRequest({required this.instruction});
  
  Map<String, dynamic> toJson() => {
    'instruction': instruction,
  };
}

// Response models
class TaskInstructionResponse {
  final String sessionId;
  final String status;
  final String message;
  
  TaskInstructionResponse({
    required this.sessionId,
    required this.status,
    required this.message,
  });
  
  factory TaskInstructionResponse.fromJson(Map<String, dynamic> json) {
    return TaskInstructionResponse(
      sessionId: json['session_id'],
      status: json['status'],
      message: json['message'],
    );
  }
}

// Enums
enum SubtaskStatus {
  pending,
  inProgress,
  completed,
  failed;
  
  static SubtaskStatus fromString(String value) {
    switch (value) {
      case 'pending': return SubtaskStatus.pending;
      case 'in_progress': return SubtaskStatus.inProgress;
      case 'completed': return SubtaskStatus.completed;
      case 'failed': return SubtaskStatus.failed;
      default: throw ArgumentError('Invalid status: $value');
    }
  }
}

enum SessionStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled;
  
  static SessionStatus fromString(String value) {
    switch (value) {
      case 'pending': return SessionStatus.pending;
      case 'in_progress': return SessionStatus.inProgress;
      case 'completed': return SessionStatus.completed;
      case 'failed': return SessionStatus.failed;
      case 'cancelled': return SessionStatus.cancelled;
      default: throw ArgumentError('Invalid status: $value');
    }
  }
}

// Subtask model
class Subtask {
  final String id;
  final String description;
  final SubtaskStatus status;
  final String? toolName;
  final Map<String, dynamic>? toolArgs;
  final Map<String, dynamic>? result;
  final String? error;
  final DateTime timestamp;
  
  Subtask({
    required this.id,
    required this.description,
    required this.status,
    this.toolName,
    this.toolArgs,
    this.result,
    this.error,
    required this.timestamp,
  });
  
  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'],
      description: json['description'],
      status: SubtaskStatus.fromString(json['status']),
      toolName: json['tool_name'],
      toolArgs: json['tool_args'],
      result: json['result'],
      error: json['error'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// Execution session model
class ExecutionSession {
  final String sessionId;
  final String instruction;
  final SessionStatus status;
  final List<Subtask> subtasks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  
  ExecutionSession({
    required this.sessionId,
    required this.instruction,
    required this.status,
    required this.subtasks,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });
  
  factory ExecutionSession.fromJson(Map<String, dynamic> json) {
    return ExecutionSession(
      sessionId: json['session_id'],
      instruction: json['instruction'],
      status: SessionStatus.fromString(json['status']),
      subtasks: (json['subtasks'] as List)
          .map((s) => Subtask.fromJson(s))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
    );
  }
}

// Status update model (WebSocket)
class StatusUpdate {
  final String sessionId;
  final Subtask? subtask;
  final String overallStatus;
  final String message;
  final String? windowState;  // "minimal" or "normal"
  final DateTime timestamp;
  
  StatusUpdate({
    required this.sessionId,
    this.subtask,
    required this.overallStatus,
    required this.message,
    this.windowState,
    required this.timestamp,
  });
  
  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    return StatusUpdate(
      sessionId: json['session_id'],
      subtask: json['subtask'] != null 
          ? Subtask.fromJson(json['subtask']) 
          : null,
      overallStatus: json['overall_status'],
      message: json['message'],
      windowState: json['window_state'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// Session summary model
class SessionSummary {
  final String sessionId;
  final String instruction;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int subtaskCount;
  
  SessionSummary({
    required this.sessionId,
    required this.instruction,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.subtaskCount,
  });
  
  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      sessionId: json['session_id'],
      instruction: json['instruction'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      subtaskCount: json['subtask_count'],
    );
  }
}

// History response model
class HistoryResponse {
  final List<SessionSummary> sessions;
  final int total;
  
  HistoryResponse({
    required this.sessions,
    required this.total,
  });
  
  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    return HistoryResponse(
      sessions: (json['sessions'] as List)
          .map((s) => SessionSummary.fromJson(s))
          .toList(),
      total: json['total'],
    );
  }
}

// Error response model
class ErrorResponse {
  final String error;
  final String? details;
  final String? sessionId;
  
  ErrorResponse({
    required this.error,
    this.details,
    this.sessionId,
  });
  
  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      error: json['error'],
      details: json['details'],
      sessionId: json['session_id'],
    );
  }
}

// UI-specific models
class SubtaskDisplay {
  final Subtask subtask;
  final bool isHighlighted;
  
  SubtaskDisplay({
    required this.subtask,
    this.isHighlighted = false,
  });
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Onboarding Flag Storage

*For any* completion of the onboarding flow, the local storage must contain the onboarding_completed flag set to true.

**Validates: Requirements 1.3**

### Property 2: Submit Button State

*For any* text input value in the landing screen input field, the submit button must be enabled if and only if the input is non-empty (after trimming whitespace).

**Validates: Requirements 2.2**

### Property 3: Task Submission Request

*For any* valid task instruction submitted from the landing screen, a POST request must be sent to /api/start_task with the instruction in the request body.

**Validates: Requirements 2.3**

### Property 4: Navigation on Success

*For any* successful backend response containing a session ID, the app must navigate to the Task Execution Screen.

**Validates: Requirements 2.4**

### Property 5: Error Display Without Navigation

*For any* error response from the backend, an error message must be displayed on the landing screen and navigation must not occur.

**Validates: Requirements 2.5**

### Property 6: WebSocket Connection Establishment

*For any* Task Execution Screen display, a WebSocket connection must be established to /ws/execution/{session_id} where session_id matches the current session.

**Validates: Requirements 3.1**

### Property 7: Subtask Card Addition

*For any* WebSocket status update containing a new subtask, a new Subtask Card must be added to the display list.

**Validates: Requirements 3.2**

### Property 8: Completed Subtask Indicator

*For any* subtask with status "completed", the corresponding Subtask Card must display a success indicator (checkmark icon).

**Validates: Requirements 3.3**

### Property 9: Failed Subtask Indicator

*For any* subtask with status "failed", the corresponding Subtask Card must display an error indicator (error icon) and the error message.

**Validates: Requirements 3.4**

### Property 10: In-Progress Subtask Indicator

*For any* subtask with status "in_progress", the corresponding Subtask Card must display a loading indicator (spinner).

**Validates: Requirements 3.5**

### Property 11: Instruction Display

*For any* execution session, the original task instruction must be displayed at the top of the Task Execution Screen.

**Validates: Requirements 4.1**

### Property 12: Success Completion UI

*For any* execution session where all subtasks have status "completed", a success message and "Done" button must be displayed.

**Validates: Requirements 4.2**

### Property 13: Failure Completion UI

*For any* execution session where at least one subtask has status "failed", an error summary and "Back" button must be displayed.

**Validates: Requirements 4.3**

### Property 14: Final Status Determination

*For any* WebSocket connection closure, the final session status must be determined based on the most recent status updates received.

**Validates: Requirements 4.4**

### Property 15: Return Option After Completion

*For any* completed execution session (success or failure), a button or option to return to the Landing Screen must be available.

**Validates: Requirements 4.5**

### Property 16: Cancel Button Visibility

*For any* Task Execution Screen displayed while execution status is "in_progress", a "Cancel" button must be visible.

**Validates: Requirements 5.1**

### Property 17: Cancellation Confirmation Dialog

*For any* tap on the "Cancel" button, a confirmation dialog must be displayed before proceeding.

**Validates: Requirements 5.2**

### Property 18: Cancellation Request

*For any* confirmed cancellation, a DELETE request must be sent to /api/execution/{session_id}.

**Validates: Requirements 5.3**

### Property 19: Cancellation Cleanup

*For any* successful cancellation response from the backend, the WebSocket connection must be closed and the app must navigate to the Landing Screen.

**Validates: Requirements 5.4**

### Property 20: Cancellation Failure Handling

*For any* failed cancellation request, an error message must be displayed and the Task Execution Screen must remain active.

**Validates: Requirements 5.5**

### Property 21: History Request

*For any* navigation to the History View, a GET request must be sent to /api/history.

**Validates: Requirements 6.2**

### Property 22: History Display

*For any* history response from the backend, each session in the response must be displayed with timestamp, instruction, and status.

**Validates: Requirements 6.3**

### Property 23: Session Detail Request

*For any* tap on a history item, a GET request must be sent to /api/history/{session_id} where session_id matches the tapped item.

**Validates: Requirements 6.4**

### Property 24: Session Detail Display

*For any* session detail response, the complete subtask sequence and results must be displayed.

**Validates: Requirements 6.5**

### Property 25: Network Error Messages

*For any* network request that fails due to connectivity issues, a user-friendly error message must be displayed.

**Validates: Requirements 7.1**

### Property 26: WebSocket Reconnection Attempts

*For any* unexpected WebSocket connection drop, the app must attempt to reconnect up to 3 times before giving up.

**Validates: Requirements 7.2**

### Property 27: Reconnection Failure UI

*For any* WebSocket reconnection that fails after 3 attempts, an error message and option to return to the Landing Screen must be displayed.

**Validates: Requirements 7.3**

### Property 28: Backend Offline Message

*For any* request where the backend is unreachable, a message indicating the backend is offline must be displayed.

**Validates: Requirements 7.4**

### Property 29: Automatic Retry on Connectivity Restoration

*For any* failed request where network connectivity is subsequently restored, the request must be automatically retried.

**Validates: Requirements 7.5**

### Property 30: Status Color Coding

*For any* status indicator displayed, the color must match the status type: green for success/completed, red for error/failed, blue for in-progress.

**Validates: Requirements 8.2**

### Property 31: Button Visual Feedback

*For any* button tap, visual feedback (ripple effect or color change) must be provided immediately.

**Validates: Requirements 8.3**

### Property 32: State Preservation Across Navigation

*For any* navigation between screens, relevant state (such as execution session data) must be preserved and accessible after navigation.

**Validates: Requirements 9.2**

### Property 33: UI Updates on WebSocket Messages

*For any* WebSocket status update received, the application state must be updated and the UI must rebuild to reflect the changes.

**Validates: Requirements 9.3**

### Property 34: WebSocket Persistence When Backgrounded

*For any* app backgrounding event during active execution, the WebSocket connection must remain open.

**Validates: Requirements 9.4**

### Property 35: UI Sync on Foreground

*For any* app foregrounding event during active execution, the UI must sync with the current execution state.

**Validates: Requirements 9.5**

### Property 36: Loading Indicator on Submission

*For any* task instruction submission, a loading indicator must be displayed until the backend responds.

**Validates: Requirements 10.1**

### Property 37: Button Tap Feedback

*For any* button tap, immediate visual feedback must be provided.

**Validates: Requirements 10.2**

### Property 38: Progress Indicator During Loading

*For any* data loading operation from the backend, a progress indicator must be displayed.

**Validates: Requirements 10.3**

### Property 39: Error Display with Icon

*For any* error that occurs, the error message must be displayed with an appropriate error icon.

**Validates: Requirements 10.4**

### Property 40: Button Disabling During Operations

*For any* long-running operation in progress, relevant buttons must be disabled to prevent duplicate actions.

**Validates: Requirements 10.5**

### Property 41: Subtask Chronological Ordering

*For any* list of subtasks displayed, the subtasks must be ordered chronologically from top to bottom based on their timestamps.

**Validates: Requirements 11.1**

### Property 42: In-Progress Subtask Highlighting

*For any* subtask with status "in_progress", the subtask card must be visually highlighted (e.g., with a border or background color).

**Validates: Requirements 11.2**

### Property 43: Completed Subtask Visual Treatment

*For any* subtask with status "completed", the subtask card must show a checkmark icon and be slightly dimmed.

**Validates: Requirements 11.3**

### Property 44: Failed Subtask Error Display

*For any* subtask with status "failed", the subtask card must show an error icon and display the error message below the description.

**Validates: Requirements 11.4**

### Property 45: Scrollable Subtask List

*For any* execution session with more subtasks than fit on screen, the subtask list must be scrollable while keeping the header visible.

**Validates: Requirements 11.5**

### Property 46: Request Serialization

*For any* request sent to the backend, the data must be serialized using Dart classes that match the backend Pydantic models.

**Validates: Requirements 12.1**

### Property 47: Response Deserialization

*For any* response received from the backend, the JSON must be deserialized into typed Dart objects.

**Validates: Requirements 12.2**

### Property 48: Parsing Error Handling

*For any* response containing unexpected or malformed data, the parsing error must be caught and handled gracefully without crashing the app.

**Validates: Requirements 12.3**

## Error Handling

### Error Categories

1. **Network Errors**
   - Connection timeout
   - No internet connection
   - Backend unreachable
   - DNS resolution failure

2. **API Errors**
   - 400 Bad Request
   - 422 Validation Error
   - 500 Internal Server Error
   - Unexpected status codes

3. **WebSocket Errors**
   - Connection failure
   - Unexpected disconnection
   - Message parsing errors
   - Reconnection failures

4. **Parsing Errors**
   - Invalid JSON
   - Missing required fields
   - Type mismatches
   - Unexpected data structure

5. **UI Errors**
   - Navigation failures
   - State inconsistencies
   - Widget build errors

### Error Display Strategy

**User-Friendly Messages:**
- Network errors: "Unable to connect. Please check your internet connection."
- Backend offline: "The automation service is currently offline. Please try again later."
- Validation errors: Display the specific validation message from backend
- Unknown errors: "Something went wrong. Please try again."

**Error UI Components:**
- SnackBar for transient errors
- Dialog for critical errors requiring user action
- Inline error messages for form validation
- Error state widgets for failed data loading

### Retry Logic

- **Network requests**: Manual retry via "Retry" button
- **WebSocket**: Automatic reconnection (3 attempts with 2s delay)
- **Failed operations**: User-initiated retry

## Testing Strategy

### Unit Testing

The frontend will use **Flutter's built-in testing framework** with the following structure:

**Test Organization:**
```
test/
├── unit/
│   ├── models/
│   │   ├── task_instruction_test.dart
│   │   ├── execution_session_test.dart
│   │   └── status_update_test.dart
│   ├── services/
│   │   ├── backend_api_service_test.dart
│   │   ├── websocket_service_test.dart
│   │   └── storage_service_test.dart
│   └── state/
│       ├── app_state_test.dart
│       ├── execution_state_test.dart
│       └── history_state_test.dart
├── widget/
│   ├── onboarding_screen_test.dart
│   ├── landing_screen_test.dart
│   ├── task_execution_screen_test.dart
│   └── history_view_test.dart
├── integration/
│   └── app_flow_test.dart
└── property/
    └── correctness_properties_test.dart
```

**Unit Test Coverage:**
- Model serialization/deserialization
- Service method behavior
- State management logic
- Error handling paths

**Widget Test Coverage:**
- UI element presence and layout
- User interaction handling
- Navigation flows
- State-driven UI updates

**Integration Test Coverage:**
- End-to-end user flows
- Backend communication
- WebSocket message handling
- Multi-screen workflows

### Property-Based Testing

The frontend will use **dart_check** (Dart's property-based testing library) to verify correctness properties.

**Configuration:**
- Minimum 100 iterations per property test
- Custom generators for instructions, session data, and UI states
- Stateful testing for navigation and state management

**Property Test Implementation:**

Each correctness property will be implemented as a single property-based test with explicit tagging:

```dart
import 'package:dart_check/dart_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Correctness Properties', () {
    testProperty(
      'Property 2: Submit button enabled only for non-empty input',
      () {
        forAll(
          Arbitrary.string,
          (instruction) {
            // Feature: rpa-frontend, Property 2: Submit Button State
            final trimmed = instruction.trim();
            final shouldBeEnabled = trimmed.isNotEmpty;
            
            // Test the button state logic
            final isEnabled = LandingScreen.isSubmitEnabled(instruction);
            
            expect(isEnabled, equals(shouldBeEnabled));
          },
        );
      },
      maxExamples: 100,
    );
    
    testProperty(
      'Property 41: Subtasks ordered chronologically',
      () {
        forAll(
          Arbitrary.list(subtaskArbitrary),
          (subtasks) {
            // Feature: rpa-frontend, Property 41: Subtask Chronological Ordering
            final displayed = ExecutionScreen.orderSubtasks(subtasks);
            
            // Verify chronological order
            for (int i = 0; i < displayed.length - 1; i++) {
              expect(
                displayed[i].timestamp.isBefore(displayed[i + 1].timestamp) ||
                displayed[i].timestamp.isAtSameMomentAs(displayed[i + 1].timestamp),
                isTrue,
              );
            }
          },
        );
      },
      maxExamples: 100,
    );
  });
}
```

**Custom Generators:**

```dart
// Generator for task instructions
final instructionArbitrary = Arbitrary.string.map(
  (s) => s.isEmpty ? 'default instruction' : s,
);

// Generator for subtasks
final subtaskArbitrary = Arbitrary.combine3(
  Arbitrary.string,
  Arbitrary.choose(['pending', 'in_progress', 'completed', 'failed']),
  Arbitrary.dateTime,
  (desc, status, timestamp) => Subtask(
    id: uuid.v4(),
    description: desc,
    status: SubtaskStatus.fromString(status),
    timestamp: timestamp,
  ),
);

// Generator for session summaries
final sessionSummaryArbitrary = Arbitrary.combine4(
  Arbitrary.string,
  instructionArbitrary,
  Arbitrary.choose(['completed', 'failed', 'cancelled']),
  Arbitrary.dateTime,
  (id, instruction, status, timestamp) => SessionSummary(
    sessionId: id,
    instruction: instruction,
    status: status,
    createdAt: timestamp,
    subtaskCount: 5,
  ),
);
```

**Mocking Strategy:**
- Mock HTTP client for API testing
- Mock WebSocket for real-time update testing
- Mock SharedPreferences for storage testing
- Use real widgets with mocked services for widget tests

### Test Execution

```bash
# Run all tests
flutter test

# Run unit tests only
flutter test test/unit/

# Run widget tests
flutter test test/widget/

# Run property tests with verbose output
flutter test test/property/ --reporter expanded

# Run with coverage
flutter test --coverage

# Run specific property test
flutter test test/property/correctness_properties_test.dart
```

### Continuous Integration

- All tests run on every commit
- Property tests run with 100 iterations in CI
- Coverage threshold: 75% minimum
- Widget tests run on multiple screen sizes
- Integration tests run against mock backend

## Material 3 Design System

### Color Palette

```dart
// Light theme
final lightColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.blue,
  brightness: Brightness.light,
);

// Dark theme
final darkColorScheme = ColorScheme.fromSeed(
  seedColor: Colors.blue,
  brightness: Brightness.dark,
);

// Status colors
const successColor = Color(0xFF4CAF50);  // Green
const errorColor = Color(0xFFF44336);    // Red
const inProgressColor = Color(0xFF2196F3); // Blue
const pendingColor = Color(0xFF9E9E9E);  // Grey
```

### Typography

```dart
final textTheme = TextTheme(
  displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
  displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
  displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
  headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
  headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
  headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
  titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
  titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
  bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
  labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
);
```

### Component Specifications

**Subtask Card:**
- Elevation: 1
- Border radius: 12px
- Padding: 16px
- Margin: 8px vertical
- Status indicator: 24px icon on left
- Description: bodyLarge text
- Error message: bodySmall text in errorColor

**Input Field:**
- Border: OutlineInputBorder
- Border radius: 8px
- Padding: 16px
- Min height: 56px
- Max lines: 3

**Buttons:**
- Primary: FilledButton (Material 3)
- Secondary: OutlinedButton
- Text: TextButton
- Height: 48px
- Border radius: 24px

## Deployment Considerations

### Environment Configuration

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
  
  static const int wsReconnectAttempts = 3;
  static const Duration wsReconnectDelay = Duration(seconds: 2);
  static const Duration requestTimeout = Duration(seconds: 30);
}
```

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.0  # or riverpod: ^2.4.0
  http: ^1.1.0
  web_socket_channel: ^2.4.0
  shared_preferences: ^2.2.0
  uuid: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  dart_check: ^0.5.0  # Property-based testing
  mockito: ^5.4.0
  flutter_lints: ^3.0.0
```

### Performance Targets

- App launch time: < 2s
- Screen transition: < 300ms
- WebSocket message processing: < 50ms
- UI rebuild time: < 16ms (60 FPS)
- Memory usage: < 100MB

### Platform Support

- **Primary**: Windows Desktop
- **Future**: Android, iOS, macOS, Linux

## Future Enhancements

1. **Offline Mode**: Cache recent sessions for offline viewing
2. **Voice Input**: Voice-to-text for task instructions
3. **Favorites**: Save frequently used instructions
4. **Notifications**: Push notifications for completed tasks
5. **Themes**: Custom color themes and dark mode improvements
6. **Accessibility**: Enhanced screen reader support
7. **Animations**: Smooth transitions and micro-interactions
8. **Multi-Language**: Internationalization support


## Window Management for RPA Execution

### Overview

During RPA execution, the application window automatically transitions to a minimal floating mode to provide the automation agent with unobstructed access to the desktop and other applications.

### Window States

**Normal Mode (Default):**
- Full application window (800x600 or larger)
- Standard window decorations (title bar, borders)
- Resizable
- Not always on top

**Minimal Mode (During Execution):**
- Small floating panel (300x100 pixels)
- Positioned at top-right corner (20px from edges)
- Always on top
- Borderless (no title bar)
- Non-resizable
- Shows only current subtask and progress

### Implementation

**Package:** `window_manager: ^0.3.0`

**Service Layer:**
- `WindowService` handles all window state transitions
- Saves current window size and position before minimizing
- Restores original state after execution completes

**State Integration:**
- `ExecutionState` listens for `window_state` field in WebSocket messages
- Calls `WindowService.enterMinimalMode()` on `"minimal"` command
- Calls `WindowService.exitMinimalMode()` on `"normal"` command or completion

**UI Adaptation:**
- `TaskExecutionScreen` renders different layouts based on `isMinimalMode` flag
- Normal mode: Full screen with scrollable subtask list
- Minimal mode: Compact view with only current subtask

### Transition Flow

1. User submits task → Window stays normal during planning
2. Backend sends `window_state: "minimal"` before first desktop action
3. Frontend minimizes window to 300x100 floating panel
4. User sees compact progress indicator during execution
5. Backend sends `window_state: "normal"` on completion
6. Frontend restores original window size and position

### Edge Cases

- **Cancellation**: Window restored immediately on user cancel
- **Connection Loss**: Window restored if WebSocket disconnects
- **Multiple Monitors**: Minimal window positioned on primary monitor
- **Screen Resolution Changes**: Position recalculated if screen size changes
- **Manual Dragging**: User can drag minimal window to preferred location

### Configuration

```dart
class WindowConfig {
  static const Size minimalSize = Size(300, 100);
  static const Duration transitionDuration = Duration(milliseconds: 250);
  static const double minimalOffsetX = 20;  // From right edge
  static const double minimalOffsetY = 20;  // From top
}
```
