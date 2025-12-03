# Implementation Plan

- [x] 1. Set up Flutter project structure and dependencies





  - Create Flutter project with `flutter create aegis_front`
  - Add dependencies to pubspec.yaml: provider, http, web_socket_channel, shared_preferences, uuid, window_manager
  - Add dev dependencies: flutter_test, dart_check, mockito, flutter_lints
  - Create directory structure: lib/models/, lib/services/, lib/screens/, lib/state/, lib/widgets/
  - _Requirements: 9.1, 13.1_

- [x] 2. Implement data models





  - Create lib/models/task_instruction.dart with request/response models
  - Create lib/models/subtask.dart with Subtask and SubtaskStatus enum
  - Create lib/models/execution_session.dart with ExecutionSession and SessionStatus enum
  - Create lib/models/status_update.dart for WebSocket messages with optional window_state field
  - Create lib/models/session_summary.dart for history
  - Add fromJson() and toJson() methods to all models
  - _Requirements: 12.1, 12.2, 13.1_

- [x] 2.1 Write unit tests for data models






  - Test JSON serialization and deserialization
  - Test enum conversions
  - Test model validation
  - _Requirements: 12.1, 12.2_

- [x] 2.2 Write property test for model serialization






  - **Property 46: Request Serialization**
  - **Property 47: Response Deserialization**
  - **Validates: Requirements 12.1, 12.2**

- [x] 3. Implement Storage Service





  - Create lib/services/storage_service.dart
  - Implement getOnboardingCompleted() using SharedPreferences
  - Implement setOnboardingCompleted()
  - Add error handling for storage operations
  - _Requirements: 1.3, 1.4_

- [x] 3.1 Write unit tests for storage service






  - Test reading and writing onboarding flag
  - Test error handling
  - Mock SharedPreferences
  - _Requirements: 1.3_

- [ ]* 3.2 Write property test for onboarding flag storage
  - **Property 1: Onboarding Flag Storage**
  - **Validates: Requirements 1.3**

- [x] 4. Implement Backend API Service





  - Create lib/services/backend_api_service.dart
  - Implement startTask() for POST /api/start_task
  - Implement getHistory() for GET /api/history
  - Implement getSessionDetails() for GET /api/history/{session_id}
  - Implement cancelSession() for DELETE /api/execution/{session_id}
  - Add error handling for network errors, API errors, timeouts
  - Add request timeout configuration (30s)
  - _Requirements: 2.3, 5.3, 6.2, 6.4, 7.1, 7.4_

- [x] 4.1 Write unit tests for API service






  - Test each endpoint with mock HTTP client
  - Test error handling (network errors, API errors)
  - Test request serialization and response deserialization
  - _Requirements: 2.3, 7.1_

- [ ]* 4.2 Write property test for API requests
  - **Property 3: Task Submission Request**
  - **Property 18: Cancellation Request**
  - **Property 21: History Request**
  - **Property 23: Session Detail Request**
  - **Validates: Requirements 2.3, 5.3, 6.2, 6.4**

- [x] 5. Implement WebSocket Service





  - Create lib/services/websocket_service.dart
  - Implement connect() to establish WebSocket connection
  - Implement disconnect() to close connection
  - Implement reconnect() with retry logic (3 attempts, 2s delay)
  - Add message parsing and error handling
  - Add connection state tracking
  - _Requirements: 3.1, 7.2, 7.3_

- [x] 5.1 Implement Window Service


  - Create lib/services/window_service.dart
  - Implement enterMinimalMode() to resize window to 300x100, set always on top, remove decorations
  - Implement exitMinimalMode() to restore original size, position, and decorations
  - Save and restore window state (size, position)
  - Add smooth transition animations (250ms duration)
  - Handle edge cases (multiple monitors, screen resolution changes)
  - _Requirements: 13.2, 13.3, 13.4_

- [x] 5.1 Write unit tests for WebSocket service








  - Test connection establishment
  - Test message parsing
  - Test reconnection logic
  - Test error handling
  - Mock WebSocketChannel
  - _Requirements: 3.1, 7.2_

- [x] 5.2 Write unit tests for Window Service






  - Test enterMinimalMode() saves state and resizes window
  - Test exitMinimalMode() restores original state
  - Test edge cases (null saved state, invalid positions)
  - Mock window_manager
  - _Requirements: 13.2, 13.3, 13.4_

- [x] 5.3 Write property test for WebSocket reconnection






  - **Property 26: WebSocket Reconnection Attempts**
  - **Validates: Requirements 7.2**

- [x] 6. Implement App State





  - Create lib/state/app_state.dart with AppState class extending ChangeNotifier
  - Implement loadOnboardingStatus()
  - Implement completeOnboarding()
  - Add notifyListeners() calls
  - _Requirements: 1.3, 1.4_

- [x] 6.1 Write unit tests for app state






  - Test onboarding status loading
  - Test onboarding completion
  - Test state change notifications
  - _Requirements: 1.3, 1.4_

- [x] 7. Implement Execution State





  - Create lib/state/execution_state.dart with ExecutionStateNotifier
  - Implement startExecution() to submit task and connect WebSocket
  - Implement onStatusUpdate() to handle WebSocket messages including window_state commands
  - Implement cancelExecution() to cancel session and restore window
  - Track session ID, instruction, status, subtasks list, window mode state
  - Integrate WindowService to handle window state transitions
  - Call WindowService.enterMinimalMode() on WINDOW_STATE_MINIMAL
  - Call WindowService.exitMinimalMode() on WINDOW_STATE_NORMAL or completion
  - _Requirements: 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 3.5, 5.3, 5.4, 13.1, 13.2, 13.3, 13.4, 13.5_

- [x] 7.1 Write unit tests for execution state





  - Test execution start flow
  - Test status update handling
  - Test cancellation flow
  - Test state change notifications
  - Mock services
  - _Requirements: 2.3, 3.1, 5.3_

- [-] 7.2 Write property test for execution state









  - **Property 6: WebSocket Connection Establishment**
  - **Property 7: Subtask Card Addition**
  - **Property 19: Cancellation Cleanup**
  - **Validates: Requirements 3.1, 3.2, 5.4**

- [x] 7.3 Write unit tests for window state handling
  - Test window enters minimal mode on WINDOW_STATE_MINIMAL command
  - Test window restores on WINDOW_STATE_NORMAL command
  - Test window restores on execution completion
  - Test window restores on cancellation
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

- [x] 8. Implement History State





  - Create lib/state/history_state.dart with HistoryStateNotifier
  - Implement loadHistory() to fetch sessions
  - Track sessions list, loading state, error message
  - Add notifyListeners() calls
  - _Requirements: 6.2, 6.3_

- [x] 8.1 Write unit tests for history state






  - Test history loading
  - Test error handling
  - Test state change notifications
  - Mock API service
  - _Requirements: 6.2_

- [ ]* 8.2 Write property test for history display
  - **Property 22: History Display**
  - **Validates: Requirements 6.3**

- [x] 9. Implement Onboarding Screen











  - Create lib/screens/onboarding_screen.dart
  - Add hero image/animation
  - Add 3-4 feature highlights with icons
  - Add "Get Started" button
  - Add "Skip" option
  - Implement navigation to Landing Screen
  - Call AppState.completeOnboarding() on completion
  - _Requirements: 1.1, 1.2, 1.3, 1.5_

- [x] 9.1 Write widget tests for onboarding screen






  - Test UI elements presence
  - Test "Get Started" button navigation
  - Test onboarding completion
  - _Requirements: 1.2, 1.5_

- [x] 10. Implement Landing Screen





  - Create lib/screens/landing_screen.dart
  - Add app bar with title and history icon
  - Add large text input field with hint text
  - Add submit button (enabled only when input is non-empty)
  - Add error message display area
  - Add loading indicator during submission
  - Implement onSubmit() to call ExecutionState.startExecution()
  - Implement navigation to Task Execution Screen on success
  - Implement navigation to History View on history tap
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 6.1_

- [x] 10.1 Write widget tests for landing screen






  - Test UI elements presence
  - Test submit button state based on input
  - Test submission flow
  - Test error display
  - Test navigation
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 10.2 Write property test for submit button state






  - **Property 2: Submit Button State**
  - **Validates: Requirements 2.2**

- [x] 11. Implement Task Execution Screen





  - Create lib/screens/task_execution_screen.dart
  - Add app bar with session info and cancel button
  - Add original instruction display card at top
  - Add scrollable list of subtask cards
  - Add overall status indicator
  - Add "Done" / "Back" button (shown when complete)
  - Implement onCancel() with confirmation dialog
  - Listen to ExecutionState for updates
  - Add minimal mode UI variant (compact view with current subtask and progress)
  - Switch between normal and minimal layouts based on window mode state
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 13.2_

- [ ]* 11.1 Write widget tests for task execution screen
  - Test UI elements presence
  - Test subtask card display
  - Test status indicators
  - Test cancel button and dialog
  - Test completion UI
  - _Requirements: 3.2, 3.3, 3.4, 3.5, 4.1_

- [ ]* 11.2 Write property test for execution screen
  - **Property 8: Completed Subtask Indicator**
  - **Property 9: Failed Subtask Indicator**
  - **Property 10: In-Progress Subtask Indicator**
  - **Property 11: Instruction Display**
  - **Property 41: Subtask Chronological Ordering**
  - **Validates: Requirements 3.3, 3.4, 3.5, 4.1, 11.1**

- [x] 12. Implement Subtask Card Widget





  - Create lib/widgets/subtask_card.dart
  - Display subtask description
  - Display status icon (spinner, checkmark, error icon)
  - Display error message if failed
  - Display timestamp
  - Apply highlighting for in-progress subtasks
  - Apply dimming for completed subtasks
  - Use Material 3 Card with elevation 1
  - _Requirements: 3.3, 3.4, 3.5, 11.1, 11.2, 11.3, 11.4_

- [x] 12.1 Write widget tests for subtask card





  - Test card display for each status
  - Test icon display
  - Test error message display
  - Test visual styling
  - _Requirements: 3.3, 3.4, 3.5_

- [x] 12.2 Write property test for subtask card visual treatment






  - **Property 42: In-Progress Subtask Highlighting**
  - **Property 43: Completed Subtask Visual Treatment**
  - **Property 44: Failed Subtask Error Display**
  - **Validates: Requirements 11.2, 11.3, 11.4**

- [x] 13. Implement History View





  - Create lib/screens/history_view.dart
  - Add app bar with back button
  - Add scrollable list of session summary cards
  - Add pull-to-refresh
  - Add empty state message
  - Implement onRefresh() to call HistoryState.loadHistory()
  - Implement onSessionTapped() to navigate to Session Detail View
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 13.1 Write widget tests for history view






  - Test UI elements presence
  - Test session list display
  - Test pull-to-refresh
  - Test empty state
  - Test navigation to detail view
  - _Requirements: 6.2, 6.3_

- [x] 14. Implement Session Summary Card Widget





  - Create lib/widgets/session_summary_card.dart
  - Display instruction (truncated)
  - Display status badge (completed/failed/cancelled)
  - Display timestamp
  - Display subtask count
  - Make card tappable
  - Use Material 3 Card styling
  - _Requirements: 6.3_

- [x] 14.1 Write widget tests for session summary card






  - Test card display
  - Test status badge colors
  - Test tap handling
  - _Requirements: 6.3_

- [x] 15. Implement Session Detail View





  - Create lib/screens/session_detail_view.dart
  - Add app bar with back button
  - Display original instruction
  - Display overall status
  - Display complete list of subtasks with results
  - Display timestamps
  - Load session details on screen init
  - _Requirements: 6.4, 6.5_

- [ ]* 15.1 Write widget tests for session detail view
  - Test UI elements presence
  - Test session details display
  - Test subtask list display
  - _Requirements: 6.5_

- [ ]* 15.2 Write property test for session detail display
  - **Property 24: Session Detail Display**
  - **Validates: Requirements 6.5**

- [x] 16. Implement Material 3 theme





  - Create lib/theme/app_theme.dart
  - Define light and dark ColorScheme
  - Define status colors (success green, error red, in-progress blue)
  - Define TextTheme with Material 3 typography
  - Configure ThemeData with Material 3 components
  - _Requirements: 8.1, 8.2, 8.4, 8.5_

- [ ]* 16.1 Write tests for theme
  - Test color scheme definitions
  - Test status color mappings
  - Test theme switching
  - _Requirements: 8.2_

- [ ]* 16.2 Write property test for status color coding
  - **Property 30: Status Color Coding**
  - **Validates: Requirements 8.2**

- [x] 17. Implement navigation and routing





  - Create lib/routes/app_router.dart
  - Define routes for all screens
  - Implement initial route logic (onboarding vs landing)
  - Add navigation guards if needed
  - _Requirements: 1.4, 2.4, 4.5, 5.4, 6.4_

- [ ]* 17.1 Write integration tests for navigation
  - Test navigation flows
  - Test state preservation across navigation
  - Test back button handling
  - _Requirements: 2.4, 9.2_

- [ ]* 17.2 Write property test for state preservation
  - **Property 32: State Preservation Across Navigation**
  - **Validates: Requirements 9.2**

- [x] 18. Implement error handling and user feedback





  - Add error display widgets (SnackBar, Dialog, inline messages)
  - Implement user-friendly error messages for each error category
  - Add loading indicators for all async operations
  - Add button visual feedback (ripple effects)
  - Implement button disabling during operations
  - _Requirements: 7.1, 7.3, 7.4, 8.3, 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ]* 18.1 Write widget tests for error handling
  - Test error message display
  - Test loading indicators
  - Test button feedback
  - Test button disabling
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ]* 18.2 Write property test for user feedback
  - **Property 25: Network Error Messages**
  - **Property 36: Loading Indicator on Submission**
  - **Property 37: Button Tap Feedback**
  - **Property 39: Error Display with Icon**
  - **Property 40: Button Disabling During Operations**
  - **Validates: Requirements 7.1, 10.1, 10.2, 10.4, 10.5**

- [x] 19. Implement WebSocket lifecycle management





  - Add WebSocket connection handling in ExecutionState
  - Implement reconnection logic on connection drop
  - Implement connection persistence when app is backgrounded
  - Implement UI sync when app returns to foreground
  - Add connection status indicator
  - _Requirements: 7.2, 7.3, 9.3, 9.4, 9.5_

- [ ]* 19.1 Write tests for WebSocket lifecycle
  - Test connection establishment
  - Test reconnection attempts
  - Test backgrounding behavior
  - Test foregrounding behavior
  - _Requirements: 7.2, 9.4, 9.5_

- [ ]* 19.2 Write property test for WebSocket lifecycle
  - **Property 27: Reconnection Failure UI**
  - **Property 33: UI Updates on WebSocket Messages**
  - **Property 34: WebSocket Persistence When Backgrounded**
  - **Property 35: UI Sync on Foreground**
  - **Validates: Requirements 7.3, 9.3, 9.4, 9.5**

- [x] 20. Implement configuration and environment setup





  - Create lib/config/app_config.dart
  - Add environment variables for backend URL, WebSocket URL
  - Add configuration for timeouts, retry attempts
  - Add WindowConfig with minimal window size (300x100), transition duration (250ms), position offsets
  - Add validation for required configuration
  - _Requirements: 7.2, 13.2_

- [x] 21. Wire up Provider state management




  - Create lib/main.dart with MultiProvider setup
  - Register AppState, ExecutionStateNotifier, HistoryStateNotifier
  - Initialize services (BackendApiService, WebSocketService, StorageService, WindowService)
  - Initialize window_manager in main() before runApp()
  - Set up initial route based on onboarding status
  - _Requirements: 9.1, 9.2, 13.2_

- [ ]* 21.1 Write integration tests for app flow
  - Test complete onboarding → task submission → execution → completion flow
  - Test history viewing flow
  - Test cancellation flow
  - Test error scenarios
  - _Requirements: 1.1, 2.3, 3.1, 5.3, 6.2_

- [ ] 22. Implement scrollable subtask list with fixed header
  - Ensure subtask list is scrollable when many subtasks present
  - Keep header (instruction display) fixed at top
  - Add scroll-to-bottom on new subtask
  - _Requirements: 11.5_

- [ ]* 22.1 Write widget test for scrollable list
  - Test scrolling behavior with many subtasks
  - Test header visibility during scroll
  - _Requirements: 11.5_

- [ ]* 22.2 Write property test for scrollable list
  - **Property 45: Scrollable Subtask List**
  - **Validates: Requirements 11.5**

- [ ] 23. Implement parsing error handling
  - Add try-catch blocks for JSON parsing
  - Handle unexpected data gracefully
  - Display user-friendly error messages
  - Log parsing errors for debugging
  - _Requirements: 12.3_

- [ ]* 23.1 Write unit tests for parsing error handling
  - Test parsing with malformed JSON
  - Test parsing with missing fields
  - Test parsing with wrong types
  - _Requirements: 12.3_

- [ ]* 23.2 Write property test for parsing error handling
  - **Property 48: Parsing Error Handling**
  - **Validates: Requirements 12.3**

- [ ] 24. Add accessibility features
  - Add semantic labels to all interactive elements
  - Ensure proper focus order
  - Add screen reader support
  - Test with TalkBack/VoiceOver
  - _Requirements: 8.1_

- [ ] 25. Checkpoint - Ensure all tests pass
  - Run all unit tests
  - Run all widget tests
  - Run all property tests with 100 iterations
  - Run integration tests
  - Fix any failing tests
  - Verify coverage meets 75% threshold
  - Ask the user if questions arise
