"""
Unit tests for RPA Tools.

Tests each tool function with mocked PyAutoGUI/Win32API, error handling,
and ToolResult structure validation.

Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5
"""

import pytest
from unittest.mock import Mock, patch, MagicMock, call
from PIL import Image
from io import BytesIO
import base64

from src.rpa_tools import (
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
)
from src.models import ToolResult


class TestClickElement:
    """Test suite for click_element tool."""
    
    @patch('src.rpa_tools.pyautogui')
    def test_click_element_success_left_button(self, mock_pyautogui):
        """Test successful left click at valid coordinates."""
        mock_pyautogui.size.return_value = (1920, 1080)
        
        result = click_element(100, 200, "left")
        
        assert isinstance(result, ToolResult)
        assert result.success is True
        assert result.data["x"] == 100
        assert result.data["y"] == 200
        assert result.data["button"] == "left"
        assert "timestamp" in result.data
        mock_pyautogui.click.assert_called_once_with(x=100, y=200, button="left")

    @patch('src.rpa_tools.pyautogui')
    def test_click_element_success_right_button(self, mock_pyautogui):
        """Test successful right click."""
        mock_pyautogui.size.return_value = (1920, 1080)
        
        result = click_element(500, 600, "right")
        
        assert result.success is True
        assert result.data["button"] == "right"
        mock_pyautogui.click.assert_called_once_with(x=500, y=600, button="right")
    
    @patch('src.rpa_tools.pyautogui')
    def test_click_element_invalid_button(self, mock_pyautogui):
        """Test click with invalid button parameter."""
        mock_pyautogui.size.return_value = (1920, 1080)
        
        result = click_element(100, 200, "invalid")
        
        assert result.success is False
        assert "Invalid button" in result.error
        mock_pyautogui.click.assert_not_called()
    
    @patch('src.rpa_tools.pyautogui')
    def test_click_element_out_of_bounds(self, mock_pyautogui):
        """Test click with coordinates outside screen bounds."""
        mock_pyautogui.size.return_value = (1920, 1080)
        
        result = click_element(2000, 200, "left")
        
        assert result.success is False
        assert "out of screen bounds" in result.error
        mock_pyautogui.click.assert_not_called()
    
    @patch('src.rpa_tools.pyautogui')
    def test_click_element_exception_handling(self, mock_pyautogui):
        """Test click error handling when PyAutoGUI raises exception."""
        mock_pyautogui.size.return_value = (1920, 1080)
        mock_pyautogui.click.side_effect = Exception("Mouse error")
        
        result = click_element(100, 200, "left")
        
        assert result.success is False
        assert "Click failed" in result.error
        assert "Mouse error" in result.error


class TestTypeText:
    """Test suite for type_text tool."""
    
    @patch('src.rpa_tools.pyautogui')
    def test_type_text_basic_success(self, mock_pyautogui):
        """Test basic text typing without intelligent features."""
        result = type_text("Hello World", interval=0.05, use_intelligent=False)
        
        assert isinstance(result, ToolResult)
        assert result.success is True
        assert result.data["text_length"] == 11
        assert result.data["interval"] == 0.05
        assert result.data["intelligent_mode"] is False
        mock_pyautogui.write.assert_called_once_with("Hello World", interval=0.05)

    @patch('src.rpa_tools.pyautogui')
    def test_type_text_negative_interval(self, mock_pyautogui):
        """Test type_text with negative interval."""
        result = type_text("Test", interval=-0.1, use_intelligent=False)
        
        assert result.success is False
        assert "Interval must be non-negative" in result.error
        mock_pyautogui.write.assert_not_called()
    
    @patch('src.rpa_tools.pyautogui')
    def test_type_text_exception_handling(self, mock_pyautogui):
        """Test type_text error handling."""
        mock_pyautogui.write.side_effect = Exception("Keyboard error")
        
        result = type_text("Test", use_intelligent=False)
        
        assert result.success is False
        assert "Typing failed" in result.error


class TestPressKey:
    """Test suite for press_key tool."""
    
    @patch('src.rpa_tools.pyautogui')
    def test_press_key_without_modifiers(self, mock_pyautogui):
        """Test pressing a single key without modifiers."""
        result = press_key("enter")
        
        assert isinstance(result, ToolResult)
        assert result.success is True
        assert result.data["key"] == "enter"
        assert result.data["modifiers"] == []
        mock_pyautogui.press.assert_called_once_with("enter")
    
    @patch('src.rpa_tools.pyautogui')
    def test_press_key_with_single_modifier(self, mock_pyautogui):
        """Test pressing key with single modifier."""
        result = press_key("c", modifiers=["ctrl"])
        
        assert result.success is True
        assert result.data["key"] == "c"
        assert result.data["modifiers"] == ["ctrl"]
        mock_pyautogui.hotkey.assert_called_once_with("ctrl", "c")
    
    @patch('src.rpa_tools.pyautogui')
    def test_press_key_with_multiple_modifiers(self, mock_pyautogui):
        """Test pressing key with multiple modifiers."""
        result = press_key("v", modifiers=["ctrl", "shift"])
        
        assert result.success is True
        mock_pyautogui.hotkey.assert_called_once_with("ctrl", "shift", "v")
    
    @patch('src.rpa_tools.pyautogui')
    def test_press_key_invalid_modifier(self, mock_pyautogui):
        """Test press_key with invalid modifier."""
        result = press_key("a", modifiers=["invalid"])
        
        assert result.success is False
        assert "Invalid modifier" in result.error
        mock_pyautogui.hotkey.assert_not_called()
        mock_pyautogui.press.assert_not_called()

    @patch('src.rpa_tools.pyautogui')
    def test_press_key_exception_handling(self, mock_pyautogui):
        """Test press_key error handling."""
        mock_pyautogui.press.side_effect = Exception("Key error")
        
        result = press_key("enter")
        
        assert result.success is False
        assert "Key press failed" in result.error


class TestLaunchApplication:
    """Test suite for launch_application tool."""
    
    @patch('src.rpa_tools.subprocess.Popen')
    @patch('src.rpa_tools.time.sleep')
    @patch('src.rpa_tools.WINDOWS_AVAILABLE', False)
    def test_launch_application_success_non_windows(self, mock_sleep, mock_popen):
        """Test successful application launch on non-Windows platform."""
        mock_process = Mock()
        mock_process.poll.return_value = None
        mock_process.pid = 12345
        mock_popen.return_value = mock_process
        
        result = launch_application("notepad.exe", wait_time=2)
        
        assert isinstance(result, ToolResult)
        assert result.success is True
        assert result.data["app_name"] == "notepad.exe"
        assert result.data["pid"] == 12345
        assert result.data["wait_time"] == 2
        mock_popen.assert_called_once_with("notepad.exe", shell=True)
    
    @patch('src.rpa_tools.subprocess.Popen')
    @patch('src.rpa_tools.time.sleep')
    def test_launch_application_negative_wait_time(self, mock_sleep, mock_popen):
        """Test launch_application with negative wait time."""
        result = launch_application("notepad.exe", wait_time=-1)
        
        assert result.success is False
        assert "Wait time must be non-negative" in result.error
        mock_popen.assert_not_called()
    
    @patch('src.rpa_tools.subprocess.Popen')
    @patch('src.rpa_tools.time.sleep')
    def test_launch_application_file_not_found(self, mock_sleep, mock_popen):
        """Test launch_application with non-existent application."""
        mock_popen.side_effect = FileNotFoundError()
        
        result = launch_application("nonexistent.exe")
        
        assert result.success is False
        assert "not found" in result.error
    
    @patch('src.rpa_tools.subprocess.Popen')
    @patch('src.rpa_tools.time.sleep')
    @patch('src.rpa_tools.WINDOWS_AVAILABLE', False)
    def test_launch_application_process_exits_with_error(self, mock_sleep, mock_popen):
        """Test launch_application when process exits with error code."""
        mock_process = Mock()
        mock_process.poll.return_value = 1  # Non-zero exit code
        mock_popen.return_value = mock_process
        
        result = launch_application("app.exe")
        
        assert result.success is False
        assert "exited with code 1" in result.error


class TestFocusWindow:
    """Test suite for focus_window tool."""
    
    @patch('src.rpa_tools.WINDOWS_AVAILABLE', False)
    def test_focus_window_non_windows_platform(self):
        """Test focus_window on non-Windows platform."""
        result = focus_window("Notepad")
        
        assert result.success is False
        assert "requires Windows platform" in result.error
    
    @patch('src.rpa_tools.WINDOWS_AVAILABLE', True)
    @patch('src.rpa_tools.win32gui')
    def test_focus_window_success(self, mock_win32gui):
        """Test successful window focus."""
        # Mock window enumeration
        def enum_windows_side_effect(callback, windows):
            callback(12345, windows)
            return True
        
        mock_win32gui.EnumWindows.side_effect = enum_windows_side_effect
        mock_win32gui.IsWindowVisible.return_value = True
        mock_win32gui.GetWindowText.return_value = "Notepad - Untitled"
        
        result = focus_window("Notepad")
        
        assert result.success is True
        assert result.data["window_title"] == "Notepad - Untitled"
        assert result.data["hwnd"] == 12345
        mock_win32gui.ShowWindow.assert_called_once()
        mock_win32gui.SetForegroundWindow.assert_called_once_with(12345)
    
    @patch('src.rpa_tools.WINDOWS_AVAILABLE', True)
    @patch('src.rpa_tools.win32gui')
    def test_focus_window_not_found(self, mock_win32gui):
        """Test focus_window when window is not found."""
        def enum_windows_side_effect(callback, windows):
            # No windows match
            return True
        
        mock_win32gui.EnumWindows.side_effect = enum_windows_side_effect
        
        result = focus_window("NonExistent")
        
        assert result.success is False
        assert "No window found" in result.error


class TestCaptureScreen:
    """Test suite for capture_screen tool."""
    
    @patch('src.rpa_tools.pyautogui')
    def test_capture_screen_full_screen(self, mock_pyautogui):
        """Test full screen capture."""
        # Create a mock image
        mock_image = Image.new('RGB', (100, 100), color='red')
        mock_pyautogui.screenshot.return_value = mock_image
        
        result = capture_screen()
        
        assert isinstance(result, ToolResult)
        assert result.success is True
        assert "image" in result.data
        assert result.data["width"] == 100
        assert result.data["height"] == 100
        assert result.data["region"] is None
        mock_pyautogui.screenshot.assert_called_once_with()

    @patch('src.rpa_tools.pyautogui')
    def test_capture_screen_with_region(self, mock_pyautogui):
        """Test screen capture with specific region."""
        mock_image = Image.new('RGB', (50, 50), color='blue')
        mock_pyautogui.screenshot.return_value = mock_image
        
        region = (10, 20, 50, 50)
        result = capture_screen(region=region)
        
        assert result.success is True
        assert result.data["region"] == region
        mock_pyautogui.screenshot.assert_called_once_with(region=region)
    
    @patch('src.rpa_tools.pyautogui')
    def test_capture_screen_exception_handling(self, mock_pyautogui):
        """Test capture_screen error handling."""
        mock_pyautogui.screenshot.side_effect = Exception("Screen capture error")
        
        result = capture_screen()
        
        assert result.success is False
        assert "Screen capture failed" in result.error


class TestFindElementByImage:
    """Test suite for find_element_by_image tool."""
    
    @patch('src.rpa_tools.pyautogui')
    def test_find_element_by_image_success(self, mock_pyautogui):
        """Test successful image recognition."""
        # Mock location result
        mock_location = Mock()
        mock_location.left = 100
        mock_location.top = 200
        mock_location.width = 50
        mock_location.height = 30
        mock_pyautogui.locateOnScreen.return_value = mock_location
        
        mock_center = Mock()
        mock_center.x = 125
        mock_center.y = 215
        mock_pyautogui.center.return_value = mock_center
        
        result = find_element_by_image("template.png", confidence=0.9)
        
        assert isinstance(result, ToolResult)
        assert result.success is True
        assert result.data["x"] == 125
        assert result.data["y"] == 215
        assert result.data["confidence"] == 0.9
        mock_pyautogui.locateOnScreen.assert_called_once_with("template.png", confidence=0.9)
    
    @patch('src.rpa_tools.pyautogui')
    def test_find_element_by_image_not_found(self, mock_pyautogui):
        """Test image recognition when template not found."""
        mock_pyautogui.locateOnScreen.return_value = None
        
        result = find_element_by_image("template.png")
        
        assert result.success is False
        assert "not found on screen" in result.error
    
    @patch('src.rpa_tools.pyautogui')
    def test_find_element_by_image_invalid_confidence(self, mock_pyautogui):
        """Test find_element_by_image with invalid confidence value."""
        result = find_element_by_image("template.png", confidence=1.5)
        
        assert result.success is False
        assert "Confidence must be between 0 and 1" in result.error
        mock_pyautogui.locateOnScreen.assert_not_called()

    @patch('src.rpa_tools.pyautogui')
    def test_find_element_by_image_file_not_found(self, mock_pyautogui):
        """Test find_element_by_image with non-existent template file."""
        mock_pyautogui.locateOnScreen.side_effect = FileNotFoundError()
        
        result = find_element_by_image("nonexistent.png")
        
        assert result.success is False
        assert "not found" in result.error


class TestScroll:
    """Test suite for scroll tool."""
    
    @patch('src.rpa_tools.pyautogui')
    def test_scroll_up(self, mock_pyautogui):
        """Test scrolling up."""
        result = scroll("up", 5)
        
        assert isinstance(result, ToolResult)
        assert result.success is True
        assert result.data["direction"] == "up"
        assert result.data["amount"] == 5
        mock_pyautogui.scroll.assert_called_once_with(5)
    
    @patch('src.rpa_tools.pyautogui')
    def test_scroll_down(self, mock_pyautogui):
        """Test scrolling down."""
        result = scroll("down", 3)
        
        assert result.success is True
        assert result.data["direction"] == "down"
        mock_pyautogui.scroll.assert_called_once_with(-3)
    
    @patch('src.rpa_tools.pyautogui')
    def test_scroll_left(self, mock_pyautogui):
        """Test scrolling left."""
        result = scroll("left", 2)
        
        assert result.success is True
        mock_pyautogui.hscroll.assert_called_once_with(-2)
    
    @patch('src.rpa_tools.pyautogui')
    def test_scroll_right(self, mock_pyautogui):
        """Test scrolling right."""
        result = scroll("right", 4)
        
        assert result.success is True
        mock_pyautogui.hscroll.assert_called_once_with(4)
    
    @patch('src.rpa_tools.pyautogui')
    def test_scroll_invalid_direction(self, mock_pyautogui):
        """Test scroll with invalid direction."""
        result = scroll("diagonal", 5)
        
        assert result.success is False
        assert "Invalid direction" in result.error
        mock_pyautogui.scroll.assert_not_called()
    
    @patch('src.rpa_tools.pyautogui')
    def test_scroll_negative_amount(self, mock_pyautogui):
        """Test scroll with negative amount."""
        result = scroll("up", -5)
        
        assert result.success is False
        assert "Amount must be positive" in result.error
        mock_pyautogui.scroll.assert_not_called()


class TestClipboardOperations:
    """Test suite for clipboard operations."""
    
    @patch('src.rpa_tools.CLIPBOARD_AVAILABLE', True)
    @patch('src.rpa_tools.pyperclip')
    def test_copy_to_clipboard_success(self, mock_pyperclip):
        """Test successful copy to clipboard."""
        mock_pyperclip.paste.return_value = "Test text"
        
        result = copy_to_clipboard("Test text")
        
        assert isinstance(result, ToolResult)
        assert result.success is True
        assert result.data["text_length"] == 9
        mock_pyperclip.copy.assert_called_once_with("Test text")
    
    @patch('src.rpa_tools.CLIPBOARD_AVAILABLE', False)
    def test_copy_to_clipboard_unavailable(self):
        """Test copy_to_clipboard when pyperclip is unavailable."""
        result = copy_to_clipboard("Test")
        
        assert result.success is False
        assert "require pyperclip" in result.error
    
    @patch('src.rpa_tools.CLIPBOARD_AVAILABLE', True)
    @patch('src.rpa_tools.pyperclip')
    def test_copy_to_clipboard_verification_failure(self, mock_pyperclip):
        """Test copy_to_clipboard when verification fails."""
        mock_pyperclip.paste.return_value = "Different text"
        
        result = copy_to_clipboard("Test text")
        
        assert result.success is False
        assert "verification failed" in result.error
    
    @patch('src.rpa_tools.CLIPBOARD_AVAILABLE', True)
    @patch('src.rpa_tools.pyperclip')
    def test_paste_from_clipboard_success(self, mock_pyperclip):
        """Test successful paste from clipboard."""
        mock_pyperclip.paste.return_value = "Clipboard content"
        
        result = paste_from_clipboard()
        
        assert isinstance(result, ToolResult)
        assert result.success is True
        assert result.data["text"] == "Clipboard content"
        assert result.data["text_length"] == 17
    
    @patch('src.rpa_tools.CLIPBOARD_AVAILABLE', False)
    def test_paste_from_clipboard_unavailable(self):
        """Test paste_from_clipboard when pyperclip is unavailable."""
        result = paste_from_clipboard()
        
        assert result.success is False
        assert "require pyperclip" in result.error


class TestWindowOperations:
    """Test suite for window operations."""
    
    @patch('src.rpa_tools.WINDOWS_AVAILABLE', True)
    @patch('src.rpa_tools.win32gui')
    @patch('src.rpa_tools.win32process')
    def test_get_active_window_success(self, mock_win32process, mock_win32gui):
        """Test getting active window information."""
        mock_win32gui.GetForegroundWindow.return_value = 54321
        mock_win32gui.GetWindowText.return_value = "Active Window"
        mock_win32process.GetWindowThreadProcessId.return_value = (1, 9999)
        
        result = get_active_window()
        
        assert isinstance(result, ToolResult)
        assert result.success is True
        assert result.data["hwnd"] == 54321
        assert result.data["title"] == "Active Window"
        assert result.data["pid"] == 9999

    @patch('src.rpa_tools.WINDOWS_AVAILABLE', False)
    def test_get_active_window_non_windows(self):
        """Test get_active_window on non-Windows platform."""
        result = get_active_window()
        
        assert result.success is False
        assert "requires Windows platform" in result.error
    
    @patch('src.rpa_tools.WINDOWS_AVAILABLE', True)
    @patch('src.rpa_tools.win32gui')
    def test_get_active_window_no_window(self, mock_win32gui):
        """Test get_active_window when no window is active."""
        mock_win32gui.GetForegroundWindow.return_value = None
        
        result = get_active_window()
        
        assert result.success is False
        assert "No active window" in result.error
    
    @patch('src.rpa_tools.WINDOWS_AVAILABLE', True)
    @patch('src.rpa_tools.win32gui')
    @patch('src.rpa_tools.win32process')
    def test_list_open_windows_success(self, mock_win32process, mock_win32gui):
        """Test listing open windows."""
        # Mock window enumeration
        def enum_windows_side_effect(callback, windows):
            callback(111, windows)
            callback(222, windows)
            callback(333, windows)
            return True
        
        mock_win32gui.EnumWindows.side_effect = enum_windows_side_effect
        mock_win32gui.IsWindowVisible.return_value = True
        mock_win32gui.GetWindowText.side_effect = ["Window 1", "Window 2", "Window 3"]
        mock_win32process.GetWindowThreadProcessId.side_effect = [
            (1, 1001), (1, 1002), (1, 1003)
        ]
        
        result = list_open_windows()
        
        assert isinstance(result, ToolResult)
        assert result.success is True
        assert result.data["count"] == 3
        assert len(result.data["windows"]) == 3
        assert result.data["windows"][0]["title"] == "Window 1"
        assert result.data["windows"][0]["pid"] == 1001
    
    @patch('src.rpa_tools.WINDOWS_AVAILABLE', False)
    def test_list_open_windows_non_windows(self):
        """Test list_open_windows on non-Windows platform."""
        result = list_open_windows()
        
        assert result.success is False
        assert "requires Windows platform" in result.error


class TestToolResultStructure:
    """Test suite for ToolResult structure validation."""
    
    @patch('src.rpa_tools.pyautogui')
    def test_tool_result_has_required_fields(self, mock_pyautogui):
        """Test that ToolResult has all required fields."""
        mock_pyautogui.size.return_value = (1920, 1080)
        
        result = click_element(100, 200)
        
        # Check required fields exist
        assert hasattr(result, 'success')
        assert hasattr(result, 'data')
        assert hasattr(result, 'error')
        
        # Check types
        assert isinstance(result.success, bool)
        assert result.data is None or isinstance(result.data, dict)
        assert result.error is None or isinstance(result.error, str)
    
    @patch('src.rpa_tools.pyautogui')
    def test_successful_result_structure(self, mock_pyautogui):
        """Test structure of successful ToolResult."""
        mock_pyautogui.size.return_value = (1920, 1080)
        
        result = click_element(100, 200)
        
        assert result.success is True
        assert result.data is not None
        assert isinstance(result.data, dict)
        assert result.error is None
    
    @patch('src.rpa_tools.pyautogui')
    def test_failed_result_structure(self, mock_pyautogui):
        """Test structure of failed ToolResult."""
        mock_pyautogui.size.return_value = (1920, 1080)
        
        result = click_element(100, 200, "invalid_button")
        
        assert result.success is False
        assert result.error is not None
        assert isinstance(result.error, str)
