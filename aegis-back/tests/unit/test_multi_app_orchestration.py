"""
Unit tests for multi-app orchestration features.

Tests the new clipboard operations, application identification,
and context tracking functionality.
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from src.rpa_tools import (
    copy_to_clipboard,
    paste_from_clipboard,
    get_active_window,
    list_open_windows,
    launch_application
)
from src.rpa_engine import RPAEngine
from src.adk_agent import ADKAgentManager
from src.models import ToolResult


class TestClipboardOperations:
    """Test clipboard operations for data transfer between applications."""
    
    @patch('src.rpa_tools.CLIPBOARD_AVAILABLE', True)
    @patch('src.rpa_tools.pyperclip')
    def test_copy_to_clipboard_success(self, mock_pyperclip):
        """Test successful clipboard copy operation."""
        test_text = "Hello, World!"
        mock_pyperclip.paste.return_value = test_text
        
        result = copy_to_clipboard(test_text)
        
        assert result.success is True
        assert result.data["text_length"] == len(test_text)
        mock_pyperclip.copy.assert_called_once_with(test_text)
    
    @patch('src.rpa_tools.CLIPBOARD_AVAILABLE', False)
    def test_copy_to_clipboard_unavailable(self):
        """Test clipboard copy when pyperclip is not available."""
        result = copy_to_clipboard("test")
        
        assert result.success is False
        assert "pyperclip" in result.error.lower()
    
    @patch('src.rpa_tools.CLIPBOARD_AVAILABLE', True)
    @patch('src.rpa_tools.pyperclip')
    def test_paste_from_clipboard_success(self, mock_pyperclip):
        """Test successful clipboard paste operation."""
        test_text = "Clipboard content"
        mock_pyperclip.paste.return_value = test_text
        
        result = paste_from_clipboard()
        
        assert result.success is True
        assert result.data["text"] == test_text
        assert result.data["text_length"] == len(test_text)
    
    @patch('src.rpa_tools.CLIPBOARD_AVAILABLE', False)
    def test_paste_from_clipboard_unavailable(self):
        """Test clipboard paste when pyperclip is not available."""
        result = paste_from_clipboard()
        
        assert result.success is False
        assert "pyperclip" in result.error.lower()


class TestWindowManagement:
    """Test window management for multi-app orchestration."""
    
    @patch('src.rpa_tools.WINDOWS_AVAILABLE', True)
    @patch('src.rpa_tools.win32gui')
    @patch('src.rpa_tools.win32process')
    def test_get_active_window_success(self, mock_win32process, mock_win32gui):
        """Test getting active window information."""
        mock_win32gui.GetForegroundWindow.return_value = 12345
        mock_win32gui.GetWindowText.return_value = "Notepad"
        mock_win32process.GetWindowThreadProcessId.return_value = (1, 6789)
        
        result = get_active_window()
        
        assert result.success is True
        assert result.data["hwnd"] == 12345
        assert result.data["title"] == "Notepad"
        assert result.data["pid"] == 6789
    
    @patch('src.rpa_tools.WINDOWS_AVAILABLE', False)
    def test_get_active_window_unavailable(self):
        """Test get active window when Windows API is not available."""
        result = get_active_window()
        
        assert result.success is False
        assert "windows" in result.error.lower()
    
    @patch('src.rpa_tools.WINDOWS_AVAILABLE', True)
    @patch('src.rpa_tools.win32gui')
    @patch('src.rpa_tools.win32process')
    def test_list_open_windows_success(self, mock_win32process, mock_win32gui):
        """Test listing all open windows."""
        # Mock window enumeration
        def enum_windows_callback(callback, windows_list):
            # Simulate 3 windows
            for hwnd in [100, 200, 300]:
                callback(hwnd, windows_list)
        
        mock_win32gui.EnumWindows.side_effect = enum_windows_callback
        mock_win32gui.IsWindowVisible.return_value = True
        mock_win32gui.GetWindowText.side_effect = ["Notepad", "Chrome", "Excel"]
        mock_win32process.GetWindowThreadProcessId.side_effect = [
            (1, 1001), (1, 1002), (1, 1003)
        ]
        
        result = list_open_windows()
        
        assert result.success is True
        assert result.data["count"] == 3
        assert len(result.data["windows"]) == 3
        assert result.data["windows"][0]["title"] == "Notepad"


class TestApplicationLaunchWithReadiness:
    """Test enhanced application launch with readiness check."""
    
    @patch('src.rpa_tools.WINDOWS_AVAILABLE', True)
    @patch('src.rpa_tools.subprocess.Popen')
    @patch('src.rpa_tools.win32gui')
    @patch('src.rpa_tools.time.sleep')
    def test_launch_application_already_running(self, mock_sleep, mock_win32gui, mock_popen):
        """Test launching application that is already running."""
        # Mock window enumeration to show app is already running
        def enum_windows_callback(callback, windows_list):
            callback(12345, windows_list)
        
        mock_win32gui.EnumWindows.side_effect = enum_windows_callback
        mock_win32gui.IsWindowVisible.return_value = True
        mock_win32gui.GetWindowText.return_value = "Notepad - Untitled"
        
        result = launch_application("notepad", wait_time=5)
        
        assert result.success is True
        assert result.data["already_running"] is True
        # Should not launch if already running
        mock_popen.assert_not_called()
    
    @patch('src.rpa_tools.WINDOWS_AVAILABLE', True)
    @patch('src.rpa_tools.subprocess.Popen')
    @patch('src.rpa_tools.win32gui')
    @patch('src.rpa_tools.time.sleep')
    def test_launch_application_with_readiness_check(self, mock_sleep, mock_win32gui, mock_popen):
        """Test launching application with readiness verification."""
        # First check: no windows (not running)
        # Second check: window appeared (ready)
        call_count = [0]
        
        def enum_windows_callback(callback, windows_list):
            call_count[0] += 1
            if call_count[0] > 1:  # Second call after launch
                callback(12345, windows_list)
        
        mock_win32gui.EnumWindows.side_effect = enum_windows_callback
        mock_win32gui.IsWindowVisible.return_value = True
        mock_win32gui.GetWindowText.return_value = "Notepad"
        
        mock_process = Mock()
        mock_process.pid = 9999
        mock_process.poll.return_value = None
        mock_popen.return_value = mock_process
        
        result = launch_application("notepad", wait_time=5)
        
        assert result.success is True
        assert result.data["window_ready"] is True
        assert result.data["pid"] == 9999
        mock_popen.assert_called_once()


class TestRPAEngineMultiApp:
    """Test RPA Engine with multi-app orchestration methods."""
    
    def test_engine_has_clipboard_methods(self):
        """Test that RPA Engine has clipboard operation methods."""
        engine = RPAEngine()
        
        assert hasattr(engine, 'execute_copy_to_clipboard')
        assert hasattr(engine, 'execute_paste_from_clipboard')
        assert hasattr(engine, 'get_active_window_info')
        assert hasattr(engine, 'list_all_open_windows')


class TestADKAgentMultiApp:
    """Test ADK Agent Manager with multi-app orchestration features."""
    
    def test_agent_has_application_context(self):
        """Test that ADK Agent has application context tracking."""
        with patch.dict('os.environ', {'GOOGLE_ADK_API_KEY': 'test-key'}):
            agent = ADKAgentManager()
            
            assert hasattr(agent, 'active_application')
            assert hasattr(agent, 'application_context')
            assert agent.active_application is None
            assert agent.application_context == {}
    
    def test_identify_applications_single_app(self):
        """Test application identification with single app."""
        with patch.dict('os.environ', {'GOOGLE_ADK_API_KEY': 'test-key'}):
            agent = ADKAgentManager()
            
            instruction = "Open notepad and type hello"
            apps = agent._identify_applications(instruction)
            
            assert "notepad" in apps
    
    def test_identify_applications_multiple_apps(self):
        """Test application identification with multiple apps."""
        with patch.dict('os.environ', {'GOOGLE_ADK_API_KEY': 'test-key'}):
            agent = ADKAgentManager()
            
            instruction = "Copy data from Excel and paste into Word"
            apps = agent._identify_applications(instruction)
            
            assert "excel" in apps
            assert "word" in apps
            assert len(apps) == 2
    
    def test_update_active_application(self):
        """Test updating active application context."""
        with patch.dict('os.environ', {'GOOGLE_ADK_API_KEY': 'test-key'}):
            agent = ADKAgentManager()
            
            agent._update_active_application("notepad")
            
            assert agent.active_application == "notepad"
            assert "notepad" in agent.application_context
            assert agent.application_context["notepad"]["action_count"] == 1
            
            # Update again
            agent._update_active_application("notepad")
            assert agent.application_context["notepad"]["action_count"] == 2
    
    def test_should_focus_application(self):
        """Test determining if application focus is needed."""
        with patch.dict('os.environ', {'GOOGLE_ADK_API_KEY': 'test-key'}):
            agent = ADKAgentManager()
            agent.active_application = "notepad"
            
            # Tools that require focus
            assert agent._should_focus_application("click_element", {}) == "notepad"
            assert agent._should_focus_application("type_text", {}) == "notepad"
            
            # Tools that don't require focus
            assert agent._should_focus_application("launch_application", {}) is None
            assert agent._should_focus_application("capture_screen", {}) is None
