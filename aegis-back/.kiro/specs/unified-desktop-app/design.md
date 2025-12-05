# Design Document: Unified Desktop App

## Overview

The unified desktop app feature transforms AEGIS from a development-oriented client-server architecture into a single-click installable application. The Flutter frontend will embed and manage the Python backend as a subprocess, presenting users with a seamless single-application experience.

## Architecture

### High-Level Flow

```
User launches AEGIS.exe
    ↓
Flutter app starts
    ↓
BackendLauncherService checks localhost:8000
    ↓
If not running → Launch backend/aegis-backend.exe
    ↓
Poll backend health endpoint
    ↓
Backend ready → Show main UI
    ↓
User closes app → Terminate backend process
```

### Component Interaction

```
┌─────────────────────────────────────┐
│      Flutter Frontend (UI)          │
│  ┌───────────────────────────────┐  │
│  │  BackendLauncherService       │  │
│  │  - Process management         │  │
│  │  - Health checking            │  │
│  │  - Lifecycle control          │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
              ↓ subprocess
┌─────────────────────────────────────┐
│   Backend Executable (Packaged)     │
│   - FastAPI server                  │
│   - Bundled Python runtime          │
│   - All dependencies included       │
└─────────────────────────────────────┘
```

## Components and Interfaces

### 1. Backend Packaging (Python)

**Tool:** PyInstaller

**Configuration:** `aegis-back/build_executable.spec`
- Entry point: `main.py`
- Include all `src/` modules
- Include `config/` directory
- Bundle Python runtime
- Single-file or single-directory mode (directory preferred for faster startup)

**Output:** `dist/aegis-backend/aegis-backend.exe` (Windows)

### 2. Backend Launcher Service (Flutter)

**File:** `aegis-front/lib/services/backend_launcher_service.dart`

**Interface:**
```dart
class BackendLauncherService {
  Future<BackendStatus> checkBackendStatus();
  Future<void> startBackend();
  Future<void> stopBackend();
  Future<void> waitForBackendReady({Duration timeout});
  Stream<BackendHealth> get healthStream;
}

enum BackendStatus { running, stopped, starting, error }

class BackendHealth {
  final bool isHealthy;
  final String? errorMessage;
  final DateTime timestamp;
}
```

**Responsibilities:**
- Locate bundled backend executable
- Launch backend as subprocess
- Monitor backend process health
- Gracefully terminate backend on app exit
- Handle backend crashes

### 3. Startup Screen (Flutter)

**File:** `aegis-front/lib/screens/startup_screen.dart`

**Purpose:** Display loading state while backend initializes

**States:**
- Checking backend status
- Starting backend
- Waiting for backend ready
- Error (with retry option)

### 4. Build Integration

**Backend Build Script:** `aegis-back/build.py`
- Run PyInstaller with spec file
- Copy output to known location
- Verify executable works

**Frontend Build Integration:**
- Copy backend executable to Flutter assets during build
- Update `pubspec.yaml` to include backend in bundle
- Platform-specific bundling (Windows: include in `data/` folder)

## Data Models

### Backend Configuration

**File:** `aegis-back/src/config.py`

```python
@dataclass
class UnifiedAppConfig:
    port: int = 8000
    host: str = "127.0.0.1"  # localhost only
    data_dir: Path = Path.home() / "AEGIS" / "data"
    log_level: str = "INFO"
    
    @classmethod
    def from_env(cls):
        # Load from environment or use defaults
        pass
```

### Backend Health Response

```python
class HealthResponse(BaseModel):
    status: str = "healthy"
    version: str
    uptime_seconds: float
```

**Endpoint:** `GET /health`

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Backend process lifecycle

*For any* app session, when the Flutter app starts and successfully launches the backend, then when the Flutter app exits, the backend process should no longer be running.

**Validates: Requirements 3.4**

### Property 2: Health check convergence

*For any* backend startup sequence, if the backend process is running, then repeated health checks should eventually return success within the timeout period.

**Validates: Requirements 4.4**

### Property 3: Port availability detection

*For any* app startup, if port 8000 is already occupied by a healthy AEGIS backend, then the launcher should not start a new backend process.

**Validates: Requirements 3.1**

### Property 4: Data directory creation

*For any* backend startup, if the configured data directory does not exist, then after startup the directory should exist and be writable.

**Validates: Requirements 2.4**

### Property 5: Executable location resolution

*For any* Flutter app installation, the backend launcher should be able to locate the bundled backend executable relative to the app's installation path.

**Validates: Requirements 5.2**

## Error Handling

### Backend Launch Failures

**Scenarios:**
- Executable not found → Show installation corruption error
- Port already in use (non-AEGIS) → Show port conflict error with instructions
- Backend crashes immediately → Show error logs and troubleshooting steps
- Backend doesn't respond to health checks → Timeout error with retry option

**User Actions:**
- Retry button (attempts relaunch)
- View logs button (opens log file)
- Exit button (closes app)

### Runtime Failures

**Scenarios:**
- Backend crashes during operation → Detect via health monitoring, show reconnection dialog
- Backend becomes unresponsive → Detect via failed API calls, attempt restart

**Recovery:**
- Automatic restart attempt (once)
- If restart fails, show error and require manual app restart

## Testing Strategy

### Unit Tests

**Backend (Python):**
- Test `UnifiedAppConfig` loading from environment
- Test health endpoint returns correct format
- Test data directory creation logic

**Frontend (Dart):**
- Test `BackendLauncherService.checkBackendStatus()` with mocked HTTP client
- Test `BackendLauncherService.startBackend()` with mocked Process
- Test executable path resolution logic
- Test health polling logic

### Property-Based Tests

**Library:** Hypothesis (Python), dart_check (Dart)

**Tests:**
- Property 1: Backend lifecycle (integration test with real process)
- Property 2: Health check convergence (with various delays)
- Property 3: Port detection (with mock server on port)
- Property 4: Data directory creation (with various path scenarios)
- Property 5: Executable location (with various installation paths)

### Integration Tests

**End-to-End Flow:**
1. Start Flutter app
2. Verify backend launches
3. Verify health endpoint responds
4. Submit a simple task
5. Verify task executes
6. Close Flutter app
7. Verify backend terminates

**Manual Testing:**
- Install on clean Windows machine
- Verify single-click launch
- Verify no Python installation required
- Test with antivirus software
- Test with firewall enabled

## Implementation Notes

### PyInstaller Configuration

- Use `--onedir` mode (faster startup than `--onefile`)
- Include hidden imports for FastAPI, Pydantic, PyAutoGUI
- Exclude unnecessary packages (tests, dev tools)
- Set console mode to hidden (no console window)

### Flutter Process Management

- Use `Process.start()` for subprocess management
- Capture stdout/stderr for logging
- Use `Process.kill()` for graceful termination
- Register app lifecycle listener to ensure cleanup

### Port Configuration

- Hardcode port 8000 for simplicity
- Backend binds to 127.0.0.1 only (security)
- No external network access needed

### Data Directory

- Windows: `%USERPROFILE%\AEGIS\data`
- Structure: `data/history/`, `data/cache/`, `data/logs/`
- Backend and frontend share this location

### Build Automation

- Create `build_unified.py` script that:
  1. Builds backend executable
  2. Copies to Flutter assets
  3. Builds Flutter app
  4. Creates installer (optional: Inno Setup)

## Future Enhancements

- Auto-update mechanism
- Multiple backend instances for parallel execution
- Backend version compatibility checking
- Installer with custom branding
- System tray icon for background operation
