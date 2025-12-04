# Subtask Display Issue - Fix Complete

## Issue
Subtasks were not displaying during task execution, only appearing in history after completion.

## Root Cause
WebSocket disconnect bug in backend causing connection state issues.

## Fix Applied

### Backend Fix (aegis-back/main.py)
**Lines 371, 374**: Fixed WebSocket disconnect method calls

**Before:**
```python
await websocket_manager.disconnect(session_id)
```

**After:**
```python
await websocket_manager.disconnect(websocket, session_id)
```

This ensures WebSocket connections close properly and don't block real-time updates.

### Debug Logging Added

**Frontend (websocket_service.dart)**:
```dart
print('WebSocket received: $json');
print('Parsed StatusUpdate - subtask: ${update.subtask?.id}, status: ${update.overallStatus}');
```

**Frontend (execution_state.dart)**:
```dart
print('ExecutionState received update - subtask: ${update.subtask?.id}, status: ${update.overallStatus}, subtasks count: ${_subtasks.length}');
print('DEBUG: Adding/updating subtask ${update.subtask!.id}');
print('DEBUG: Subtasks count after update: ${_subtasks.length}');
```

## Testing

Both backend and frontend are now running with the fix:
- ✅ Backend: http://0.0.0.0:8000
- ✅ Frontend: Building...

### To Test:
1. Wait for frontend to finish building
2. Submit a test task (e.g., "Open notepad")
3. Watch console output for debug messages
4. Verify subtasks appear in real-time on execution screen

### Expected Console Output:
```
WebSocket received: {session_id: ..., subtask: {...}, ...}
Parsed StatusUpdate - subtask: abc123_subtask_1, status: in_progress
ExecutionState received update - subtask: abc123_subtask_1, status: in_progress, subtasks count: 0
DEBUG: Adding/updating subtask abc123_subtask_1
DEBUG: Subtasks count after update: 1
```

## Files Modified
1. `aegis-back/main.py` - Fixed WebSocket disconnect calls
2. `aegis-front/lib/services/websocket_service.dart` - Added debug logging
3. `aegis-front/lib/state/execution_state.dart` - Added debug logging

## Next Steps
Once confirmed working, remove debug logging for production.
