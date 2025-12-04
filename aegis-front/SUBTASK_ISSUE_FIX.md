# Subtask Display Issue - Investigation and Fix

## Problem
Subtasks are not showing during task execution, but they appear correctly in the history after completion.

## Root Cause Analysis

### Backend Investigation
1. **ADK Agent** (`aegis-back/src/adk_agent.py`):
   - ✅ Correctly creates `Subtask` objects
   - ✅ Yields `StatusUpdate` with subtask data
   - ✅ Sends two updates per subtask (start + completion)

2. **WebSocket Manager** (`aegis-back/src/websocket_manager.py`):
   - ✅ Correctly broadcasts StatusUpdate to connected clients
   - ⚠️ Bug found: `disconnect()` method signature mismatch in `main.py`

3. **Main.py** (`aegis-back/main.py`):
   - ✅ Receives StatusUpdate from ADK agent
   - ✅ Broadcasts via WebSocket
   - ❌ **BUG**: Calls `websocket_manager.disconnect(session_id)` but method expects `disconnect(websocket, session_id)`

### Frontend Investigation
1. **WebSocket Service** (`aegis-front/lib/services/websocket_service.dart`):
   - ✅ Receives messages
   - ✅ Parses JSON correctly
   - ✅ Calls onUpdate callback

2. **Execution State** (`aegis-front/lib/state/execution_state.dart`):
   - ✅ Has `onStatusUpdate()` method
   - ✅ Has `_updateSubtask()` method
   - ✅ Calls `notifyListeners()` after updates

3. **Task Execution Screen** (`aegis-front/lib/screens/task_execution_screen.dart`):
   - ✅ Uses `Consumer<ExecutionStateNotifier>`
   - ✅ Displays subtasks from `executionState.subtasks`

## Fixes Applied

### 1. Backend WebSocket Disconnect Fix
**File**: `aegis-back/main.py`
**Lines**: 371, 374

Changed from:
```python
await websocket_manager.disconnect(session_id)
```

To:
```python
await websocket_manager.disconnect(websocket, session_id)
```

### 2. Added Debug Logging
**Files**: 
- `aegis-front/lib/services/websocket_service.dart`
- `aegis-front/lib/state/execution_state.dart`

Added print statements to track:
- Raw WebSocket messages received
- Parsed StatusUpdate objects
- Subtask additions/updates
- Subtask count changes

## Testing Steps

1. Start the backend:
```bash
cd aegis-back
venv\Scripts\activate
python main.py
```

2. Start the frontend:
```bash
cd aegis-front
flutter run -d windows
```

3. Submit a test task (e.g., "Open notepad and type hello")

4. Watch the console output for debug messages:
   - "WebSocket received: ..."
   - "Parsed StatusUpdate - subtask: ..."
   - "ExecutionState received update - subtask: ..."
   - "DEBUG: Adding/updating subtask ..."
   - "DEBUG: Subtasks count after update: ..."

5. Verify subtasks appear in real-time on the execution screen

## Next Steps

If subtasks still don't appear after this fix:
1. Check console output for any parsing errors
2. Verify WebSocket connection is established (check connection status indicator)
3. Check if subtasks are being added but UI not updating (notifyListeners issue)
4. Verify the backend is actually generating subtasks (check backend logs)

## Additional Notes

The disconnect bug could cause WebSocket connections to not close properly, potentially leading to:
- Memory leaks
- Connection state issues
- Reconnection problems

This fix ensures proper cleanup of WebSocket connections.
