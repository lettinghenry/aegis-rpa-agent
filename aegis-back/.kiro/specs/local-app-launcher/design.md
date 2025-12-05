# Design Document: Local App Launcher

## Overview

The Local App Launcher is a pre-processing optimization module that intercepts application launch requests and executes them directly using PyAutoGUI keyboard automation, bypassing the ADK/Gemini LLM entirely. This design reduces latency from seconds to milliseconds, eliminates API costs for simple app launches, and improves system reliability by removing network dependencies for common operations.

The module integrates into the existing preprocessing layer as a first-pass filter, attempting local execution before falling back to the full ADK agent pipeline when necessary.

## Architecture

### System Integration

```
User Request → PreProcessor → Local App Launcher → [Success] → Response
                            ↓                      ↓
                            [Not Applicable]       [Failure]
                            ↓                      ↓
                            ADK Agent (Fallback) → Response
```

### Component Hierarchy

1. **PreProcessor** (existing): Entry point that now checks Local App Launcher first
2. **LocalAppLauncher**: New module with pattern detection and execution
3. **AppNameExtractor**: Subcomponent for parsing natural language
4. **AppNameMapper**: Subcomponent for normalizing app name variations
5. **LaunchExecutor**: Subcomponent for PyAutoGUI keyboard automation
6. **LaunchVerifier**: Subcomponent for success verification
7. **RPAEngine** (existing): Used for low-level PyAutoGUI operations

## Components and Interfaces

### LocalAppLauncher Class

**Purpose**: Main orchestrator that determines if a request can be handled locally and coordinates the launch process.

**Public Methods**:
```python
class LocalAppLauncher:
    def __init__(self, config: LauncherConfig):
        """Initialize with configuration for timing and mappings."""
        
    def can_handle(self, instruction: str) -> bool:
        """Determine if instruction is a simple app launch request."""
        
    def launch(self, instruction: str) -> LaunchResult:
        """Execute local app launch and return result."""
        
    def reload_config(self) -> None:
        """Reload configuration from file without restart."""
```

**Dependencies**: AppNameExtractor, AppNameMapper, LaunchExecutor, LaunchVerifier

### AppNameExtractor Class

**Purpose**: Extract application names from natural language instructions using regex patterns.

**Public Methods**:
```python
class AppNameExtractor:
    def extract(self, instruction: str) -> Optional[str]:
        """Extract app name from instruction, return None if not found."""
        
    def is_simple_launch(self, instruction: str) -> bool:
        """Check if instruction is a simple launch (not multi-step)."""
```

**Patterns**:
- `r"(?:open|launch|start|run)\s+([a-zA-Z0-9\s]+)(?:\s|$)"`
- `r"(?:can you |please )?(?:open|launch|start|run)\s+([a-zA-Z0-9\s]+)"`

### AppNameMapper Class

**Purpose**: Map common app name variations to canonical Windows search terms.

**Public Methods**:
```python
class AppNameMapper:
    def __init__(self, mapping_file: str):
        """Load mappings from JSON file."""
        
    def normalize(self, app_name: str) -> str:
        """Return canonical name or original if not in mapping."""
        
    def reload(self) -> None:
        """Reload mappings from file."""
```

**Default Mappings** (app_mappings.json):
```json
{
  "chrome": ["chrome", "google chrome", "browser"],
  "excel": ["excel", "spreadsheet", "ms excel", "microsoft excel"],
  "word": ["word", "document", "ms word", "microsoft word"],
  "notepad": ["notepad", "text editor", "note pad"],
  "calculator": ["calculator", "calc"],
  "explorer": ["explorer", "file explorer", "files"],
  "cmd": ["cmd", "command prompt", "terminal"],
  "powershell": ["powershell", "power shell", "ps"]
}
```

### LaunchExecutor Class

**Purpose**: Execute the Windows Start Menu keyboard automation sequence.

**Public Methods**:
```python
class LaunchExecutor:
    def __init__(self, timing_config: TimingConfig):
        """Initialize with timing parameters."""
        
    def execute_launch_pattern(self, app_name: str) -> ExecutionResult:
        """Execute Win key → type → Enter → Enter sequence."""
```

**Launch Pattern Steps**:
1. Press Windows key
2. Wait `menu_open_delay` (default: 1.0s)
3. Type app name with `typing_interval` (default: 0.1s)
4. Press Enter
5. Wait `search_delay` (default: 1.0s)
6. Press Enter again
7. Wait `launch_delay` (default: 2.0s)

### LaunchVerifier Class

**Purpose**: Verify that the application launched successfully by checking window titles.

**Public Methods**:
```python
class LaunchVerifier:
    def verify_launch(
        self,
        app_name: str,
        timeout: float = 5.0
    ) -> VerificationResult:
        """Poll for window containing app name within timeout."""
```

**Verification Strategy**:
- Poll every 0.5 seconds for up to `timeout` seconds
- Check if any window title contains the app name (case-insensitive)
- Use RPAEngine's `list_all_open_windows()` method

## Data Models

### LauncherConfig
```python
@dataclass
class LauncherConfig:
    mapping_file: str = "config/app_mappings.json"
    menu_open_delay: float = 1.0
    typing_interval: float = 0.1
    search_delay: float = 1.0
    launch_delay: float = 2.0
    verification_timeout: float = 5.0
    max_instruction_words: int = 10
```

### LaunchResult
```python
@dataclass
class LaunchResult:
    success: bool
    app_name: Optional[str]
    normalized_name: Optional[str]
    execution_time: float
    error: Optional[str]
    fallback_triggered: bool
```

### ExecutionResult
```python
@dataclass
class ExecutionResult:
    success: bool
    steps_completed: int
    error: Optional[str]
```

### VerificationResult
```python
@dataclass
class VerificationResult:
    success: bool
    window_found: Optional[str]
    time_taken: float
```

## Correctness Properties


*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Extraction consistency
*For any* instruction containing a launch pattern ("open X", "launch X", etc.), extracting the app name should return a non-empty string that appears in the original instruction.
**Validates: Requirements 1.1**

### Property 2: Normalization idempotence
*For any* app name, normalizing it twice should produce the same result as normalizing it once (normalization is idempotent).
**Validates: Requirements 1.2**

### Property 3: Unmapped passthrough
*For any* app name not in the mapping dictionary, normalization should return the original name unchanged.
**Validates: Requirements 2.5**

### Property 4: Failure triggers fallback
*For any* launch attempt that fails (verification timeout, execution error, etc.), the fallback mechanism should be triggered.
**Validates: Requirements 3.5**

### Property 5: Successful local launch bypasses ADK
*For any* instruction that the Local App Launcher successfully handles, the ADK agent should not be invoked.
**Validates: Requirements 4.2**

### Property 6: Unhandled requests route to ADK
*For any* instruction that the Local App Launcher cannot handle (multi-step, complex, ambiguous), the request should be routed to the ADK agent.
**Validates: Requirements 4.3**

### Property 7: History records launch method
*For any* completed execution (success or failure), the history entry should include a field indicating whether local launching was attempted.
**Validates: Requirements 4.5**

### Property 8: Multi-sentence detection
*For any* instruction containing multiple sentences (detected by multiple periods, question marks, or "and then" phrases), the Local App Launcher should decline to handle it.
**Validates: Requirements 5.1**

### Property 9: Complex action detection
*For any* instruction containing additional actions beyond launching (e.g., "and navigate", "then type", "after opening"), the Local App Launcher should decline to handle it.
**Validates: Requirements 5.2**

### Property 10: Ambiguity detection
*For any* instruction that extracts multiple potential app names or no clear app name, the Local App Launcher should decline to handle it.
**Validates: Requirements 5.3**

### Property 11: Decline triggers routing
*For any* declined request, the ADK agent should be invoked and the decline reason should be logged.
**Validates: Requirements 5.4**

### Property 12: Processing logs extraction
*For any* processed request, the logs should contain both the extracted app name and the normalized app name.
**Validates: Requirements 6.1**

### Property 13: Execution logs all steps
*For any* launch pattern execution, the logs should contain entries for each step (Win key press, typing, Enter presses) with timestamps.
**Validates: Requirements 6.2**

### Property 14: Outcome includes timing
*For any* completed launch attempt (success or failure), the recorded outcome should include execution time in seconds.
**Validates: Requirements 6.3**

### Property 15: Fallback logs reason
*For any* fallback trigger, the logs should contain a specific reason (verification failed, execution error, declined, etc.).
**Validates: Requirements 6.4**

### Property 16: History includes method field
*For any* execution history entry, the entry should have a boolean or enum field indicating the launch method used.
**Validates: Requirements 6.5**

### Property 17: Invalid config uses defaults
*For any* invalid or missing timing configuration value, the system should use the documented default value (1.0s menu open, 0.1s typing interval, etc.).
**Validates: Requirements 7.4**

## Error Handling

### Error Categories

1. **Extraction Errors**: Instruction doesn't match launch patterns
   - Action: Decline and route to ADK
   - Log: "No app name extracted from instruction"

2. **Execution Errors**: PyAutoGUI operations fail
   - Action: Trigger fallback to ADK
   - Log: "Launch pattern execution failed: {error}"

3. **Verification Errors**: App doesn't launch within timeout
   - Action: Trigger fallback to ADK
   - Log: "Launch verification failed after {timeout}s"

4. **Configuration Errors**: Missing or invalid config files
   - Action: Use defaults and continue
   - Log: "Config error: {error}, using defaults"

5. **Complexity Errors**: Instruction too complex for local handling
   - Action: Decline and route to ADK
   - Log: "Instruction too complex: {reason}"

### Fallback Strategy

All errors result in graceful fallback to the ADK agent, ensuring no user request fails completely. The system logs the reason for fallback to enable monitoring and optimization of detection patterns.

### Retry Logic

The Local App Launcher does NOT implement retry logic. If any step fails, it immediately falls back to ADK. This is intentional to minimize latency - retrying would negate the speed advantage of local launching.

## Testing Strategy

### Unit Tests

1. **AppNameExtractor Tests**:
   - Test extraction with various patterns ("open X", "launch X", "start X")
   - Test multi-sentence detection
   - Test complex action detection
   - Test ambiguity detection

2. **AppNameMapper Tests**:
   - Test all default mappings (chrome, excel, word, notepad, etc.)
   - Test unmapped names pass through unchanged
   - Test case-insensitive matching
   - Test config file loading and reloading

3. **LaunchExecutor Tests** (mocked PyAutoGUI):
   - Test launch pattern sequence
   - Test timing parameters are respected
   - Test error handling for PyAutoGUI failures

4. **LaunchVerifier Tests** (mocked window list):
   - Test successful verification
   - Test timeout behavior
   - Test case-insensitive window matching

5. **LocalAppLauncher Integration Tests**:
   - Test end-to-end flow for simple launch
   - Test fallback on verification failure
   - Test decline for complex instructions
   - Test logging at each stage

### Property-Based Tests

We will use **Hypothesis** for property-based testing in Python.

**Configuration**: Each property test should run a minimum of 100 iterations.

1. **Property 1: Extraction consistency**
   - **Feature: local-app-launcher, Property 1: Extraction consistency**
   - Generate random instructions with launch patterns
   - Verify extracted name appears in original instruction

2. **Property 2: Normalization idempotence**
   - **Feature: local-app-launcher, Property 2: Normalization idempotence**
   - Generate random app names
   - Verify normalize(normalize(x)) == normalize(x)

3. **Property 3: Unmapped passthrough**
   - **Feature: local-app-launcher, Property 3: Unmapped passthrough**
   - Generate random app names not in mapping
   - Verify normalization returns original

4. **Property 4: Failure triggers fallback**
   - **Feature: local-app-launcher, Property 4: Failure triggers fallback**
   - Generate random failure scenarios
   - Verify fallback is always triggered

5. **Property 5: Successful local launch bypasses ADK**
   - **Feature: local-app-launcher, Property 5: Successful local launch bypasses ADK**
   - Generate random successful launches
   - Verify ADK is never called

6. **Property 6: Unhandled requests route to ADK**
   - **Feature: local-app-launcher, Property 6: Unhandled requests route to ADK**
   - Generate random complex instructions
   - Verify ADK is always called

7. **Property 7: History records launch method**
   - **Feature: local-app-launcher, Property 7: History records launch method**
   - Generate random executions
   - Verify history always has method field

8. **Property 8: Multi-sentence detection**
   - **Feature: local-app-launcher, Property 8: Multi-sentence detection**
   - Generate random multi-sentence instructions
   - Verify all are declined

9. **Property 9: Complex action detection**
   - **Feature: local-app-launcher, Property 9: Complex action detection**
   - Generate random instructions with "and", "then", etc.
   - Verify all are declined

10. **Property 10: Ambiguity detection**
    - **Feature: local-app-launcher, Property 10: Ambiguity detection**
    - Generate random ambiguous instructions
    - Verify all are declined

11. **Property 11: Decline triggers routing**
    - **Feature: local-app-launcher, Property 11: Decline triggers routing**
    - Generate random declined requests
    - Verify ADK is called and reason is logged

12. **Property 12: Processing logs extraction**
    - **Feature: local-app-launcher, Property 12: Processing logs extraction**
    - Generate random processed requests
    - Verify logs contain both names

13. **Property 13: Execution logs all steps**
    - **Feature: local-app-launcher, Property 13: Execution logs all steps**
    - Generate random executions
    - Verify all steps are logged

14. **Property 14: Outcome includes timing**
    - **Feature: local-app-launcher, Property 14: Outcome includes timing**
    - Generate random outcomes
    - Verify timing is always present

15. **Property 15: Fallback logs reason**
    - **Feature: local-app-launcher, Property 15: Fallback logs reason**
    - Generate random fallback scenarios
    - Verify reason is always logged

16. **Property 16: History includes method field**
    - **Feature: local-app-launcher, Property 16: History includes method field**
    - Generate random history entries
    - Verify method field is always present

17. **Property 17: Invalid config uses defaults**
    - **Feature: local-app-launcher, Property 17: Invalid config uses defaults**
    - Generate random invalid configs
    - Verify defaults are always used

### Integration Tests

1. **End-to-End Simple Launch**: Submit "open notepad" and verify it launches without ADK
2. **End-to-End Complex Fallback**: Submit "open chrome and go to google.com" and verify ADK is called
3. **Configuration Reload**: Update mapping file and verify changes take effect
4. **Verification Timeout**: Mock slow app launch and verify fallback occurs

## Implementation Notes

### Performance Considerations

- **Latency Target**: Local launch should complete in < 5 seconds (vs 10-30s for ADK)
- **Pattern Matching**: Use compiled regex for efficiency
- **Config Caching**: Keep mappings in memory, reload only on explicit request
- **Logging**: Use async logging to avoid blocking execution

### Platform Compatibility

- **Primary**: Windows 10/11 with Start Menu search
- **Future**: Could adapt for macOS Spotlight, Linux application launchers
- **Limitations**: Requires keyboard-accessible application launcher

### Security Considerations

- **Input Validation**: Sanitize app names to prevent command injection
- **Path Restrictions**: Only allow app names, not full paths or commands
- **Logging**: Don't log sensitive information from instructions

### Configuration Management

- **Default Config Location**: `config/app_mappings.json`
- **Environment Variables**: 
  - `LOCAL_LAUNCHER_ENABLED`: Enable/disable feature (default: true)
  - `LOCAL_LAUNCHER_MENU_DELAY`: Menu open delay in seconds
  - `LOCAL_LAUNCHER_TYPING_INTERVAL`: Typing interval in seconds
  - `LOCAL_LAUNCHER_VERIFICATION_TIMEOUT`: Verification timeout in seconds

### Monitoring and Metrics

Track the following metrics for optimization:
- **Local Launch Success Rate**: % of attempts that succeed without fallback
- **Average Execution Time**: Time from request to verification
- **Fallback Reasons**: Distribution of why fallback was triggered
- **Most Launched Apps**: Which apps are launched most frequently

These metrics will inform future optimizations like expanding the mapping dictionary or adjusting timing parameters.
