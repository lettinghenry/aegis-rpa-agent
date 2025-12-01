"""
History Store for AEGIS RPA Backend.

This module provides persistent storage for execution sessions, allowing
retrieval of past automation runs for review and debugging.
"""

import json
import os
from typing import List, Optional
from datetime import datetime
from pathlib import Path

from src.models import ExecutionSession, SessionSummary


class HistoryStore:
    """
    Manages persistent storage of execution sessions.
    
    Sessions are stored as individual JSON files in the history directory,
    with an index file for quick lookups and ordering.
    """
    
    def __init__(self, history_dir: str = "./data/history"):
        """
        Initialize the HistoryStore.
        
        Args:
            history_dir: Directory path for storing session files
        """
        self.history_dir = Path(history_dir)
        self.index_file = self.history_dir / "index.json"
        
        # Ensure directory exists
        self.history_dir.mkdir(parents=True, exist_ok=True)
        
        # Initialize index if it doesn't exist
        if not self.index_file.exists():
            self._write_index([])
    
    def save_session(self, session: ExecutionSession) -> None:
        """
        Persist an execution session to storage.
        
        Args:
            session: The ExecutionSession to save
        """
        # Save session to individual file
        session_file = self.history_dir / f"{session.session_id}.json"
        session_data = session.model_dump(mode='json')
        
        with open(session_file, 'w', encoding='utf-8') as f:
            json.dump(session_data, f, indent=2, default=str)
        
        # Update index
        self._update_index(session)
    
    def get_all_sessions(self, limit: int = 100) -> List[SessionSummary]:
        """
        Retrieve session summaries ordered by timestamp descending.
        
        Args:
            limit: Maximum number of sessions to return
            
        Returns:
            List of SessionSummary objects, newest first
        """
        index = self._read_index()
        
        # Sort by created_at descending (newest first)
        sorted_index = sorted(
            index,
            key=lambda x: x.get('created_at', ''),
            reverse=True
        )
        
        # Apply limit
        limited_index = sorted_index[:limit]
        
        # Convert to SessionSummary objects
        summaries = []
        for entry in limited_index:
            try:
                summary = SessionSummary(
                    session_id=entry['session_id'],
                    instruction=entry['instruction'],
                    status=entry['status'],
                    created_at=datetime.fromisoformat(entry['created_at']),
                    completed_at=datetime.fromisoformat(entry['completed_at']) if entry.get('completed_at') else None,
                    subtask_count=entry['subtask_count']
                )
                summaries.append(summary)
            except (KeyError, ValueError) as e:
                # Skip malformed entries
                continue
        
        return summaries
    
    def get_session_details(self, session_id: str) -> Optional[ExecutionSession]:
        """
        Retrieve full details of a specific session.
        
        Args:
            session_id: The unique session identifier
            
        Returns:
            ExecutionSession if found, None otherwise
        """
        session_file = self.history_dir / f"{session_id}.json"
        
        if not session_file.exists():
            return None
        
        try:
            with open(session_file, 'r', encoding='utf-8') as f:
                session_data = json.load(f)
            
            # Convert datetime strings back to datetime objects
            session_data['created_at'] = datetime.fromisoformat(session_data['created_at'])
            session_data['updated_at'] = datetime.fromisoformat(session_data['updated_at'])
            if session_data.get('completed_at'):
                session_data['completed_at'] = datetime.fromisoformat(session_data['completed_at'])
            
            # Convert subtask timestamps
            for subtask in session_data.get('subtasks', []):
                subtask['timestamp'] = datetime.fromisoformat(subtask['timestamp'])
            
            return ExecutionSession(**session_data)
        except (json.JSONDecodeError, KeyError, ValueError) as e:
            # Return None for corrupted files
            return None
    
    def _read_index(self) -> List[dict]:
        """
        Read the index file.
        
        Returns:
            List of index entries
        """
        try:
            with open(self.index_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            return []
    
    def _write_index(self, index: List[dict]) -> None:
        """
        Write the index file.
        
        Args:
            index: List of index entries to write
        """
        with open(self.index_file, 'w', encoding='utf-8') as f:
            json.dump(index, f, indent=2, default=str)
    
    def _update_index(self, session: ExecutionSession) -> None:
        """
        Update the index with a new or updated session.
        
        Args:
            session: The session to add/update in the index
        """
        index = self._read_index()
        
        # Create summary entry
        entry = {
            'session_id': session.session_id,
            'instruction': session.instruction,
            'status': session.status,
            'created_at': session.created_at.isoformat(),
            'completed_at': session.completed_at.isoformat() if session.completed_at else None,
            'subtask_count': len(session.subtasks)
        }
        
        # Remove existing entry if present
        index = [e for e in index if e['session_id'] != session.session_id]
        
        # Add new entry
        index.append(entry)
        
        # Write updated index
        self._write_index(index)
