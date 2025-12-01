"""
Logging utilities for AEGIS RPA Backend.

This module provides structured logging with session context,
enabling better traceability and debugging of execution flows.

Validates: Requirements 6.1, 6.2, 6.3, 8.1
"""

import logging
import sys
from typing import Optional, Dict, Any
from datetime import datetime
from contextvars import ContextVar
import json


# Context variable to store current session ID
current_session_id: ContextVar[Optional[str]] = ContextVar('current_session_id', default=None)


class SessionContextFilter(logging.Filter):
    """
    Logging filter that adds session context to log records.
    
    This filter automatically includes the current session ID in all log messages,
    making it easier to trace execution flows across multiple sessions.
    """
    
    def filter(self, record: logging.LogRecord) -> bool:
        """
        Add session context to log record.
        
        Args:
            record: Log record to filter
        
        Returns:
            True (always allow the record)
        """
        # Get current session ID from context
        session_id = current_session_id.get()
        record.session_id = session_id if session_id else "N/A"
        return True


class StructuredFormatter(logging.Formatter):
    """
    Formatter that outputs structured JSON logs.
    
    This formatter creates JSON-formatted log entries that are easier
    to parse and analyze in log aggregation systems.
    """
    
    def format(self, record: logging.LogRecord) -> str:
        """
        Format log record as JSON.
        
        Args:
            record: Log record to format
        
        Returns:
            JSON-formatted log string
        """
        log_data = {
            "timestamp": datetime.fromtimestamp(record.created).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "session_id": getattr(record, 'session_id', 'N/A')
        }
        
        # Add exception info if present
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)
        
        # Add extra fields if present
        if hasattr(record, 'extra_data'):
            log_data["extra"] = record.extra_data
        
        return json.dumps(log_data)


class SessionLogger:
    """
    Logger wrapper that automatically includes session context.
    
    This class provides a convenient interface for logging with
    automatic session ID inclusion and structured data support.
    """
    
    def __init__(self, logger: logging.Logger):
        """
        Initialize session logger.
        
        Args:
            logger: Underlying Python logger
        """
        self.logger = logger
    
    def _log(
        self,
        level: int,
        message: str,
        session_id: Optional[str] = None,
        extra_data: Optional[Dict[str, Any]] = None,
        exc_info: bool = False
    ):
        """
        Internal logging method with session context.
        
        Args:
            level: Log level
            message: Log message
            session_id: Optional session ID (overrides context)
            extra_data: Optional extra data to include
            exc_info: Whether to include exception info
        """
        # Use provided session_id or get from context
        if session_id:
            token = current_session_id.set(session_id)
        
        # Create extra dict for structured data
        extra = {}
        if extra_data:
            extra['extra_data'] = extra_data
        
        # Log the message
        self.logger.log(level, message, extra=extra, exc_info=exc_info)
        
        # Reset context if we set it
        if session_id:
            current_session_id.reset(token)
    
    def debug(
        self,
        message: str,
        session_id: Optional[str] = None,
        extra_data: Optional[Dict[str, Any]] = None
    ):
        """Log debug message with session context."""
        self._log(logging.DEBUG, message, session_id, extra_data)
    
    def info(
        self,
        message: str,
        session_id: Optional[str] = None,
        extra_data: Optional[Dict[str, Any]] = None
    ):
        """Log info message with session context."""
        self._log(logging.INFO, message, session_id, extra_data)
    
    def warning(
        self,
        message: str,
        session_id: Optional[str] = None,
        extra_data: Optional[Dict[str, Any]] = None
    ):
        """Log warning message with session context."""
        self._log(logging.WARNING, message, session_id, extra_data)
    
    def error(
        self,
        message: str,
        session_id: Optional[str] = None,
        extra_data: Optional[Dict[str, Any]] = None,
        exc_info: bool = True
    ):
        """Log error message with session context and exception info."""
        self._log(logging.ERROR, message, session_id, extra_data, exc_info)
    
    def critical(
        self,
        message: str,
        session_id: Optional[str] = None,
        extra_data: Optional[Dict[str, Any]] = None,
        exc_info: bool = True
    ):
        """Log critical message with session context and exception info."""
        self._log(logging.CRITICAL, message, session_id, extra_data, exc_info)


def setup_logging(
    log_level: str = "INFO",
    use_json: bool = False,
    log_file: Optional[str] = None
) -> None:
    """
    Configure application-wide logging.
    
    Args:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        use_json: Whether to use JSON formatting
        log_file: Optional log file path
    """
    # Convert log level string to constant
    level = getattr(logging, log_level.upper(), logging.INFO)
    
    # Create formatter
    if use_json:
        formatter = StructuredFormatter()
    else:
        formatter = logging.Formatter(
            '%(asctime)s - [%(session_id)s] - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
    
    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(level)
    
    # Remove existing handlers
    root_logger.handlers.clear()
    
    # Add console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level)
    console_handler.setFormatter(formatter)
    console_handler.addFilter(SessionContextFilter())
    root_logger.addHandler(console_handler)
    
    # Add file handler if specified
    if log_file:
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(level)
        file_handler.setFormatter(formatter)
        file_handler.addFilter(SessionContextFilter())
        root_logger.addHandler(file_handler)


def get_session_logger(name: str) -> SessionLogger:
    """
    Get a session-aware logger for a module.
    
    Args:
        name: Logger name (typically __name__)
    
    Returns:
        SessionLogger instance
    """
    logger = logging.getLogger(name)
    return SessionLogger(logger)


def set_session_context(session_id: str) -> Any:
    """
    Set the current session ID in context.
    
    Args:
        session_id: Session ID to set
    
    Returns:
        Context token for resetting
    """
    return current_session_id.set(session_id)


def clear_session_context(token: Any = None) -> None:
    """
    Clear the current session ID from context.
    
    Args:
        token: Optional token from set_session_context to reset to previous value
    """
    if token:
        current_session_id.reset(token)
    else:
        current_session_id.set(None)


def log_exception(
    logger: logging.Logger,
    exception: Exception,
    session_id: Optional[str] = None,
    context: Optional[Dict[str, Any]] = None
):
    """
    Log an exception with full context.
    
    Args:
        logger: Logger to use
        exception: Exception to log
        session_id: Optional session ID
        context: Optional context information
    """
    # Set session context if provided
    if session_id:
        token = current_session_id.set(session_id)
    
    # Build error message
    error_msg = f"Exception occurred: {type(exception).__name__}: {str(exception)}"
    
    # Add context if provided
    extra = {}
    if context:
        extra['extra_data'] = context
    
    # Log the exception
    logger.error(error_msg, extra=extra, exc_info=True)
    
    # Reset context if we set it
    if session_id:
        current_session_id.reset(token)


def log_action_start(
    logger: logging.Logger,
    action_name: str,
    session_id: str,
    action_params: Optional[Dict[str, Any]] = None
):
    """
    Log the start of an RPA action.
    
    Args:
        logger: Logger to use
        action_name: Name of the action
        session_id: Session ID
        action_params: Optional action parameters
    """
    token = current_session_id.set(session_id)
    
    extra = {'extra_data': {
        'action': action_name,
        'params': action_params or {}
    }}
    
    logger.info(f"Starting action: {action_name}", extra=extra)
    current_session_id.reset(token)


def log_action_complete(
    logger: logging.Logger,
    action_name: str,
    session_id: str,
    success: bool,
    retry_count: int = 0,
    error: Optional[str] = None
):
    """
    Log the completion of an RPA action.
    
    Args:
        logger: Logger to use
        action_name: Name of the action
        session_id: Session ID
        success: Whether the action succeeded
        retry_count: Number of retries
        error: Optional error message
    """
    token = current_session_id.set(session_id)
    
    extra = {'extra_data': {
        'action': action_name,
        'success': success,
        'retry_count': retry_count,
        'error': error
    }}
    
    if success:
        logger.info(
            f"Action completed successfully: {action_name} (retries: {retry_count})",
            extra=extra
        )
    else:
        logger.error(
            f"Action failed: {action_name} after {retry_count} retries - {error}",
            extra=extra
        )
    
    current_session_id.reset(token)
