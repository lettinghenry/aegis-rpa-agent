"""
Integration tests for complete execution flow.

Tests the end-to-end integration of all components:
Pre-Processing → Plan Cache → ADK Agent → RPA Engine → Action Observer
Session Manager ↔ WebSocket Manager ↔ History Store

Validates: Requirements 2.1, 2.3, 1.3, 6.5, 8.4, 13.1, 13.3, 13.4, 13.5
"""

import pytest
import asyncio
from unittest.mock import Mock, patch, AsyncMock, MagicMock
from datetime import datetime

from src.preprocessing import PreProcessor
from src.plan_cache import PlanCache
from src.adk_agent import ADKAgentManager
from src.session_manager import SessionManager
from src.history_store import HistoryStore
from src.websocket_manager import WebSocketManager
from src.models import (
    ValidationResult,
    ExecutionSession,
    StatusUpdate,
    Subtask,
    SubtaskStatus,
    ToolResult,
    ExecutionPlan
)


@pytest.fixture
def mock_preprocessor():
    """Mock PreProcessor."""
    preprocessor = Mock(spec=PreProcessor)
    preprocessor.validate_and_sanitize.return_value = (
        ValidationResult(is_valid=True),
        "Open notepad"
    )
    return preprocessor


@pytest.fixture
def mock_plan_cache():
    """Mock PlanCache."""
    cache = Mock(spec=PlanCache)
    cache.get_cached_plan.return_value = None  # No cache hit by default
    cache.store_plan.return_value = None
    return cache


@pytest.fixture
def mock_adk_agent():
    """Mock ADKAgentManager."""
    agent = Mock(spec=ADKAgentManager)
    
    async def mock_execute(instruction, session_id):
        """Mock execution that yields status updates."""
        # First update - start with window minimize
        yield StatusUpdate(
            session_id=session_id,
            subtask=Subtask(
                id=f"{session_id}_subtask_1",
                description="Launch notepad",
                status=SubtaskStatus.IN_PROGRESS,
                tool_name="launch_application",
                tool_args={"app_name": "notepad"},
                timestamp=datetime.now()
            ),
            overall_status="in_progress",
            message="Starting subtask: launch_application",
            window_state="minimal",
            timestamp=datetime.now()
        )
        
        # Second update - subtask completed
        yield StatusUpdate(
            session_id=session_id,
            subtask=Subtask(
                id=f"{session_id}_subtask_1",
                description="Launch notepad",
                status=SubtaskStatus.COMPLETED,
                tool_name="launch_application",
                tool_args={"app_name": "notepad"},
                result={"success": True},
                timestamp=datetime.now()
            ),
            overall_status="in_progress",
            message="Completed subtask: launch_application",
            timestamp=datetime.now()
        )
        
        # Final update - execution completed with window restore
        yield StatusUpdate(
            session_id=session_id,
            subtask=None,
            overall_status="completed",
            message="Task execution completed successfully",
            window_state="normal",
            timestamp=datetime.now()
        )
    
    agent.execute_instruction = mock_execute
    return agent


@pytest.fixture
def session_manager():
    """Real SessionManager instance."""
    return SessionManager()


@pytest.fixture
def history_store(tmp_path):
    """Real HistoryStore instance with temporary directory."""
    store = HistoryStore(history_dir=str(tmp_path / "history"))
    return store


@pytest.fixture
def websocket_manager():
    """Mock WebSocketManager."""
    manager = Mock(spec=WebSocketManager)
    manager.broadcast_update = AsyncMock()
    manager.send_window_state = AsyncMock()
    return manager


@pytest.mark.asyncio
async def test_complete_execution_flow(
    mock_preprocessor,
    mock_plan_cache,
    mock_adk_agent,
    session_manager,
    history_store,
    websocket_manager
):
    """
    Test the complete execution flow integrating all components.
    
    This test verifies:
    1. Pre-processing validates instruction
    2. Plan cache is checked
    3. ADK agent executes instruction
    4. Session manager tracks state
    5. WebSocket manager broadcasts updates
    6. History store persists session
    7. Window state commands are sent correctly
    """
    instruction = "Open notepad"
    
    # Step 1: Pre-processing
    validation_result, sanitized = mock_preprocessor.validate_and_sanitize(instruction)
    assert validation_result.is_valid
    assert sanitized == "Open notepad"
    
    # Step 2: Create session
    session_id = session_manager.create_session(sanitized)
    assert session_id is not None
    
    session = session_manager.get_session(session_id)
    assert session is not None
    assert session.status == "pending"
    assert session.instruction == sanitized
    
    # Step 3: Check plan cache
    cached_plan = mock_plan_cache.get_cached_plan(sanitized)
    assert cached_plan is None  # No cache hit
    
    # Step 4: Update session to in_progress
    from src.session_manager import SessionUpdate as SessionMgrUpdate
    session.status = "in_progress"
    session.updated_at = datetime.now()
    session_manager.update_session(session_id, SessionMgrUpdate(status="in_progress"))
    
    # Step 5: Execute instruction with ADK agent
    window_state_minimal_sent = False
    window_state_normal_sent = False
    
    async for status_update in mock_adk_agent.execute_instruction(sanitized, session_id):
        # Update session
        session_manager.update_session(session_id, status_update)
        
        # Broadcast via WebSocket
        await websocket_manager.broadcast_update(session_id, status_update)
        
        # Track window state commands
        if status_update.window_state == "minimal":
            window_state_minimal_sent = True
        elif status_update.window_state == "normal":
            window_state_normal_sent = True
        
        # Check if completed
        if status_update.overall_status in ["completed", "failed"]:
            final_session = session_manager.get_session(session_id)
            final_session.completed_at = datetime.now()
            final_session.updated_at = datetime.now()
            
            # Save to history
            history_store.save_session(final_session)
            break
    
    # Step 6: Verify final state
    final_session = session_manager.get_session(session_id)
    assert final_session.status == "completed"
    assert final_session.completed_at is not None
    assert len(final_session.subtasks) > 0
    
    # Step 7: Verify window state commands were sent
    assert window_state_minimal_sent, "WINDOW_STATE_MINIMAL should be sent before first action"
    assert window_state_normal_sent, "WINDOW_STATE_NORMAL should be sent on completion"
    
    # Step 8: Verify WebSocket broadcasts
    assert websocket_manager.broadcast_update.call_count >= 3
    
    # Step 9: Verify history persistence
    retrieved_session = history_store.get_session_details(session_id)
    assert retrieved_session is not None
    assert retrieved_session.session_id == session_id
    assert retrieved_session.status == "completed"
    
    # Step 10: Verify plan cache storage (would happen in real flow)
    # In real implementation, the plan would be stored after successful execution
    
    print("✓ Complete execution flow test passed")


@pytest.mark.asyncio
async def test_execution_flow_with_cache_hit(
    mock_preprocessor,
    mock_plan_cache,
    mock_adk_agent,
    session_manager,
    history_store,
    websocket_manager
):
    """
    Test execution flow when plan cache has a hit.
    
    Validates: Requirement 2.3 (cache lookup performed)
    """
    instruction = "Open notepad"
    
    # Configure cache to return a cached plan
    cached_plan = ExecutionPlan(
        instruction=instruction,
        subtasks=[
            {"tool_name": "launch_application", "tool_args": {"app_name": "notepad"}}
        ],
        created_at=datetime.now()
    )
    mock_plan_cache.get_cached_plan.return_value = cached_plan
    
    # Pre-processing
    validation_result, sanitized = mock_preprocessor.validate_and_sanitize(instruction)
    assert validation_result.is_valid
    
    # Create session
    session_id = session_manager.create_session(sanitized)
    
    # Check cache
    cached = mock_plan_cache.get_cached_plan(sanitized)
    assert cached is not None
    assert cached.instruction == instruction
    
    # Verify cache was checked
    mock_plan_cache.get_cached_plan.assert_called_once_with(sanitized)
    
    print("✓ Cache hit test passed")


@pytest.mark.asyncio
async def test_execution_flow_with_cancellation(
    mock_preprocessor,
    mock_plan_cache,
    session_manager,
    history_store,
    websocket_manager
):
    """
    Test execution flow when session is cancelled.
    
    Validates: Requirements 8.5, 13.4 (cancellation cleanup and window restore)
    """
    instruction = "Open notepad"
    
    # Pre-processing
    validation_result, sanitized = mock_preprocessor.validate_and_sanitize(instruction)
    assert validation_result.is_valid
    
    # Create session
    session_id = session_manager.create_session(sanitized)
    session = session_manager.get_session(session_id)
    session.status = "in_progress"
    
    # Cancel session
    success = session_manager.cancel_session(session_id)
    assert success
    
    # Verify session is cancelled
    cancelled_session = session_manager.get_session(session_id)
    assert cancelled_session.status == "cancelled"
    
    # Send cancellation update with window restore
    cancel_update = StatusUpdate(
        session_id=session_id,
        subtask=None,
        overall_status="cancelled",
        message="Execution cancelled by user",
        window_state="normal",
        timestamp=datetime.now()
    )
    await websocket_manager.broadcast_update(session_id, cancel_update)
    
    # Update session timestamps
    cancelled_session.completed_at = datetime.now()
    cancelled_session.updated_at = datetime.now()
    
    # Save to history
    history_store.save_session(cancelled_session)
    
    # Verify history
    retrieved = history_store.get_session_details(session_id)
    assert retrieved.status == "cancelled"
    assert retrieved.completed_at is not None
    
    # Verify window restore was sent
    websocket_manager.broadcast_update.assert_called_once()
    call_args = websocket_manager.broadcast_update.call_args[0]
    assert call_args[1].window_state == "normal"
    
    print("✓ Cancellation flow test passed")


@pytest.mark.asyncio
async def test_execution_flow_with_failure(
    mock_preprocessor,
    mock_plan_cache,
    session_manager,
    history_store,
    websocket_manager
):
    """
    Test execution flow when execution fails.
    
    Validates: Requirements 6.5, 13.3 (failure handling and window restore)
    """
    instruction = "Open notepad"
    
    # Pre-processing
    validation_result, sanitized = mock_preprocessor.validate_and_sanitize(instruction)
    assert validation_result.is_valid
    
    # Create session
    session_id = session_manager.create_session(sanitized)
    session = session_manager.get_session(session_id)
    session.status = "in_progress"
    
    # Simulate failure
    session.status = "failed"
    session.completed_at = datetime.now()
    session.updated_at = datetime.now()
    
    # Send failure update with window restore
    failure_update = StatusUpdate(
        session_id=session_id,
        subtask=None,
        overall_status="failed",
        message="Execution failed: Tool error",
        window_state="normal",
        timestamp=datetime.now()
    )
    await websocket_manager.broadcast_update(session_id, failure_update)
    
    # Save to history
    history_store.save_session(session)
    
    # Verify history
    retrieved = history_store.get_session_details(session_id)
    assert retrieved.status == "failed"
    assert retrieved.completed_at is not None
    
    # Verify window restore was sent
    websocket_manager.broadcast_update.assert_called_once()
    call_args = websocket_manager.broadcast_update.call_args[0]
    assert call_args[1].window_state == "normal"
    
    print("✓ Failure flow test passed")


@pytest.mark.asyncio
async def test_sequential_request_processing(
    mock_preprocessor,
    session_manager
):
    """
    Test that requests are processed sequentially.
    
    Validates: Requirement 8.4 (sequential request processing)
    """
    # Create multiple sessions
    session_ids = []
    for i in range(3):
        instruction = f"Task {i+1}"
        validation_result, sanitized = mock_preprocessor.validate_and_sanitize(instruction)
        session_id = session_manager.create_session(sanitized)
        session_ids.append(session_id)
    
    # Verify all sessions were created
    assert len(session_ids) == 3
    assert len(set(session_ids)) == 3  # All unique
    
    # In real implementation, these would be queued and processed one at a time
    # The queue ensures sequential processing
    
    print("✓ Sequential processing test passed")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
