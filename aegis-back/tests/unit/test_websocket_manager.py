"""
Unit tests for WebSocket Manager.

Tests WebSocket connection management, message broadcasting,
and window state commands.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime
from src.websocket_manager import WebSocketManager
from src.models import StatusUpdate, Subtask, SubtaskStatus


class TestWebSocketManager:
    """Test suite for WebSocket Manager."""
    
    @pytest.mark.asyncio
    async def test_connect_accepts_websocket(self):
        """Test that connect() accepts and registers a WebSocket connection."""
        manager = WebSocketManager()
        websocket = AsyncMock()
        session_id = "test-session-123"
        
        await manager.connect(websocket, session_id)
        
        # Verify websocket.accept() was called
        websocket.accept.assert_called_once()
        
        # Verify connection was registered
        assert manager.has_connections(session_id)
        assert manager.get_connection_count(session_id) == 1
    
    @pytest.mark.asyncio
    async def test_connect_multiple_connections_per_session(self):
        """Test that multiple connections can be registered for the same session."""
        manager = WebSocketManager()
        websocket1 = AsyncMock()
        websocket2 = AsyncMock()
        session_id = "test-session-123"
        
        await manager.connect(websocket1, session_id)
        await manager.connect(websocket2, session_id)
        
        # Verify both connections are registered
        assert manager.get_connection_count(session_id) == 2
    
    @pytest.mark.asyncio
    async def test_disconnect_removes_connection(self):
        """Test that disconnect() removes and closes a WebSocket connection."""
        manager = WebSocketManager()
        websocket = AsyncMock()
        session_id = "test-session-123"
        
        await manager.connect(websocket, session_id)
        await manager.disconnect(websocket, session_id)
        
        # Verify websocket.close() was called
        websocket.close.assert_called_once()
        
        # Verify connection was removed
        assert not manager.has_connections(session_id)
        assert manager.get_connection_count(session_id) == 0
    
    @pytest.mark.asyncio
    async def test_broadcast_update_sends_to_all_connections(self):
        """Test that broadcast_update() sends messages to all connected clients."""
        manager = WebSocketManager()
        websocket1 = AsyncMock()
        websocket2 = AsyncMock()
        session_id = "test-session-123"
        
        await manager.connect(websocket1, session_id)
        await manager.connect(websocket2, session_id)
        
        # Create a status update
        update = StatusUpdate(
            session_id=session_id,
            subtask=None,
            overall_status="in_progress",
            message="Test message",
            window_state=None,
            timestamp=datetime.now()
        )
        
        await manager.broadcast_update(session_id, update)
        
        # Verify both websockets received the message
        websocket1.send_text.assert_called_once()
        websocket2.send_text.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_broadcast_update_with_window_state(self):
        """Test that broadcast_update() includes window_state field."""
        manager = WebSocketManager()
        websocket = AsyncMock()
        session_id = "test-session-123"
        
        await manager.connect(websocket, session_id)
        
        # Create a status update with window state
        update = StatusUpdate(
            session_id=session_id,
            subtask=None,
            overall_status="in_progress",
            message="Minimizing window",
            window_state="minimal",
            timestamp=datetime.now()
        )
        
        await manager.broadcast_update(session_id, update)
        
        # Verify message was sent
        websocket.send_text.assert_called_once()
        
        # Verify the sent message contains window_state
        sent_message = websocket.send_text.call_args[0][0]
        assert "window_state" in sent_message
        assert "minimal" in sent_message
    
    @pytest.mark.asyncio
    async def test_send_window_state_minimal(self):
        """Test send_window_state() with 'minimal' state."""
        manager = WebSocketManager()
        websocket = AsyncMock()
        session_id = "test-session-123"
        
        await manager.connect(websocket, session_id)
        await manager.send_window_state(session_id, "minimal")
        
        # Verify message was sent
        websocket.send_text.assert_called_once()
        
        # Verify the message contains window_state: minimal
        sent_message = websocket.send_text.call_args[0][0]
        assert "window_state" in sent_message
        assert "minimal" in sent_message
    
    @pytest.mark.asyncio
    async def test_send_window_state_normal(self):
        """Test send_window_state() with 'normal' state."""
        manager = WebSocketManager()
        websocket = AsyncMock()
        session_id = "test-session-123"
        
        await manager.connect(websocket, session_id)
        await manager.send_window_state(session_id, "normal")
        
        # Verify message was sent
        websocket.send_text.assert_called_once()
        
        # Verify the message contains window_state: normal
        sent_message = websocket.send_text.call_args[0][0]
        assert "window_state" in sent_message
        assert "normal" in sent_message
    
    @pytest.mark.asyncio
    async def test_close_all_connections(self):
        """Test that close_all_connections() closes all connections for a session."""
        manager = WebSocketManager()
        websocket1 = AsyncMock()
        websocket2 = AsyncMock()
        session_id = "test-session-123"
        
        await manager.connect(websocket1, session_id)
        await manager.connect(websocket2, session_id)
        
        await manager.close_all_connections(session_id)
        
        # Verify both websockets were closed
        websocket1.close.assert_called_once()
        websocket2.close.assert_called_once()
        
        # Verify connections were removed
        assert not manager.has_connections(session_id)
    
    @pytest.mark.asyncio
    async def test_broadcast_to_nonexistent_session(self):
        """Test that broadcasting to a session with no connections doesn't error."""
        manager = WebSocketManager()
        session_id = "nonexistent-session"
        
        update = StatusUpdate(
            session_id=session_id,
            subtask=None,
            overall_status="in_progress",
            message="Test message",
            window_state=None,
            timestamp=datetime.now()
        )
        
        # Should not raise an exception
        await manager.broadcast_update(session_id, update)
    
    @pytest.mark.asyncio
    async def test_has_connections_returns_false_for_new_session(self):
        """Test that has_connections() returns False for sessions with no connections."""
        manager = WebSocketManager()
        session_id = "new-session"
        
        assert not manager.has_connections(session_id)
    
    @pytest.mark.asyncio
    async def test_get_connection_count_returns_zero_for_new_session(self):
        """Test that get_connection_count() returns 0 for sessions with no connections."""
        manager = WebSocketManager()
        session_id = "new-session"
        
        assert manager.get_connection_count(session_id) == 0
