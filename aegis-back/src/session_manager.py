"""
Session Manager for AEGIS RPA Backend.

This module manages the lifecycle of execution sessions, including creation,
state tracking, updates, and cancellation. It coordinates with WebSocket
manager for status updates and history store for persistence.

Requirements: 3.1, 3.5, 8.5
"""

import uuid
from datetime import datetime, timezone
from typing import Optional, Dict, List
from threading import Lock

from src.models import (
    ExecutionSession,
    Subtask,
    SubtaskStatus,
    StatusUpdate
)


class SessionUpdate:
    """Model for session updates."""
    def __init__(
        self,
        status: Optional[str] = None,
        subtask: Optional[Subtask] = None,
        completed_at: Optional[datetime] = None
    ):
        self.status = status
        self.subtask = subtask
        self.completed_at = completed_at


class SessionManager:
    """
    Manages execution session lifecycle and state.
    
    Responsibilities:
    - Create new execution sessions with unique IDs
    - Track session state and progress
    - Update sessions with subtask results
    - Handle session cancellation
    - Provide thread-safe access to session data
    """
    
    def __init__(self):
        """Initialize the session manager with empty session storage."""
        self._sessions: Dict[str, ExecutionSession] = {}
        self._lock = Lock()
    
    def create_session(self, instruction: str) -> str:
        """
        Create a new execution session with a unique session ID.
        
        Args:
            instruction: The natural language task instruction
            
        Returns:
            str: Unique session ID (UUID)
            
        Requirements:
            - 3.1: Return unique execution session ID
        """
        session_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc)
        
        session = ExecutionSession(
            session_id=session_id,
            instruction=instruction,
            status="pending",
            subtasks=[],
            created_at=now,
            updated_at=now,
            completed_at=None
        )
        
        with self._lock:
            self._sessions[session_id] = session
        
        return session_id
    
    def get_session(self, session_id: str) -> Optional[ExecutionSession]:
        """
        Retrieve a session by its ID.
        
        Args:
            session_id: The unique session identifier
            
        Returns:
            Optional[ExecutionSession]: The session if found, None otherwise
        """
        with self._lock:
            return self._sessions.get(session_id)
    
    def update_session(
        self,
        session_id: str,
        update: Optional[SessionUpdate | StatusUpdate]
    ) -> bool:
        """
        Update a session with new status, subtask, or completion time.
        
        Args:
            session_id: The unique session identifier
            update: SessionUpdate or StatusUpdate containing the changes to apply,
                   or None to just update the timestamp
            
        Returns:
            bool: True if update succeeded, False if session not found
            
        Requirements:
            - 3.5: Track session state and subtask progress
        """
        with self._lock:
            session = self._sessions.get(session_id)
            if not session:
                return False
            
            # Handle None update (just update timestamp)
            if update is None:
                session.updated_at = datetime.now(timezone.utc)
                return True
            
            # Handle StatusUpdate from models.py (from ADK agent)
            if isinstance(update, StatusUpdate):
                # Update status from overall_status
                if update.overall_status:
                    session.status = update.overall_status
                
                # Add or update subtask if provided
                if update.subtask:
                    # Check if subtask already exists (update case)
                    existing_index = None
                    for i, st in enumerate(session.subtasks):
                        if st.id == update.subtask.id:
                            existing_index = i
                            break
                    
                    if existing_index is not None:
                        # Update existing subtask
                        session.subtasks[existing_index] = update.subtask
                    else:
                        # Add new subtask
                        session.subtasks.append(update.subtask)
            
            # Handle SessionUpdate from session_manager.py
            else:
                # Update status if provided
                if update.status:
                    session.status = update.status
                
                # Add or update subtask if provided
                if update.subtask:
                    # Check if subtask already exists (update case)
                    existing_index = None
                    for i, st in enumerate(session.subtasks):
                        if st.id == update.subtask.id:
                            existing_index = i
                            break
                    
                    if existing_index is not None:
                        # Update existing subtask
                        session.subtasks[existing_index] = update.subtask
                    else:
                        # Add new subtask
                        session.subtasks.append(update.subtask)
                
                # Update completion time if provided
                if update.completed_at:
                    session.completed_at = update.completed_at
            
            # Always update the updated_at timestamp
            session.updated_at = datetime.now(timezone.utc)
            
            return True
    
    def cancel_session(self, session_id: str) -> bool:
        """
        Cancel an ongoing execution session.
        
        Args:
            session_id: The unique session identifier
            
        Returns:
            bool: True if cancellation succeeded, False if session not found
                  or already completed
            
        Requirements:
            - 8.5: Mark session as "cancelled" and clean up resources
        """
        with self._lock:
            session = self._sessions.get(session_id)
            if not session:
                return False
            
            # Only cancel if session is in progress or pending
            if session.status in ["pending", "in_progress"]:
                session.status = "cancelled"
                session.updated_at = datetime.now(timezone.utc)
                session.completed_at = datetime.now(timezone.utc)
                return True
            
            # Session already completed, failed, or cancelled
            return False
    
    def get_all_sessions(self) -> List[ExecutionSession]:
        """
        Retrieve all sessions.
        
        Returns:
            List[ExecutionSession]: List of all sessions
        """
        with self._lock:
            return list(self._sessions.values())
    
    def delete_session(self, session_id: str) -> bool:
        """
        Delete a session from memory.
        
        Args:
            session_id: The unique session identifier
            
        Returns:
            bool: True if deletion succeeded, False if session not found
        """
        with self._lock:
            if session_id in self._sessions:
                del self._sessions[session_id]
                return True
            return False
    
    def is_session_active(self, session_id: str) -> bool:
        """
        Check if a session is currently active (pending or in_progress).
        
        Args:
            session_id: The unique session identifier
            
        Returns:
            bool: True if session is active, False otherwise
        """
        session = self.get_session(session_id)
        if not session:
            return False
        return session.status in ["pending", "in_progress"]

