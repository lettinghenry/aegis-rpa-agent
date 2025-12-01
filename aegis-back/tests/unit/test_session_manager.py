"""
Unit tests for Session Manager.

Tests the session lifecycle management including creation, retrieval,
updates, and cancellation.
"""

import pytest
from datetime import datetime, timezone
from src.session_manager import SessionManager, SessionUpdate
from src.models import ExecutionSession, Subtask, SubtaskStatus


class TestSessionManager:
    """Test suite for Session Manager."""
    
    def test_create_session_returns_unique_id(self):
        """Test that create_session returns a unique session ID."""
        manager = SessionManager()
        instruction = "Open notepad and type hello"
        
        session_id = manager.create_session(instruction)
        
        assert session_id is not None
        assert isinstance(session_id, str)
        assert len(session_id) > 0
    
    def test_create_session_stores_session(self):
        """Test that created session is stored and retrievable."""
        manager = SessionManager()
        instruction = "Open notepad"
        
        session_id = manager.create_session(instruction)
        session = manager.get_session(session_id)
        
        assert session is not None
        assert session.session_id == session_id
        assert session.instruction == instruction
        assert session.status == "pending"
        assert len(session.subtasks) == 0
    
    def test_create_multiple_sessions_have_unique_ids(self):
        """Test that multiple sessions get unique IDs (Property 8)."""
        manager = SessionManager()
        
        session_id_1 = manager.create_session("Task 1")
        session_id_2 = manager.create_session("Task 2")
        session_id_3 = manager.create_session("Task 1")  # Same instruction
        
        # All IDs should be unique
        assert session_id_1 != session_id_2
        assert session_id_1 != session_id_3
        assert session_id_2 != session_id_3
    
    def test_get_session_returns_none_for_invalid_id(self):
        """Test that get_session returns None for non-existent ID."""
        manager = SessionManager()
        
        session = manager.get_session("invalid-id")
        
        assert session is None
    
    def test_update_session_changes_status(self):
        """Test updating session status."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        
        update = SessionUpdate(status="in_progress")
        result = manager.update_session(session_id, update)
        
        assert result is True
        session = manager.get_session(session_id)
        assert session.status == "in_progress"
    
    def test_update_session_adds_subtask(self):
        """Test adding a subtask to session."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        
        subtask = Subtask(
            id="subtask_1",
            description="Open notepad",
            status=SubtaskStatus.IN_PROGRESS,
            tool_name="launch_application",
            tool_args={"app_name": "notepad"},
            timestamp=datetime.now(timezone.utc)
        )
        
        update = SessionUpdate(subtask=subtask)
        result = manager.update_session(session_id, update)
        
        assert result is True
        session = manager.get_session(session_id)
        assert len(session.subtasks) == 1
        assert session.subtasks[0].id == "subtask_1"
        assert session.subtasks[0].description == "Open notepad"
    
    def test_update_session_updates_existing_subtask(self):
        """Test updating an existing subtask."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        
        # Add initial subtask
        subtask = Subtask(
            id="subtask_1",
            description="Open notepad",
            status=SubtaskStatus.IN_PROGRESS,
            tool_name="launch_application",
            timestamp=datetime.now(timezone.utc)
        )
        manager.update_session(session_id, SessionUpdate(subtask=subtask))
        
        # Update the same subtask
        updated_subtask = Subtask(
            id="subtask_1",
            description="Open notepad",
            status=SubtaskStatus.COMPLETED,
            tool_name="launch_application",
            result={"success": True},
            timestamp=datetime.now(timezone.utc)
        )
        manager.update_session(session_id, SessionUpdate(subtask=updated_subtask))
        
        session = manager.get_session(session_id)
        assert len(session.subtasks) == 1
        assert session.subtasks[0].status == SubtaskStatus.COMPLETED
        assert session.subtasks[0].result == {"success": True}
    
    def test_update_session_adds_multiple_subtasks(self):
        """Test adding multiple subtasks sequentially."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        
        subtask1 = Subtask(
            id="subtask_1",
            description="Open notepad",
            status=SubtaskStatus.COMPLETED,
            timestamp=datetime.now(timezone.utc)
        )
        subtask2 = Subtask(
            id="subtask_2",
            description="Type text",
            status=SubtaskStatus.IN_PROGRESS,
            timestamp=datetime.now(timezone.utc)
        )
        
        manager.update_session(session_id, SessionUpdate(subtask=subtask1))
        manager.update_session(session_id, SessionUpdate(subtask=subtask2))
        
        session = manager.get_session(session_id)
        assert len(session.subtasks) == 2
        assert session.subtasks[0].id == "subtask_1"
        assert session.subtasks[1].id == "subtask_2"
    
    def test_update_session_sets_completion_time(self):
        """Test setting completion time on session."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        
        completion_time = datetime.now(timezone.utc)
        update = SessionUpdate(
            status="completed",
            completed_at=completion_time
        )
        manager.update_session(session_id, update)
        
        session = manager.get_session(session_id)
        assert session.status == "completed"
        assert session.completed_at == completion_time
    
    def test_update_session_returns_false_for_invalid_id(self):
        """Test that update returns False for non-existent session."""
        manager = SessionManager()
        
        update = SessionUpdate(status="in_progress")
        result = manager.update_session("invalid-id", update)
        
        assert result is False
    
    def test_cancel_session_marks_as_cancelled(self):
        """Test cancelling an active session."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        
        # Set to in_progress first
        manager.update_session(session_id, SessionUpdate(status="in_progress"))
        
        result = manager.cancel_session(session_id)
        
        assert result is True
        session = manager.get_session(session_id)
        assert session.status == "cancelled"
        assert session.completed_at is not None
    
    def test_cancel_pending_session(self):
        """Test cancelling a pending session."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        
        result = manager.cancel_session(session_id)
        
        assert result is True
        session = manager.get_session(session_id)
        assert session.status == "cancelled"
    
    def test_cancel_completed_session_fails(self):
        """Test that cancelling a completed session fails."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        
        # Complete the session
        manager.update_session(session_id, SessionUpdate(status="completed"))
        
        result = manager.cancel_session(session_id)
        
        assert result is False
        session = manager.get_session(session_id)
        assert session.status == "completed"  # Status unchanged
    
    def test_cancel_failed_session_fails(self):
        """Test that cancelling a failed session fails."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        
        # Fail the session
        manager.update_session(session_id, SessionUpdate(status="failed"))
        
        result = manager.cancel_session(session_id)
        
        assert result is False
        session = manager.get_session(session_id)
        assert session.status == "failed"  # Status unchanged
    
    def test_cancel_session_returns_false_for_invalid_id(self):
        """Test that cancel returns False for non-existent session."""
        manager = SessionManager()
        
        result = manager.cancel_session("invalid-id")
        
        assert result is False
    
    def test_get_all_sessions_returns_empty_list_initially(self):
        """Test that get_all_sessions returns empty list when no sessions."""
        manager = SessionManager()
        
        sessions = manager.get_all_sessions()
        
        assert sessions == []
    
    def test_get_all_sessions_returns_all_sessions(self):
        """Test that get_all_sessions returns all created sessions."""
        manager = SessionManager()
        
        session_id_1 = manager.create_session("Task 1")
        session_id_2 = manager.create_session("Task 2")
        session_id_3 = manager.create_session("Task 3")
        
        sessions = manager.get_all_sessions()
        
        assert len(sessions) == 3
        session_ids = [s.session_id for s in sessions]
        assert session_id_1 in session_ids
        assert session_id_2 in session_ids
        assert session_id_3 in session_ids
    
    def test_delete_session_removes_session(self):
        """Test deleting a session."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        
        result = manager.delete_session(session_id)
        
        assert result is True
        assert manager.get_session(session_id) is None
    
    def test_delete_session_returns_false_for_invalid_id(self):
        """Test that delete returns False for non-existent session."""
        manager = SessionManager()
        
        result = manager.delete_session("invalid-id")
        
        assert result is False
    
    def test_is_session_active_for_pending_session(self):
        """Test that pending session is considered active."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        
        assert manager.is_session_active(session_id) is True
    
    def test_is_session_active_for_in_progress_session(self):
        """Test that in_progress session is considered active."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        manager.update_session(session_id, SessionUpdate(status="in_progress"))
        
        assert manager.is_session_active(session_id) is True
    
    def test_is_session_active_for_completed_session(self):
        """Test that completed session is not considered active."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        manager.update_session(session_id, SessionUpdate(status="completed"))
        
        assert manager.is_session_active(session_id) is False
    
    def test_is_session_active_for_failed_session(self):
        """Test that failed session is not considered active."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        manager.update_session(session_id, SessionUpdate(status="failed"))
        
        assert manager.is_session_active(session_id) is False
    
    def test_is_session_active_for_cancelled_session(self):
        """Test that cancelled session is not considered active."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        manager.cancel_session(session_id)
        
        assert manager.is_session_active(session_id) is False
    
    def test_is_session_active_for_invalid_id(self):
        """Test that invalid session ID returns False."""
        manager = SessionManager()
        
        assert manager.is_session_active("invalid-id") is False
    
    def test_session_timestamps_are_set(self):
        """Test that session timestamps are properly set."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        
        session = manager.get_session(session_id)
        
        assert session.created_at is not None
        assert session.updated_at is not None
        assert isinstance(session.created_at, datetime)
        assert isinstance(session.updated_at, datetime)
    
    def test_update_session_updates_timestamp(self):
        """Test that updating session updates the updated_at timestamp."""
        manager = SessionManager()
        session_id = manager.create_session("Test task")
        
        session = manager.get_session(session_id)
        original_updated_at = session.updated_at
        
        # Small delay to ensure timestamp difference
        import time
        time.sleep(0.01)
        
        manager.update_session(session_id, SessionUpdate(status="in_progress"))
        
        session = manager.get_session(session_id)
        assert session.updated_at > original_updated_at
    
    def test_thread_safety_concurrent_creates(self):
        """Test thread safety with concurrent session creation."""
        import threading
        
        manager = SessionManager()
        session_ids = []
        
        def create_session(instruction):
            sid = manager.create_session(instruction)
            session_ids.append(sid)
        
        threads = []
        for i in range(10):
            t = threading.Thread(target=create_session, args=(f"Task {i}",))
            threads.append(t)
            t.start()
        
        for t in threads:
            t.join()
        
        # All session IDs should be unique
        assert len(session_ids) == 10
        assert len(set(session_ids)) == 10
        
        # All sessions should be retrievable
        for sid in session_ids:
            assert manager.get_session(sid) is not None

