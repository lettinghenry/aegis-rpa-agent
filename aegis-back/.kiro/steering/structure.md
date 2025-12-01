# Project Structure

## Directory Organization

```
aegis-back/
├── src/
│   ├── main.py                 # FastAPI application entry point
│   ├── models.py               # Pydantic data models (request/response)
│   ├── preprocessing.py        # Pre-processing validation layer
│   ├── plan_cache.py           # Execution plan caching
│   ├── adk_agent.py            # ADK agent manager (Gemini integration)
│   ├── rpa_tools.py            # Custom RPA toolbox (click, type, launch, etc.)
│   ├── rpa_engine.py           # RPA execution engine (PyAutoGUI/Win32API)
│   ├── action_observer.py      # Action verification and monitoring
│   ├── session_manager.py      # Session lifecycle management
│   ├── history_store.py        # Execution history persistence
│   ├── websocket_manager.py    # WebSocket connection handling
│   └── strategy_module.py      # Strategy selection logic
├── tests/
│   ├── unit/                   # Unit tests for individual modules
│   ├── integration/            # Integration tests for complete flows
│   └── property/               # Property-based tests (Hypothesis)
├── data/
│   ├── history/                # Execution history storage (JSON files)
│   └── cache/                  # Plan cache storage (JSON files)
├── .kiro/
│   ├── specs/                  # Feature specifications
│   └── steering/               # AI assistant guidance (this file)
├── .env                        # Environment configuration (not in git)
├── requirements.txt            # Python dependencies
└── README.md                   # Project documentation
```

## Architecture Layers

### API Layer (main.py)
- **REST Endpoints**: `/api/start_task`, `/api/history`, `/api/history/{session_id}`, `/api/execution/{session_id}`
- **WebSocket Endpoint**: `/ws/execution/{session_id}`
- **Request Validation**: Pydantic models
- **Error Handling**: HTTP exception handlers

### Pre-Processing Layer (preprocessing.py)
- **Input Validation**: Check instruction format and content
- **Early Rejection**: Filter invalid requests before LLM calls
- **Cost Optimization**: Minimize unnecessary API usage

### Caching Layer (plan_cache.py)
- **Plan Storage**: Cache execution plans by instruction hash
- **Cache Lookup**: Retrieve cached plans for repeated instructions
- **Cache Management**: LRU eviction, size limits

### Agent Layer (adk_agent.py)
- **ADK Integration**: Google Agent Development Kit with Gemini
- **Tool Registration**: Custom RPA toolbox
- **Plan Generation**: Convert natural language to action sequences
- **Error Handling**: Retry logic with exponential backoff

### RPA Layer (rpa_tools.py, rpa_engine.py)
- **RPA Tools**: High-level actions (click_element, type_text, launch_app, focus_window)
- **RPA Engine**: Low-level execution (PyAutoGUI, Win32API wrappers)
- **Strategy Selection**: Coordinate-based vs element-based interaction
- **Action Observer**: Verify action success

### Session Management (session_manager.py)
- **Lifecycle**: Create, track, cancel, complete sessions
- **State Tracking**: Session status, subtasks, errors
- **Concurrency Control**: Manage concurrent execution limits

### Storage Layer (history_store.py)
- **Persistence**: Save execution sessions to JSON files
- **Retrieval**: Load session history and details
- **Cleanup**: Manage storage size and retention

### WebSocket Layer (websocket_manager.py)
- **Connection Management**: Handle client connections
- **Broadcasting**: Send status updates to connected clients
- **Reconnection**: Handle connection drops gracefully

## Key Conventions

### Models (models.py)
- Use Pydantic `BaseModel` for all data structures
- Include validation rules and constraints
- Match frontend Dart models for type safety
- Use enums for status fields

### Async/Await
- All I/O operations are async (database, file system, network)
- Use `async def` for route handlers
- Use `await` for async operations
- Avoid blocking operations in async context

### Error Handling
- Raise `HTTPException` for API errors
- Use custom exception classes for domain errors
- Log errors with appropriate severity
- Return user-friendly error messages

### Testing
- Unit tests for all modules with mocked dependencies
- Property-based tests for critical invariants
- Integration tests for complete execution flows
- Target: 80% code coverage

### Logging
- Use Python `logging` module
- Log levels: DEBUG (development), INFO (production), WARNING, ERROR
- Include context in log messages (session_id, instruction, etc.)
- Avoid logging sensitive information

### Configuration
- All configuration via environment variables
- Use `.env` file for local development
- Validate required configuration on startup
- Provide sensible defaults

### Code Style
- Follow PEP 8 style guidelines
- Use type hints for all function signatures
- Use docstrings for public functions and classes
- Format with `black`, lint with `flake8`, type-check with `mypy`
