"""
Unit tests for Intelligent Text Input module.

Tests the intelligent text input features including focus verification,
special character encoding, human-like typing speed, text clearing, and
typing verification.
"""

import unittest
from unittest.mock import patch, MagicMock, call
import time

from src.intelligent_text_input import IntelligentTextInput
from src.models import ToolResult


class TestIntelligentTextInput(unittest.TestCase):
    """Test cases for IntelligentTextInput class."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.text_input = IntelligentTextInput()
    
    @patch('src.intelligent_text_input.WINDOWS_AVAILABLE', True)
    @patch('src.intelligent_text_input.win32gui')
    def test_verify_focus_success(self, mock_win32gui):
        """Test successful focus verification."""
        mock_win32gui.GetForegroundWindow.return_value = 12345
        mock_win32gui.GetWindowText.return_value = "Notepad"
        
        result = self.text_input.verify_focus()
        
        assert result.success is True
        assert result.data["window_title"] == "Notepad"
        assert result.data["focus_verified"] is True
    
    @patch('src.intelligent_text_input.WINDOWS_AVAILABLE', True)
    @patch('src.intelligent_text_input.win32gui')
    def test_verify_focus_with_expected_window(self, mock_win32gui):
        """Test focus verification with expected window title."""
        mock_win32gui.GetForegroundWindow.return_value = 12345
        mock_win32gui.GetWindowText.return_value = "Notepad - Untitled"
        
        result = self.text_input.verify_focus(expected_window="Notepad")
        
        assert result.success is True
        assert "Notepad" in result.data["window_title"]
    
    @patch('src.intelligent_text_input.WINDOWS_AVAILABLE', True)
    @patch('src.intelligent_text_input.win32gui')
    def test_verify_focus_wrong_window(self, mock_win32gui):
        """Test focus verification fails when wrong window is focused."""
        mock_win32gui.GetForegroundWindow.return_value = 12345
        mock_win32gui.GetWindowText.return_value = "Chrome"
        
        result = self.text_input.verify_focus(expected_window="Notepad")
        
        assert result.success is False
        assert "Expected window" in result.error
    
    @patch('src.intelligent_text_input.WINDOWS_AVAILABLE', False)
    def test_verify_focus_non_windows(self):
        """Test focus verification on non-Windows platform."""
        result = self.text_input.verify_focus()
        
        # Should succeed but with assumed focus
        assert result.success is True
        assert result.data["platform"] == "non-windows"
        assert result.data["assumed_focused"] is True
    
    @patch('src.intelligent_text_input.pyautogui')
    @patch('src.intelligent_text_input.time.sleep')
    def test_clear_existing_text(self, mock_sleep, mock_pyautogui):
        """Test clearing existing text with Ctrl+A."""
        result = self.text_input.clear_existing_text()
        
        assert result.success is True
        mock_pyautogui.hotkey.assert_called_once_with('ctrl', 'a')
        mock_pyautogui.press.assert_called_once_with('delete')
        assert result.data["method"] == "ctrl+a_delete"
    
    def test_get_human_like_interval(self):
        """Test human-like typing interval generation."""
        # Generate multiple intervals and check they're in range
        intervals = [self.text_input._get_human_like_interval() for _ in range(100)]
        
        min_interval = self.text_input.MIN_TYPING_INTERVAL_MS / 1000.0
        max_interval = self.text_input.MAX_TYPING_INTERVAL_MS / 1000.0
        
        for interval in intervals:
            assert min_interval <= interval <= max_interval
    
    def test_encode_special_character(self):
        """Test special character encoding."""
        # Test known special characters
        assert self.text_input._encode_special_character('@') == ('shift', '2')
        assert self.text_input._encode_special_character('#') == ('shift', '3')
        assert self.text_input._encode_special_character('$') == ('shift', '4')
        assert self.text_input._encode_special_character('!') is None  # Not in map
        assert self.text_input._encode_special_character('a') is None  # Regular char
    
    @patch('src.intelligent_text_input.pyautogui')
    @patch('src.intelligent_text_input.time.sleep')
    def test_type_with_intelligence_basic(self, mock_sleep, mock_pyautogui):
        """Test basic intelligent typing without verification."""
        with patch.object(self.text_input, 'verify_focus') as mock_verify:
            mock_verify.return_value = ToolResult(success=True, data={"focus_verified": True})
            
            result = self.text_input.type_with_intelligence(
                text="hello",
                verify_focus=True,
                clear_existing=False,
                verify_result=False,
                use_human_speed=False
            )
            
            assert result.success is True
            assert result.data["text_length"] == 5
            assert result.data["chars_typed"] == 5
            assert result.data["special_chars_encoded"] == 0
            mock_verify.assert_called_once()
    
    @patch('src.intelligent_text_input.pyautogui')
    @patch('src.intelligent_text_input.time.sleep')
    def test_type_with_intelligence_special_chars(self, mock_sleep, mock_pyautogui):
        """Test intelligent typing with special characters."""
        with patch.object(self.text_input, 'verify_focus') as mock_verify:
            mock_verify.return_value = ToolResult(success=True, data={"focus_verified": True})
            
            result = self.text_input.type_with_intelligence(
                text="test@email.com",
                verify_focus=True,
                clear_existing=False,
                verify_result=False,
                use_human_speed=False
            )
            
            assert result.success is True
            assert result.data["special_chars_encoded"] == 1  # @ symbol
            # Verify hotkey was called for @
            mock_pyautogui.hotkey.assert_any_call('shift', '2')
    
    @patch('src.intelligent_text_input.pyautogui')
    @patch('src.intelligent_text_input.time.sleep')
    def test_type_with_intelligence_clear_existing(self, mock_sleep, mock_pyautogui):
        """Test intelligent typing with text clearing."""
        with patch.object(self.text_input, 'verify_focus') as mock_verify:
            with patch.object(self.text_input, 'clear_existing_text') as mock_clear:
                mock_verify.return_value = ToolResult(success=True, data={"focus_verified": True})
                mock_clear.return_value = ToolResult(success=True, data={"action": "clear_text"})
                
                result = self.text_input.type_with_intelligence(
                    text="new text",
                    verify_focus=True,
                    clear_existing=True,
                    verify_result=False,
                    use_human_speed=False
                )
                
                assert result.success is True
                assert result.data["text_cleared"] is True
                mock_clear.assert_called_once()
    
    @patch('src.intelligent_text_input.pyautogui')
    @patch('src.intelligent_text_input.time.sleep')
    def test_type_with_intelligence_focus_fails(self, mock_sleep, mock_pyautogui):
        """Test intelligent typing fails when focus verification fails."""
        with patch.object(self.text_input, 'verify_focus') as mock_verify:
            mock_verify.return_value = ToolResult(success=False, error="No focus")
            
            result = self.text_input.type_with_intelligence(
                text="hello",
                verify_focus=True,
                verify_result=False
            )
            
            assert result.success is False
            assert "Focus verification failed" in result.error
            # Should not attempt to type
            mock_pyautogui.write.assert_not_called()
    
    @patch('src.intelligent_text_input.CLIPBOARD_AVAILABLE', True)
    @patch('src.intelligent_text_input.pyperclip')
    @patch('src.intelligent_text_input.pyautogui')
    @patch('src.intelligent_text_input.time.sleep')
    def test_verify_typed_text_success(self, mock_sleep, mock_pyautogui, mock_pyperclip):
        """Test typing verification succeeds when text matches."""
        mock_pyperclip.paste.side_effect = ["original", "hello", "original"]
        
        result = self.text_input.verify_typed_text("hello")
        
        assert result.success is True
        assert result.data["match"] is True
        assert result.data["expected_length"] == 5
        assert result.data["actual_length"] == 5
    
    @patch('src.intelligent_text_input.CLIPBOARD_AVAILABLE', True)
    @patch('src.intelligent_text_input.pyperclip')
    @patch('src.intelligent_text_input.pyautogui')
    @patch('src.intelligent_text_input.time.sleep')
    def test_verify_typed_text_mismatch(self, mock_sleep, mock_pyautogui, mock_pyperclip):
        """Test typing verification fails when text doesn't match."""
        mock_pyperclip.paste.side_effect = ["original", "world", "original"]
        
        result = self.text_input.verify_typed_text("hello")
        
        assert result.success is False
        assert result.data["match"] is False
        assert "Text mismatch" in result.error
    
    @patch('src.intelligent_text_input.CLIPBOARD_AVAILABLE', False)
    def test_verify_typed_text_no_clipboard(self):
        """Test typing verification fails when clipboard is not available."""
        result = self.text_input.verify_typed_text("hello")
        
        assert result.success is False
        assert "Clipboard not available" in result.error


if __name__ == '__main__':
    unittest.main()
