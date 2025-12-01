"""
Unit tests for logging utilities.

Validates: Requirements 6.1, 6.2, 6.3, 8.1
"""

import pytest
import logging
from src.logging_utils import (
    SessionContextFilter,
    SessionLogger,
    setup_logging,
    get_session_logger,
    set_session_context,
    clear_session_context,
    log_action_start,
    log_action_complete
)


class TestSessionContextFilter:
    """Test session context filter."""
    
    def test_filter_adds_session_id(self):
        """Test that filter adds session ID to log record."""
        filter_obj = SessionContextFilter()
        record = logging.LogRecord(
            name="test",
            level=logging.INFO,
            pathname="",
            lineno=0,
            msg="Test message",
            args=(),
            exc_info=None
        )
        
        # Set session context
        token = set_session_context("session123")
        
        # Apply filter
        result = filter_obj.filter(record)
        
        assert result is True
        assert hasattr(record, 'session_id')
        assert record.session_id == "session123"
        
        # Clear context
        clear_session_context(token)
    
    def test_filter_with_no_session(self):
        """Test filter when no session context is set."""
        filter_obj = SessionContextFilter()
        record = logging.LogRecord(
            name="test",
            level=logging.INFO,
            pathname="",
            lineno=0,
            msg="Test message",
            args=(),
            exc_info=None
        )
        
        # Clear any existing context
        clear_session_context()
        
        # Apply filter
        result = filter_obj.filter(record)
        
        assert result is True
        assert hasattr(record, 'session_id')
        assert record.session_id == "N/A"


class TestSessionLogger:
    """Test session logger wrapper."""
    
    def test_logger_with_session_id(self, caplog):
        """Test logging with explicit session ID."""
        logger = logging.getLogger("test_logger")
        session_logger = SessionLogger(logger)
        
        with caplog.at_level(logging.INFO):
            session_logger.info("Test message", session_id="session123")
        
        assert len(caplog.records) == 1
        assert caplog.records[0].message == "Test message"
    
    def test_logger_with_extra_data(self, caplog):
        """Test logging with extra data."""
        logger = logging.getLogger("test_logger")
        session_logger = SessionLogger(logger)
        
        with caplog.at_level(logging.INFO):
            session_logger.info(
                "Test message",
                session_id="session123",
                extra_data={"key": "value"}
            )
        
        assert len(caplog.records) == 1
        assert hasattr(caplog.records[0], 'extra_data')
        assert caplog.records[0].extra_data == {"key": "value"}
    
    def test_logger_error_with_exc_info(self, caplog):
        """Test error logging with exception info."""
        logger = logging.getLogger("test_logger")
        session_logger = SessionLogger(logger)
        
        try:
            raise ValueError("Test error")
        except ValueError:
            with caplog.at_level(logging.ERROR):
                session_logger.error("Error occurred", session_id="session123")
        
        assert len(caplog.records) == 1
        assert caplog.records[0].levelname == "ERROR"


class TestSessionContext:
    """Test session context management."""
    
    def test_set_and_clear_context(self):
        """Test setting and clearing session context."""
        # Set context
        token = set_session_context("session123")
        
        # Verify context is set (indirectly through filter)
        filter_obj = SessionContextFilter()
        record = logging.LogRecord(
            name="test",
            level=logging.INFO,
            pathname="",
            lineno=0,
            msg="Test",
            args=(),
            exc_info=None
        )
        filter_obj.filter(record)
        assert record.session_id == "session123"
        
        # Clear context
        clear_session_context(token)
        
        # Verify context is cleared
        record2 = logging.LogRecord(
            name="test",
            level=logging.INFO,
            pathname="",
            lineno=0,
            msg="Test",
            args=(),
            exc_info=None
        )
        filter_obj.filter(record2)
        assert record2.session_id == "N/A"
    
    def test_nested_contexts(self):
        """Test nested session contexts."""
        # Set first context
        token1 = set_session_context("session1")
        
        # Set second context
        token2 = set_session_context("session2")
        
        # Verify second context is active
        filter_obj = SessionContextFilter()
        record = logging.LogRecord(
            name="test",
            level=logging.INFO,
            pathname="",
            lineno=0,
            msg="Test",
            args=(),
            exc_info=None
        )
        filter_obj.filter(record)
        assert record.session_id == "session2"
        
        # Reset to first context
        clear_session_context(token2)
        
        record2 = logging.LogRecord(
            name="test",
            level=logging.INFO,
            pathname="",
            lineno=0,
            msg="Test",
            args=(),
            exc_info=None
        )
        filter_obj.filter(record2)
        assert record2.session_id == "session1"
        
        # Clear first context
        clear_session_context(token1)


class TestActionLogging:
    """Test action logging utilities."""
    
    def test_log_action_start(self, caplog):
        """Test logging action start."""
        logger = logging.getLogger("test_action")
        
        with caplog.at_level(logging.INFO):
            log_action_start(
                logger,
                "click_element",
                "session123",
                {"x": 100, "y": 200}
            )
        
        assert len(caplog.records) == 1
        assert "Starting action: click_element" in caplog.records[0].message
        assert hasattr(caplog.records[0], 'extra_data')
        assert caplog.records[0].extra_data["action"] == "click_element"
        assert caplog.records[0].extra_data["params"] == {"x": 100, "y": 200}
    
    def test_log_action_complete_success(self, caplog):
        """Test logging successful action completion."""
        logger = logging.getLogger("test_action")
        
        with caplog.at_level(logging.INFO):
            log_action_complete(
                logger,
                "click_element",
                "session123",
                success=True,
                retry_count=0
            )
        
        assert len(caplog.records) == 1
        assert "Action completed successfully" in caplog.records[0].message
        assert "click_element" in caplog.records[0].message
        assert caplog.records[0].extra_data["success"] is True
        assert caplog.records[0].extra_data["retry_count"] == 0
    
    def test_log_action_complete_failure(self, caplog):
        """Test logging failed action completion."""
        logger = logging.getLogger("test_action")
        
        with caplog.at_level(logging.ERROR):
            log_action_complete(
                logger,
                "click_element",
                "session123",
                success=False,
                retry_count=3,
                error="Element not found"
            )
        
        assert len(caplog.records) == 1
        assert "Action failed" in caplog.records[0].message
        assert "click_element" in caplog.records[0].message
        assert "3 retries" in caplog.records[0].message
        assert caplog.records[0].extra_data["success"] is False
        assert caplog.records[0].extra_data["error"] == "Element not found"


class TestSetupLogging:
    """Test logging setup."""
    
    def test_setup_logging_basic(self):
        """Test basic logging setup."""
        setup_logging(log_level="DEBUG")
        
        root_logger = logging.getLogger()
        assert root_logger.level == logging.DEBUG
        assert len(root_logger.handlers) > 0
    
    def test_get_session_logger(self):
        """Test getting a session logger."""
        session_logger = get_session_logger("test_module")
        
        assert isinstance(session_logger, SessionLogger)
        assert session_logger.logger.name == "test_module"
