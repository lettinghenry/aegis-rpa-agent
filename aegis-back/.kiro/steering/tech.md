# Technology Stack

## Language & Framework

- **Language**: Python 3.10+
- **Framework**: FastAPI (async API)
- **Server**: Uvicorn (ASGI server)

## Core Dependencies

- **AI/LLM**: Google Agent Development Kit (ADK) with Gemini
- **RPA Tools**: PyAutoGUI (cross-platform), PyWin32 (Windows-specific)
- **Data Validation**: Pydantic (models and validation)
- **Testing**: pytest, Hypothesis (property-based testing)

## API Architecture

- **REST Endpoints**: Task submission, history retrieval, execution cancellation
- **WebSocket**: Real-time execution status streaming
- **Async/Await**: Non-blocking I/O for concurrent operations

## Common Commands

### Development

```bash
# Activate virtual environment (Windows)
venv\Scripts\activate

# Activate virtual environment (Unix/MacOS)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run development server with hot reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Run production server
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

### Testing

```bash
# Run all tests
pytest

# Run unit tests only
pytest tests/unit/

# Run property-based tests
pytest tests/property/ -v

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest tests/unit/test_preprocessing.py -v
```

### Code Quality

```bash
# Format code
black src/ tests/

# Lint code
flake8 src/ tests/

# Type checking
mypy src/

# Sort imports
isort src/ tests/
```

### Setup

```bash
# Create virtual environment
python -m venv venv

# Create data directories
mkdir -p data/history data/cache

# Set up environment variables
# Create .env file with required configuration
```

## Configuration

Environment variables in `.env`:

### ADK Configuration
- `GOOGLE_ADK_API_KEY`: Google Cloud API key for ADK
- `GEMINI_MODEL`: Gemini model version (default: gemini-1.5-pro)
- `ADK_TIMEOUT`: Timeout for ADK requests in seconds (default: 30)

### Server Configuration
- `HOST`: Server host (default: 0.0.0.0)
- `PORT`: Server port (default: 8000)
- `LOG_LEVEL`: Logging level (INFO, DEBUG, WARNING, ERROR)

### Storage Configuration
- `HISTORY_DIR`: Directory for execution history (default: ./data/history)
- `CACHE_DIR`: Directory for plan cache (default: ./data/cache)
- `MAX_CACHE_SIZE`: Maximum cached plans (default: 100)

### Performance Configuration
- `MAX_CONCURRENT_SESSIONS`: Concurrent execution sessions (default: 1)
- `REQUEST_QUEUE_SIZE`: Maximum queued requests (default: 10)
- `WEBSOCKET_PING_INTERVAL`: WebSocket ping interval in seconds (default: 30)

## API Documentation

Once running, access interactive API documentation:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
