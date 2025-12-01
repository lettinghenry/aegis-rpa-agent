# AEGIS RPA Agent

A cognitive, intent-driven RPA (Robotic Process Automation) system that processes natural language instructions and executes desktop automation tasks through intelligent orchestration.

## Overview

AEGIS consists of two main components:

- **aegis-back**: FastAPI-based backend powered by Google Agent Development Kit (ADK) with Gemini for intelligent task interpretation and RPA execution
- **aegis-front**: Flutter desktop application providing an intuitive interface for commanding and monitoring automation tasks

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AEGIS Frontend (Flutter)                  │
│  ┌────────────┐  ┌────────────┐  ┌──────────────────────┐  │
│  │ Onboarding │→ │  Landing   │→ │  Task Execution      │  │
│  │  Screen    │  │  Screen    │  │  Screen (Real-time)  │  │
│  └────────────┘  └────────────┘  └──────────────────────┘  │
│                         │                    ↑                │
│                         │ HTTP/WebSocket     │                │
└─────────────────────────┼────────────────────┼────────────────┘
                          ↓                    │
┌─────────────────────────────────────────────────────────────┐
│                   AEGIS Backend (FastAPI)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ Pre-Process  │→ │  Plan Cache  │→ │  ADK Agent       │  │
│  │ Validation   │  │              │  │  (Gemini)        │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│                                              ↓                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              RPA Engine (PyAutoGUI/Win32)            │   │
│  │  • Click  • Type  • Launch  • Focus  • Screenshot    │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Key Features

### Backend (aegis-back)
- **Cognitive Task Interpretation**: Leverages Google ADK with Gemini for natural language understanding
- **Cost Optimization**: Pre-processing validation and plan caching minimize LLM API calls
- **Multi-App Orchestration**: Seamlessly automates across desktop applications
- **Real-Time Streaming**: WebSocket-based status updates for live execution monitoring
- **Robust Error Handling**: Automatic retry logic with exponential backoff
- **Execution History**: Persistent storage for review and debugging
- **Intelligent Strategy Selection**: Coordinate-based vs element-based interaction

### Frontend (aegis-front)
- **Simple Task Input**: Natural language command interface
- **Real-Time Progress Monitoring**: WebSocket-powered live updates with subtask cards
- **Execution History**: Review past automation sessions with detailed results
- **Material 3 Design**: Modern UI with dark mode support
- **Window Management**: Minimizes to floating panel during RPA execution for unobstructed desktop access
- **Reactive State Management**: Provider-based state propagation

## Project Structure

```
aegis-rpa-agent/
├── aegis-back/              # Backend (Python/FastAPI)
│   ├── src/
│   │   ├── main.py          # FastAPI application entry
│   │   ├── models.py        # Pydantic data models
│   │   ├── preprocessing.py # Input validation
│   │   ├── plan_cache.py    # Execution plan caching
│   │   ├── adk_agent.py     # ADK/Gemini integration
│   │   ├── rpa_tools.py     # RPA toolbox
│   │   ├── rpa_engine.py    # PyAutoGUI/Win32 execution
│   │   └── ...
│   ├── tests/               # Unit, integration, property tests
│   ├── data/                # History and cache storage
│   └── requirements.txt
│
└── aegis-front/             # Frontend (Flutter)
    ├── lib/
    │   ├── main.dart        # Application entry point
    │   ├── models/          # Data models
    │   ├── services/        # API, WebSocket, Storage
    │   ├── screens/         # UI screens
    │   ├── state/           # State management
    │   ├── widgets/         # Reusable components
    │   └── ...
    ├── test/                # Unit, widget, integration tests
    └── pubspec.yaml
```

## Getting Started

### Prerequisites

**Backend:**
- Python 3.10+
- Google Cloud API key for ADK/Gemini
- Windows OS (for Win32API support)

**Frontend:**
- Flutter 3.x
- Dart 3.x

### Backend Setup

```bash
cd aegis-back

# Create virtual environment
python -m venv venv

# Activate virtual environment (Windows)
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file with configuration
# GOOGLE_ADK_API_KEY=your_api_key_here
# GEMINI_MODEL=gemini-1.5-pro
# HOST=0.0.0.0
# PORT=8000

# Create data directories
mkdir -p data/history data/cache

# Run development server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Setup

```bash
cd aegis-front

# Install dependencies
flutter pub get

# Run on Windows
flutter run -d windows

# Or build release
flutter build windows --release
```

## Development

### Backend

```bash
# Run tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Format code
black src/ tests/

# Lint
flake8 src/ tests/

# Type check
mypy src/
```

### Frontend

```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Run specific test
flutter test test/widget/main_test.dart
```

## API Documentation

Once the backend is running, access interactive API documentation:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Key Endpoints

- `POST /api/start_task` - Submit automation task
- `GET /api/history` - Retrieve execution history
- `GET /api/history/{session_id}` - Get session details
- `DELETE /api/execution/{session_id}` - Cancel execution
- `WS /ws/execution/{session_id}` - Real-time status updates

## Configuration

### Backend (.env)

```env
# ADK Configuration
GOOGLE_ADK_API_KEY=your_api_key_here
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

### Frontend (lib/config/app_config.dart)

```dart
static const String backendUrl = 'http://localhost:8000';
static const String wsUrl = 'ws://localhost:8000';
static const Duration requestTimeout = Duration(seconds: 30);
static const int wsReconnectAttempts = 3;
```

## Testing Strategy

Both projects use a comprehensive testing approach:

- **Unit Tests**: Test individual components in isolation
- **Property-Based Tests**: Verify correctness properties across all inputs (Hypothesis for Python, test package for Dart)
- **Integration Tests**: Test complete workflows end-to-end
- **Widget Tests** (Frontend only): Test UI components

Target coverage: 75-80%

## Specifications

Detailed specifications are available in each project's `.kiro/specs/` directory:

- **Requirements**: EARS-compliant acceptance criteria
- **Design**: Architecture, components, and correctness properties
- **Tasks**: Implementation plan with task breakdown

## Contributing

1. Follow the existing code style and conventions
2. Write tests for new features
3. Update documentation as needed
4. Ensure all tests pass before submitting

## License

[Your License Here]

## Support

For issues, questions, or contributions, please refer to the individual project READMEs:
- [Backend README](aegis-back/README.md)
- [Frontend README](aegis-front/README.md)
