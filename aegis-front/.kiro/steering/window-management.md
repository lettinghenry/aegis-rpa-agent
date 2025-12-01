# Window Management for RPA Execution

## Critical Requirement

During RPA execution, the AEGIS Frontend must minimize to a small floating window to give the automation agent unobstructed access to the desktop and other applications.

## Implementation Approach

### Package Selection

Use one of these Flutter window management packages:
- **window_manager** (recommended) - Cross-platform, actively maintained
- **bitsdojo_window** - Alternative with more customization options

Add to `pubspec.yaml`:
```yaml
dependencies:
  window_manager: ^0.3.0  # or bitsdojo_window: ^0.1.6
```

### Window States

#### Normal Mode (Default)
- **Size**: Full application window (e.g., 800x600 or larger)
- **Position**: Centered on screen or last saved position
- **Properties**: 
  - Standard window decorations (title bar, borders)
  - Resizable
  - Not always on top

#### Minimal Mode (During Execution)
- **Size**: Small floating panel (e.g., 300x100 pixels)
- **Position**: Top-right corner of screen (or user preference)
- **Properties**:
  - Always on top
  - Borderless (no title bar)
  - Non-resizable
  - Shows minimal execution status (current subtask, progress indicator)

### WebSocket Commands

The backend sends these commands via WebSocket:

```json
{
  "session_id": "abc123",
  "window_state": "minimal",  // or "normal"
  "subtask": { ... },
  "overall_status": "in_progress",
  "message": "Executing click action",
  "timestamp": "2024-12-01T10:30:00Z"
}
```

### Implementation Flow

1. **Execution Starts**: Window remains normal during planning phase
2. **First Desktop Action**: Backend sends `window_state: "minimal"`
3. **Frontend Responds**: 
   - Save current window size and position
   - Resize to minimal mode (300x100)
   - Set always on top
   - Remove window decorations
4. **During Execution**: Window stays minimal, shows current subtask
5. **Execution Completes**: Backend sends `window_state: "normal"`
6. **Frontend Responds**:
   - Restore original size and position
   - Restore window decorations
   - Remove always on top

### Service Layer

Create `lib/services/window_service.dart`:

```dart
class WindowService {
  Size? _savedSize;
  Offset? _savedPosition;
  
  Future<void> enterMinimalMode() async {
    // Save current state
    _savedSize = await windowManager.getSize();
    _savedPosition = await windowManager.getPosition();
    
    // Enter minimal mode
    await windowManager.setSize(Size(300, 100));
    await windowManager.setPosition(Offset(
      // Top-right corner
      screenWidth - 320,
      20,
    ));
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setResizable(false);
  }
  
  Future<void> exitMinimalMode() async {
    // Restore original state
    if (_savedSize != null) {
      await windowManager.setSize(_savedSize!);
    }
    if (_savedPosition != null) {
      await windowManager.setPosition(_savedPosition!);
    }
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setResizable(true);
  }
}
```

### State Management Integration

Update `ExecutionState` to handle window state commands:

```dart
void onStatusUpdate(StatusUpdate update) {
  // Handle window state changes
  if (update.windowState == 'minimal' && !isMinimalMode) {
    WindowService.enterMinimalMode();
    isMinimalMode = true;
  } else if (update.windowState == 'normal' && isMinimalMode) {
    WindowService.exitMinimalMode();
    isMinimalMode = false;
  }
  
  // Handle other updates...
  notifyListeners();
}
```

### Minimal Mode UI

When in minimal mode, show a compact view:
- Current subtask description (truncated)
- Progress indicator (spinner or progress bar)
- Small cancel button (optional)

Example layout:
```
┌─────────────────────────────────┐
│ 🔄 Clicking "Submit" button...  │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
└─────────────────────────────────┘
```

## User Experience Considerations

### Smooth Transitions
- Animate window resize (200-300ms duration)
- Fade in/out window decorations
- Maintain visual continuity

### User Control
- Allow user to manually toggle minimal mode (optional)
- Remember user's preferred minimal window position
- Provide setting to disable auto-minimize (for debugging)

### Edge Cases
- **Multiple Monitors**: Position minimal window on primary monitor
- **Screen Resolution Changes**: Recalculate position if screen size changes
- **Window Dragging**: Allow user to drag minimal window to preferred location
- **Connection Loss**: Restore normal mode if WebSocket disconnects

## Testing

### Manual Testing
1. Submit a task that requires desktop interaction
2. Verify window minimizes when first action starts
3. Verify window shows current subtask in minimal mode
4. Verify window restores when execution completes
5. Test cancellation restores window
6. Test with multiple monitors

### Automated Testing
- Widget tests for minimal mode UI
- Integration tests for window state transitions
- Mock WebSocket commands to trigger state changes

## Configuration

Add to `lib/config/app_config.dart`:

```dart
class WindowConfig {
  static const Size minimalSize = Size(300, 100);
  static const Duration transitionDuration = Duration(milliseconds: 250);
  static const bool enableAutoMinimize = true;
  
  // Minimal window position (offset from top-right)
  static const double minimalOffsetX = 20;
  static const double minimalOffsetY = 20;
}
```

## Platform Support

- **Windows**: Full support with window_manager
- **macOS**: Full support with window_manager
- **Linux**: Full support with window_manager
- **Web**: Not applicable (no window management)
- **Mobile**: Not applicable (no desktop automation)
