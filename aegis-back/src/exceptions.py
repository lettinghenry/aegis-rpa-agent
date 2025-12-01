"""
Custom exception classes for AEGIS RPA Backend.

This module defines structured exception classes for different error categories,
enabling consistent error handling and reporting throughout the application.

Validates: Requirements 8.1, 8.2, 8.3
"""

from typing import Optional, Dict, Any


class AEGISException(Exception):
    """
    Base exception class for all AEGIS-specific errors.
    
    All custom exceptions inherit from this class to enable
    centralized exception handling.
    """
    
    def __init__(
        self,
        message: str,
        details: Optional[str] = None,
        session_id: Optional[str] = None,
        context: Optional[Dict[str, Any]] = None
    ):
        """
        Initialize AEGIS exception.
        
        Args:
            message: Human-readable error message
            details: Additional error details
            session_id: Associated session ID (if applicable)
            context: Additional context information
        """
        super().__init__(message)
        self.message = message
        self.details = details
        self.session_id = session_id
        self.context = context or {}
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convert exception to dictionary for API responses.
        
        Returns:
            Dictionary representation of the error
        """
        result = {
            "error": self.__class__.__name__,
            "message": self.message
        }
        
        if self.details:
            result["details"] = self.details
        
        if self.session_id:
            result["session_id"] = self.session_id
        
        if self.context:
            result["context"] = self.context
        
        return result


# Validation Errors (HTTP 422)

class ValidationError(AEGISException):
    """
    Exception raised when input validation fails.
    
    Examples:
    - Empty or malformed instructions
    - Missing required fields
    - Invalid data types
    
    Validates: Requirement 9.2
    """
    pass


class InstructionValidationError(ValidationError):
    """Exception raised when task instruction validation fails."""
    pass


class FieldValidationError(ValidationError):
    """Exception raised when a specific field fails validation."""
    
    def __init__(
        self,
        field_name: str,
        message: str,
        details: Optional[str] = None,
        session_id: Optional[str] = None
    ):
        """
        Initialize field validation error.
        
        Args:
            field_name: Name of the field that failed validation
            message: Error message
            details: Additional details
            session_id: Associated session ID
        """
        super().__init__(
            message=message,
            details=details,
            session_id=session_id,
            context={"field": field_name}
        )
        self.field_name = field_name


# Client Errors (HTTP 400)

class ClientError(AEGISException):
    """
    Exception raised for client-side errors.
    
    Examples:
    - Invalid session ID
    - Session already completed/cancelled
    - Invalid operation for current state
    """
    pass


class SessionNotFoundError(ClientError):
    """Exception raised when a session cannot be found."""
    
    def __init__(self, session_id: str, details: Optional[str] = None):
        """
        Initialize session not found error.
        
        Args:
            session_id: The session ID that was not found
            details: Additional details
        """
        super().__init__(
            message=f"Session {session_id} not found",
            details=details,
            session_id=session_id
        )


class InvalidSessionStateError(ClientError):
    """Exception raised when an operation is invalid for the current session state."""
    
    def __init__(
        self,
        session_id: str,
        current_state: str,
        operation: str,
        details: Optional[str] = None
    ):
        """
        Initialize invalid session state error.
        
        Args:
            session_id: The session ID
            current_state: Current session state
            operation: Operation that was attempted
            details: Additional details
        """
        super().__init__(
            message=f"Cannot perform '{operation}' on session in state '{current_state}'",
            details=details,
            session_id=session_id,
            context={
                "current_state": current_state,
                "operation": operation
            }
        )


# System Errors (HTTP 500)

class SystemError(AEGISException):
    """
    Exception raised for system-level errors.
    
    Examples:
    - ADK agent initialization failure
    - RPA tool execution failure
    - File system errors
    - Database errors
    
    Validates: Requirement 8.1
    """
    pass


class ADKAgentError(SystemError):
    """Exception raised when ADK agent operations fail."""
    pass


class RPAToolError(SystemError):
    """Exception raised when RPA tool execution fails."""
    
    def __init__(
        self,
        tool_name: str,
        message: str,
        details: Optional[str] = None,
        session_id: Optional[str] = None,
        tool_args: Optional[Dict[str, Any]] = None
    ):
        """
        Initialize RPA tool error.
        
        Args:
            tool_name: Name of the tool that failed
            message: Error message
            details: Additional details
            session_id: Associated session ID
            tool_args: Arguments passed to the tool
        """
        super().__init__(
            message=message,
            details=details,
            session_id=session_id,
            context={
                "tool_name": tool_name,
                "tool_args": tool_args or {}
            }
        )
        self.tool_name = tool_name


class StorageError(SystemError):
    """Exception raised when storage operations fail."""
    pass


class CacheError(SystemError):
    """Exception raised when cache operations fail."""
    pass


# RPA Execution Errors

class RPAExecutionError(AEGISException):
    """
    Base exception for RPA execution errors.
    
    Examples:
    - Application launch failure
    - UI element not found
    - Permission denied
    - Timeout errors
    """
    pass


class ApplicationLaunchError(RPAExecutionError):
    """
    Exception raised when an application fails to launch.
    
    Validates: Requirement 8.2
    """
    
    def __init__(
        self,
        app_name: str,
        timeout: int,
        details: Optional[str] = None,
        session_id: Optional[str] = None
    ):
        """
        Initialize application launch error.
        
        Args:
            app_name: Name of the application that failed to launch
            timeout: Timeout value in seconds
            details: Additional details
            session_id: Associated session ID
        """
        super().__init__(
            message=f"Application '{app_name}' failed to launch within {timeout} seconds",
            details=details,
            session_id=session_id,
            context={
                "app_name": app_name,
                "timeout": timeout
            }
        )
        self.app_name = app_name
        self.timeout = timeout


class ElementNotFoundError(RPAExecutionError):
    """
    Exception raised when a UI element cannot be found.
    
    Validates: Requirement 8.3
    """
    
    def __init__(
        self,
        element_description: str,
        search_method: str,
        search_value: Any,
        details: Optional[str] = None,
        session_id: Optional[str] = None,
        screenshot_path: Optional[str] = None
    ):
        """
        Initialize element not found error.
        
        Args:
            element_description: Human-readable description of the element
            search_method: Method used to search (e.g., "coordinates", "image", "xpath")
            search_value: Value used in the search
            details: Additional details
            session_id: Associated session ID
            screenshot_path: Path to screenshot for debugging
        """
        super().__init__(
            message=f"UI element not found: {element_description}",
            details=details,
            session_id=session_id,
            context={
                "element_description": element_description,
                "search_method": search_method,
                "search_value": search_value,
                "screenshot_path": screenshot_path
            }
        )
        self.element_description = element_description
        self.search_method = search_method
        self.search_value = search_value


class ActionTimeoutError(RPAExecutionError):
    """Exception raised when an action times out."""
    
    def __init__(
        self,
        action_name: str,
        timeout: int,
        details: Optional[str] = None,
        session_id: Optional[str] = None
    ):
        """
        Initialize action timeout error.
        
        Args:
            action_name: Name of the action that timed out
            timeout: Timeout value in seconds
            details: Additional details
            session_id: Associated session ID
        """
        super().__init__(
            message=f"Action '{action_name}' timed out after {timeout} seconds",
            details=details,
            session_id=session_id,
            context={
                "action_name": action_name,
                "timeout": timeout
            }
        )
        self.action_name = action_name
        self.timeout = timeout


class PermissionDeniedError(RPAExecutionError):
    """Exception raised when a permission error occurs."""
    
    def __init__(
        self,
        operation: str,
        resource: str,
        details: Optional[str] = None,
        session_id: Optional[str] = None
    ):
        """
        Initialize permission denied error.
        
        Args:
            operation: Operation that was denied
            resource: Resource that was being accessed
            details: Additional details
            session_id: Associated session ID
        """
        super().__init__(
            message=f"Permission denied for operation '{operation}' on resource '{resource}'",
            details=details,
            session_id=session_id,
            context={
                "operation": operation,
                "resource": resource
            }
        )
        self.operation = operation
        self.resource = resource


class ActionVerificationError(RPAExecutionError):
    """Exception raised when action verification fails after all retries."""
    
    def __init__(
        self,
        action_name: str,
        retry_count: int,
        details: Optional[str] = None,
        session_id: Optional[str] = None
    ):
        """
        Initialize action verification error.
        
        Args:
            action_name: Name of the action that failed verification
            retry_count: Number of retries attempted
            details: Additional details
            session_id: Associated session ID
        """
        super().__init__(
            message=f"Action '{action_name}' failed verification after {retry_count} retries",
            details=details,
            session_id=session_id,
            context={
                "action_name": action_name,
                "retry_count": retry_count
            }
        )
        self.action_name = action_name
        self.retry_count = retry_count


class WindowNotFoundError(RPAExecutionError):
    """Exception raised when a window cannot be found."""
    
    def __init__(
        self,
        window_title: str,
        details: Optional[str] = None,
        session_id: Optional[str] = None,
        available_windows: Optional[list] = None
    ):
        """
        Initialize window not found error.
        
        Args:
            window_title: Title of the window that was not found
            details: Additional details
            session_id: Associated session ID
            available_windows: List of available window titles
        """
        super().__init__(
            message=f"Window '{window_title}' not found",
            details=details,
            session_id=session_id,
            context={
                "window_title": window_title,
                "available_windows": available_windows or []
            }
        )
        self.window_title = window_title


# Resource Management Errors

class ResourceCleanupError(SystemError):
    """Exception raised when resource cleanup fails."""
    
    def __init__(
        self,
        resource_type: str,
        resource_id: str,
        details: Optional[str] = None,
        session_id: Optional[str] = None
    ):
        """
        Initialize resource cleanup error.
        
        Args:
            resource_type: Type of resource (e.g., "websocket", "file", "process")
            resource_id: Identifier for the resource
            details: Additional details
            session_id: Associated session ID
        """
        super().__init__(
            message=f"Failed to cleanup {resource_type} resource: {resource_id}",
            details=details,
            session_id=session_id,
            context={
                "resource_type": resource_type,
                "resource_id": resource_id
            }
        )
        self.resource_type = resource_type
        self.resource_id = resource_id
