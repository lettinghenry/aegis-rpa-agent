# AEGIS RPA Backend

A cognitive, intent-driven RPA (Robotic Process Automation) engine that processes natural language instructions and executes desktop automation tasks through intelligent orchestration of RPA tools.

## Overview

AEGIS RPA Backend is a Python FastAPI application that serves as the automation brain for the AEGIS system. It leverages the Google Agent Development Kit (ADK) with Gemini to provide intelligent task interpretation, translating high-level natural language instructions into sequences of low-level desktop actions.

### Key Features

- **🧠 Cognitive Task Interpretation**: Uses Google ADK with Gemini to understand and plan complex automation workflows
- **💰 Cost-Optimized**: Pre-processing validation and plan caching minimize unnecessary LLM calls
- **🎯 Multi-App Orchestration**: Seamlessly automates workflows across multiple desktop applications
- **🔄 Real-Time Streaming**: WebSocket-based status updates for live execution monitoring
- **🛡️ Robust Error Handling**: Automatic retry logic with exponential backoff and comprehensive error reporting
- **📊 Execution History**: Persistent storage of all automation sessions for review and debugging
- **🎨 Strategy Selection**: Intelligent choice between coordinate-based and element-based interaction strategies

## Architecture

```
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
│  │  └────────────────────────────────┘  │  │
│  └──────────────┬───────────────────────┘  │
│                 │                           │
│  ┌──────────────▼───────────────────────┐  │
│  │      RPA Engine                      │  │
│  │  - PyAutoGUI wrapper                 │  │
│  │  - Win32API wrapper                  │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

## Technology Stack

- **Language**: Python 3.10+
- **Framework**: FastAPI (async API)
- **Server**: Uvicorn
- **AI/LLM**: Google Agent Development Kit (ADK) with Gemini
- **RPA Tools**: PyAutoGUI, PyWin32
- **Testing**: pytest, Hypothesis (property-based testing)
- **Data Validation**: Pydantic

## Prerequisites

- Python 3.10 or higher
- Windows OS (for Win32API support)
- Google Cloud account with ADK API access
- pip or poetry for dependency management

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd aegis-rpa-agent/aegis-back
```

### 2. Create Virtual Environment

```bash
python -m venv venv
```

### 3. Activate Virtual Environment

**Windows:**
```bash
venv\Scripts\activate
```

**Unix/MacOS:**
```bash
source venv/bin/activate
```

### 4. Install Dependencies

```bash
pip install -r requirements.txt
```

### 5. Configure Environment Variables

Create a `.env` file in the project root:

```env
# ADK Configuration
GOOGLE_ADK_API_KEY=your-api-key-here
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

### 6. Create Data Directories

```bash
mkdir -p data/history data/cache
```

## Running the Application

### Development Mode

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Production Mode

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

The API will be available at:
- **API**: http://localhost:8000
- **OpenAPI Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## API Endpoints

### REST API

- `POST /api/start_task` - Submit a new task instruction
- `GET /api/history` - Retrieve execution history
- `GET /api/history/{session_id}` - Get specific session details
- `DELETE /api/execution/{session_id}` - Cancel ongoing execution

### WebSocket

- `WS /ws/execution/{session_id}` - Real-time execution status updates

## Testing

### Run All Tests

```bash
pytest
```

### Run Unit Tests Only

```bash
pytest tests/unit/
```

### Run Property-Based Tests

```bash
pytest tests/property/ -v
```

### Run with Coverage

```bash
pytest --cov=src --cov-report=html
```

### Run Specific Test

```bash
pytest tests/unit/test_preprocessing.py -v
```

## Project Structure

```
aegis-back/
├── src/
│   ├── main.py                 # FastAPI application entry point
│   ├── models.py               # Pydantic data models
│   ├── preprocessing.py        # Pre-processing validation layer
│   ├── plan_cache.py           # Execution plan caching
│   ├── adk_agent.py            # ADK agent manager
│   ├── rpa_tools.py            # Custom RPA toolbox
│   ├── rpa_engine.py           # RPA execution engine
│   ├── action_observer.py      # Action verification
│   ├── session_manager.py      # Session lifecycle management
│   ├── history_store.py        # Execution history persistence
│   ├── websocket_manager.py    # WebSocket connection handling
│   └── strategy_module.py      # Strategy selection logic
├── tests/
│   ├── unit/                   # Unit tests
│   ├── integration/            # Integration tests
│   └── property/               # Property-based tests
├── data/
│   ├── history/                # Execution history storage
│   └── cache/                  # Plan cache storage
├── .env                        # Environment configuration
├── requirements.txt            # Python dependencies
└── README.md                   # This file
```

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

Follow the implementation tasks in `.kiro/specs/rpa-backend/tasks.md`

### 3. Run Tests

```bash
pytest
```

### 4. Check Code Quality

```bash
# Format code
black src/ tests/

# Lint code
flake8 src/ tests/

# Type checking
mypy src/
```

### 5. Commit Changes

```bash
git add .
git commit -m "feat: your feature description"
```

### 6. Push and Create PR

```bash
git push origin feature/your-feature-name
```

## Configuration

### ADK Agent Configuration

The ADK agent can be configured through environment variables:

- `GOOGLE_ADK_API_KEY`: Your Google Cloud API key
- `GEMINI_MODEL`: Gemini model version (default: gemini-1.5-pro)
- `ADK_TIMEOUT`: Timeout for ADK requests in seconds

### Performance Tuning

- `MAX_CONCURRENT_SESSIONS`: Number of concurrent execution sessions (default: 1)
- `REQUEST_QUEUE_SIZE`: Maximum queued requests (default: 10)
- `MAX_CACHE_SIZE`: Maximum cached execution plans (default: 100)

## Troubleshooting

### Common Issues

**Issue**: `ModuleNotFoundError: No module named 'google.adk'`
- **Solution**: Ensure google-adk is installed: `pip install google-adk`

**Issue**: `Permission denied` errors during RPA execution
- **Solution**: Run the application with administrator privileges on Windows

**Issue**: WebSocket connection drops frequently
- **Solution**: Adjust `WEBSOCKET_PING_INTERVAL` in .env file

**Issue**: ADK agent timeout errors
- **Solution**: Increase `ADK_TIMEOUT` value or check network connectivity

### Logs

Logs are written to stdout. To save logs to a file:

```bash
uvicorn main:app --log-config logging.conf > app.log 2>&1
```

## Contributing

1. Review the design document: `.kiro/specs/rpa-backend/design.md`
2. Check the requirements: `.kiro/specs/rpa-backend/requirements.md`
3. Follow the task list: `.kiro/specs/rpa-backend/tasks.md`
4. Write tests for new features
5. Ensure all tests pass before submitting PR
6. Follow Python PEP 8 style guidelines

## License

[License](aegis-back/LICENSE)

## Support

For issues and questions:
- Create an issue in the GitHub repository
- Contact the development team
- Check the documentation in `.kiro/specs/`

## Current Status

### Completed Features ✅

**Core Infrastructure:**
- ✅ Project structure and dependencies (Python 3.10+, FastAPI, Uvicorn)
- ✅ Virtual environment setup with all required packages
- ✅ Directory structure (src/, tests/, data/)

**Data Layer:**
- ✅ Pydantic data models with full validation
- ✅ Window state support in StatusUpdate model (minimal/normal)
- ✅ Request/response models for all API endpoints

**Pre-Processing & Caching:**
- ✅ Pre-processing validation layer (empty, malformed, oversized checks)
- ✅ Plan cache with embedding-based similarity matching
- ✅ LRU eviction policy (max 100 plans, 24-hour TTL)
- ✅ Cosine similarity computation (threshold: 0.95)

**RPA Execution:**
- ✅ RPA toolbox with 12 ADK-compatible tools:
  - click_element, type_text, press_key
  - launch_application, focus_window
  - capture_screen, find_element_by_image, scroll
  - copy_to_clipboard, paste_from_clipboard
  - get_active_window, list_open_windows
- ✅ RPA engine with retry logic (exponential backoff: 1s, 2s, 4s)
- ✅ Action observer for verification
- ✅ Strategy selection module (coordinate vs element-based)

**AI Integration:**
- ✅ ADK agent manager with Gemini integration
- ✅ Custom toolbox registration
- ✅ Streaming execution updates

**Session Management:**
- ✅ Session lifecycle management (create, track, cancel)
- ✅ Unique session ID generation
- ✅ State tracking and subtask progress
- ✅ Thread-safe session operations

**Storage & History:**
- ✅ History store with JSON persistence
- ✅ Session retrieval with timestamp ordering
- ✅ Persistent storage across restarts

**Communication:**
- ✅ WebSocket manager with connection handling
- ✅ Window state commands (WINDOW_STATE_MINIMAL, WINDOW_STATE_NORMAL)
- ✅ Real-time status broadcasting
- ✅ Multiple concurrent connections per session

**API Layer:**
- ✅ FastAPI application with all endpoints
- ✅ POST /api/start_task - Task submission
- ✅ GET /api/history - History retrieval
- ✅ GET /api/history/{session_id} - Session details
- ✅ DELETE /api/execution/{session_id} - Cancellation
- ✅ WS /ws/execution/{session_id} - Real-time updates
- ✅ OpenAPI documentation at /docs

**Integration:**
- ✅ Main execution flow with all components wired
- ✅ Request queuing for sequential processing
- ✅ Window state management during execution
- ✅ Automatic window restore on completion/cancellation

**Multi-App Support:**
- ✅ Application identification logic
- ✅ Window focus management
- ✅ Application launch with readiness check
- ✅ Clipboard operations for data transfer
- ✅ Active application context tracking

**Error Handling & Logging:**
- ✅ Custom exception hierarchy (AEGISException, ValidationError, ClientError, SystemError)
- ✅ Structured error responses with to_dict() serialization
- ✅ Session-aware logging with contextvars
- ✅ Resource cleanup manager for automatic cleanup on errors
- ✅ Global exception handlers in FastAPI
- ✅ JSON logging support for production environments

### In Progress 🚧

**Testing:**
- ⏳ Unit tests for data models (Task 2.1)
- ⏳ Property-based tests for pre-processing (Task 3.1)
- ⏳ Property-based tests for plan cache (Task 4.1)
- ⏳ Unit tests for RPA tools (Task 5.1)
- ⏳ Property tests for action observation (Task 7.1)
- ⏳ Property tests for ADK agent (Task 8.1)
- ⏳ Property tests for session management (Task 9.1)
- ⏳ Property tests for history storage (Task 10.1)
- ⏳ Property tests for WebSocket streaming (Task 11.1)
- ⏳ Property tests for API endpoints (Task 12.1)
- ⏳ Integration tests for execution flow (Task 13.1)
- ⏳ Property tests for strategy selection (Task 14.1)
- ⏳ Property tests for multi-app orchestration (Task 15.1)

**Intelligent Text Input:**
- ✅ Intelligent text input handling (Task 16)
  - Focus verification before typing
  - Special character encoding
  - Human-like typing speed (30-150ms)
  - Text clearing with Ctrl+A
  - Typing verification

**Error Handling & Logging:**
- ✅ Advanced error handling and logging (Task 17)
  - Structured error responses with custom exception classes
  - Session context logging with contextvars
  - Resource cleanup with ResourceManager
  - Comprehensive exception handlers in main.py
  - JSON logging support for production

**Remaining Features:**
- ⏳ Configuration and environment setup (Task 18)
  - .env file creation
  - Environment variable loading
  - Configuration validation

### Next Steps 📋

1. **Complete Testing Suite** (Priority: High)
   - Write unit tests for all modules
   - Implement property-based tests with Hypothesis
   - Create integration tests for end-to-end flows
   - Target: 80% code coverage

2. **Implement Remaining Features** (Priority: Medium)
   - Task 18: Configuration management

3. **Final Checkpoint** (Priority: High)
   - Run all tests and ensure they pass
   - Verify coverage meets 80% threshold
   - Performance testing and optimization

### Future Enhancements 🚀

- Browser automation integration (Selenium/Playwright)
- Enhanced OCR capabilities for visual element detection
- Mobile device automation support
- Voice command input
- Machine learning for action prediction
- Advanced error recovery strategies
