"""
WebSocket Manager for AEGIS RPA Backend.

This module manages WebSocket connections for real-time status updates
during task execution. It handles connection lifecycle, message broadcasting,
and window state commands.
"""

from fastapi import WebSocket, WebSocketDisconnect
from typing import Dict, List, Optional, Literal
from datetime import datetime
import json
import logging
from src.models import StatusUpdate

logger = logging.getLogger(__name__)


class WebSocketManager:
    """
    Manages WebSocket connections for real-time execution status updates.
    
    Responsibilities:
    - Accept and register WebSocket connections per session
    - Broadcast status updates to all connected clients for a session
    - Send window state commands (minimal/normal) to frontend
    - Handle connection lifecycle and cleanup
    - Support multiple concurrent connections per session
    """
    
    def __init__(self):
        """Initialize the WebSocket manager with empty connection registry."""
        # Dictionary mapping session_id to list of active WebSocket connections
        self._connections: Dict[str, List[WebSocket]] = {}
        logger.info("WebSocketManager initialized")
    
    async def connect(self, websocket: WebSocket, session_id: str) -> None:
        """
        Accept and register a WebSocket connection for a session.
        
        Args:
            websocket: The WebSocket connection to register
            session_id: The execution session ID this connection is for
        """
        await websocket.accept()
        
        # Initialize connection list for session if it doesn't exist
        if session_id not in self._connections:
            self._connections[session_id] = []
        
        # Add connection to the session's connection list
        self._connections[session_id].append(websocket)
        
        logger.info(
            f"WebSocket connected for session {session_id}. "
            f"Total connections for session: {len(self._connections[session_id])}"
        )
    
    async def disconnect(self, websocket: WebSocket, session_id: str) -> None:
        """
        Remove and close a WebSocket connection.
        
        Args:
            websocket: The WebSocket connection to disconnect
            session_id: The execution session ID
        """
        if session_id in self._connections:
            if websocket in self._connections[session_id]:
                self._connections[session_id].remove(websocket)
                logger.info(
                    f"WebSocket disconnected for session {session_id}. "
                    f"Remaining connections: {len(self._connections[session_id])}"
                )
            
            # Clean up empty connection lists
            if not self._connections[session_id]:
                del self._connections[session_id]
                logger.info(f"All connections closed for session {session_id}")
        
        try:
            await websocket.close()
        except Exception as e:
            logger.warning(f"Error closing WebSocket: {e}")
    
    async def broadcast_update(
        self, 
        session_id: str, 
        update: StatusUpdate
    ) -> None:
        """
        Send a status update to all connected clients for a session.
        
        Args:
            session_id: The execution session ID
            update: The StatusUpdate message to broadcast
        """
        if session_id not in self._connections:
            logger.warning(
                f"No active connections for session {session_id}. "
                f"Update not broadcast: {update.message}"
            )
            return
        
        # Convert update to JSON
        update_json = update.model_dump_json()
        
        # Track disconnected clients for cleanup
        disconnected = []
        
        # Broadcast to all connected clients
        for websocket in self._connections[session_id]:
            try:
                await websocket.send_text(update_json)
                logger.debug(
                    f"Sent update to session {session_id}: {update.message}"
                )
            except WebSocketDisconnect:
                logger.warning(
                    f"Client disconnected during broadcast for session {session_id}"
                )
                disconnected.append(websocket)
            except Exception as e:
                logger.error(
                    f"Error sending update to session {session_id}: {e}"
                )
                disconnected.append(websocket)
        
        # Clean up disconnected clients
        for websocket in disconnected:
            if websocket in self._connections[session_id]:
                self._connections[session_id].remove(websocket)
        
        # Clean up empty connection lists
        if session_id in self._connections and not self._connections[session_id]:
            del self._connections[session_id]
    
    async def send_window_state(
        self, 
        session_id: str, 
        state: Literal["minimal", "normal"]
    ) -> None:
        """
        Send a window state command to the frontend.
        
        This is a helper method that creates a StatusUpdate with the window_state
        field set and broadcasts it to all connected clients.
        
        Args:
            session_id: The execution session ID
            state: The window state to set ("minimal" or "normal")
        """
        # Create a status update with window state command
        update = StatusUpdate(
            session_id=session_id,
            subtask=None,
            overall_status="in_progress",
            message=f"Window state: {state}",
            window_state=state,
            timestamp=datetime.now()
        )
        
        await self.broadcast_update(session_id, update)
        
        logger.info(
            f"Sent window state command '{state}' for session {session_id}"
        )
    
    async def close_all_connections(self, session_id: str) -> None:
        """
        Close all WebSocket connections for a session.
        
        This is typically called when a session completes or is cancelled.
        
        Args:
            session_id: The execution session ID
        """
        if session_id not in self._connections:
            return
        
        connections = self._connections[session_id].copy()
        
        for websocket in connections:
            try:
                await websocket.close()
            except Exception as e:
                logger.warning(
                    f"Error closing WebSocket for session {session_id}: {e}"
                )
        
        # Clean up connection list
        if session_id in self._connections:
            del self._connections[session_id]
        
        logger.info(f"Closed all connections for session {session_id}")
    
    def get_connection_count(self, session_id: str) -> int:
        """
        Get the number of active connections for a session.
        
        Args:
            session_id: The execution session ID
            
        Returns:
            Number of active WebSocket connections for the session
        """
        if session_id not in self._connections:
            return 0
        return len(self._connections[session_id])
    
    def has_connections(self, session_id: str) -> bool:
        """
        Check if a session has any active connections.
        
        Args:
            session_id: The execution session ID
            
        Returns:
            True if the session has at least one active connection
        """
        return self.get_connection_count(session_id) > 0
