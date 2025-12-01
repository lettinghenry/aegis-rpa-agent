"""
Unit tests for custom exception classes.

Validates: Requirements 8.1, 8.2, 8.3
"""

import pytest
from src.exceptions import (
    AEGISException,
    ValidationError,
    InstructionValidationError,
    FieldValidationError,
    ClientError,
    SessionNotFoundError,
    InvalidSessionStateError,
    SystemError,
    ADKAgentError,
    RPAToolError,
    StorageError,
    CacheError,
    RPAExecutionError,
    ApplicationLaunchError,
    ElementNotFoundError,
    ActionTimeoutError,
    PermissionDeniedError,
    ActionVerificationError,
    WindowNotFoundError,
    ResourceCleanupError
)


class TestAEGISException:
    """Test base AEGIS exception class."""
    
    def test_basic_exception(self):
        """Test basic exception creation."""
        exc = AEGISException(message="Test error")
        assert exc.message == "Test error"
        assert exc.details is None
        assert exc.session_id is None
        assert exc.context == {}
    
    def test_exception_with_all_fields(self):
        """Test exception with all fields."""
        exc = AEGISException(
            message="Test error",
            details="Additional details",
            session_id="session123",
            context={"key": "value"}
        )
        assert exc.message == "Test error"
        assert exc.details == "Additional details"
        assert exc.session_id == "session123"
        assert exc.context == {"key": "value"}
    
    def test_to_dict(self):
        """Test exception serialization to dictionary."""
        exc = AEGISException(
            message="Test error",
            details="Additional details",
            session_id="session123",
            context={"key": "value"}
        )
        result = exc.to_dict()
        
        assert result["error"] == "AEGISException"
        assert result["message"] == "Test error"
        assert result["details"] == "Additional details"
        assert result["session_id"] == "session123"
        assert result["context"] == {"key": "value"}


class TestValidationErrors:
    """Test validation error classes."""
    
    def test_instruction_validation_error(self):
        """Test instruction validation error."""
        exc = InstructionValidationError(
            message="Invalid instruction",
            details="Instruction is empty"
        )
        assert exc.message == "Invalid instruction"
        assert exc.details == "Instruction is empty"
    
    def test_field_validation_error(self):
        """Test field validation error."""
        exc = FieldValidationError(
            field_name="instruction",
            message="Field validation failed",
            details="Field is required"
        )
        assert exc.field_name == "instruction"
        assert exc.message == "Field validation failed"
        assert exc.context["field"] == "instruction"


class TestClientErrors:
    """Test client error classes."""
    
    def test_session_not_found_error(self):
        """Test session not found error."""
        exc = SessionNotFoundError(
            session_id="session123",
            details="Session does not exist"
        )
        assert exc.session_id == "session123"
        assert "session123" in exc.message
        assert exc.details == "Session does not exist"
    
    def test_invalid_session_state_error(self):
        """Test invalid session state error."""
        exc = InvalidSessionStateError(
            session_id="session123",
            current_state="completed",
            operation="cancel"
        )
        assert exc.session_id == "session123"
        assert "cancel" in exc.message
        assert "completed" in exc.message
        assert exc.context["current_state"] == "completed"
        assert exc.context["operation"] == "cancel"


class TestSystemErrors:
    """Test system error classes."""
    
    def test_adk_agent_error(self):
        """Test ADK agent error."""
        exc = ADKAgentError(
            message="ADK agent failed",
            details="Connection timeout"
        )
        assert exc.message == "ADK agent failed"
        assert exc.details == "Connection timeout"
    
    def test_rpa_tool_error(self):
        """Test RPA tool error."""
        exc = RPAToolError(
            tool_name="click_element",
            message="Tool execution failed",
            details="Invalid coordinates",
            tool_args={"x": 100, "y": 200}
        )
        assert exc.tool_name == "click_element"
        assert exc.message == "Tool execution failed"
        assert exc.context["tool_name"] == "click_element"
        assert exc.context["tool_args"] == {"x": 100, "y": 200}


class TestRPAExecutionErrors:
    """Test RPA execution error classes."""
    
    def test_application_launch_error(self):
        """
        Test application launch error.
        
        Validates: Requirement 8.2
        """
        exc = ApplicationLaunchError(
            app_name="notepad",
            timeout=10,
            details="Application did not start"
        )
        assert exc.app_name == "notepad"
        assert exc.timeout == 10
        assert "notepad" in exc.message
        assert "10 seconds" in exc.message
        assert exc.context["app_name"] == "notepad"
        assert exc.context["timeout"] == 10
    
    def test_element_not_found_error(self):
        """
        Test element not found error.
        
        Validates: Requirement 8.3
        """
        exc = ElementNotFoundError(
            element_description="Submit button",
            search_method="image",
            search_value="submit.png",
            details="Template not found on screen",
            screenshot_path="/tmp/screenshot.png"
        )
        assert exc.element_description == "Submit button"
        assert exc.search_method == "image"
        assert exc.search_value == "submit.png"
        assert "Submit button" in exc.message
        assert exc.context["search_method"] == "image"
        assert exc.context["screenshot_path"] == "/tmp/screenshot.png"
    
    def test_action_timeout_error(self):
        """Test action timeout error."""
        exc = ActionTimeoutError(
            action_name="click_element",
            timeout=30,
            details="Action did not complete"
        )
        assert exc.action_name == "click_element"
        assert exc.timeout == 30
        assert "click_element" in exc.message
        assert "30 seconds" in exc.message
    
    def test_permission_denied_error(self):
        """
        Test permission denied error.
        
        Validates: Requirement 8.1
        """
        exc = PermissionDeniedError(
            operation="write",
            resource="/system/file.txt",
            details="Access denied"
        )
        assert exc.operation == "write"
        assert exc.resource == "/system/file.txt"
        assert "write" in exc.message
        assert "/system/file.txt" in exc.message
    
    def test_action_verification_error(self):
        """Test action verification error."""
        exc = ActionVerificationError(
            action_name="type_text",
            retry_count=3,
            details="Text did not appear in field"
        )
        assert exc.action_name == "type_text"
        assert exc.retry_count == 3
        assert "type_text" in exc.message
        assert "3 retries" in exc.message
    
    def test_window_not_found_error(self):
        """Test window not found error."""
        exc = WindowNotFoundError(
            window_title="Notepad",
            details="Window does not exist",
            available_windows=["Chrome", "Explorer"]
        )
        assert exc.window_title == "Notepad"
        assert "Notepad" in exc.message
        assert exc.context["available_windows"] == ["Chrome", "Explorer"]


class TestResourceErrors:
    """Test resource management error classes."""
    
    def test_resource_cleanup_error(self):
        """
        Test resource cleanup error.
        
        Validates: Requirement 8.5
        """
        exc = ResourceCleanupError(
            resource_type="websocket",
            resource_id="ws123",
            details="Connection already closed"
        )
        assert exc.resource_type == "websocket"
        assert exc.resource_id == "ws123"
        assert "websocket" in exc.message
        assert "ws123" in exc.message
        assert exc.context["resource_type"] == "websocket"
        assert exc.context["resource_id"] == "ws123"
