# Implementation Plan: Unified Desktop App

- [ ] 1. Set up backend packaging infrastructure
  - Create `aegis-back/build_executable.spec` PyInstaller configuration file
  - Configure entry point as `main.py`
  - Include all `src/` modules and `config/` directory
  - Set to `--onedir` mode for faster startup
  - Add hidden imports for FastAPI, Pydantic, PyAutoGUI, uvicorn
  - Set console mode to hidden
  - _Requirements: 2.1_

- [ ] 2. Add backend health endpoint
  - Create `HealthResponse` model in `src/models.py` with status, version, uptime_seconds fields
  - Add `GET /health` endpoint in `main.py` that returns HealthResponse
  - Include app version and uptime calculation
  - _Requirements: 4.4_

- [ ]* 2.1 Write unit test for health endpoint
  - Test health endpoint returns correct format
  - Test uptime increases over time
  - _Requirements: 4.4_

- [ ] 3. Update backend configuration for unified app mode
  - Create `UnifiedAppConfig` dataclass in `src/config.py`
  - Add fields: port (default 8000), host (default 127.0.0.1), data_dir, log_level
  - Implement `from_env()` classmethod to load from environment variables with defaults
  - Update `main.py` to use UnifiedAppConfig when starting server
  - Ensure data directories are created on startup if they don't exist
  - _Requirements: 2.2, 2.3, 2.4, 6.1, 6.2, 7.1, 7.3_

- [ ]* 3.1 Write property test for data directory creation
  - **Property 4: Data directory creation**
  - **Validates: Requirements 2.4**

- [ ]* 3.2 Write unit tests for UnifiedAppConfig
  - Test loading from environment variables
  - Test default values when env vars not set
  - Test data directory path resolution
  - _Requirements: 2.3, 7.1, 7.3_

- [ ] 4. Create backend build script
  - Create `aegis-back/build.py` Python script
  - Script should run PyInstaller with the spec file
  - Verify output executable exists in `dist/aegis-backend/`
  - Add simple smoke test that launches executable and checks health endpoint
  - _Requirements: 2.1_

- [ ] 5. Implement BackendLauncherService in Flutter
  - Create `aegis-front/lib/services/backend_launcher_service.dart`
  - Define `BackendStatus` enum (running, stopped, starting, error)
  - Define `BackendHealth` class with isHealthy, errorMessage, timestamp fields
  - Implement `checkBackendStatus()` method that checks if port 8000 responds to health endpoint
  - Implement `getBackendExecutablePath()` method to locate bundled executable
  - Implement `startBackend()` method using Process.start() to launch executable
  - Implement `stopBackend()` method using Process.kill() to terminate
  - Implement `waitForBackendReady()` method that polls health endpoint with timeout
  - Add `healthStream` that periodically checks backend health
  - Capture backend stdout/stderr for logging
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 4.4, 5.2, 5.3_

- [ ]* 5.1 Write property test for backend lifecycle
  - **Property 1: Backend process lifecycle**
  - **Validates: Requirements 3.4**

- [ ]* 5.2 Write property test for health check convergence
  - **Property 2: Health check convergence**
  - **Validates: Requirements 4.4**

- [ ]* 5.3 Write property test for port availability detection
  - **Property 3: Port availability detection**
  - **Validates: Requirements 3.1**

- [ ]* 5.4 Write property test for executable location resolution
  - **Property 5: Executable location resolution**
  - **Validates: Requirements 5.2**

- [ ]* 5.5 Write unit tests for BackendLauncherService
  - Test checkBackendStatus with mocked HTTP client
  - Test startBackend with mocked Process
  - Test stopBackend with mocked Process
  - Test waitForBackendReady polling logic
  - Test executable path resolution
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 5.2_

- [ ] 6. Create startup screen in Flutter
  - Create `aegis-front/lib/screens/startup_screen.dart`
  - Display loading indicator with status messages
  - Show states: "Checking backend...", "Starting backend...", "Waiting for backend..."
  - Add error state with retry button and view logs button
  - Transition to main app when backend ready
  - _Requirements: 4.1, 4.2, 4.3_

- [ ]* 6.1 Write widget test for startup screen
  - Test loading states display correctly
  - Test error state shows retry button
  - Test transition to main app on success
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 7. Integrate BackendLauncherService into app lifecycle
  - Update `aegis-front/lib/main.dart` to initialize BackendLauncherService
  - Add app lifecycle listener (WidgetsBindingObserver) to detect app exit
  - Call `startBackend()` on app start
  - Call `stopBackend()` on app exit (AppLifecycleState.detached)
  - Show StartupScreen as initial route
  - Navigate to main app after backend ready
  - _Requirements: 3.2, 3.4, 4.1, 4.2_

- [ ]* 7.1 Write integration test for app lifecycle
  - Test backend starts when app starts
  - Test backend stops when app exits
  - Test navigation from startup to main screen
  - _Requirements: 3.2, 3.4, 4.1, 4.2_

- [ ] 8. Set up Flutter build to bundle backend executable
  - Create `aegis-front/bundle_backend.dart` script
  - Script copies backend executable from `../aegis-back/dist/aegis-backend/` to `aegis-front/assets/backend/`
  - Update `aegis-front/pubspec.yaml` to include `assets/backend/` in assets
  - Update BackendLauncherService to look for executable in bundled assets location
  - _Requirements: 5.1, 5.2_

- [ ] 9. Create unified build script
  - Create `build_unified.py` in project root
  - Script should: 1) Build backend with PyInstaller, 2) Copy backend to Flutter assets, 3) Build Flutter Windows app
  - Add command-line options for debug/release builds
  - Add verification step that checks both executables exist
  - _Requirements: 1.1, 5.1_

- [ ] 10. Update shared data directory configuration
  - Update backend to use `%USERPROFILE%\AEGIS\data` on Windows
  - Update Flutter StorageService to use same data directory
  - Ensure both frontend and backend create subdirectories (history, cache, logs)
  - _Requirements: 6.1, 6.2, 6.3_

- [ ]* 10.1 Write unit tests for data directory configuration
  - Test backend uses correct data directory
  - Test frontend uses correct data directory
  - Test subdirectories are created
  - _Requirements: 6.1, 6.2, 6.3_

- [ ] 11. Add error handling and user feedback
  - Add error messages for missing executable (installation corruption)
  - Add error messages for port conflicts
  - Add error messages for backend crash
  - Add error messages for health check timeout
  - Include troubleshooting guidance in error dialogs
  - _Requirements: 4.3, 5.3_

- [ ] 12. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Create documentation
  - Update `aegis-back/README.md` with build instructions
  - Update `aegis-front/README.md` with unified app information
  - Create `BUILD.md` with step-by-step build process
  - Document data directory structure
  - Document troubleshooting common issues
  - _Requirements: 7.2_

- [ ] 14. Final checkpoint - Manual testing
  - Build unified app and test on clean Windows machine
  - Verify single-click launch works
  - Verify backend starts automatically
  - Verify task execution works end-to-end
  - Verify app closes cleanly and backend terminates
  - Verify data persists across app restarts
