"""
Unit tests for Pydantic data models.

Tests cover:
- Model serialization and deserialization
- Validation logic
- Edge cases (empty fields, invalid types)
"""

import pytest
from datetime import datetime
from pydantic import ValidationError
from src.models import (
    TaskInstructionRequest,
    TaskInstructionResponse,
    SubtaskStatus,
    Subtask,
    ExecutionSession,
    StatusUpdate,
    SessionSummary,
    HistoryResponse,
    ErrorResponse,
    ValidationResult,
    ExecutionPlan,
    ToolResult,
    ActionResult,
)


class TestTaskInstructionRequest:
    """Tests for TaskInstructionRequest model."""

    def test_valid_instruction(self):
        """Test creating a valid task instruction request."""
        request = TaskInstructionRequest(instruction="Open Chrome and navigate to Google")
        assert request.instruction == "Open Chrome and navigate to Google"

    def test_serialization(self):
        """Test serialization to JSON."""
        request = TaskInstructionRequest(instruction="Test instruction")
        json_data = request.model_dump()
        assert json_data == {"instruction": "Test instruction"}

    def test_deserialization(self):
        """Test deserialization from JSON."""
        json_data = {"instruction": "Test instruction"}
        request = TaskInstructionRequest(**json_data)
        assert request.instruction == "Test instruction"

    def test_empty_instruction_rejected(self):
        """Test that empty instructions are rejected."""
        with pytest.raises(ValidationError) as exc_info:
            TaskInstructionRequest(instruction="")
        assert "String should have at least 1 character" in str(exc_info.value)

    def test_instruction_too_long_rejected(self):
        """Test that instructions exceeding max length are rejected."""
        long_instruction = "a" * 1001
        with pytest.raises(ValidationError) as exc_info:
            TaskInstructionRequest(instruction=long_instruction)
        assert "String should have at most 1000 characters" in str(exc_info.value)

    def test_missing_instruction_rejected(self):
        """Test that missing instruction field is rejected."""
        with pytest.raises(ValidationError) as exc_info:
            TaskInstructionRequest()
        assert "Field required" in str(exc_info.value)

    def test_invalid_type_rejected(self):
        """Test that non-string instruction is rejected."""
        with pytest.raises(ValidationError) as exc_info:
            TaskInstructionRequest(instruction=123)
        assert "Input should be a valid string" in str(exc_info.value)


class TestTaskInstructionResponse:
    """Tests for TaskInstructionResponse model."""

    def test_valid_response_pending(self):
        """Test creating a valid response with pending status."""
        response = TaskInstructionResponse(
            session_id="abc123",
            status="pending",
            message="Task queued for execution"
        )
        assert response.session_id == "abc123"
        assert response.status == "pending"
        assert response.message == "Task queued for execution"

    def test_valid_response_in_progress(self):
        """Test creating a valid response with in_progress status."""
        response = TaskInstructionResponse(
            session_id="xyz789",
            status="in_progress",
            message="Task execution started"
        )
        assert response.status == "in_progress"

    def test_serialization(self):
        """Test serialization to JSON."""
        response = TaskInstructionResponse(
            session_id="test123",
            status="pending",
            message="Test message"
        )
        json_data = response.model_dump()
        assert json_data["session_id"] == "test123"
        assert json_data["status"] == "pending"
        assert json_data["message"] == "Test message"

    def test_deserialization(self):
        """Test deserialization from JSON."""
        json_data = {
            "session_id": "test123",
            "status": "pending",
            "message": "Test message"
        }
        response = TaskInstructionResponse(**json_data)
        assert response.session_id == "test123"

    def test_invalid_status_rejected(self):
        """Test that invalid status values are rejected."""
        with pytest.raises(ValidationError) as exc_info:
            TaskInstructionResponse(
                session_id="test",
                status="invalid_status",
                message="Test"
            )
        assert "Input should be 'pending' or 'in_progress'" in str(exc_info.value)


class TestSubtaskStatus:
    """Tests for SubtaskStatus enum."""

    def test_all_status_values(self):
        """Test all enum values are accessible."""
        assert SubtaskStatus.PENDING == "pending"
        assert SubtaskStatus.IN_PROGRESS == "in_progress"
        assert SubtaskStatus.COMPLETED == "completed"
        assert SubtaskStatus.FAILED == "failed"

    def test_enum_comparison(self):
        """Test enum value comparison."""
        status = SubtaskStatus.PENDING
        assert status == SubtaskStatus.PENDING
        assert status != SubtaskStatus.COMPLETED


class TestSubtask:
    """Tests for Subtask model."""

    def test_valid_subtask_minimal(self):
        """Test creating a subtask with minimal required fields."""
        now = datetime.now()
        subtask = Subtask(
            id="subtask-1",
            description="Click submit button",
            status=SubtaskStatus.PENDING,
            timestamp=now
        )
        assert subtask.id == "subtask-1"
        assert subtask.description == "Click submit button"
        assert subtask.status == SubtaskStatus.PENDING
        assert subtask.tool_name is None
        assert subtask.tool_args is None
        assert subtask.result is None
        assert subtask.error is None

    def test_valid_subtask_complete(self):
        """Test creating a subtask with all fields."""
        now = datetime.now()
        subtask = Subtask(
            id="subtask-2",
            description="Type text",
            status=SubtaskStatus.COMPLETED,
            tool_name="type_text",
            tool_args={"text": "Hello", "interval": 0.05},
            result={"success": True},
            error=None,
            timestamp=now
        )
        assert subtask.tool_name == "type_text"
        assert subtask.tool_args == {"text": "Hello", "interval": 0.05}
        assert subtask.result == {"success": True}

    def test_subtask_with_error(self):
        """Test creating a failed subtask with error message."""
        now = datetime.now()
        subtask = Subtask(
            id="subtask-3",
            description="Launch app",
            status=SubtaskStatus.FAILED,
            error="Application not found",
            timestamp=now
        )
        assert subtask.status == SubtaskStatus.FAILED
        assert subtask.error == "Application not found"

    def test_serialization(self):
        """Test serialization to JSON."""
        now = datetime.now()
        subtask = Subtask(
            id="test-1",
            description="Test",
            status=SubtaskStatus.PENDING,
            timestamp=now
        )
        json_data = subtask.model_dump()
        assert json_data["id"] == "test-1"
        assert json_data["status"] == "pending"

    def test_deserialization(self):
        """Test deserialization from JSON."""
        now = datetime.now()
        json_data = {
            "id": "test-1",
            "description": "Test",
            "status": "pending",
            "timestamp": now.isoformat()
        }
        subtask = Subtask(**json_data)
        assert subtask.id == "test-1"

    def test_missing_required_field(self):
        """Test that missing required fields are rejected."""
        with pytest.raises(ValidationError) as exc_info:
            Subtask(id="test", description="Test")
        assert "Field required" in str(exc_info.value)


class TestExecutionSession:
    """Tests for ExecutionSession model."""

    def test_valid_session_minimal(self):
        """Test creating a session with minimal fields."""
        now = datetime.now()
        session = ExecutionSession(
            session_id="session-1",
            instruction="Test instruction",
            status="pending",
            created_at=now,
            updated_at=now
        )
        assert session.session_id == "session-1"
        assert session.instruction == "Test instruction"
        assert session.status == "pending"
        assert session.subtasks == []
        assert session.completed_at is None

    def test_valid_session_with_subtasks(self):
        """Test creating a session with subtasks."""
        now = datetime.now()
        subtask = Subtask(
            id="sub-1",
            description="Test",
            status=SubtaskStatus.COMPLETED,
            timestamp=now
        )
        session = ExecutionSession(
            session_id="session-2",
            instruction="Test",
            status="completed",
            subtasks=[subtask],
            created_at=now,
            updated_at=now,
            completed_at=now
        )
        assert len(session.subtasks) == 1
        assert session.subtasks[0].id == "sub-1"
        assert session.completed_at == now

    def test_all_status_values(self):
        """Test all valid status values."""
        now = datetime.now()
        for status in ["pending", "in_progress", "completed", "failed", "cancelled"]:
            session = ExecutionSession(
                session_id="test",
                instruction="Test",
                status=status,
                created_at=now,
                updated_at=now
            )
            assert session.status == status

    def test_invalid_status_rejected(self):
        """Test that invalid status is rejected."""
        now = datetime.now()
        with pytest.raises(ValidationError) as exc_info:
            ExecutionSession(
                session_id="test",
                instruction="Test",
                status="invalid",
                created_at=now,
                updated_at=now
            )
        assert "Input should be" in str(exc_info.value)

    def test_serialization(self):
        """Test serialization to JSON."""
        now = datetime.now()
        session = ExecutionSession(
            session_id="test",
            instruction="Test",
            status="pending",
            created_at=now,
            updated_at=now
        )
        json_data = session.model_dump()
        assert json_data["session_id"] == "test"
        assert json_data["subtasks"] == []

    def test_deserialization(self):
        """Test deserialization from JSON."""
        now = datetime.now()
        json_data = {
            "session_id": "test",
            "instruction": "Test",
            "status": "pending",
            "subtasks": [],
            "created_at": now.isoformat(),
            "updated_at": now.isoformat()
        }
        session = ExecutionSession(**json_data)
        assert session.session_id == "test"


class TestStatusUpdate:
    """Tests for StatusUpdate model."""

    def test_valid_update_minimal(self):
        """Test creating a status update with minimal fields."""
        now = datetime.now()
        update = StatusUpdate(
            session_id="session-1",
            overall_status="in_progress",
            message="Executing task",
            timestamp=now
        )
        assert update.session_id == "session-1"
        assert update.overall_status == "in_progress"
        assert update.message == "Executing task"
        assert update.subtask is None
        assert update.window_state is None

    def test_valid_update_with_subtask(self):
        """Test creating a status update with subtask."""
        now = datetime.now()
        subtask = Subtask(
            id="sub-1",
            description="Test",
            status=SubtaskStatus.IN_PROGRESS,
            timestamp=now
        )
        update = StatusUpdate(
            session_id="session-1",
            subtask=subtask,
            overall_status="in_progress",
            message="Executing subtask",
            timestamp=now
        )
        assert update.subtask is not None
        assert update.subtask.id == "sub-1"

    def test_valid_update_with_window_state(self):
        """Test creating a status update with window state."""
        now = datetime.now()
        update = StatusUpdate(
            session_id="session-1",
            overall_status="in_progress",
            message="Minimizing window",
            window_state="minimal",
            timestamp=now
        )
        assert update.window_state == "minimal"

    def test_window_state_normal(self):
        """Test window state with normal value."""
        now = datetime.now()
        update = StatusUpdate(
            session_id="session-1",
            overall_status="completed",
            message="Restoring window",
            window_state="normal",
            timestamp=now
        )
        assert update.window_state == "normal"

    def test_invalid_window_state_rejected(self):
        """Test that invalid window state is rejected."""
        now = datetime.now()
        with pytest.raises(ValidationError) as exc_info:
            StatusUpdate(
                session_id="test",
                overall_status="test",
                message="test",
                window_state="invalid",
                timestamp=now
            )
        assert "Input should be 'minimal' or 'normal'" in str(exc_info.value)

    def test_serialization(self):
        """Test serialization to JSON."""
        now = datetime.now()
        update = StatusUpdate(
            session_id="test",
            overall_status="test",
            message="test",
            timestamp=now
        )
        json_data = update.model_dump()
        assert json_data["session_id"] == "test"


class TestSessionSummary:
    """Tests for SessionSummary model."""

    def test_valid_summary_without_completion(self):
        """Test creating a summary for incomplete session."""
        now = datetime.now()
        summary = SessionSummary(
            session_id="session-1",
            instruction="Test instruction",
            status="in_progress",
            created_at=now,
            subtask_count=5
        )
        assert summary.session_id == "session-1"
        assert summary.instruction == "Test instruction"
        assert summary.status == "in_progress"
        assert summary.subtask_count == 5
        assert summary.completed_at is None

    def test_valid_summary_with_completion(self):
        """Test creating a summary for completed session."""
        now = datetime.now()
        summary = SessionSummary(
            session_id="session-2",
            instruction="Test",
            status="completed",
            created_at=now,
            completed_at=now,
            subtask_count=3
        )
        assert summary.completed_at == now

    def test_serialization(self):
        """Test serialization to JSON."""
        now = datetime.now()
        summary = SessionSummary(
            session_id="test",
            instruction="Test",
            status="completed",
            created_at=now,
            subtask_count=1
        )
        json_data = summary.model_dump()
        assert json_data["session_id"] == "test"
        assert json_data["subtask_count"] == 1

    def test_deserialization(self):
        """Test deserialization from JSON."""
        now = datetime.now()
        json_data = {
            "session_id": "test",
            "instruction": "Test",
            "status": "completed",
            "created_at": now.isoformat(),
            "subtask_count": 1
        }
        summary = SessionSummary(**json_data)
        assert summary.session_id == "test"


class TestHistoryResponse:
    """Tests for HistoryResponse model."""

    def test_valid_history_empty(self):
        """Test creating an empty history response."""
        history = HistoryResponse(sessions=[], total=0)
        assert history.sessions == []
        assert history.total == 0

    def test_valid_history_with_sessions(self):
        """Test creating a history response with sessions."""
        now = datetime.now()
        summary = SessionSummary(
            session_id="test",
            instruction="Test",
            status="completed",
            created_at=now,
            subtask_count=1
        )
        history = HistoryResponse(sessions=[summary], total=1)
        assert len(history.sessions) == 1
        assert history.total == 1

    def test_serialization(self):
        """Test serialization to JSON."""
        history = HistoryResponse(sessions=[], total=0)
        json_data = history.model_dump()
        assert json_data["sessions"] == []
        assert json_data["total"] == 0


class TestErrorResponse:
    """Tests for ErrorResponse model."""

    def test_valid_error_minimal(self):
        """Test creating an error response with minimal fields."""
        error = ErrorResponse(error="Test error")
        assert error.error == "Test error"
        assert error.details is None
        assert error.session_id is None

    def test_valid_error_complete(self):
        """Test creating an error response with all fields."""
        error = ErrorResponse(
            error="Validation error",
            details="Field 'instruction' is required",
            session_id="session-123"
        )
        assert error.error == "Validation error"
        assert error.details == "Field 'instruction' is required"
        assert error.session_id == "session-123"

    def test_serialization(self):
        """Test serialization to JSON."""
        error = ErrorResponse(error="Test")
        json_data = error.model_dump()
        assert json_data["error"] == "Test"


class TestValidationResult:
    """Tests for ValidationResult model."""

    def test_valid_result_success(self):
        """Test creating a successful validation result."""
        result = ValidationResult(is_valid=True)
        assert result.is_valid is True
        assert result.error_message is None

    def test_valid_result_failure(self):
        """Test creating a failed validation result."""
        result = ValidationResult(
            is_valid=False,
            error_message="Instruction is empty"
        )
        assert result.is_valid is False
        assert result.error_message == "Instruction is empty"

    def test_serialization(self):
        """Test serialization to JSON."""
        result = ValidationResult(is_valid=True)
        json_data = result.model_dump()
        assert json_data["is_valid"] is True


class TestExecutionPlan:
    """Tests for ExecutionPlan model."""

    def test_valid_plan_minimal(self):
        """Test creating an execution plan with minimal fields."""
        now = datetime.now()
        plan = ExecutionPlan(
            instruction="Test instruction",
            subtasks=[],
            created_at=now
        )
        assert plan.instruction == "Test instruction"
        assert plan.subtasks == []
        assert plan.estimated_duration is None

    def test_valid_plan_with_subtasks(self):
        """Test creating an execution plan with subtasks."""
        now = datetime.now()
        plan = ExecutionPlan(
            instruction="Test",
            subtasks=[
                {"tool": "click_element", "args": {"x": 100, "y": 200}},
                {"tool": "type_text", "args": {"text": "Hello"}}
            ],
            estimated_duration=30,
            created_at=now
        )
        assert len(plan.subtasks) == 2
        assert plan.estimated_duration == 30

    def test_serialization(self):
        """Test serialization to JSON."""
        now = datetime.now()
        plan = ExecutionPlan(
            instruction="Test",
            subtasks=[],
            created_at=now
        )
        json_data = plan.model_dump()
        assert json_data["instruction"] == "Test"


class TestToolResult:
    """Tests for ToolResult model."""

    def test_valid_result_success(self):
        """Test creating a successful tool result."""
        result = ToolResult(success=True, data={"x": 100, "y": 200})
        assert result.success is True
        assert result.data == {"x": 100, "y": 200}
        assert result.error is None

    def test_valid_result_failure(self):
        """Test creating a failed tool result."""
        result = ToolResult(
            success=False,
            error="Element not found"
        )
        assert result.success is False
        assert result.error == "Element not found"
        assert result.data is None

    def test_serialization(self):
        """Test serialization to JSON."""
        result = ToolResult(success=True)
        json_data = result.model_dump()
        assert json_data["success"] is True


class TestActionResult:
    """Tests for ActionResult model."""

    def test_valid_result_success(self):
        """Test creating a successful action result."""
        result = ActionResult(success=True, retry_count=0)
        assert result.success is True
        assert result.retry_count == 0
        assert result.error is None

    def test_valid_result_with_retries(self):
        """Test creating a result after retries."""
        result = ActionResult(success=True, retry_count=2)
        assert result.success is True
        assert result.retry_count == 2

    def test_valid_result_failure(self):
        """Test creating a failed action result."""
        result = ActionResult(
            success=False,
            retry_count=3,
            error="Max retries exceeded"
        )
        assert result.success is False
        assert result.retry_count == 3
        assert result.error == "Max retries exceeded"

    def test_serialization(self):
        """Test serialization to JSON."""
        result = ActionResult(success=True, retry_count=0)
        json_data = result.model_dump()
        assert json_data["success"] is True
        assert json_data["retry_count"] == 0
