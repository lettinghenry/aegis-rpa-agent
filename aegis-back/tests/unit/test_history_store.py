"""
Unit tests for History Store.

Tests the persistent storage and retrieval of execution sessions.
"""

import pytest
import tempfile
import shutil
from pathlib import Path
from datetime import datetime, timezone
from src.history_store import HistoryStore
from src.models import ExecutionSession, Subtask, SubtaskStatus


class TestHistoryStore:
    """Test suite for History Store."""
    
    @pytest.fixture
    def temp_history_dir(self):
        """Create a temporary directory for testing."""
        temp_dir = tempfile.mkdtemp()
        yield temp_dir
        # Cleanup after test
        shutil.rmtree(temp_dir, ignore_errors=True)
    
    @pytest.fixture
    def history_store(self, temp_history_dir):
        """Create a HistoryStore instance with temporary directory."""
        return HistoryStore(history_dir=temp_history_dir)
    
    @pytest.fixture
    def sample_session(self):
        """Create a sample execution session for testing."""
        return ExecutionSession(
            session_id="test_session_1",
            instruction="Open notepad and type hello",
            status="completed",
            subtasks=[
                Subtask(
                    id="subtask_1",
                    description="Open notepad",
                    status=SubtaskStatus.COMPLETED,
                    tool_name="launch_application",
                    tool_args={"app_name": "notepad"},
                    result={"success": True},
                    timestamp=datetime.now(timezone.utc)
                ),
                Subtask(
                    id="subtask_2",
                    description="Type hello",
                    status=SubtaskStatus.COMPLETED,
                    tool_name="type_text",
                    tool_args={"text": "hello"},
                    result={"success": True},
                    timestamp=datetime.now(timezone.utc)
                )
            ],
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
            completed_at=datetime.now(timezone.utc)
        )
    
    def test_save_session_creates_file(self, history_store, sample_session, temp_history_dir):
        """Test that save_session creates a JSON file."""
        history_store.save_session(sample_session)
        
        session_file = Path(temp_history_dir) / f"{sample_session.session_id}.json"
        assert session_file.exists()
    
    def test_save_session_creates_index(self, history_store, sample_session, temp_history_dir):
        """Test that save_session updates the index file."""
        history_store.save_session(sample_session)
        
        index_file = Path(temp_history_dir) / "index.json"
        assert index_file.exists()
    
    def test_get_session_details_retrieves_saved_session(self, history_store, sample_session):
        """Test retrieving a saved session."""
        history_store.save_session(sample_session)
        
        retrieved = history_store.get_session_details(sample_session.session_id)
        
        assert retrieved is not None
        assert retrieved.session_id == sample_session.session_id
        assert retrieved.instruction == sample_session.instruction
        assert retrieved.status == sample_session.status
        assert len(retrieved.subtasks) == 2
    
    def test_get_session_details_returns_none_for_nonexistent(self, history_store):
        """Test that get_session_details returns None for non-existent session."""
        retrieved = history_store.get_session_details("nonexistent_id")
        
        assert retrieved is None
    
    def test_get_all_sessions_returns_empty_list_initially(self, history_store):
        """Test that get_all_sessions returns empty list when no sessions."""
        sessions = history_store.get_all_sessions()
        
        assert sessions == []
    
    def test_get_all_sessions_returns_saved_sessions(self, history_store):
        """Test that get_all_sessions returns all saved sessions."""
        # Create multiple sessions
        session1 = ExecutionSession(
            session_id="session_1",
            instruction="Task 1",
            status="completed",
            subtasks=[],
            created_at=datetime(2024, 1, 1, 10, 0, 0, tzinfo=timezone.utc),
            updated_at=datetime(2024, 1, 1, 10, 5, 0, tzinfo=timezone.utc),
            completed_at=datetime(2024, 1, 1, 10, 5, 0, tzinfo=timezone.utc)
        )
        session2 = ExecutionSession(
            session_id="session_2",
            instruction="Task 2",
            status="completed",
            subtasks=[],
            created_at=datetime(2024, 1, 2, 10, 0, 0, tzinfo=timezone.utc),
            updated_at=datetime(2024, 1, 2, 10, 5, 0, tzinfo=timezone.utc),
            completed_at=datetime(2024, 1, 2, 10, 5, 0, tzinfo=timezone.utc)
        )
        
        history_store.save_session(session1)
        history_store.save_session(session2)
        
        sessions = history_store.get_all_sessions()
        
        assert len(sessions) == 2
        session_ids = [s.session_id for s in sessions]
        assert "session_1" in session_ids
        assert "session_2" in session_ids
    
    def test_get_all_sessions_ordered_by_timestamp_descending(self, history_store):
        """Test that sessions are ordered by timestamp descending (newest first)."""
        # Create sessions with different timestamps
        session1 = ExecutionSession(
            session_id="session_1",
            instruction="Task 1",
            status="completed",
            subtasks=[],
            created_at=datetime(2024, 1, 1, 10, 0, 0, tzinfo=timezone.utc),
            updated_at=datetime(2024, 1, 1, 10, 5, 0, tzinfo=timezone.utc),
            completed_at=datetime(2024, 1, 1, 10, 5, 0, tzinfo=timezone.utc)
        )
        session2 = ExecutionSession(
            session_id="session_2",
            instruction="Task 2",
            status="completed",
            subtasks=[],
            created_at=datetime(2024, 1, 3, 10, 0, 0, tzinfo=timezone.utc),
            updated_at=datetime(2024, 1, 3, 10, 5, 0, tzinfo=timezone.utc),
            completed_at=datetime(2024, 1, 3, 10, 5, 0, tzinfo=timezone.utc)
        )
        session3 = ExecutionSession(
            session_id="session_3",
            instruction="Task 3",
            status="completed",
            subtasks=[],
            created_at=datetime(2024, 1, 2, 10, 0, 0, tzinfo=timezone.utc),
            updated_at=datetime(2024, 1, 2, 10, 5, 0, tzinfo=timezone.utc),
            completed_at=datetime(2024, 1, 2, 10, 5, 0, tzinfo=timezone.utc)
        )
        
        history_store.save_session(session1)
        history_store.save_session(session2)
        history_store.save_session(session3)
        
        sessions = history_store.get_all_sessions()
        
        # Should be ordered: session2 (Jan 3), session3 (Jan 2), session1 (Jan 1)
        assert len(sessions) == 3
        assert sessions[0].session_id == "session_2"
        assert sessions[1].session_id == "session_3"
        assert sessions[2].session_id == "session_1"
    
    def test_get_all_sessions_respects_limit(self, history_store):
        """Test that get_all_sessions respects the limit parameter."""
        # Create 5 sessions
        for i in range(5):
            session = ExecutionSession(
                session_id=f"session_{i}",
                instruction=f"Task {i}",
                status="completed",
                subtasks=[],
                created_at=datetime(2024, 1, i+1, 10, 0, 0, tzinfo=timezone.utc),
                updated_at=datetime(2024, 1, i+1, 10, 5, 0, tzinfo=timezone.utc),
                completed_at=datetime(2024, 1, i+1, 10, 5, 0, tzinfo=timezone.utc)
            )
            history_store.save_session(session)
        
        sessions = history_store.get_all_sessions(limit=3)
        
        assert len(sessions) == 3
    
    def test_save_session_updates_existing_session(self, history_store):
        """Test that saving a session with same ID updates the existing one."""
        session = ExecutionSession(
            session_id="session_1",
            instruction="Task 1",
            status="in_progress",
            subtasks=[],
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        
        history_store.save_session(session)
        
        # Update the session
        session.status = "completed"
        session.completed_at = datetime.now(timezone.utc)
        history_store.save_session(session)
        
        # Should only have one session in index
        sessions = history_store.get_all_sessions()
        assert len(sessions) == 1
        assert sessions[0].status == "completed"
    
    def test_session_summary_includes_subtask_count(self, history_store, sample_session):
        """Test that session summary includes correct subtask count."""
        history_store.save_session(sample_session)
        
        sessions = history_store.get_all_sessions()
        
        assert len(sessions) == 1
        assert sessions[0].subtask_count == 2
    
    def test_persistence_across_instances(self, temp_history_dir, sample_session):
        """Test that sessions persist across HistoryStore instances."""
        # Save with first instance
        store1 = HistoryStore(history_dir=temp_history_dir)
        store1.save_session(sample_session)
        
        # Retrieve with second instance
        store2 = HistoryStore(history_dir=temp_history_dir)
        retrieved = store2.get_session_details(sample_session.session_id)
        
        assert retrieved is not None
        assert retrieved.session_id == sample_session.session_id
    
    def test_handles_session_without_completed_at(self, history_store):
        """Test handling sessions without completed_at timestamp."""
        session = ExecutionSession(
            session_id="session_1",
            instruction="Task 1",
            status="in_progress",
            subtasks=[],
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
            completed_at=None
        )
        
        history_store.save_session(session)
        
        sessions = history_store.get_all_sessions()
        assert len(sessions) == 1
        assert sessions[0].completed_at is None
        
        retrieved = history_store.get_session_details(session.session_id)
        assert retrieved.completed_at is None
