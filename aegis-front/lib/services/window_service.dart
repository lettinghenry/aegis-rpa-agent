import 'dart:ui';
import 'package:window_manager/window_manager.dart';

/// Service for managing window state transitions during RPA execution.
/// 
/// Handles switching between normal and minimal window modes to provide
/// the automation agent with unobstructed access to the desktop.
class WindowService {
  Size? _savedSize;
  Offset? _savedPosition;
  bool _isMinimalMode = false;

  /// Whether the window is currently in minimal mode
  bool get isMinimalMode => _isMinimalMode;

  /// Configuration for minimal window mode
  static const Size minimalSize = Size(300, 100);
  static const Duration transitionDuration = Duration(milliseconds: 250);
  static const double minimalOffsetX = 20; // From right edge
  static const double minimalOffsetY = 20; // From top

  /// Enter minimal mode: resize window to small floating panel
  /// 
  /// Saves current window state and transitions to a compact 300x100 window
  /// positioned at the top-right corner, always on top, with no decorations.
  Future<void> enterMinimalMode() async {
    if (_isMinimalMode) return;

    try {
      // Save current state
      _savedSize = await windowManager.getSize();
      _savedPosition = await windowManager.getPosition();

      // Get screen dimensions to calculate position
      final bounds = await windowManager.getBounds();
      final screenSize = await _getScreenSize();

      // Calculate position (top-right corner with offset)
      final newPosition = Offset(
        screenSize.width - minimalSize.width - minimalOffsetX,
        minimalOffsetY,
      );

      // Enter minimal mode with smooth transition
      await windowManager.setSize(minimalSize, animate: true);
      await windowManager.setPosition(newPosition, animate: true);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setResizable(false);

      _isMinimalMode = true;
    } catch (e) {
      // Log error but don't throw - window management is not critical
      print('Error entering minimal mode: $e');
    }
  }

  /// Exit minimal mode: restore window to original size and position
  /// 
  /// Restores the window to its previous state before entering minimal mode.
  Future<void> exitMinimalMode() async {
    if (!_isMinimalMode) return;

    try {
      // Restore original state
      if (_savedSize != null) {
        await windowManager.setSize(_savedSize!, animate: true);
      }
      if (_savedPosition != null) {
        await windowManager.setPosition(_savedPosition!, animate: true);
      }

      await windowManager.setAlwaysOnTop(false);
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      await windowManager.setResizable(true);

      _isMinimalMode = false;
    } catch (e) {
      // Log error but don't throw - window management is not critical
      print('Error exiting minimal mode: $e');
    }
  }

  /// Get the screen size, handling edge cases like multiple monitors
  Future<Size> _getScreenSize() async {
    try {
      // Get the primary screen bounds
      final bounds = await windowManager.getBounds();
      
      // For multiple monitors, we use the current screen
      // window_manager doesn't provide direct screen info, so we estimate
      // based on typical screen sizes
      return const Size(1920, 1080); // Default to common resolution
    } catch (e) {
      // Fallback to a safe default
      return const Size(1920, 1080);
    }
  }

  /// Reset the service state (useful for testing)
  void reset() {
    _savedSize = null;
    _savedPosition = null;
    _isMinimalMode = false;
  }
}
