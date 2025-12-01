"""
Unit tests for RPA Engine.

Tests the core RPA engine functionality including retry logic and action execution.
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from src.rpa_engine import RPAEngine
from src.models import ActionResult, ToolResult


class TestRPAEngine:
    """Test suite for RPAEngine class."""
    
    def setup_method(self):
        """Set up test fixtures."""
        self.engine = RPAEngine(max_retries=3)
    
    def test_initialization(self):
        """Test RPAEngine initialization."""
        assert self.engine.max_retries == 3
        assert self.engine.retry_delays == [1, 2, 4]
    
    @patch('src.rpa_engine.click_element')
    def test_execute_click_success(self, mock_click):
        """Test successful click execution."""
        # Mock successful click
        mock_click.return_value = ToolResult(success=True, data={"x": 100, "y": 200})
        
        result = self.engine.execute_click(100, 200, "left")
        
        assert result.success is True
        assert result.retry_count == 0
        assert result.error is None
        mock_click.assert_called_once_with(100, 200, "left")
    
    @patch('src.rpa_engine.click_element')
    @patch('src.rpa_engine.time.sleep')
    def test_execute_click_retry_then_success(self, mock_sleep, mock_click):
        """Test click execution that fails once then succeeds."""
        # First call fails, second succeeds
        mock_click.side_effect = [
            ToolResult(success=False, error="First attempt failed"),
            ToolResult(success=True, data={"x": 100, "y": 200})
        ]
        
        result = self.engine.execute_click(100, 200, "left")
        
        assert result.success is True
        assert result.retry_count == 1
        assert result.error is None
        assert mock_click.call_count == 2
        mock_sleep.assert_called_once_with(1)  # First retry delay
    
    @patch('src.rpa_engine.click_element')
    @patch('src.rpa_engine.time.sleep')
    def test_execute_click_all_retries_fail(self, mock_sleep, mock_click):
        """Test click execution that fails all retries."""
        # All attempts fail
        mock_click.return_value = ToolResult(success=False, error="Click failed")
        
        result = self.engine.execute_click(100, 200, "left")
        
        assert result.success is False
        assert result.retry_count == 3
        assert result.error == "Click failed"
        assert mock_click.call_count == 3
        assert mock_sleep.call_count == 2  # Sleep between retries (not after last)
    
    @patch('src.rpa_engine.type_text')
    def test_execute_type_success(self, mock_type):
        """Test successful typing execution."""
        mock_type.return_value = ToolResult(success=True, data={"text_length": 5})
        
        result = self.engine.execute_type("hello", 0.05)
        
        assert result.success is True
        assert result.retry_count == 0
        mock_type.assert_called_once_with("hello", 0.05)
    
    @patch('src.rpa_engine.press_key')
    def test_execute_key_press_success(self, mock_press):
        """Test successful key press execution."""
        mock_press.return_value = ToolResult(success=True, data={"key": "enter"})
        
        result = self.engine.execute_key_press("enter", ["ctrl"])
        
        assert result.success is True
        assert result.retry_count == 0
        mock_press.assert_called_once_with("enter", ["ctrl"])
    
    @patch('src.rpa_engine.press_key')
    def test_execute_key_press_no_modifiers(self, mock_press):
        """Test key press without modifiers."""
        mock_press.return_value = ToolResult(success=True, data={"key": "a"})
        
        result = self.engine.execute_key_press("a", None)
        
        assert result.success is True
        mock_press.assert_called_once_with("a", [])
    
    @patch('src.rpa_engine.launch_application')
    def test_launch_app_success(self, mock_launch):
        """Test successful application launch."""
        mock_launch.return_value = ToolResult(success=True, data={"pid": 1234})
        
        result = self.engine.launch_app("notepad.exe", 5)
        
        assert result.success is True
        assert result.retry_count == 0
        mock_launch.assert_called_once_with("notepad.exe", 5)
    
    @patch('src.rpa_engine.focus_window')
    def test_execute_focus_window_success(self, mock_focus):
        """Test successful window focus."""
        mock_focus.return_value = ToolResult(success=True, data={"window_title": "Notepad"})
        
        result = self.engine.execute_focus_window("Notepad")
        
        assert result.success is True
        assert result.retry_count == 0
        mock_focus.assert_called_once_with("Notepad")
    
    @patch('src.rpa_engine.scroll')
    def test_execute_scroll_success(self, mock_scroll):
        """Test successful scroll execution."""
        mock_scroll.return_value = ToolResult(success=True, data={"direction": "down"})
        
        result = self.engine.execute_scroll("down", 5)
        
        assert result.success is True
        assert result.retry_count == 0
        mock_scroll.assert_called_once_with("down", 5)
    
    @patch('src.rpa_engine.capture_screen')
    def test_capture_screen_state(self, mock_capture):
        """Test screen capture (no retry logic)."""
        mock_capture.return_value = ToolResult(
            success=True,
            data={"image": "base64data", "width": 1920, "height": 1080}
        )
        
        result = self.engine.capture_screen_state()
        
        assert result.success is True
        mock_capture.assert_called_once_with(None)
    
    @patch('src.rpa_engine.capture_screen')
    def test_capture_screen_state_with_region(self, mock_capture):
        """Test screen capture with region."""
        region = (0, 0, 800, 600)
        mock_capture.return_value = ToolResult(success=True, data={"image": "base64data"})
        
        result = self.engine.capture_screen_state(region)
        
        assert result.success is True
        mock_capture.assert_called_once_with(region)
    
    @patch('src.rpa_engine.click_element')
    @patch('src.rpa_engine.time.sleep')
    def test_exponential_backoff_delays(self, mock_sleep, mock_click):
        """Test that retry delays follow exponential backoff pattern."""
        # All attempts fail
        mock_click.return_value = ToolResult(success=False, error="Failed")
        
        self.engine.execute_click(100, 200)
        
        # Verify sleep was called with correct delays
        assert mock_sleep.call_count == 2
        calls = [call[0][0] for call in mock_sleep.call_args_list]
        assert calls == [1, 2]  # First and second retry delays
