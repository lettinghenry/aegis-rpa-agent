"""
Resource management and cleanup utilities for AEGIS RPA Backend.

This module provides utilities for managing and cleaning up resources
during normal operation and error conditions.

Validates: Requirements 8.5
"""

import logging
import asyncio
from typing import Optional, List, Callable, Any
from contextlib import asynccontextmanager, contextmanager
from datetime import datetime

from src.exceptions import ResourceCleanupError
from src.logging_utils import get_session_logger

logger = get_session_logger(__name__)


class ResourceManager:
    """
    Manager for tracking and cleaning up resources.
    
    This class maintains a registry of resources that need cleanup
    and ensures they are properly released even in error conditions.
    """
    
    def __init__(self, session_id: str):
        """
        Initialize resource manager for a session.
        
        Args:
            session_id: Session ID for context
        """
        self.session_id = session_id
        self.resources: List[dict] = []
        self._cleanup_handlers: List[Callable] = []
        logger.debug(f"ResourceManager initialized", session_id=session_id)
    
    def register_resource(
        self,
        resource_type: str,
        resource_id: str,
        cleanup_func: Callable,
        resource_data: Optional[Any] = None
    ):
        """
        Register a resource for cleanup.
        
        Args:
            resource_type: Type of resource (e.g., "websocket", "file", "process")
            resource_id: Unique identifier for the resource
            cleanup_func: Function to call for cleanup
            resource_data: Optional data associated with the resource
        """
        resource = {
            "type": resource_type,
            "id": resource_id,
            "cleanup_func": cleanup_func,
            "data": resource_data,
            "registered_at": datetime.now()
        }
        self.resources.append(resource)
        
        logger.debug(
            f"Registered resource: {resource_type}:{resource_id}",
            session_id=self.session_id,
            extra_data={"resource_type": resource_type, "resource_id": resource_id}
        )
    
    def unregister_resource(self, resource_type: str, resource_id: str) -> bool:
        """
        Unregister a resource (without cleanup).
        
        Args:
            resource_type: Type of resource
            resource_id: Resource identifier
        
        Returns:
            True if resource was found and removed, False otherwise
        """
        for i, resource in enumerate(self.resources):
            if resource["type"] == resource_type and resource["id"] == resource_id:
                self.resources.pop(i)
                logger.debug(
                    f"Unregistered resource: {resource_type}:{resource_id}",
                    session_id=self.session_id
                )
                return True
        return False
    
    async def cleanup_all(self, suppress_errors: bool = True):
        """
        Clean up all registered resources.
        
        Args:
            suppress_errors: Whether to suppress cleanup errors (default: True)
        """
        logger.info(
            f"Cleaning up {len(self.resources)} resources",
            session_id=self.session_id
        )
        
        errors = []
        
        # Clean up resources in reverse order (LIFO)
        for resource in reversed(self.resources):
            try:
                cleanup_func = resource["cleanup_func"]
                
                # Handle both sync and async cleanup functions
                if asyncio.iscoroutinefunction(cleanup_func):
                    await cleanup_func()
                else:
                    cleanup_func()
                
                logger.debug(
                    f"Cleaned up resource: {resource['type']}:{resource['id']}",
                    session_id=self.session_id
                )
                
            except Exception as e:
                error_msg = f"Failed to cleanup {resource['type']}:{resource['id']}: {str(e)}"
                logger.error(
                    error_msg,
                    session_id=self.session_id,
                    extra_data={
                        "resource_type": resource['type'],
                        "resource_id": resource['id']
                    }
                )
                
                if not suppress_errors:
                    errors.append(ResourceCleanupError(
                        resource_type=resource['type'],
                        resource_id=resource['id'],
                        details=str(e),
                        session_id=self.session_id
                    ))
        
        # Clear the resources list
        self.resources.clear()
        
        # Raise errors if not suppressing
        if errors and not suppress_errors:
            raise errors[0]  # Raise the first error
        
        logger.info(
            f"Resource cleanup complete",
            session_id=self.session_id,
            extra_data={"error_count": len(errors)}
        )
    
    def cleanup_sync(self, suppress_errors: bool = True):
        """
        Synchronous cleanup for non-async contexts.
        
        Args:
            suppress_errors: Whether to suppress cleanup errors
        """
        logger.info(
            f"Cleaning up {len(self.resources)} resources (sync)",
            session_id=self.session_id
        )
        
        errors = []
        
        for resource in reversed(self.resources):
            try:
                cleanup_func = resource["cleanup_func"]
                
                # Only call if it's a sync function
                if not asyncio.iscoroutinefunction(cleanup_func):
                    cleanup_func()
                    logger.debug(
                        f"Cleaned up resource: {resource['type']}:{resource['id']}",
                        session_id=self.session_id
                    )
                else:
                    logger.warning(
                        f"Skipping async cleanup in sync context: {resource['type']}:{resource['id']}",
                        session_id=self.session_id
                    )
                
            except Exception as e:
                error_msg = f"Failed to cleanup {resource['type']}:{resource['id']}: {str(e)}"
                logger.error(error_msg, session_id=self.session_id)
                
                if not suppress_errors:
                    errors.append(ResourceCleanupError(
                        resource_type=resource['type'],
                        resource_id=resource['id'],
                        details=str(e),
                        session_id=self.session_id
                    ))
        
        self.resources.clear()
        
        if errors and not suppress_errors:
            raise errors[0]


@asynccontextmanager
async def managed_resource(
    resource_manager: ResourceManager,
    resource_type: str,
    resource_id: str,
    cleanup_func: Callable,
    resource_data: Optional[Any] = None
):
    """
    Context manager for automatic resource cleanup.
    
    Args:
        resource_manager: ResourceManager instance
        resource_type: Type of resource
        resource_id: Resource identifier
        cleanup_func: Cleanup function
        resource_data: Optional resource data
    
    Yields:
        The resource data
    
    Example:
        async with managed_resource(rm, "file", "temp.txt", cleanup_func, file_handle):
            # Use the resource
            pass
        # Resource is automatically cleaned up
    """
    resource_manager.register_resource(
        resource_type,
        resource_id,
        cleanup_func,
        resource_data
    )
    
    try:
        yield resource_data
    finally:
        # Cleanup this specific resource
        try:
            if asyncio.iscoroutinefunction(cleanup_func):
                await cleanup_func()
            else:
                cleanup_func()
            
            # Unregister after successful cleanup
            resource_manager.unregister_resource(resource_type, resource_id)
            
        except Exception as e:
            logger.error(
                f"Error cleaning up resource {resource_type}:{resource_id}: {e}",
                session_id=resource_manager.session_id
            )


@contextmanager
def managed_resource_sync(
    resource_manager: ResourceManager,
    resource_type: str,
    resource_id: str,
    cleanup_func: Callable,
    resource_data: Optional[Any] = None
):
    """
    Synchronous context manager for automatic resource cleanup.
    
    Args:
        resource_manager: ResourceManager instance
        resource_type: Type of resource
        resource_id: Resource identifier
        cleanup_func: Cleanup function (must be synchronous)
        resource_data: Optional resource data
    
    Yields:
        The resource data
    """
    resource_manager.register_resource(
        resource_type,
        resource_id,
        cleanup_func,
        resource_data
    )
    
    try:
        yield resource_data
    finally:
        try:
            cleanup_func()
            resource_manager.unregister_resource(resource_type, resource_id)
        except Exception as e:
            logger.error(
                f"Error cleaning up resource {resource_type}:{resource_id}: {e}",
                session_id=resource_manager.session_id
            )


class TimeoutManager:
    """
    Manager for handling operation timeouts.
    
    This class provides utilities for detecting and handling timeouts
    in RPA operations, particularly application launches.
    
    Validates: Requirement 8.2
    """
    
    @staticmethod
    async def wait_with_timeout(
        coro,
        timeout: int,
        operation_name: str,
        session_id: Optional[str] = None
    ):
        """
        Wait for a coroutine with timeout.
        
        Args:
            coro: Coroutine to wait for
            timeout: Timeout in seconds
            operation_name: Name of the operation for error messages
            session_id: Optional session ID for logging
        
        Returns:
            Result of the coroutine
        
        Raises:
            asyncio.TimeoutError: If operation times out
        """
        try:
            logger.debug(
                f"Starting operation with {timeout}s timeout: {operation_name}",
                session_id=session_id
            )
            
            result = await asyncio.wait_for(coro, timeout=timeout)
            
            logger.debug(
                f"Operation completed within timeout: {operation_name}",
                session_id=session_id
            )
            
            return result
            
        except asyncio.TimeoutError:
            logger.error(
                f"Operation timed out after {timeout}s: {operation_name}",
                session_id=session_id,
                extra_data={
                    "operation": operation_name,
                    "timeout": timeout
                }
            )
            raise
    
    @staticmethod
    def wait_sync_with_timeout(
        func: Callable,
        timeout: int,
        operation_name: str,
        session_id: Optional[str] = None,
        poll_interval: float = 0.1
    ) -> Any:
        """
        Wait for a synchronous function with timeout.
        
        Args:
            func: Function to execute (should return True when complete)
            timeout: Timeout in seconds
            operation_name: Name of the operation
            session_id: Optional session ID
            poll_interval: Polling interval in seconds
        
        Returns:
            Result of the function
        
        Raises:
            TimeoutError: If operation times out
        """
        import time
        
        start_time = time.time()
        
        logger.debug(
            f"Starting sync operation with {timeout}s timeout: {operation_name}",
            session_id=session_id
        )
        
        while time.time() - start_time < timeout:
            try:
                result = func()
                if result:
                    logger.debug(
                        f"Sync operation completed: {operation_name}",
                        session_id=session_id
                    )
                    return result
            except Exception as e:
                logger.debug(
                    f"Sync operation check failed: {operation_name} - {e}",
                    session_id=session_id
                )
            
            time.sleep(poll_interval)
        
        # Timeout reached
        elapsed = time.time() - start_time
        logger.error(
            f"Sync operation timed out after {elapsed:.1f}s: {operation_name}",
            session_id=session_id,
            extra_data={
                "operation": operation_name,
                "timeout": timeout,
                "elapsed": elapsed
            }
        )
        
        raise TimeoutError(f"Operation '{operation_name}' timed out after {timeout} seconds")
