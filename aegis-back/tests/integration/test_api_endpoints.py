"""
Integration tests for FastAPI endpoints.

Tests the REST API endpoints and WebSocket functionality.
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch, AsyncMock
from datetime import datetime

from main import app
from src.models import (
    TaskInstructionRequest,
    ExecutionSession,
    SessionSummary,
    SubtaskStatus
)


@pytest.fixture
def client():
    """Create a test client for the FastAPI app."""
    return TestClient(app)


@pytest.fixture
def mock_services():
    """Mock all service dependencies."""
    with patch('main.preprocessor') as mock_preprocessor, \
         patch('main.session_manager') as mock_session_manager, \
         patch('main.history_store') as mock_history_store, \
         patch('main.websocket_manager') as mock_websocket_manager:
        
        # Configure mocks
        mock_preprocessor.validate_and_sanitize.return_value = (
            Mock(is_valid=True),
            "Open notepad"
        )
        
        mock_session_manager.create_session.return_value = "test-session-123"
        mock_session_manager.get_session.return_value = ExecutionSession(
            session_id="test-session-123",
            instruction="Open notepad",
            status="pending",
            subtasks=[],
            created_at=datetime.now(),
            updated_at=datetime.now()
        )
        mock_session_manager.cancel_session.return_value = True
        
        mock_history_store.get_all_sessions.return_value = [
            SessionSummary(
                session_id="test-session-123",
                instruction="Open notepad",
                status="completed",
                created_at=datetime.now(),
                completed_at=datetime.now(),
                subtask_count=2
            )
        ]
        mock_history_store.get_session_details.return_value = ExecutionSession(
            session_id="test-session-123",
            instruction="Open notepad",
            status="completed",
            subtasks=[],
            created_at=datetime.now(),
            updated_at=datetime.now(),
            completed_at=datetime.now()
        )
        
        # Make websocket_manager methods async
        mock_websocket_manager.send_window_state = AsyncMock()
        mock_websocket_manager.broadcast_update = AsyncMock()
        
        yield {
            'preprocessor': mock_preprocessor,
            'session_manager': mock_session_manager,
            'history_store': mock_history_store,
            'websocket_manager': mock_websocket_manager
        }


def test_root_endpoint(client):
    """Test the root health check endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "online"
    assert data["service"] == "AEGIS RPA Backend"


def test_start_task_success(client, mock_services):
    """Test successful task submission."""
    response = client.post(
        "/api/start_task",
        json={"instruction": "Open notepad"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "session_id" in data
    assert data["status"] == "pending"
    assert data["message"] == "Task queued for execution"


def test_start_task_validation_failure(client, mock_services):
    """Test task submission with invalid instruction."""
    # Configure mock to return validation failure
    mock_services['preprocessor'].validate_and_sanitize.return_value = (
        Mock(is_valid=False, error_message="Instruction cannot be empty"),
        None
    )
    
    response = client.post(
        "/api/start_task",
        json={"instruction": ""}
    )
    
    assert response.status_code == 422


def test_get_history(client, mock_services):
    """Test retrieving execution history."""
    response = client.get("/api/history")
    
    assert response.status_code == 200
    data = response.json()
    assert "sessions" in data
    assert "total" in data
    assert len(data["sessions"]) > 0


def test_get_history_with_limit(client, mock_services):
    """Test retrieving execution history with limit parameter."""
    response = client.get("/api/history?limit=50")
    
    assert response.status_code == 200
    data = response.json()
    assert "sessions" in data
    assert "total" in data


def test_get_session_details_success(client, mock_services):
    """Test retrieving session details for existing session."""
    response = client.get("/api/history/test-session-123")
    
    assert response.status_code == 200
    data = response.json()
    assert data["session_id"] == "test-session-123"
    assert data["instruction"] == "Open notepad"


def test_get_session_details_not_found(client, mock_services):
    """Test retrieving session details for non-existent session."""
    # Configure mocks to return None
    mock_services['session_manager'].get_session.return_value = None
    mock_services['history_store'].get_session_details.return_value = None
    
    response = client.get("/api/history/non-existent-session")
    
    assert response.status_code == 404


def test_cancel_execution_success(client, mock_services):
    """Test cancelling an ongoing execution."""
    response = client.delete("/api/execution/test-session-123")
    
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "session_id" in data


def test_cancel_execution_not_found(client, mock_services):
    """Test cancelling a non-existent session."""
    mock_services['session_manager'].get_session.return_value = None
    mock_services['history_store'].get_session_details.return_value = None
    
    response = client.delete("/api/execution/non-existent-session")
    
    assert response.status_code == 404


def test_cancel_execution_already_completed(client, mock_services):
    """Test cancelling an already completed session."""
    mock_services['session_manager'].get_session.return_value = ExecutionSession(
        session_id="test-session-123",
        instruction="Open notepad",
        status="completed",
        subtasks=[],
        created_at=datetime.now(),
        updated_at=datetime.now(),
        completed_at=datetime.now()
    )
    
    response = client.delete("/api/execution/test-session-123")
    
    assert response.status_code == 400


def test_openapi_docs_available(client):
    """Test that OpenAPI documentation is available."""
    response = client.get("/docs")
    assert response.status_code == 200
    
    response = client.get("/redoc")
    assert response.status_code == 200


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
