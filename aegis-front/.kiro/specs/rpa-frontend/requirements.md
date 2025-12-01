# Requirements Document

## Introduction

The AEGIS RPA Frontend is a Flutter-based mobile/desktop application that provides an intuitive interface for users to command the AEGIS RPA Backend and monitor automation execution in real-time. The application focuses on simplicity and clarity, allowing users to input natural language task instructions and observe the cognitive agent's progress through visual feedback.

## Glossary

- **AEGIS Frontend**: The Flutter application that serves as the user interface for the AEGIS RPA system
- **Landing Screen**: The main screen where users input task instructions
- **Task Execution Screen**: The screen that displays real-time progress of automation execution
- **Onboarding Screen**: The initial screen shown to first-time users explaining the system
- **Status Update**: A real-time message from the backend indicating the current state of execution
- **Execution Session**: A single automation run tracked from start to completion
- **Subtask Card**: A UI component displaying the status of an individual subtask within an execution
- **History View**: The screen displaying past execution sessions
- **Backend Client**: The HTTP and WebSocket client that communicates with the AEGIS Backend
- **Minimal Window Mode**: A compact, floating window state that maximizes desktop space for RPA operations
- **Window Manager**: The Flutter package (bitsdojo_window or window_manager) that controls window size, position, and properties

## Requirements

### Requirement 1

**User Story:** As a first-time user, I want to see an onboarding screen, so that I understand how to use the AEGIS RPA Agent.

#### Acceptance Criteria

1. WHEN the AEGIS Frontend launches for the first time, THEN the AEGIS Frontend SHALL display the Onboarding Screen
2. WHEN the Onboarding Screen is displayed, THEN the AEGIS Frontend SHALL show a clear explanation of the system's capabilities
3. WHEN the user completes onboarding, THEN the AEGIS Frontend SHALL store a flag indicating onboarding is complete
4. WHEN the user launches the app after completing onboarding, THEN the AEGIS Frontend SHALL skip the Onboarding Screen and show the Landing Screen
5. WHEN the Onboarding Screen is displayed, THEN the AEGIS Frontend SHALL provide a "Get Started" button to proceed to the Landing Screen

### Requirement 2

**User Story:** As a user, I want to input task instructions on the landing screen, so that I can command the automation agent.

#### Acceptance Criteria

1. WHEN the Landing Screen is displayed, THEN the AEGIS Frontend SHALL show a prominent text input field for task instructions
2. WHEN the user types in the input field, THEN the AEGIS Frontend SHALL enable the submit button only if the input is non-empty
3. WHEN the user submits a task instruction, THEN the AEGIS Frontend SHALL send a POST request to the backend /api/start_task endpoint
4. WHEN the backend returns a session ID, THEN the AEGIS Frontend SHALL navigate to the Task Execution Screen
5. IF the backend returns an error, THEN the AEGIS Frontend SHALL display an error message below the input field without navigating away

### Requirement 3

**User Story:** As a user, I want to see real-time execution progress, so that I understand what the automation agent is doing.

#### Acceptance Criteria

1. WHEN the Task Execution Screen is displayed, THEN the AEGIS Frontend SHALL establish a WebSocket connection to /ws/execution/{session_id}
2. WHEN the AEGIS Frontend receives a status update for a new subtask, THEN the AEGIS Frontend SHALL add a new Subtask Card to the display
3. WHEN a subtask status changes to "completed", THEN the AEGIS Frontend SHALL update the corresponding Subtask Card with a success indicator
4. WHEN a subtask status changes to "failed", THEN the AEGIS Frontend SHALL update the corresponding Subtask Card with an error indicator and message
5. WHEN a subtask status is "in_progress", THEN the AEGIS Frontend SHALL display a loading indicator on the corresponding Subtask Card

### Requirement 4

**User Story:** As a user, I want to see the overall execution status, so that I know when my automation is complete or has failed.

#### Acceptance Criteria

1. WHEN the execution session starts, THEN the AEGIS Frontend SHALL display the original task instruction at the top of the Task Execution Screen
2. WHEN all subtasks complete successfully, THEN the AEGIS Frontend SHALL display a success message and enable a "Done" button
3. IF any subtask fails, THEN the AEGIS Frontend SHALL display an error summary and enable a "Back" button
4. WHEN the WebSocket connection closes, THEN the AEGIS Frontend SHALL determine the final session status based on received updates
5. WHEN the execution is complete, THEN the AEGIS Frontend SHALL provide an option to return to the Landing Screen

### Requirement 5

**User Story:** As a user, I want to cancel an ongoing execution, so that I can stop automation if needed.

#### Acceptance Criteria

1. WHEN the Task Execution Screen is displayed during active execution, THEN the AEGIS Frontend SHALL show a "Cancel" button
2. WHEN the user taps the "Cancel" button, THEN the AEGIS Frontend SHALL display a confirmation dialog
3. WHEN the user confirms cancellation, THEN the AEGIS Frontend SHALL send a DELETE request to /api/execution/{session_id}
4. WHEN the backend confirms cancellation, THEN the AEGIS Frontend SHALL close the WebSocket connection and return to the Landing Screen
5. WHEN the cancellation request fails, THEN the AEGIS Frontend SHALL display an error message and keep the execution screen active

### Requirement 6

**User Story:** As a user, I want to view my execution history, so that I can review past automation sessions.

#### Acceptance Criteria

1. WHEN the Landing Screen is displayed, THEN the AEGIS Frontend SHALL show a "History" button or navigation option
2. WHEN the user navigates to the History View, THEN the AEGIS Frontend SHALL send a GET request to /api/history
3. WHEN the backend returns the history list, THEN the AEGIS Frontend SHALL display each session with timestamp, instruction, and status
4. WHEN the user taps on a history item, THEN the AEGIS Frontend SHALL send a GET request to /api/history/{session_id}
5. WHEN the session details are retrieved, THEN the AEGIS Frontend SHALL display the complete subtask sequence and results

### Requirement 7

**User Story:** As a developer, I want the frontend to handle network errors gracefully, so that users have a good experience even when connectivity issues occur.

#### Acceptance Criteria

1. WHEN a network request fails due to connectivity issues, THEN the AEGIS Frontend SHALL display a user-friendly error message
2. WHEN the WebSocket connection drops unexpectedly, THEN the AEGIS Frontend SHALL attempt to reconnect up to three times
3. IF reconnection fails, THEN the AEGIS Frontend SHALL display an error message and provide an option to return to the Landing Screen
4. WHEN the backend is unreachable, THEN the AEGIS Frontend SHALL display a message indicating the backend is offline
5. WHEN network connectivity is restored, THEN the AEGIS Frontend SHALL automatically retry the failed request

### Requirement 8

**User Story:** As a user, I want the UI to follow Material 3 design principles, so that the application feels modern and intuitive.

#### Acceptance Criteria

1. WHEN any screen is displayed, THEN the AEGIS Frontend SHALL use Material 3 components and styling
2. WHEN displaying status indicators, THEN the AEGIS Frontend SHALL use appropriate Material 3 colors (success green, error red, in-progress blue)
3. WHEN the user interacts with buttons, THEN the AEGIS Frontend SHALL provide Material 3 ripple effects and visual feedback
4. WHEN displaying cards or lists, THEN the AEGIS Frontend SHALL use Material 3 elevation and spacing guidelines
5. WHEN the app theme is applied, THEN the AEGIS Frontend SHALL support both light and dark modes based on system preferences

### Requirement 9

**User Story:** As a developer, I want the frontend to manage state effectively, so that the UI remains responsive and consistent.

#### Acceptance Criteria

1. WHEN the application state changes, THEN the AEGIS Frontend SHALL use Provider or Riverpod to propagate changes to the UI
2. WHEN navigating between screens, THEN the AEGIS Frontend SHALL preserve relevant state (e.g., execution session data)
3. WHEN the WebSocket receives updates, THEN the AEGIS Frontend SHALL update the state and trigger UI rebuilds efficiently
4. WHEN the app is backgrounded during execution, THEN the AEGIS Frontend SHALL maintain the WebSocket connection
5. WHEN the app returns to foreground, THEN the AEGIS Frontend SHALL sync the UI with the current execution state

### Requirement 10

**User Story:** As a user, I want clear visual feedback for all interactions, so that I know the system is responding to my actions.

#### Acceptance Criteria

1. WHEN the user submits a task instruction, THEN the AEGIS Frontend SHALL display a loading indicator until the backend responds
2. WHEN the user taps any button, THEN the AEGIS Frontend SHALL provide immediate visual feedback (ripple, color change)
3. WHEN data is being loaded from the backend, THEN the AEGIS Frontend SHALL display a progress indicator
4. WHEN an error occurs, THEN the AEGIS Frontend SHALL display the error message with an appropriate icon
5. WHEN a long-running operation is in progress, THEN the AEGIS Frontend SHALL disable relevant buttons to prevent duplicate actions

### Requirement 11

**User Story:** As a user, I want the subtask display to be clear and organized, so that I can easily follow the automation progress.

#### Acceptance Criteria

1. WHEN subtasks are displayed, THEN the AEGIS Frontend SHALL show them in chronological order from top to bottom
2. WHEN a subtask is in progress, THEN the AEGIS Frontend SHALL highlight it visually to draw attention
3. WHEN a subtask completes, THEN the AEGIS Frontend SHALL show a checkmark icon and dim the card slightly
4. WHEN a subtask fails, THEN the AEGIS Frontend SHALL show an error icon and display the error message below the subtask description
5. WHEN many subtasks are present, THEN the AEGIS Frontend SHALL make the list scrollable while keeping the header visible

### Requirement 12

**User Story:** As a developer, I want the frontend to communicate with the backend using typed models, so that data exchange is reliable and type-safe.

#### Acceptance Criteria

1. WHEN sending requests to the backend, THEN the AEGIS Frontend SHALL serialize data using Dart classes that match the backend Pydantic models
2. WHEN receiving responses from the backend, THEN the AEGIS Frontend SHALL deserialize JSON into typed Dart objects
3. WHEN a response contains unexpected data, THEN the AEGIS Frontend SHALL handle the parsing error gracefully
4. WHEN defining API models, THEN the AEGIS Frontend SHALL include validation logic to ensure data integrity
5. WHEN the backend API changes, THEN the AEGIS Frontend SHALL detect type mismatches during development

### Requirement 13

**User Story:** As a user, I want the application window to minimize during RPA execution, so that the automation agent has unobstructed access to the desktop and other applications.

#### Acceptance Criteria

1. WHEN the AEGIS Frontend receives a 'WINDOW_STATE_MINIMAL' command from the backend via WebSocket, THEN the AEGIS Frontend SHALL transition to minimal window mode
2. WHEN entering minimal window mode, THEN the AEGIS Frontend SHALL resize the window to a small floating panel (e.g., 300x100 pixels)
3. WHEN in minimal window mode, THEN the AEGIS Frontend SHALL set the window to Always On Top to remain visible
4. WHEN in minimal window mode, THEN the AEGIS Frontend SHALL make the window borderless to maximize screen real estate
5. WHEN the AEGIS Frontend receives a 'WINDOW_STATE_NORMAL' command or the execution completes, THEN the AEGIS Frontend SHALL restore the window to its original size and position
