"""
RPA Engine for AEGIS Backend.

This module provides the core RPA execution engine that wraps PyAutoGUI and Win32API
operations with retry logic and action observation integration.
"""

import time
import logging
from typing import List, Optional
import pyautogui

from src.models import ActionResult, ToolResult
from src.rpa_tools import (
    click_element,
    type_text,
    press_key,
    launch_application,
    focus_window,
    capture_screen,
    scroll,
    copy_to_clipboard,
    paste_from_clipboard,
    get_active_window,
    list_open_windows
)

# Platform-specific imports
try:
    import win32gui
    import win32con
    WINDOWS_AVAILABLE = True
except ImportError:
    WINDOWS_AVAILABLE = False

logger = logging.getLogger(__name__)


class RPAEngine:
    """
    RPA Engine that executes low-level desktop actions with retry logic.
    
    This class wraps RPA tool functions and provides:
    - Retry logic with exponential backoff (1s, 2s, 4s)
    - Action observation integration
    - Error handling and logging
    """
    
    def __init__(self, max_retries: int = 3):
        """
        Initialize the RPA Engine.
        
        Args:
            max_retries: Maximum number of retry attempts (default: 3)
        """
        self.max_retries = max_retries
        self.retry_delays = [1, 2, 4]  # Exponential backoff in seconds
        logger.info(f"RPAEngine initialized with max_retries={max_retries}")
    
    def _retry_with_backoff(self, action_func, action_name: str) -> ActionResult:
        """
        Execute an action with retry logic and exponential backoff.
        
        Args:
            action_func: Function that returns ToolResult
            action_name: Name of the action for logging
        
        Returns:
            ActionResult with success status and retry count
        """
        retry_count = 0
        last_error = None
        
        for attempt in range(self.max_retries):
            try:
                logger.debug(f"Attempting {action_name} (attempt {attempt + 1}/{self.max_retries})")
                
                # Execute the action
                tool_result = action_func()
                
                if tool_result.success:
                    logger.info(f"{action_name} succeeded on attempt {attempt + 1}")
                    return ActionResult(
                        success=True,
                        retry_count=retry_count,
                        error=None
                    )
                else:
                    last_error = tool_result.error
                    logger.warning(f"{action_name} failed on attempt {attempt + 1}: {last_error}")
                    
            except Exception as e:
                last_error = str(e)
                logger.error(f"{action_name} raised exception on attempt {attempt + 1}: {last_error}")
            
            # Increment retry count
            retry_count += 1
            
            # Wait before retrying (except on last attempt)
            if attempt < self.max_retries - 1:
                delay = self.retry_delays[attempt]
                logger.debug(f"Waiting {delay}s before retry...")
                time.sleep(delay)
        
        # All retries exhausted
        logger.error(f"{action_name} failed after {self.max_retries} attempts")
        return ActionResult(
            success=False,
            retry_count=retry_count,
            error=last_error or "Action failed after all retries"
        )

    def execute_click(self, x: int, y: int, button: str = "left") -> ActionResult:
        """
        Execute a mouse click action with retry logic.
        
        Args:
            x: X coordinate on screen
            y: Y coordinate on screen
            button: Mouse button ("left", "right", "middle")
        
        Returns:
            ActionResult with success status and retry count
        """
        logger.info(f"Executing click at ({x}, {y}) with button={button}")
        
        def action():
            return click_element(x, y, button)
        
        return self._retry_with_backoff(action, f"click({x}, {y}, {button})")
    
    def execute_type(
        self,
        text: str,
        interval: float = 0.05,
        verify_focus: bool = True,
        clear_existing: bool = False,
        verify_result: bool = True,
        expected_window: Optional[str] = None,
        use_intelligent: bool = True
    ) -> ActionResult:
        """
        Execute a typing action with retry logic and intelligent features.
        
        Args:
            text: Text to type
            interval: Delay between keystrokes in seconds (ignored if use_intelligent=True)
            verify_focus: Whether to verify focus before typing
            clear_existing: Whether to clear existing text first
            verify_result: Whether to verify the typed text
            expected_window: Optional window title to verify focus
            use_intelligent: Whether to use intelligent text input features
        
        Returns:
            ActionResult with success status and retry count
        
        Validates: Requirements 12.1, 12.2, 12.3, 12.4, 12.5
        """
        logger.info(f"Executing type with text length={len(text)}, interval={interval}, "
                   f"intelligent={use_intelligent}, verify_focus={verify_focus}, "
                   f"clear_existing={clear_existing}, verify_result={verify_result}")
        
        def action():
            return type_text(
                text=text,
                interval=interval,
                verify_focus=verify_focus,
                clear_existing=clear_existing,
                verify_result=verify_result,
                expected_window=expected_window,
                use_intelligent=use_intelligent
            )
        
        return self._retry_with_backoff(action, f"type_text(len={len(text)})")
    
    def execute_key_press(self, key: str, modifiers: Optional[List[str]] = None) -> ActionResult:
        """
        Execute a key press action with retry logic.
        
        Args:
            key: Key to press
            modifiers: Optional list of modifier keys
        
        Returns:
            ActionResult with success status and retry count
        """
        modifiers = modifiers or []
        logger.info(f"Executing key press: key={key}, modifiers={modifiers}")
        
        def action():
            return press_key(key, modifiers)
        
        modifier_str = "+".join(modifiers + [key]) if modifiers else key
        return self._retry_with_backoff(action, f"press_key({modifier_str})")
    
    def launch_app(self, app_name: str, wait_time: int = 5) -> ActionResult:
        """
        Launch an application with retry logic.
        
        Args:
            app_name: Application name or path
            wait_time: Seconds to wait for app to launch
        
        Returns:
            ActionResult with success status and retry count
        """
        logger.info(f"Launching application: {app_name}, wait_time={wait_time}")
        
        def action():
            return launch_application(app_name, wait_time)
        
        return self._retry_with_backoff(action, f"launch_app({app_name})")
    
    def execute_focus_window(self, window_title: str) -> ActionResult:
        """
        Focus a window by title with retry logic.
        
        Args:
            window_title: Window title to focus
        
        Returns:
            ActionResult with success status and retry count
        """
        logger.info(f"Focusing window: {window_title}")
        
        def action():
            return focus_window(window_title)
        
        return self._retry_with_backoff(action, f"focus_window({window_title})")
    
    def execute_scroll(self, direction: str, amount: int) -> ActionResult:
        """
        Execute a scroll action with retry logic.
        
        Args:
            direction: Scroll direction ("up", "down", "left", "right")
            amount: Scroll amount in clicks
        
        Returns:
            ActionResult with success status and retry count
        """
        logger.info(f"Executing scroll: direction={direction}, amount={amount}")
        
        def action():
            return scroll(direction, amount)
        
        return self._retry_with_backoff(action, f"scroll({direction}, {amount})")
    
    def capture_screen_state(self, region: Optional[tuple] = None) -> ToolResult:
        """
        Capture the current screen state for observation.
        
        This method does not use retry logic as screen capture is typically
        reliable and we want the exact state at the moment of capture.
        
        Args:
            region: Optional (x, y, width, height) tuple
        
        Returns:
            ToolResult with captured screen data
        """
        logger.debug(f"Capturing screen state, region={region}")
        return capture_screen(region)
    
    def execute_copy_to_clipboard(self, text: str) -> ActionResult:
        """
        Copy text to clipboard with retry logic.
        
        Args:
            text: Text to copy to clipboard
        
        Returns:
            ActionResult with success status and retry count
        
        Validates: Requirements 11.4
        """
        logger.info(f"Copying text to clipboard, length={len(text)}")
        
        def action():
            return copy_to_clipboard(text)
        
        return self._retry_with_backoff(action, f"copy_to_clipboard(len={len(text)})")
    
    def execute_paste_from_clipboard(self) -> ActionResult:
        """
        Paste text from clipboard with retry logic.
        
        Returns:
            ActionResult with success status and retry count
        
        Validates: Requirements 11.4
        """
        logger.info("Pasting text from clipboard")
        
        def action():
            return paste_from_clipboard()
        
        return self._retry_with_backoff(action, "paste_from_clipboard()")
    
    def get_active_window_info(self) -> ToolResult:
        """
        Get information about the currently active window.
        
        This method does not use retry logic as it's a query operation.
        
        Returns:
            ToolResult with active window information
        
        Validates: Requirements 11.5
        """
        logger.debug("Getting active window information")
        return get_active_window()
    
    def list_all_open_windows(self) -> ToolResult:
        """
        List all open windows.
        
        This method does not use retry logic as it's a query operation.
        
        Returns:
            ToolResult with list of open windows
        
        Validates: Requirements 11.1
        """
        logger.debug("Listing all open windows")
        return list_open_windows()

    def execute_copy_to_clipboard(self, text: str) -> ActionResult:
        """
        Copy text to clipboard with retry logic.
        
        Args:
            text: Text to copy to clipboard
        
        Returns:
            ActionResult with success status and retry count
        
        Validates: Requirements 11.4
        """
        logger.info(f"Copying text to clipboard, length={len(text)}")
        
        def action():
            return copy_to_clipboard(text)
        
        return self._retry_with_backoff(action, f"copy_to_clipboard(len={len(text)})")
    
    def execute_paste_from_clipboard(self) -> ActionResult:
        """
        Paste text from clipboard with retry logic.
        
        Returns:
            ActionResult with success status and retry count
        
        Validates: Requirements 11.4
        """
        logger.info("Pasting text from clipboard")
        
        def action():
            return paste_from_clipboard()
        
        return self._retry_with_backoff(action, "paste_from_clipboard()")
    
    def get_active_window_info(self) -> ToolResult:
        """
        Get information about the currently active window.
        
        This method does not use retry logic as it's a query operation.
        
        Returns:
            ToolResult with active window information
        
        Validates: Requirements 11.5
        """
        logger.debug("Getting active window information")
        return get_active_window()
    
    def list_all_open_windows(self) -> ToolResult:
        """
        List all open windows.
        
        This method does not use retry logic as it's a query operation.
        
        Returns:
            ToolResult with list of open windows
        
        Validates: Requirements 11.1
        """
        logger.debug("Listing all open windows")
        return list_open_windows()
