"""
RPA Toolbox for AEGIS Backend.

This module provides ADK-compatible tool definitions that wrap PyAutoGUI and Win32API
functionality for desktop automation. Each tool returns a ToolResult with success status.
"""

import pyautogui
import subprocess
import time
import base64
from io import BytesIO
from typing import List, Optional, Tuple
from PIL import Image

from src.models import ToolResult

# Configure PyAutoGUI safety settings
pyautogui.FAILSAFE = True  # Move mouse to corner to abort
pyautogui.PAUSE = 0.1  # Small pause between PyAutoGUI calls

# Platform-specific imports
try:
    import win32gui
    import win32con
    import win32process
    WINDOWS_AVAILABLE = True
except ImportError:
    WINDOWS_AVAILABLE = False

# Clipboard support
try:
    import pyperclip
    CLIPBOARD_AVAILABLE = True
except ImportError:
    CLIPBOARD_AVAILABLE = False


def tool(func):
    """
    Decorator to mark functions as ADK-compatible tools.
    This is a placeholder for the actual ADK @tool decorator.
    """
    func._is_tool = True
    return func


@tool
def click_element(x: int, y: int, button: str = "left") -> ToolResult:
    """
    Click at specified screen coordinates.
    
    Args:
        x: X coordinate on screen
        y: Y coordinate on screen
        button: Mouse button to click ("left", "right", "middle")
    
    Returns:
        ToolResult with success status and click details
    """
    try:
        # Validate button parameter
        valid_buttons = ["left", "right", "middle"]
        if button not in valid_buttons:
            return ToolResult(
                success=False,
                error=f"Invalid button '{button}'. Must be one of: {valid_buttons}"
            )
        
        # Validate coordinates
        screen_width, screen_height = pyautogui.size()
        if not (0 <= x <= screen_width and 0 <= y <= screen_height):
            return ToolResult(
                success=False,
                error=f"Coordinates ({x}, {y}) out of screen bounds ({screen_width}x{screen_height})"
            )
        
        # Perform the click
        pyautogui.click(x=x, y=y, button=button)
        
        return ToolResult(
            success=True,
            data={
                "x": x,
                "y": y,
                "button": button,
                "timestamp": time.time()
            }
        )
    
    except Exception as e:
        return ToolResult(
            success=False,
            error=f"Click failed: {str(e)}"
        )


@tool
def type_text(
    text: str,
    interval: float = 0.05,
    verify_focus: bool = True,
    clear_existing: bool = False,
    verify_result: bool = True,
    expected_window: Optional[str] = None,
    use_intelligent: bool = True
) -> ToolResult:
    """
    Type text into the currently focused element with intelligent features.
    
    Args:
        text: Text to type
        interval: Delay between keystrokes in seconds (default: 0.05, ignored if use_intelligent=True)
        verify_focus: Whether to verify focus before typing (default: True)
        clear_existing: Whether to clear existing text first (default: False)
        verify_result: Whether to verify the typed text (default: True)
        expected_window: Optional window title to verify focus
        use_intelligent: Whether to use intelligent text input features (default: True)
    
    Returns:
        ToolResult with success status
    
    Validates: Requirements 12.1, 12.2, 12.3, 12.4, 12.5
    """
    try:
        # Validate interval
        if interval < 0:
            return ToolResult(
                success=False,
                error="Interval must be non-negative"
            )
        
        # Use intelligent text input if enabled
        if use_intelligent:
            from src.intelligent_text_input import intelligent_text_input
            return intelligent_text_input.type_with_intelligence(
                text=text,
                verify_focus=verify_focus,
                clear_existing=clear_existing,
                verify_result=verify_result,
                expected_window=expected_window,
                use_human_speed=True
            )
        
        # Fallback to basic typing
        pyautogui.write(text, interval=interval)
        
        return ToolResult(
            success=True,
            data={
                "text_length": len(text),
                "interval": interval,
                "intelligent_mode": False,
                "timestamp": time.time()
            }
        )
    
    except Exception as e:
        return ToolResult(
            success=False,
            error=f"Typing failed: {str(e)}"
        )


@tool
def press_key(key: str, modifiers: Optional[List[str]] = None) -> ToolResult:
    """
    Press keyboard key with optional modifiers.
    
    Args:
        key: Key to press (e.g., "enter", "a", "tab")
        modifiers: List of modifier keys (e.g., ["ctrl", "shift"])
    
    Returns:
        ToolResult with success status
    """
    try:
        if modifiers is None:
            modifiers = []
        
        # Validate modifiers
        valid_modifiers = ["ctrl", "alt", "shift", "win", "command"]
        for mod in modifiers:
            if mod.lower() not in valid_modifiers:
                return ToolResult(
                    success=False,
                    error=f"Invalid modifier '{mod}'. Must be one of: {valid_modifiers}"
                )
        
        # Press key with modifiers
        if modifiers:
            # Build hotkey combination
            hotkey_parts = [mod.lower() for mod in modifiers] + [key.lower()]
            pyautogui.hotkey(*hotkey_parts)
        else:
            pyautogui.press(key.lower())
        
        return ToolResult(
            success=True,
            data={
                "key": key,
                "modifiers": modifiers,
                "timestamp": time.time()
            }
        )
    
    except Exception as e:
        return ToolResult(
            success=False,
            error=f"Key press failed: {str(e)}"
        )


@tool
def launch_application(app_name: str, wait_time: int = 5) -> ToolResult:
    """
    Launch application by name or path with readiness check.
    
    Args:
        app_name: Application name or full path to executable
        wait_time: Seconds to wait for app to launch (default: 5)
    
    Returns:
        ToolResult with success status and process info
    
    Validates: Requirements 11.3
    """
    try:
        # Validate wait_time
        if wait_time < 0:
            return ToolResult(
                success=False,
                error="Wait time must be non-negative"
            )
        
        # Check if application is already running (Windows only)
        if WINDOWS_AVAILABLE:
            # Try to find existing window with app name
            def check_existing(hwnd, windows):
                if win32gui.IsWindowVisible(hwnd):
                    title = win32gui.GetWindowText(hwnd)
                    if app_name.lower() in title.lower():
                        windows.append((hwnd, title))
                return True
            
            existing_windows = []
            win32gui.EnumWindows(check_existing, existing_windows)
            
            if existing_windows:
                # Application already running
                return ToolResult(
                    success=True,
                    data={
                        "app_name": app_name,
                        "already_running": True,
                        "window_count": len(existing_windows),
                        "timestamp": time.time()
                    }
                )
        
        # Launch the application
        process = subprocess.Popen(app_name, shell=True)
        
        # Wait for the specified time
        time.sleep(wait_time)
        
        # Check if process is still running
        poll_result = process.poll()
        if poll_result is not None and poll_result != 0:
            return ToolResult(
                success=False,
                error=f"Application exited with code {poll_result}"
            )
        
        # Verify application window appeared (Windows only)
        if WINDOWS_AVAILABLE:
            # Give a bit more time for window to appear
            time.sleep(1)
            
            windows_found = []
            win32gui.EnumWindows(check_existing, windows_found)
            
            if not windows_found:
                return ToolResult(
                    success=False,
                    error=f"Application launched but no window appeared within {wait_time + 1}s"
                )
            
            return ToolResult(
                success=True,
                data={
                    "app_name": app_name,
                    "pid": process.pid,
                    "wait_time": wait_time,
                    "window_ready": True,
                    "window_count": len(windows_found),
                    "timestamp": time.time()
                }
            )
        
        # Non-Windows platforms
        return ToolResult(
            success=True,
            data={
                "app_name": app_name,
                "pid": process.pid,
                "wait_time": wait_time,
                "timestamp": time.time()
            }
        )
    
    except FileNotFoundError:
        return ToolResult(
            success=False,
            error=f"Application '{app_name}' not found"
        )
    except Exception as e:
        return ToolResult(
            success=False,
            error=f"Application launch failed: {str(e)}"
        )


@tool
def focus_window(window_title: str) -> ToolResult:
    """
    Bring window to foreground by title.
    
    Args:
        window_title: Partial or full window title to match
    
    Returns:
        ToolResult with success status
    """
    try:
        if not WINDOWS_AVAILABLE:
            return ToolResult(
                success=False,
                error="Window focus requires Windows platform (pywin32)"
            )
        
        # Find window by title
        def callback(hwnd, windows):
            if win32gui.IsWindowVisible(hwnd):
                title = win32gui.GetWindowText(hwnd)
                if window_title.lower() in title.lower():
                    windows.append((hwnd, title))
            return True
        
        windows = []
        win32gui.EnumWindows(callback, windows)
        
        if not windows:
            return ToolResult(
                success=False,
                error=f"No window found matching '{window_title}'"
            )
        
        # Focus the first matching window
        hwnd, title = windows[0]
        win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
        win32gui.SetForegroundWindow(hwnd)
        
        return ToolResult(
            success=True,
            data={
                "window_title": title,
                "hwnd": hwnd,
                "matches_found": len(windows),
                "timestamp": time.time()
            }
        )
    
    except Exception as e:
        return ToolResult(
            success=False,
            error=f"Window focus failed: {str(e)}"
        )


@tool
def capture_screen(region: Optional[Tuple[int, int, int, int]] = None) -> ToolResult:
    """
    Capture screenshot for observation.
    
    Args:
        region: Optional (x, y, width, height) tuple for partial capture
    
    Returns:
        ToolResult with base64-encoded image data
    """
    try:
        # Capture screenshot
        if region:
            x, y, width, height = region
            screenshot = pyautogui.screenshot(region=(x, y, width, height))
        else:
            screenshot = pyautogui.screenshot()
        
        # Convert to base64
        buffered = BytesIO()
        screenshot.save(buffered, format="PNG")
        img_base64 = base64.b64encode(buffered.getvalue()).decode('utf-8')
        
        return ToolResult(
            success=True,
            data={
                "image": img_base64,
                "width": screenshot.width,
                "height": screenshot.height,
                "region": region,
                "timestamp": time.time()
            }
        )
    
    except Exception as e:
        return ToolResult(
            success=False,
            error=f"Screen capture failed: {str(e)}"
        )


@tool
def find_element_by_image(template_path: str, confidence: float = 0.8) -> ToolResult:
    """
    Locate element on screen using image recognition.
    
    Args:
        template_path: Path to template image file
        confidence: Match confidence threshold 0-1 (default: 0.8)
    
    Returns:
        ToolResult with element coordinates if found
    """
    try:
        # Validate confidence
        if not (0 <= confidence <= 1):
            return ToolResult(
                success=False,
                error="Confidence must be between 0 and 1"
            )
        
        # Locate image on screen
        location = pyautogui.locateOnScreen(template_path, confidence=confidence)
        
        if location is None:
            return ToolResult(
                success=False,
                error=f"Template image not found on screen (confidence: {confidence})"
            )
        
        # Get center point
        center = pyautogui.center(location)
        
        return ToolResult(
            success=True,
            data={
                "x": center.x,
                "y": center.y,
                "left": location.left,
                "top": location.top,
                "width": location.width,
                "height": location.height,
                "confidence": confidence,
                "timestamp": time.time()
            }
        )
    
    except FileNotFoundError:
        return ToolResult(
            success=False,
            error=f"Template image file not found: {template_path}"
        )
    except Exception as e:
        return ToolResult(
            success=False,
            error=f"Image recognition failed: {str(e)}"
        )


@tool
def scroll(direction: str, amount: int) -> ToolResult:
    """
    Scroll in specified direction.
    
    Args:
        direction: Scroll direction ("up", "down", "left", "right")
        amount: Scroll amount in clicks (positive integer)
    
    Returns:
        ToolResult with success status
    """
    try:
        # Validate direction
        valid_directions = ["up", "down", "left", "right"]
        if direction.lower() not in valid_directions:
            return ToolResult(
                success=False,
                error=f"Invalid direction '{direction}'. Must be one of: {valid_directions}"
            )
        
        # Validate amount
        if amount <= 0:
            return ToolResult(
                success=False,
                error="Amount must be positive"
            )
        
        # Perform scroll
        direction = direction.lower()
        if direction == "up":
            pyautogui.scroll(amount)
        elif direction == "down":
            pyautogui.scroll(-amount)
        elif direction == "left":
            pyautogui.hscroll(-amount)
        elif direction == "right":
            pyautogui.hscroll(amount)
        
        return ToolResult(
            success=True,
            data={
                "direction": direction,
                "amount": amount,
                "timestamp": time.time()
            }
        )
    
    except Exception as e:
        return ToolResult(
            success=False,
            error=f"Scroll failed: {str(e)}"
        )


@tool
def copy_to_clipboard(text: str) -> ToolResult:
    """
    Copy text to system clipboard for data transfer between applications.
    
    Args:
        text: Text to copy to clipboard
    
    Returns:
        ToolResult with success status
    
    Validates: Requirements 11.4
    """
    try:
        if not CLIPBOARD_AVAILABLE:
            return ToolResult(
                success=False,
                error="Clipboard operations require pyperclip library"
            )
        
        pyperclip.copy(text)
        
        # Verify the copy worked
        clipboard_content = pyperclip.paste()
        if clipboard_content != text:
            return ToolResult(
                success=False,
                error="Clipboard verification failed - content mismatch"
            )
        
        return ToolResult(
            success=True,
            data={
                "text_length": len(text),
                "timestamp": time.time()
            }
        )
    
    except Exception as e:
        return ToolResult(
            success=False,
            error=f"Clipboard copy failed: {str(e)}"
        )


@tool
def paste_from_clipboard() -> ToolResult:
    """
    Paste text from system clipboard.
    
    Returns:
        ToolResult with clipboard content
    
    Validates: Requirements 11.4
    """
    try:
        if not CLIPBOARD_AVAILABLE:
            return ToolResult(
                success=False,
                error="Clipboard operations require pyperclip library"
            )
        
        clipboard_content = pyperclip.paste()
        
        return ToolResult(
            success=True,
            data={
                "text": clipboard_content,
                "text_length": len(clipboard_content),
                "timestamp": time.time()
            }
        )
    
    except Exception as e:
        return ToolResult(
            success=False,
            error=f"Clipboard paste failed: {str(e)}"
        )


@tool
def get_active_window() -> ToolResult:
    """
    Get information about the currently active window.
    
    Returns:
        ToolResult with active window information
    
    Validates: Requirements 11.5
    """
    try:
        if not WINDOWS_AVAILABLE:
            return ToolResult(
                success=False,
                error="Active window detection requires Windows platform (pywin32)"
            )
        
        # Get the foreground window
        hwnd = win32gui.GetForegroundWindow()
        
        if not hwnd:
            return ToolResult(
                success=False,
                error="No active window found"
            )
        
        # Get window title
        title = win32gui.GetWindowText(hwnd)
        
        # Get process ID
        _, pid = win32process.GetWindowThreadProcessId(hwnd)
        
        return ToolResult(
            success=True,
            data={
                "hwnd": hwnd,
                "title": title,
                "pid": pid,
                "timestamp": time.time()
            }
        )
    
    except Exception as e:
        return ToolResult(
            success=False,
            error=f"Failed to get active window: {str(e)}"
        )


@tool
def list_open_windows() -> ToolResult:
    """
    List all open windows with their titles.
    
    Returns:
        ToolResult with list of open windows
    
    Validates: Requirements 11.1
    """
    try:
        if not WINDOWS_AVAILABLE:
            return ToolResult(
                success=False,
                error="Window listing requires Windows platform (pywin32)"
            )
        
        def callback(hwnd, windows):
            if win32gui.IsWindowVisible(hwnd):
                title = win32gui.GetWindowText(hwnd)
                if title:  # Only include windows with titles
                    _, pid = win32process.GetWindowThreadProcessId(hwnd)
                    windows.append({
                        "hwnd": hwnd,
                        "title": title,
                        "pid": pid
                    })
            return True
        
        windows = []
        win32gui.EnumWindows(callback, windows)
        
        return ToolResult(
            success=True,
            data={
                "windows": windows,
                "count": len(windows),
                "timestamp": time.time()
            }
        )
    
    except Exception as e:
        return ToolResult(
            success=False,
            error=f"Failed to list windows: {str(e)}"
        )


# Export all tools for ADK registration
TOOLS = [
    click_element,
    type_text,
    press_key,
    launch_application,
    focus_window,
    capture_screen,
    find_element_by_image,
    scroll,
    copy_to_clipboard,
    paste_from_clipboard,
    get_active_window,
    list_open_windows
]
