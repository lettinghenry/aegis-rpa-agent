"""
Unit tests for resource manager.

Validates: Requirements 8.5
"""

import pytest
import asyncio
from src.resource_manager import ResourceManager, TimeoutManager
from src.exceptions import ResourceCleanupError


class TestResourceManager:
    """Test resource manager functionality."""
    
    def test_register_resource(self):
        """Test registering a resource."""
        rm = ResourceManager("session123")
        
        cleanup_called = []
        
        def cleanup_func():
            cleanup_called.append(True)
        
        rm.register_resource("file", "test.txt", cleanup_func)
        
        assert len(rm.resources) == 1
        assert rm.resources[0]["type"] == "file"
        assert rm.resources[0]["id"] == "test.txt"
    
    def test_unregister_resource(self):
        """Test unregistering a resource."""
        rm = ResourceManager("session123")
        
        def cleanup_func():
            pass
        
        rm.register_resource("file", "test.txt", cleanup_func)
        assert len(rm.resources) == 1
        
        result = rm.unregister_resource("file", "test.txt")
        assert result is True
        assert len(rm.resources) == 0
    
    def test_unregister_nonexistent_resource(self):
        """Test unregistering a resource that doesn't exist."""
        rm = ResourceManager("session123")
        
        result = rm.unregister_resource("file", "nonexistent.txt")
        assert result is False
    
    @pytest.mark.asyncio
    async def test_cleanup_all_sync_resources(self):
        """Test cleaning up synchronous resources."""
        rm = ResourceManager("session123")
        
        cleanup_calls = []
        
        def cleanup1():
            cleanup_calls.append("cleanup1")
        
        def cleanup2():
            cleanup_calls.append("cleanup2")
        
        rm.register_resource("file", "file1.txt", cleanup1)
        rm.register_resource("file", "file2.txt", cleanup2)
        
        await rm.cleanup_all()
        
        # Should be called in reverse order (LIFO)
        assert cleanup_calls == ["cleanup2", "cleanup1"]
        assert len(rm.resources) == 0
    
    @pytest.mark.asyncio
    async def test_cleanup_all_async_resources(self):
        """Test cleaning up asynchronous resources."""
        rm = ResourceManager("session123")
        
        cleanup_calls = []
        
        async def cleanup1():
            cleanup_calls.append("cleanup1")
        
        async def cleanup2():
            cleanup_calls.append("cleanup2")
        
        rm.register_resource("websocket", "ws1", cleanup1)
        rm.register_resource("websocket", "ws2", cleanup2)
        
        await rm.cleanup_all()
        
        # Should be called in reverse order (LIFO)
        assert cleanup_calls == ["cleanup2", "cleanup1"]
        assert len(rm.resources) == 0
    
    @pytest.mark.asyncio
    async def test_cleanup_with_error_suppressed(self):
        """Test cleanup with errors suppressed."""
        rm = ResourceManager("session123")
        
        cleanup_calls = []
        
        def cleanup1():
            cleanup_calls.append("cleanup1")
        
        def cleanup2():
            raise ValueError("Cleanup failed")
        
        def cleanup3():
            cleanup_calls.append("cleanup3")
        
        rm.register_resource("file", "file1.txt", cleanup1)
        rm.register_resource("file", "file2.txt", cleanup2)
        rm.register_resource("file", "file3.txt", cleanup3)
        
        # Should not raise exception
        await rm.cleanup_all(suppress_errors=True)
        
        # Other cleanups should still be called
        assert "cleanup1" in cleanup_calls
        assert "cleanup3" in cleanup_calls
        assert len(rm.resources) == 0
    
    @pytest.mark.asyncio
    async def test_cleanup_with_error_not_suppressed(self):
        """Test cleanup with errors not suppressed."""
        rm = ResourceManager("session123")
        
        def cleanup1():
            pass
        
        def cleanup2():
            raise ValueError("Cleanup failed")
        
        rm.register_resource("file", "file1.txt", cleanup1)
        rm.register_resource("file", "file2.txt", cleanup2)
        
        # Should raise ResourceCleanupError
        with pytest.raises(ResourceCleanupError):
            await rm.cleanup_all(suppress_errors=False)
    
    def test_cleanup_sync(self):
        """Test synchronous cleanup."""
        rm = ResourceManager("session123")
        
        cleanup_calls = []
        
        def cleanup1():
            cleanup_calls.append("cleanup1")
        
        def cleanup2():
            cleanup_calls.append("cleanup2")
        
        rm.register_resource("file", "file1.txt", cleanup1)
        rm.register_resource("file", "file2.txt", cleanup2)
        
        rm.cleanup_sync()
        
        assert cleanup_calls == ["cleanup2", "cleanup1"]
        assert len(rm.resources) == 0


class TestTimeoutManager:
    """Test timeout manager functionality."""
    
    @pytest.mark.asyncio
    async def test_wait_with_timeout_success(self):
        """Test waiting for coroutine that completes within timeout."""
        async def quick_task():
            await asyncio.sleep(0.1)
            return "success"
        
        result = await TimeoutManager.wait_with_timeout(
            quick_task(),
            timeout=1,
            operation_name="quick_task"
        )
        
        assert result == "success"
    
    @pytest.mark.asyncio
    async def test_wait_with_timeout_failure(self):
        """
        Test waiting for coroutine that exceeds timeout.
        
        Validates: Requirement 8.2
        """
        async def slow_task():
            await asyncio.sleep(2)
            return "success"
        
        with pytest.raises(asyncio.TimeoutError):
            await TimeoutManager.wait_with_timeout(
                slow_task(),
                timeout=0.5,
                operation_name="slow_task"
            )
    
    def test_wait_sync_with_timeout_success(self):
        """Test synchronous wait that completes within timeout."""
        call_count = [0]
        
        def check_func():
            call_count[0] += 1
            if call_count[0] >= 3:
                return True
            return False
        
        result = TimeoutManager.wait_sync_with_timeout(
            check_func,
            timeout=2,
            operation_name="check_func",
            poll_interval=0.1
        )
        
        assert result is True
        assert call_count[0] >= 3
    
    def test_wait_sync_with_timeout_failure(self):
        """
        Test synchronous wait that exceeds timeout.
        
        Validates: Requirement 8.2
        """
        def never_ready():
            return False
        
        with pytest.raises(TimeoutError) as exc_info:
            TimeoutManager.wait_sync_with_timeout(
                never_ready,
                timeout=0.5,
                operation_name="never_ready",
                poll_interval=0.1
            )
        
        assert "never_ready" in str(exc_info.value)
        assert "0.5 seconds" in str(exc_info.value)
