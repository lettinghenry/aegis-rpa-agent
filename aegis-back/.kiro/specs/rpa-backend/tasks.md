# Implementation Plan

- [x] 1. Set up project structure and dependencies





  - Create main.py as entry point
  - Set up requirements.txt with FastAPI, Uvicorn, Pydantic, google-adk, pyautogui, pywin32, hypothesis, pytest
  - Create directory structure: src/, tests/, data/
  - Initialize Python virtual environment
  - _Requirements: 1.1, 7.1_

- [x] 2. Implement Pydantic data models





  - Create models.py with all request/response models
  - Define TaskInstructionRequest, TaskInstructionResponse, Subtask, ExecutionSession, StatusUpdate, SessionSummary, HistoryResponse, ErrorResponse
  - Add window_state field to StatusUpdate model (optional, values: "minimal", "normal")
  - Add validation logic to models
  - _Requirements: 7.1, 7.3, 13.2_

- [ ]* 2.1 Write unit tests for data models
  - Test model serialization and deserialization
  - Test validation logic
  - Test edge cases (empty fields, invalid types)
  - _Requirements: 7.1, 7.3_

- [x] 3. Implement Pre-Processing Layer





  - Create preprocessing.py with PreProcessor class
  - Implement validate_instruction() method
  - Implement sanitize_instruction() method
  - Add validation for empty, malformed, and oversized instructions
  - _Requirements: 2.1, 2.2_

- [ ]* 3.1 Write property test for pre-processing validation
  - **Property 4: Pre-Processing Before ADK**
  - **Property 5: Invalid Input Rejection**
  - **Validates: Requirements 2.1, 2.2**

- [x] 4. Implement Plan Cache





  - Create plan_cache.py with PlanCache class
  - Implement get_cached_plan() using embedding-based similarity
  - Implement store_plan() with LRU eviction
  - Implement compute_similarity() using cosine similarity
  - Set cache TTL to 24 hours, max size 100
  - _Requirements: 2.3, 2.4_

- [ ]* 4.1 Write property test for plan cache
  - **Property 6: Cache Lookup Always Performed**
  - **Property 7: Cache Hit Reuse**
  - **Validates: Requirements 2.3, 2.4**

- [x] 5. Implement RPA Toolbox





  - Create rpa_tools.py with ADK-compatible tool definitions
  - Implement @tool decorated functions: click_element, type_text, press_key, launch_application, focus_window, capture_screen, find_element_by_image, scroll
  - Each tool returns ToolResult with success status
  - Wrap PyAutoGUI and Win32API calls
  - _Requirements: 1.2, 3.1, 3.2, 3.3, 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ]* 5.1 Write unit tests for RPA tools
  - Test each tool function with mock PyAutoGUI/Win32API
  - Test error handling in tools
  - Test ToolResult structure
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 6. Implement RPA Engine




  - Create rpa_engine.py with RPAEngine class
  - Implement execute_click, execute_type, execute_key_press, launch_app methods
  - Add retry logic with exponential backoff (1s, 2s, 4s)
  - Integrate with Action Observer for verification
  - _Requirements: 5.1, 5.2, 5.3, 6.3, 6.4_

- [x] 6.1 Write property test for RPA engine actions










  - **Property 15: Click Action Execution**
  - **Property 16: Typing Action Execution**
  - **Property 17: Key Press Execution**
  - **Property 20: Retry on Failure**
  - **Validates: Requirements 5.1, 5.2, 5.3, 6.3**

- [ ] 7. Implement Action Observer
  - Create action_observer.py with ActionObserver class
  - Implement capture_state() using screenshot
  - Implement verify_action() with before/after comparison
  - Implement detect_error_dialogs() using OCR
  - _Requirements: 6.1, 6.2_

- [ ]* 7.1 Write property test for action observation
  - **Property 18: Screen Capture After Action**
  - **Property 19: Action Verification**
  - **Validates: Requirements 6.1, 6.2**

- [ ] 8. Implement ADK Agent Manager
  - Create adk_agent.py with ADKAgentManager class
  - Initialize Google ADK agent with Gemini model
  - Register RPA toolbox with agent
  - Implement execute_instruction() that yields ExecutionUpdate
  - Handle ADK agent errors with retry logic
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [ ]* 8.1 Write property test for ADK agent delegation
  - **Property 1: ADK Agent Delegation**
  - **Property 2: Execution Plan Structure**
  - **Validates: Requirements 1.3, 1.4**

- [ ] 9. Implement Session Manager
  - Create session_manager.py with SessionManager class
  - Implement create_session() returning unique session_id
  - Implement get_session(), update_session(), cancel_session()
  - Track session state and subtask progress
  - _Requirements: 3.1, 3.5, 8.5_

- [ ]* 9.1 Write property test for session management
  - **Property 8: Unique Session IDs**
  - **Property 12: Pending Status After Parsing**
  - **Property 31: Cancellation Cleanup**
  - **Validates: Requirements 3.1, 3.5, 8.5**

- [ ] 10. Implement History Store
  - Create history_store.py with HistoryStore class
  - Implement save_session() to persist JSON files
  - Implement get_all_sessions() with descending timestamp order
  - Implement get_session_details()
  - Create data/history/ directory structure
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ]* 10.1 Write property test for history storage
  - **Property 35: Session Record Creation**
  - **Property 36: Subtask Result Appending**
  - **Property 37: History Ordering**
  - **Property 39: Session Persistence**
  - **Validates: Requirements 10.1, 10.2, 10.3, 10.5**

- [ ] 11. Implement WebSocket Manager
  - Create websocket_manager.py with WebSocketManager class
  - Implement connect() to accept WebSocket connections
  - Implement broadcast_update() to send StatusUpdate messages with optional window_state field
  - Implement disconnect() to close connections
  - Handle multiple concurrent connections per session
  - Add helper method to send window state commands (WINDOW_STATE_MINIMAL, WINDOW_STATE_NORMAL)
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 7.1, 7.2, 7.3, 7.4, 7.5, 13.1, 13.2_

- [ ]* 11.1 Write property test for WebSocket streaming
  - **Property 3: WebSocket Streaming**
  - **Property 23: Subtask Start Status Update**
  - **Property 24: Subtask Completion Status Update**
  - **Property 25: Subtask Failure Status Update**
  - **Validates: Requirements 1.5, 7.2, 7.3, 7.4**

- [ ] 12. Implement FastAPI endpoints
  - Create main.py with FastAPI app initialization
  - Implement POST /api/start_task endpoint
  - Implement GET /api/history endpoint
  - Implement GET /api/history/{session_id} endpoint
  - Implement DELETE /api/execution/{session_id} endpoint
  - Implement WS /ws/execution/{session_id} endpoint
  - Add error handling and appropriate status codes
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ]* 12.1 Write property test for API endpoints
  - **Property 32: Malformed Request Validation**
  - **Property 33: Required Field Validation**
  - **Property 34: Appropriate Status Codes**
  - **Validates: Requirements 9.2, 9.3, 9.4**

- [ ] 13. Integrate all components in main execution flow
  - Wire Pre-Processing → Plan Cache → ADK Agent → RPA Engine → Action Observer
  - Connect Session Manager with WebSocket Manager for status updates
  - Connect Session Manager with History Store for persistence
  - Implement request queuing for sequential processing
  - Add logic to send WINDOW_STATE_MINIMAL before first desktop action (click, type, etc.)
  - Add logic to send WINDOW_STATE_NORMAL on execution completion or cancellation
  - _Requirements: 2.1, 2.3, 1.3, 6.5, 8.4, 13.1, 13.3, 13.4, 13.5_

- [ ]* 13.1 Write integration tests for execution flow
  - Test end-to-end task execution
  - Test WebSocket message streaming
  - Test error handling and retry logic
  - Test session cancellation
  - _Requirements: 1.3, 1.4, 1.5, 6.3, 6.4, 6.5_

- [ ] 14. Implement strategy selection module
  - Create strategy_module.py with StrategyModule class
  - Implement analyze_subtask() to determine coordinate-based vs element-based
  - Implement OCR integration for visual identification
  - Implement XPath/accessibility ID support
  - Add fallback to element-based strategy with warning
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ]* 14.1 Write property test for strategy selection
  - **Property 13: Coordinate Strategy for Fixed Elements**
  - **Property 14: Element Strategy for Dynamic Content**
  - **Validates: Requirements 4.1, 4.2**

- [ ] 15. Implement multi-app orchestration
  - Add application identification logic to ADK agent
  - Implement focus_window() in RPA tools
  - Implement launch_application() with readiness check
  - Add clipboard operations for data transfer
  - Track active application context
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ]* 15.1 Write property test for multi-app orchestration
  - **Property 40: Multi-Application Identification**
  - **Property 41: Application Focus Before Action**
  - **Property 42: Application Launch When Not Running**
  - **Validates: Requirements 11.1, 11.2, 11.3**

- [ ] 16. Implement intelligent text input handling
  - Add focus verification before typing
  - Implement special character encoding
  - Add human-like typing speed (30-150ms intervals)
  - Implement text clearing with Ctrl+A
  - Add typing verification
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ]* 16.1 Write property test for text input
  - **Property 43: Focus Before Typing**
  - **Property 44: Special Character Encoding**
  - **Property 45: Human-Like Typing Speed**
  - **Property 46: Text Clearing Before Replacement**
  - **Property 47: Typing Verification**
  - **Validates: Requirements 12.1, 12.2, 12.3, 12.4, 12.5**

- [ ] 17. Implement error handling and logging
  - Add structured error responses for all error categories
  - Implement logging with session context
  - Add timeout detection for application launches
  - Add element not found error with context
  - Implement resource cleanup on errors
  - _Requirements: 6.1, 6.2, 6.3, 8.1, 8.2, 8.3_

- [ ]* 17.1 Write property test for error handling
  - **Property 27: Structured Error Responses**
  - **Property 28: Launch Failure Detection Timing**
  - **Property 29: Element Not Found Context**
  - **Validates: Requirements 8.1, 8.2, 8.3**

- [ ] 18. Add configuration and environment setup
  - Create .env file for configuration
  - Add environment variables for ADK API key, Gemini model, timeouts
  - Create config.py to load environment variables
  - Add validation for required configuration
  - _Requirements: 1.1_

- [ ] 19. Checkpoint - Ensure all tests pass
  - Run all unit tests
  - Run all property tests with 100 iterations
  - Run integration tests
  - Fix any failing tests
  - Verify coverage meets 80% threshold
  - Ask the user if questions arise
