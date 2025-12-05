# Implementation Plan: Local App Launcher

- [x] 1. Set up configuration infrastructure





  - Create `config/app_mappings.json` with default application name mappings
  - Create `LauncherConfig` dataclass in `src/models.py` with timing and path parameters
  - Add environment variable loading for launcher configuration
  - _Requirements: 7.1, 7.2, 7.4, 7.5_

- [ ] 2. Implement core data models
  - Create `LaunchResult` dataclass with success, app_name, normalized_name, execution_time, error, fallback_triggered fields
  - Create `ExecutionResult` dataclass with success, steps_completed, error fields
  - Create `VerificationResult` dataclass with success, window_found, time_taken fields
  - _Requirements: 6.3, 6.4_

- [ ] 3. Implement AppNameMapper component
  - Create `src/app_name_mapper.py` with AppNameMapper class
  - Implement `__init__` to load mappings from JSON file
  - Implement `normalize` method to map variations to canonical names
  - Implement `reload` method for hot-reloading configuration
  - Handle missing/invalid config files gracefully with empty dictionary
  - _Requirements: 1.2, 2.1, 2.2, 2.3, 2.4, 2.5, 7.2, 7.5_

- [ ]* 3.1 Write property test for AppNameMapper
  - **Property 2: Normalization idempotence**
  - **Validates: Requirements 1.2**

- [ ]* 3.2 Write property test for unmapped passthrough
  - **Property 3: Unmapped passthrough**
  - **Validates: Requirements 2.5**

- [ ]* 3.3 Write unit tests for AppNameMapper
  - Test all default mappings (chrome, excel, word, notepad)
  - Test case-insensitive matching
  - Test config file loading and reloading
  - Test graceful handling of missing config
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 7.5_

- [ ] 4. Implement AppNameExtractor component
  - Create `src/app_name_extractor.py` with AppNameExtractor class
  - Implement `extract` method with regex patterns for "open X", "launch X", "start X", "run X"
  - Implement `is_simple_launch` method to detect multi-sentence instructions
  - Implement complexity detection for "and then", "after", "navigate", etc.
  - Implement ambiguity detection for multiple or no app names
  - _Requirements: 1.1, 5.1, 5.2, 5.3_

- [ ]* 4.1 Write property test for extraction consistency
  - **Property 1: Extraction consistency**
  - **Validates: Requirements 1.1**

- [ ]* 4.2 Write property test for multi-sentence detection
  - **Property 8: Multi-sentence detection**
  - **Validates: Requirements 5.1**

- [ ]* 4.3 Write property test for complex action detection
  - **Property 9: Complex action detection**
  - **Validates: Requirements 5.2**

- [ ]* 4.4 Write property test for ambiguity detection
  - **Property 10: Ambiguity detection**
  - **Validates: Requirements 5.3**

- [ ]* 4.5 Write unit tests for AppNameExtractor
  - Test extraction with various patterns
  - Test multi-sentence detection
  - Test complex action detection
  - Test ambiguity detection
  - _Requirements: 1.1, 5.1, 5.2, 5.3_

- [ ] 5. Implement LaunchExecutor component
  - Create `src/launch_executor.py` with LaunchExecutor class
  - Implement `__init__` to accept TimingConfig parameters
  - Implement `execute_launch_pattern` method using PyAutoGUI
  - Execute sequence: Win key → wait → type app name → Enter → wait → Enter → wait
  - Use timing parameters from config (menu_open_delay, typing_interval, search_delay, launch_delay)
  - Wrap PyAutoGUI calls in try-except for error handling
  - Log each step with timestamps
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 6.2_

- [ ]* 5.1 Write property test for execution logs all steps
  - **Property 13: Execution logs all steps**
  - **Validates: Requirements 6.2**

- [ ]* 5.2 Write unit tests for LaunchExecutor (mocked PyAutoGUI)
  - Test launch pattern sequence
  - Test timing parameters are respected
  - Test error handling for PyAutoGUI failures
  - Test logging at each step
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 6.2_

- [ ] 6. Implement LaunchVerifier component
  - Create `src/launch_verifier.py` with LaunchVerifier class
  - Implement `verify_launch` method that polls for window containing app name
  - Use RPAEngine's `list_all_open_windows` method
  - Poll every 0.5 seconds up to timeout (default 5 seconds)
  - Perform case-insensitive window title matching
  - Return VerificationResult with success, window_found, time_taken
  - _Requirements: 1.4_

- [ ]* 6.1 Write unit tests for LaunchVerifier (mocked window list)
  - Test successful verification
  - Test timeout behavior
  - Test case-insensitive matching
  - _Requirements: 1.4_

- [ ] 7. Implement LocalAppLauncher orchestrator
  - Create `src/local_app_launcher.py` with LocalAppLauncher class
  - Implement `__init__` to initialize all subcomponents (extractor, mapper, executor, verifier)
  - Implement `can_handle` method that checks if instruction is simple launch
  - Implement `launch` method that orchestrates extraction → normalization → execution → verification
  - Implement `reload_config` method to reload mapper configuration
  - Add comprehensive logging at each stage (extracted name, normalized name, execution steps, outcome)
  - Handle all error cases and trigger fallback appropriately
  - Record execution time for all operations
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 5.4, 5.5, 6.1, 6.3, 6.4, 7.3_

- [ ]* 7.1 Write property test for failure triggers fallback
  - **Property 4: Failure triggers fallback**
  - **Validates: Requirements 3.5**

- [ ]* 7.2 Write property test for decline triggers routing
  - **Property 11: Decline triggers routing**
  - **Validates: Requirements 5.4**

- [ ]* 7.3 Write property test for processing logs extraction
  - **Property 12: Processing logs extraction**
  - **Validates: Requirements 6.1**

- [ ]* 7.4 Write property test for outcome includes timing
  - **Property 14: Outcome includes timing**
  - **Validates: Requirements 6.3**

- [ ]* 7.5 Write property test for fallback logs reason
  - **Property 15: Fallback logs reason**
  - **Validates: Requirements 6.4**

- [ ]* 7.6 Write property test for invalid config uses defaults
  - **Property 17: Invalid config uses defaults**
  - **Validates: Requirements 7.4**

- [ ]* 7.7 Write integration tests for LocalAppLauncher
  - Test end-to-end flow for simple launch
  - Test fallback on verification failure
  - Test decline for complex instructions
  - Test logging at each stage
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 5.4, 6.1_

- [ ] 8. Integrate with PreProcessor
  - Update `src/preprocessing.py` to add LocalAppLauncher integration
  - Add `check_local_launcher` method that calls `can_handle` and `launch`
  - Modify `validate_and_sanitize` to check local launcher before returning
  - Return early with success if local launcher handles the request
  - Route to ADK agent if local launcher declines or fails
  - _Requirements: 4.1, 4.2, 4.3_

- [ ]* 8.1 Write property test for successful local launch bypasses ADK
  - **Property 5: Successful local launch bypasses ADK**
  - **Validates: Requirements 4.2**

- [ ]* 8.2 Write property test for unhandled requests route to ADK
  - **Property 6: Unhandled requests route to ADK**
  - **Validates: Requirements 4.3**

- [ ] 9. Add WebSocket status updates
  - Update WebSocket manager to send status updates during local launching
  - Send "Launching application locally" message when local launcher starts
  - Send progress updates for each step (pressing Win key, typing, verifying)
  - Send success/failure message when complete
  - _Requirements: 4.4_

- [ ] 10. Update history storage
  - Modify `src/history_store.py` to add `launch_method` field to session model
  - Set `launch_method` to "local" when LocalAppLauncher succeeds
  - Set `launch_method` to "adk" when ADK agent is used
  - Set `launch_method` to "local_fallback" when local launcher fails and falls back
  - _Requirements: 4.5, 6.5_

- [ ]* 10.1 Write property test for history records launch method
  - **Property 7: History records launch method**
  - **Validates: Requirements 4.5**

- [ ]* 10.2 Write property test for history includes method field
  - **Property 16: History includes method field**
  - **Validates: Requirements 6.5**

- [ ] 11. Add configuration management
  - Create default `config/app_mappings.json` with common applications
  - Add environment variable support for enabling/disabling feature
  - Add environment variables for timing parameters
  - Document configuration in README
  - _Requirements: 7.1, 7.2, 7.4_

- [ ] 12. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Add monitoring and metrics
  - Add metrics tracking for local launch success rate
  - Add metrics for average execution time
  - Add metrics for fallback reasons distribution
  - Add metrics for most launched apps
  - Log metrics periodically for monitoring
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ]* 13.1 Write integration tests for metrics
  - Test metrics are recorded correctly
  - Test metrics aggregation
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 14. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
