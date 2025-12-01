"""
Intelligent Text Input Module for AEGIS Backend.

This module provides enhanced text input capabilities with:
- Focus verification before typing
- Special character encoding
- Human-like typing speed
- Text clearing before replacement
- Typing verification

Validates: Requirements 12.1, 12.2, 12.3, 12.4, 12.5
"""

import time
import random
import logging
from typing import Optional
import pyautogui

from src.models import ToolResult

# Platform-specific imports
try:
    import win32gui
    import win32api
    import win32con
    WINDOWS_AVAILABLE = True
except ImportError:
    WINDOWS_AVAILABLE = False

# Clipboard support for verification
try:
    import pyperclip
    CLIPBOARD_AVAILABLE = True
except ImportError:
    CLIPBOARD_AVAILABLE = False

logger = logging.getLogger(__name__)


class IntelligentTextInput:
    """
    Intelligent text input handler with focus verification, special character
    encoding, human-like typing, and verification.
    """
    
    # Human-like typing speed range (milliseconds)
    MIN_TYPING_INTERVAL_MS = 30
    MAX_TYPING_INTERVAL_MS = 150
    
    # Special character mappings for different keyboard layouts
    # Maps characters to their key combinations
    SPECIAL_CHAR_MAP = {
        '@': ('shift', '2'),
        '#': ('shift', '3'),
        '$': ('shift', '4'),
        '%': ('shift', '5'),
        '^': ('shift', '6'),
        '&': ('shift', '7'),
        '*': ('shift', '8'),
        '(': ('shift', '9'),
        ')': ('shift', '0'),
        '_': ('shift', '-'),
        '+': ('shift', '='),
        '{': ('shift', '['),
        '}': ('shift', ']'),
        '|': ('shift', '\\'),
        ':': ('shift', ';'),
        '"': ('shift', "'"),
        '<': ('shift', ','),
        '>': ('shift', '.'),
        '?': ('shift', '/'),
        '~': ('shift', '`'),
    }
    
    def __init__(self):
        """Initialize the intelligent text input handler."""
        logger.info("IntelligentTextInput initialized")
    
    def verify_focus(self, expected_window: Optional[str] = None) -> ToolResult:
        """
        Verify that an input field or window has focus before typing.
        
        Args:
            expected_window: Optional window title to verify focus
        
        Returns:
            ToolResult indicating if focus is verified
        
        Validates: Requirements 12.1
        """
        try:
            if not WINDOWS_AVAILABLE:
                logger.warning("Focus verification requires Windows platform")
                # On non-Windows, assume focus is correct
                return ToolResult(
                    success=True,
                    data={
                        "platform": "non-windows",
                        "focus_verified": False,
                        "assumed_focused": True
                    }
                )
            
            # Get the foreground window
            hwnd = win32gui.GetForegroundWindow()
            
            if not hwnd:
                return ToolResult(
                    success=False,
                    error="No window has focus"
                )
            
            # Get window title
            window_title = win32gui.GetWindowText(hwnd)
            
            # If expected window specified, verify it matches
            if expected_window:
                if expected_window.lower() not in window_title.lower():
                    return ToolResult(
                        success=False,
                        error=f"Expected window '{expected_window}' not focused. Current: '{window_title}'"
                    )
            
            logger.debug(f"Focus verified on window: {window_title}")
            return ToolResult(
                success=True,
                data={
                    "window_title": window_title,
                    "hwnd": hwnd,
                    "focus_verified": True
                }
            )
        
        except Exception as e:
            logger.error(f"Focus verification failed: {e}")
            return ToolResult(
                success=False,
                error=f"Focus verification failed: {str(e)}"
            )
    
    def clear_existing_text(self) -> ToolResult:
        """
        Clear existing text in the focused field using Ctrl+A and Delete.
        
        Returns:
            ToolResult indicating if text was cleared
        
        Validates: Requirements 12.4
        """
        try:
            logger.debug("Clearing existing text with Ctrl+A")
            
            # Select all text
            pyautogui.hotkey('ctrl', 'a')
            time.sleep(0.1)  # Brief pause for selection
            
            # Delete selected text
            pyautogui.press('delete')
            time.sleep(0.1)  # Brief pause after deletion
            
            logger.debug("Text cleared successfully")
            return ToolResult(
                success=True,
                data={
                    "action": "clear_text",
                    "method": "ctrl+a_delete"
                }
            )
        
        except Exception as e:
            logger.error(f"Text clearing failed: {e}")
            return ToolResult(
                success=False,
                error=f"Text clearing failed: {str(e)}"
            )
    
    def _get_human_like_interval(self) -> float:
        """
        Generate a random typing interval that mimics human typing speed.
        
        Returns:
            Interval in seconds between keystrokes
        
        Validates: Requirements 12.3
        """
        # Random interval between 30ms and 150ms
        interval_ms = random.uniform(
            self.MIN_TYPING_INTERVAL_MS,
            self.MAX_TYPING_INTERVAL_MS
        )
        return interval_ms / 1000.0  # Convert to seconds
    
    def _encode_special_character(self, char: str) -> Optional[tuple]:
        """
        Get the key combination needed for a special character.
        
        Args:
            char: Character to encode
        
        Returns:
            Tuple of (modifier, key) or None if not a special character
        
        Validates: Requirements 12.2
        """
        return self.SPECIAL_CHAR_MAP.get(char)
    
    def type_with_intelligence(
        self,
        text: str,
        verify_focus: bool = True,
        clear_existing: bool = False,
        verify_result: bool = True,
        expected_window: Optional[str] = None,
        use_human_speed: bool = True
    ) -> ToolResult:
        """
        Type text with intelligent features including focus verification,
        special character encoding, human-like speed, and result verification.
        
        Args:
            text: Text to type
            verify_focus: Whether to verify focus before typing
            clear_existing: Whether to clear existing text first
            verify_result: Whether to verify the typed text
            expected_window: Optional window title to verify focus
            use_human_speed: Whether to use human-like typing speed
        
        Returns:
            ToolResult with typing status and details
        
        Validates: Requirements 12.1, 12.2, 12.3, 12.4, 12.5
        """
        try:
            logger.info(f"Intelligent typing: text_length={len(text)}, "
                       f"verify_focus={verify_focus}, clear_existing={clear_existing}, "
                       f"verify_result={verify_result}, use_human_speed={use_human_speed}")
            
            # Step 1: Verify focus (Requirement 12.1)
            if verify_focus:
                focus_result = self.verify_focus(expected_window)
                if not focus_result.success:
                    return ToolResult(
                        success=False,
                        error=f"Focus verification failed: {focus_result.error}"
                    )
            
            # Step 2: Clear existing text if requested (Requirement 12.4)
            if clear_existing:
                clear_result = self.clear_existing_text()
                if not clear_result.success:
                    logger.warning(f"Text clearing failed: {clear_result.error}")
                    # Continue anyway as this is not critical
            
            # Step 3: Type the text with special character encoding and human-like speed
            # (Requirements 12.2, 12.3)
            chars_typed = 0
            special_chars_encoded = 0
            
            for char in text:
                # Check if this is a special character that needs encoding
                special_encoding = self._encode_special_character(char)
                
                if special_encoding:
                    # Type special character with modifier
                    modifier, key = special_encoding
                    pyautogui.hotkey(modifier, key)
                    special_chars_encoded += 1
                    logger.debug(f"Typed special character '{char}' using {modifier}+{key}")
                else:
                    # Type regular character
                    pyautogui.write(char, interval=0)
                
                chars_typed += 1
                
                # Add human-like delay between characters
                if use_human_speed and chars_typed < len(text):
                    interval = self._get_human_like_interval()
                    time.sleep(interval)
            
            logger.info(f"Typed {chars_typed} characters ({special_chars_encoded} special)")
            
            # Step 4: Verify the typed text (Requirement 12.5)
            verification_result = None
            if verify_result:
                verification_result = self.verify_typed_text(text)
                if not verification_result.success:
                    logger.warning(f"Typing verification failed: {verification_result.error}")
                    # Don't fail the entire operation, just log the warning
            
            return ToolResult(
                success=True,
                data={
                    "text_length": len(text),
                    "chars_typed": chars_typed,
                    "special_chars_encoded": special_chars_encoded,
                    "focus_verified": verify_focus,
                    "text_cleared": clear_existing,
                    "result_verified": verify_result,
                    "verification_passed": verification_result.success if verification_result else None,
                    "human_speed_used": use_human_speed,
                    "timestamp": time.time()
                }
            )
        
        except Exception as e:
            logger.error(f"Intelligent typing failed: {e}")
            return ToolResult(
                success=False,
                error=f"Intelligent typing failed: {str(e)}"
            )
    
    def verify_typed_text(self, expected_text: str) -> ToolResult:
        """
        Verify that the typed text appears in the target field.
        
        This uses clipboard-based verification: select all, copy, and compare.
        
        Args:
            expected_text: The text that should have been typed
        
        Returns:
            ToolResult indicating if verification passed
        
        Validates: Requirements 12.5
        """
        try:
            if not CLIPBOARD_AVAILABLE:
                logger.warning("Typing verification requires pyperclip library")
                return ToolResult(
                    success=False,
                    error="Clipboard not available for verification"
                )
            
            logger.debug("Verifying typed text using clipboard")
            
            # Save current clipboard content
            original_clipboard = pyperclip.paste()
            
            # Select all text in the field
            pyautogui.hotkey('ctrl', 'a')
            time.sleep(0.1)
            
            # Copy to clipboard
            pyautogui.hotkey('ctrl', 'c')
            time.sleep(0.2)  # Wait for clipboard operation
            
            # Get the copied text
            actual_text = pyperclip.paste()
            
            # Restore original clipboard
            pyperclip.copy(original_clipboard)
            
            # Compare texts
            if actual_text == expected_text:
                logger.debug("Typing verification passed")
                return ToolResult(
                    success=True,
                    data={
                        "expected_length": len(expected_text),
                        "actual_length": len(actual_text),
                        "match": True
                    }
                )
            else:
                logger.warning(f"Typing verification failed: expected '{expected_text}', got '{actual_text}'")
                return ToolResult(
                    success=False,
                    error=f"Text mismatch: expected '{expected_text}', got '{actual_text}'",
                    data={
                        "expected_length": len(expected_text),
                        "actual_length": len(actual_text),
                        "match": False
                    }
                )
        
        except Exception as e:
            logger.error(f"Typing verification failed: {e}")
            return ToolResult(
                success=False,
                error=f"Typing verification failed: {str(e)}"
            )


# Create a singleton instance for easy access
intelligent_text_input = IntelligentTextInput()
