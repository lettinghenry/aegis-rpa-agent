# Design Document

## Overview

The AEGIS RPA Backend is a Python FastAPI application that serves as a cognitive automation engine. At its core, it leverages the Google Agent Development Kit (ADK) with Gemini to provide intelligent task interpretation and orchestration. The system receives natural language instructions via REST API, delegates planning to the ADK agent, executes desktop actions through a custom toolbox of RPA functions, and streams real-time progress updates to the frontend via WebSockets.

The architecture prioritizes cost-efficiency through pre-processing validation and plan caching, while maintaining reliability through action observation and retry mechanisms. The system is designed to handle complex multi-application workflows with minimal user intervention.

## Architecture

### High-Level Architecture

```
┌─────────────────┐
│  Flutter UI     │
│  (Frontend)     │
└────────┬────────┘
         │ HTTP/WebSocket
         ▼
┌─────────────────────────────────────────────┐
│         FastAPI Backend                     │
│  ┌──────────────────────────────────────┐  │
│  │  Pre-Processing & Validation Layer   │  │
│  └──────────────┬───────────────────────┘  │
│                 │                           │
│  ┌──────────────▼───────────────────────┐  │
│  │         Plan Cache                   │  │
│  └──────────────┬───────────────────────┘  │
│                 │                           │
│  ┌──────────────▼───────────────────────┐  │
│  │      ADK Agent (Gemini)              │  │
│  │  ┌────────────────────────────────┐  │  │
│  │  │     Custom RPA Toolbox         │  │  │
│  │  │  - click_element()             │  │  │
│  │  │  - type_text()                 │  │  │
│  │  │  - launch_app()                │  │  │
│  │  │  - focus_window()              │  │  │
│  │  │  - capture_screen()            │  │  │
│  │  └────────────────────────────────┘  │  │
│  └──────────────┬───────────────────────┘  │
│                 │                           │
│  ┌──────────────▼───────────────────────┐  │
│  │      RPA Engine                      │  │
│  │  - PyAutoGUI wrapper                 │  │
│  │  - Win32API wrapper                  │  │
│  │  - Action Observer                   │  │
│  └──────────────┬───────────────────────┘  │
│                 │                           │
│  ┌──────────────▼───────────────────────┐  │
│  │    Execution History Store           │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│  Desktop OS     │
│  (Windows)      │
└─────────────────┘
```

### Component Interaction Flow

1. **Request Reception**: FastAPI receives task instruction via POST /api/start_task
2. **Pre-Processing**: Validation layer checks instruction format and basic requirements
3. **Cache Lookup**: System checks Plan Cache for similar recent instructions
4. **ADK Planning**: If no cache hit, ADK agent generates execution plan using Gemini
5. **Tool Execution**: ADK agent calls RPA Toolbox functions sequentially
6. **Action Execution**: RPA Engine translates tool calls to PyAutoGUI/Win32API operations
7. **Observation**: Action Observer verifies each action succeeded
8. **Status Streaming**: WebSocket streams real-time updates to frontend
9. **History Storage**: Completed session stored for future reference

## Components and Interfaces

### 1. FastAPI Application (main.py)

**Responsibilities:**
- Initialize and configure the FastAPI server
- Register API routes and WebSocket endpoints
- Initialize ADK agent with custom toolbox
- Manage application lifecycle

**Key Endpoints:**
- `POST /api/start_task` - Submit new task instruction
- `GET /api/history` - Retrieve execution history
- `GET /api/history/{session_id}` - Get specific session details
- `DELETE /api/execution/{session_id}` - Cancel ongoing execution
- `WS /ws/execution/{session_id}` - Real-time status updates
- `GET /docs` - OpenAPI documentation

### 2. Pre-Processing Layer (preprocessing.py)

**Responsibilities:**
- Validate task instructions before ADK invocation
- Perform basic sanitization and format checking
- Reject malformed or empty instructions
- Log validation failures

**Interface:**
```python
class PreProcessor:
    def validate_instruction(self, instruction: str) -> ValidationResult:
        """Validate instruction format and content"""
        pass
    
    def sanitize_instruction(self, instruction: str) -> str:
        """Clean and normalize instruction text"""
        pass
```

### 3. Plan Cache (plan_cache.py)

**Responsibilities:**
- Store recently generated execution plans
- Compute similarity between instructions
- Retrieve cached plans for reuse
- Implement cache expiration policy

**Interface:**
```python
class PlanCache:
    def get_cached_plan(self, instruction: str) -> Optional[ExecutionPlan]:
        """Retrieve cached plan if similar instruction exists"""
        pass
    
    def store_plan(self, instruction: str, plan: ExecutionPlan) -> None:
        """Store execution plan with instruction key"""
        pass
    
    def compute_similarity(self, inst1: str, inst2: str) -> float:
        """Calculate similarity score between instructions"""
        pass
```

**Caching Strategy:**
- Use embedding-based similarity (cosine similarity > 0.95)
- Cache TTL: 24 hours
- Max cache size: 100 plans
- LRU eviction policy

### 4. ADK Agent Manager (adk_agent.py)

**Responsibilities:**
- Initialize Google ADK agent with Gemini model
- Register custom RPA toolbox
- Manage agent lifecycle and configuration
- Handle agent errors and retries

**Interface:**
```python
class ADKAgentManager:
    def initialize_agent(self) -> Agent:
        """Create and configure ADK agent with Gemini"""
        pass
    
    def register_toolbox(self, tools: List[Tool]) -> None:
        """Register custom RPA tools with agent"""
        pass
    
    async def execute_instruction(
        self, 
        instruction: str,
        session_id: str
    ) -> AsyncIterator[ExecutionUpdate]:
        """Execute instruction and stream updates"""
        pass
```

### 5. RPA Toolbox (rpa_tools.py)

**Responsibilities:**
- Provide ADK-compatible tool definitions
- Wrap PyAutoGUI and Win32API functions
- Implement tool-specific validation
- Return structured results to ADK agent

**Tool Definitions:**

```python
@tool
def click_element(x: int, y: int, button: str = "left") -> ToolResult:
    """Click at specified coordinates
    
    Args:
        x: X coordinate on screen
        y: Y coordinate on screen
        button: Mouse button ("left", "right", "middle")
    
    Returns:
        ToolResult with success status and details
    """
    pass

@tool
def type_text(text: str, interval: float = 0.05) -> ToolResult:
    """Type text into focused element
    
    Args:
        text: Text to type
        interval: Delay between keystrokes in seconds
    
    Returns:
        ToolResult with success status
    """
    pass

@tool
def press_key(key: str, modifiers: List[str] = None) -> ToolResult:
    """Press keyboard key with optional modifiers
    
    Args:
        key: Key to press (e.g., "enter", "a")
        modifiers: List of modifiers (e.g., ["ctrl", "shift"])
    
    Returns:
        ToolResult with success status
    """
    pass

@tool
def launch_application(app_name: str, wait_time: int = 5) -> ToolResult:
    """Launch application by name
    
    Args:
        app_name: Application name or path
        wait_time: Seconds to wait for app to launch
    
    Returns:
        ToolResult with success status and process info
    """
    pass

@tool
def focus_window(window_title: str) -> ToolResult:
    """Bring window to foreground
    
    Args:
        window_title: Partial or full window title
    
    Returns:
        ToolResult with success status
    """
    pass

@tool
def capture_screen(region: Optional[Tuple[int, int, int, int]] = None) -> ToolResult:
    """Capture screenshot for observation
    
    Args:
        region: Optional (x, y, width, height) tuple
    
    Returns:
        ToolResult with base64-encoded image
    """
    pass

@tool
def find_element_by_image(template_path: str, confidence: float = 0.8) -> ToolResult:
    """Locate element using image recognition
    
    Args:
        template_path: Path to template image
        confidence: Match confidence threshold (0-1)
    
    Returns:
        ToolResult with element coordinates if found
    """
    pass

@tool
def scroll(direction: str, amount: int) -> ToolResult:
    """Scroll in specified direction
    
    Args:
        direction: "up", "down", "left", "right"
        amount: Scroll amount in pixels or clicks
    
    Returns:
        ToolResult with success status
    """
    pass
```

### 6. RPA Engine (rpa_engine.py)

**Responsibilities:**
- Execute low-level RPA operations
- Wrap PyAutoGUI and Win32API calls
- Implement retry logic for failed actions
- Coordinate with Action Observer

**Interface:**
```python
class RPAEngine:
    def execute_click(self, x: int, y: int, button: str) -> ActionResult:
        """Execute mouse click"""
        pass
    
    def execute_type(self, text: str, interval: float) -> ActionResult:
        """Execute keyboard typing"""
        pass
    
    def execute_key_press(self, key: str, modifiers: List[str]) -> ActionResult:
        """Execute key press with modifiers"""
        pass
    
    def launch_app(self, app_name: str) -> ActionResult:
        """Launch application"""
        pass
```

### 7. Action Observer (action_observer.py)

**Responsibilities:**
- Capture screen state after actions
- Verify action success through visual comparison
- Detect UI changes and state transitions
- Provide feedback for retry decisions

**Interface:**
```python
class ActionObserver:
    def capture_state(self) -> ScreenState:
        """Capture current screen state"""
        pass
    
    def verify_action(
        self, 
        before: ScreenState, 
        after: ScreenState,
        expected_change: str
    ) -> bool:
        """Verify action produced expected change"""
        pass
    
    def detect_error_dialogs(self) -> Optional[ErrorInfo]:
        """Check for error dialogs or messages"""
        pass
```

### 8. Execution Session Manager (session_manager.py)

**Responsibilities:**
- Create and manage execution sessions
- Track session state and progress
- Coordinate WebSocket updates
- Handle session cancellation

**Interface:**
```python
class SessionManager:
    def create_session(self, instruction: str) -> str:
        """Create new execution session, return session_id"""
        pass
    
    def get_session(self, session_id: str) -> Optional[ExecutionSession]:
        """Retrieve session by ID"""
        pass
    
    def update_session(self, session_id: str, update: SessionUpdate) -> None:
        """Update session with new status/subtask"""
        pass
    
    def cancel_session(self, session_id: str) -> bool:
        """Cancel ongoing session"""
        pass
```

### 9. History Store (history_store.py)

**Responsibilities:**
- Persist execution sessions to disk
- Provide query interface for history
- Implement efficient storage format
- Handle data migration

**Interface:**
```python
class HistoryStore:
    def save_session(self, session: ExecutionSession) -> None:
        """Persist session to storage"""
        pass
    
    def get_all_sessions(self, limit: int = 100) -> List[SessionSummary]:
        """Retrieve session summaries"""
        pass
    
    def get_session_details(self, session_id: str) -> Optional[ExecutionSession]:
        """Retrieve full session details"""
        pass
```

**Storage Format:**
- JSON files in `data/history/` directory
- One file per session: `{session_id}.json`
- Index file for quick lookups: `index.json`

### 10. WebSocket Manager (websocket_manager.py)

**Responsibilities:**
- Manage WebSocket connections
- Broadcast status updates to connected clients
- Handle connection lifecycle
- Implement reconnection logic

**Interface:**
```python
class WebSocketManager:
    async def connect(self, websocket: WebSocket, session_id: str) -> None:
        """Accept and register WebSocket connection"""
        pass
    
    async def broadcast_update(self, session_id: str, update: StatusUpdate) -> None:
        """Send update to all connected clients for session"""
        pass
    
    async def send_window_state(self, session_id: str, state: Literal["minimal", "normal"]) -> None:
        """Send window state command to frontend"""
        pass
    
    async def disconnect(self, session_id: str) -> None:
        """Close WebSocket connection"""
        pass
```

**Window State Management:**

The WebSocket Manager sends window state commands to control the frontend window during RPA execution:

- **WINDOW_STATE_MINIMAL**: Sent before the first desktop action (click, type, etc.) to minimize the frontend window and maximize screen space for automation
- **WINDOW_STATE_NORMAL**: Sent when execution completes (success or failure) or when user cancels to restore the frontend window

This ensures the RPA agent has unobstructed access to the desktop and other applications during execution.

## Data Models

### Pydantic Models

```python
from pydantic import BaseModel, Field
from typing import List, Optional, Literal
from datetime import datetime
from enum import Enum

class TaskInstructionRequest(BaseModel):
    instruction: str = Field(..., min_length=1, max_length=1000)

class TaskInstructionResponse(BaseModel):
    session_id: str
    status: Literal["pending", "in_progress"]
    message: str

class SubtaskStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"

class Subtask(BaseModel):
    id: str
    description: str
    status: SubtaskStatus
    tool_name: Optional[str] = None
    tool_args: Optional[dict] = None
    result: Optional[dict] = None
    error: Optional[str] = None
    timestamp: datetime

class ExecutionSession(BaseModel):
    session_id: str
    instruction: str
    status: Literal["pending", "in_progress", "completed", "failed", "cancelled"]
    subtasks: List[Subtask] = []
    created_at: datetime
    updated_at: datetime
    completed_at: Optional[datetime] = None

class StatusUpdate(BaseModel):
    session_id: str
    subtask: Optional[Subtask] = None
    overall_status: str
    message: str
    window_state: Optional[Literal["minimal", "normal"]] = None
    timestamp: datetime

class SessionSummary(BaseModel):
    session_id: str
    instruction: str
    status: str
    created_at: datetime
    completed_at: Optional[datetime] = None
    subtask_count: int

class HistoryResponse(BaseModel):
    sessions: List[SessionSummary]
    total: int

class ErrorResponse(BaseModel):
    error: str
    details: Optional[str] = None
    session_id: Optional[str] = None

class ValidationResult(BaseModel):
    is_valid: bool
    error_message: Optional[str] = None

class ExecutionPlan(BaseModel):
    instruction: str
    subtasks: List[dict]
    estimated_duration: Optional[int] = None
    created_at: datetime

class ToolResult(BaseModel):
    success: bool
    data: Optional[dict] = None
    error: Optional[str] = None

class ActionResult(BaseModel):
    success: bool
    retry_count: int
    error: Optional[str] = None
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: ADK Agent Delegation

*For any* task instruction received by the backend, the ADK agent's planning method must be called to interpret and generate the execution plan.

**Validates: Requirements 1.3**

### Property 2: Execution Plan Structure

*For any* instruction processed by the ADK agent, the resulting execution plan must contain a list of tool calls where each tool call has a tool name and arguments dictionary.

**Validates: Requirements 1.4**

### Property 3: WebSocket Streaming

*For any* tool execution by the ADK agent, a corresponding status update message must be sent to the WebSocket connection for that session.

**Validates: Requirements 1.5**

### Property 4: Pre-Processing Before ADK

*For any* task instruction received, the pre-processing validation function must be called before the ADK agent is invoked.

**Validates: Requirements 2.1**

### Property 5: Invalid Input Rejection

*For any* instruction that fails pre-processing validation (empty, malformed, etc.), the ADK agent must not be invoked and an error response must be returned.

**Validates: Requirements 2.2**

### Property 6: Cache Lookup Always Performed

*For any* task instruction received, the plan cache lookup function must be called before potentially invoking the ADK agent.

**Validates: Requirements 2.3**

### Property 7: Cache Hit Reuse

*For any* instruction that matches a cached plan (similarity > 0.95), the cached plan must be reused and the ADK agent must not be called for planning.

**Validates: Requirements 2.4**

### Property 8: Unique Session IDs

*For any* two valid task instructions submitted to POST /api/start_task, the returned session IDs must be unique.

**Validates: Requirements 3.1**

### Property 9: Structured Subtask Parsing

*For any* valid task instruction, the ADK agent must produce a structured list of subtasks where each subtask has a description and tool information.

**Validates: Requirements 3.2**

### Property 10: Multi-Goal Identification

*For any* instruction containing multiple distinct goals (identified by conjunctions like "and", "then"), all goals must be represented in the resulting subtask sequence.

**Validates: Requirements 3.3**

### Property 11: Ambiguous Instruction Error Handling

*For any* instruction that cannot be parsed or is ambiguous, the backend must return an error response with an explanation rather than proceeding with execution.

**Validates: Requirements 3.4**

### Property 12: Pending Status After Parsing

*For any* successfully parsed instruction, the execution session record must exist with status "pending" immediately after parsing completes.

**Validates: Requirements 3.5**

### Property 13: Coordinate Strategy for Fixed Elements

*For any* subtask targeting a desktop icon or fixed UI element, the strategy module must select the coordinate-based strategy.

**Validates: Requirements 4.1**

### Property 14: Element Strategy for Dynamic Content

*For any* subtask targeting a web page or dynamic application, the strategy module must select the element-based strategy.

**Validates: Requirements 4.2**

### Property 15: Click Action Execution

*For any* click action with target coordinates (x, y), the RPA engine must move the mouse to those exact coordinates before performing the click.

**Validates: Requirements 5.1**

### Property 16: Typing Action Execution

*For any* typing action with text input, the RPA engine must send keystrokes for each character in the text to the active window.

**Validates: Requirements 5.2**

### Property 17: Key Press Execution

*For any* key press action with a key combination, the RPA engine must send the correct modifier keys followed by the main key.

**Validates: Requirements 5.3**

### Property 18: Screen Capture After Action

*For any* completed RPA action, the action observer must capture the screen state immediately after the action.

**Validates: Requirements 6.1**

### Property 19: Action Verification

*For any* completed action, the action observer's verification function must be called with the before and after screen states.

**Validates: Requirements 6.2**

### Property 20: Retry on Failure

*For any* action that fails verification, the system must retry the action up to 3 times with exponential backoff (1s, 2s, 4s) before marking it as failed.

**Validates: Requirements 6.3**

### Property 21: Session Failure After Max Retries

*For any* action that fails verification after all 3 retries, the execution session status must be set to "failed" and an error must be reported.

**Validates: Requirements 6.4**

### Property 22: Sequential Subtask Progression

*For any* action that succeeds verification, the system must proceed to execute the next subtask in the sequence.

**Validates: Requirements 6.5**

### Property 23: Subtask Start Status Update

*For any* subtask that begins execution, a WebSocket status update must be sent with the subtask description and status "in_progress".

**Validates: Requirements 7.2**

### Property 24: Subtask Completion Status Update

*For any* subtask that completes successfully, a WebSocket status update must be sent with the subtask description and status "completed".

**Validates: Requirements 7.3**

### Property 25: Subtask Failure Status Update

*For any* subtask that fails, a WebSocket status update must be sent with the error message and status "failed".

**Validates: Requirements 7.4**

### Property 26: Final Status Update on Completion

*For any* execution session that completes (successfully or with failure), a final WebSocket status update must be sent with the overall session status before closing the connection.

**Validates: Requirements 7.5**

### Property 27: Structured Error Responses

*For any* system-level error (permission denied, file not found, etc.), the backend must return a structured error response containing error type and details.

**Validates: Requirements 8.1**

### Property 28: Launch Failure Detection Timing

*For any* application launch attempt that fails, the failure must be detected and reported within 10 seconds.

**Validates: Requirements 8.2**

### Property 29: Element Not Found Context

*For any* UI element search that fails to find the target, the error message must include context about what element was being searched for.

**Validates: Requirements 8.3**

### Property 30: Sequential Request Processing

*For any* set of concurrent task requests submitted when the system is under load, the requests must be queued and processed sequentially (one at a time).

**Validates: Requirements 8.4**

### Property 31: Cancellation Cleanup

*For any* execution session that is cancelled, the session status must be set to "cancelled" and all associated resources must be cleaned up.

**Validates: Requirements 8.5**

### Property 32: Malformed Request Validation

*For any* API request with malformed data (missing required fields, wrong types), the backend must return a 422 status code with validation error details.

**Validates: Requirements 9.2**

### Property 33: Required Field Validation

*For any* API request, all required fields must be validated for presence and correct type before processing.

**Validates: Requirements 9.3**

### Property 34: Appropriate Status Codes

*For any* API response, the HTTP status code must be appropriate for the outcome (200 for success, 400 for client error, 422 for validation error, 500 for server error).

**Validates: Requirements 9.4**

### Property 35: Session Record Creation

*For any* execution session that starts, a session record must be created containing timestamp, instruction, and initial status "pending".

**Validates: Requirements 10.1**

### Property 36: Subtask Result Appending

*For any* subtask that completes execution, the subtask result must be appended to the session record.

**Validates: Requirements 10.2**

### Property 37: History Ordering

*For any* GET /api/history request, the returned sessions must be ordered by timestamp in descending order (newest first).

**Validates: Requirements 10.3**

### Property 38: Session Detail Retrieval

*For any* valid session ID in GET /api/history/{session_id}, the complete session details including all subtasks must be returned.

**Validates: Requirements 10.4**

### Property 39: Session Persistence

*For any* session record stored to disk, the session must be retrievable after a server restart.

**Validates: Requirements 10.5**

### Property 40: Multi-Application Identification

*For any* instruction that mentions multiple applications by name, all mentioned applications must be identified in the execution plan.

**Validates: Requirements 11.1**

### Property 41: Application Focus Before Action

*For any* action targeting a specific application, that application must be brought to focus before the action is executed.

**Validates: Requirements 11.2**

### Property 42: Application Launch When Not Running

*For any* action targeting an application that is not currently running, the application must be launched and verified as ready before the action is executed.

**Validates: Requirements 11.3**

### Property 43: Focus Before Typing

*For any* typing action, the target input field must receive focus before keystrokes are sent.

**Validates: Requirements 12.1**

### Property 44: Special Character Encoding

*For any* typing action containing special characters (e.g., @, #, $), the characters must be properly encoded using the correct key combinations for the system keyboard layout.

**Validates: Requirements 12.2**

### Property 45: Human-Like Typing Speed

*For any* typing action into a web form, the inter-keystroke interval must be between 30ms and 150ms to simulate human typing.

**Validates: Requirements 12.3**

### Property 46: Text Clearing Before Replacement

*For any* typing action that replaces existing text, the system must first select all existing text (Ctrl+A) before typing new content.

**Validates: Requirements 12.4**

### Property 47: Typing Verification

*For any* completed typing action, the system must verify that the typed text appears in the target field.

**Validates: Requirements 12.5**

## Error Handling

### Error Categories

1. **Validation Errors** (HTTP 422)
   - Empty or malformed instructions
   - Missing required fields
   - Invalid data types
   - Handled by Pydantic validation

2. **Client Errors** (HTTP 400)
   - Invalid session ID
   - Session already completed/cancelled
   - Invalid operation for current state

3. **System Errors** (HTTP 500)
   - ADK agent initialization failure
   - RPA tool execution failure
   - File system errors
   - Database errors

4. **RPA Execution Errors**
   - Application launch failure
   - UI element not found
   - Permission denied
   - Timeout errors

### Error Response Format

All errors follow a consistent structure:

```python
{
    "error": "Error category",
    "details": "Detailed error message",
    "session_id": "optional-session-id",
    "timestamp": "2024-12-01T10:30:00Z"
}
```

### Retry Strategy

- **Action Failures**: 3 retries with exponential backoff (1s, 2s, 4s)
- **Network Errors**: No automatic retry (client responsibility)
- **ADK Agent Errors**: 1 retry after 2s delay
- **WebSocket Disconnections**: Client-side reconnection logic

### Logging

All errors are logged with:
- Timestamp
- Session ID (if applicable)
- Error category and details
- Stack trace (for system errors)
- Context (current subtask, action being performed)

## Testing Strategy

### Unit Testing

The backend will use **pytest** as the testing framework with the following structure:

**Test Organization:**
```
tests/
├── unit/
│   ├── test_preprocessing.py
│   ├── test_plan_cache.py
│   ├── test_adk_agent.py
│   ├── test_rpa_tools.py
│   ├── test_rpa_engine.py
│   ├── test_action_observer.py
│   ├── test_session_manager.py
│   ├── test_history_store.py
│   └── test_websocket_manager.py
├── integration/
│   ├── test_api_endpoints.py
│   ├── test_execution_flow.py
│   └── test_websocket_streaming.py
└── property/
    └── test_correctness_properties.py
```

**Unit Test Coverage:**
- Pre-processing validation logic
- Plan cache similarity computation
- RPA tool function wrappers
- Action observer verification logic
- Session state management
- History storage and retrieval
- WebSocket connection handling

**Integration Test Coverage:**
- End-to-end API request/response flow
- WebSocket connection and message streaming
- ADK agent integration with toolbox
- Multi-step execution workflows

### Property-Based Testing

The backend will use **Hypothesis** for property-based testing to verify the correctness properties defined in this document.

**Configuration:**
- Minimum 100 iterations per property test
- Custom generators for instructions, coordinates, and UI elements
- Stateful testing for session lifecycle

**Property Test Implementation:**
Each correctness property will be implemented as a single property-based test with explicit tagging:

```python
from hypothesis import given, strategies as st
import pytest

@given(instruction=st.text(min_size=1, max_size=1000))
def test_property_8_unique_session_ids(instruction):
    """
    Feature: rpa-backend, Property 8: Unique Session IDs
    For any two valid task instructions, session IDs must be unique
    """
    session_id_1 = api_client.post("/api/start_task", json={"instruction": instruction}).json()["session_id"]
    session_id_2 = api_client.post("/api/start_task", json={"instruction": instruction}).json()["session_id"]
    assert session_id_1 != session_id_2
```

**Custom Generators:**
```python
# Generator for valid task instructions
instructions = st.text(min_size=1, max_size=500).filter(lambda s: s.strip())

# Generator for screen coordinates
coordinates = st.tuples(
    st.integers(min_value=0, max_value=1920),
    st.integers(min_value=0, max_value=1080)
)

# Generator for application names
app_names = st.sampled_from(["notepad", "chrome", "outlook", "excel", "word"])

# Generator for multi-goal instructions
multi_goal_instructions = st.builds(
    lambda goals: " and ".join(goals),
    st.lists(instructions, min_size=2, max_size=4)
)
```

**Mocking Strategy:**
- Mock ADK agent calls for cost efficiency during testing
- Mock PyAutoGUI/Win32API for deterministic testing
- Use real implementations for integration tests
- Record/replay mode for ADK agent responses

### Test Execution

```bash
# Run all tests
pytest

# Run unit tests only
pytest tests/unit/

# Run property tests with verbose output
pytest tests/property/ -v

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific property test
pytest tests/property/test_correctness_properties.py::test_property_8_unique_session_ids
```

### Continuous Integration

- All tests run on every commit
- Property tests run with 100 iterations in CI
- Coverage threshold: 80% minimum
- Integration tests run against mock ADK agent
- Performance benchmarks for critical paths

## Deployment Considerations

### Environment Variables

```bash
# ADK Configuration
GOOGLE_ADK_API_KEY=your-api-key
GEMINI_MODEL=gemini-1.5-pro
ADK_TIMEOUT=30

# Server Configuration
HOST=0.0.0.0
PORT=8000
LOG_LEVEL=INFO

# Storage Configuration
HISTORY_DIR=./data/history
CACHE_DIR=./data/cache
MAX_CACHE_SIZE=100

# Performance Configuration
MAX_CONCURRENT_SESSIONS=1
REQUEST_QUEUE_SIZE=10
WEBSOCKET_PING_INTERVAL=30
```

### Dependencies

```txt
fastapi==0.104.1
uvicorn==0.24.0
pydantic==2.5.0
websockets==12.0
google-adk==0.1.0  # Google Agent Development Kit
pyautogui==0.9.54
pywin32==306
pillow==10.1.0
pytesseract==0.3.10  # For OCR
hypothesis==6.92.0  # For property-based testing
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-cov==4.1.0
```

### Performance Targets

- API response time: < 100ms (excluding ADK calls)
- ADK agent response time: < 5s for simple instructions
- WebSocket message latency: < 50ms
- Action execution time: < 2s per action
- Session history retrieval: < 200ms

### Security Considerations

- API key management for ADK
- Input sanitization for RPA commands
- Rate limiting on API endpoints
- WebSocket authentication
- Secure storage of execution history
- Audit logging for all actions

## Future Enhancements

1. **Multi-Session Support**: Allow concurrent execution of multiple sessions
2. **Advanced Caching**: Semantic caching using embeddings
3. **Visual Debugging**: Screenshot capture at each step
4. **Workflow Templates**: Pre-defined workflows for common tasks
5. **Performance Monitoring**: Metrics and tracing for optimization
6. **Browser Automation**: Selenium/Playwright integration for web tasks
7. **Mobile Support**: Extend to mobile device automation
8. **Voice Commands**: Voice-to-text instruction input
