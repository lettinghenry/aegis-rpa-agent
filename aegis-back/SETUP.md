# AEGIS RPA Backend - Setup Guide

## Prerequisites

- Python 3.10 or higher
- Windows OS (for Win32API support)
- Google Cloud API key for ADK/Gemini

## Installation Steps

### 1. Create Virtual Environment

```bash
# Windows
python -m venv venv
venv\Scripts\activate

# Unix/MacOS
python -m venv venv
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure Environment

```bash
# Copy the example environment file
copy .env.example .env

# Edit .env and add your Google API key
# GOOGLE_ADK_API_KEY=your_actual_api_key_here
```

### 4. Verify Installation

```bash
# Run the development server
python main.py

# Or use uvicorn directly
uvicorn main:app --reload
```

The server should start at http://localhost:8000

### 5. Access API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test types
pytest tests/unit/
pytest tests/property/
pytest tests/integration/
```

## Development Commands

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

## Project Structure

```
aegis-back/
├── src/                    # Source code modules
├── tests/                  # Test suites
│   ├── unit/              # Unit tests
│   ├── integration/       # Integration tests
│   └── property/          # Property-based tests
├── data/                   # Data storage
│   ├── history/           # Execution history
│   └── cache/             # Plan cache
├── main.py                # Application entry point
├── requirements.txt       # Python dependencies
└── .env                   # Environment configuration
```

## Troubleshooting

### Virtual Environment Issues

If you have issues activating the virtual environment:

```bash
# Windows PowerShell (if execution policy blocks)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then activate
venv\Scripts\activate
```

### Missing Dependencies

If you encounter import errors:

```bash
pip install --upgrade pip
pip install -r requirements.txt --force-reinstall
```

### Port Already in Use

If port 8000 is already in use:

```bash
# Use a different port
uvicorn main:app --reload --port 8001
```

## Next Steps

1. Configure your Google API key in `.env`
2. Review the design document at `.kiro/specs/rpa-backend/design.md`
3. Start implementing the modules according to the task list
4. Run tests frequently to ensure correctness

## Support

For issues or questions, refer to:
- Design Document: `.kiro/specs/rpa-backend/design.md`
- Requirements: `.kiro/specs/rpa-backend/requirements.md`
- Task List: `.kiro/specs/rpa-backend/tasks.md`
