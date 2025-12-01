"""
Property-based tests for RPA Engine.

This module contains property-based tests using Hypothesis to verify
correctness properties for RPA engine actions.
"""

import pytest
from hypothesis import given, strategies as st, settings
from unittest.mock import Mock, patch, MagicMock
from src.rpa_engine import RPAEngine
from src.models import ActionResult, ToolResult


# Custom strategies for generating test data
@st.composite
def screen_coordinates(draw):
    """Generate valid screen coordinates."""
    x = draw(st.integers(min_value=0, max_value=1920))
    y = draw(st.integers(min_value=0, max_value=1080))
    return x, y


@st.composite
def mouse_buttons(draw):
    """Generate valid mouse button names."""
    return draw(st.sampled_from(["left", "right", "middle"]))


@st.composite
def text_inputs(draw):
    """Generate text inputs for typing."""
    return draw(st.text(min_size=1, max_size=100))


@st.composite
def key_names(draw):
    """Generate valid key names."""
    return draw(st.sampled_from([
        "enter", "tab", "space", "escape", "backspace",
        "a", "b", "c", "1", "2", "3"
    ]))


@st.composite
def modifier_keys(draw):
    """Generate lists of modifier keys."""
    modifiers = draw(st.lists(
        st.sampled_from(["ctrl", "alt", "shift"]),
        min_size=0,
        max_size=2,
        unique=True
    ))
    return modifiers


class TestRPAEngineProperties:
    """Property-based tests for RPAEngine."""
    
    @settings(max_examples=100)
    @given(coords=screen_coordinates(), button=mouse_buttons())
    @patch('src.rpa_engine.click_element')
    def test_property_15_click_action_execution(self, mock_click, coords, button):
        """
        Feature: rpa-backend, Property 15: Click Action Execution
        
        For any click action with target coordinates (x, y), the RPA engine
        must move the mouse to those exact coordinates before performing the click.
        
        Validates: Requirements 5.1
        """
        x, y = coords
        
        # Mock successful click
        mock_click.return_value = ToolResult(
            success=True,
            data={"x": x, "y": y, "button": button}
        )
        
        engine = RPAEngine(max_retries=3)
        result = engine.execute_click(x, y, button)
        
        # Verify the click was executed with exact coordinates
        assert result.success is True
        mock_click.assert_called_once_with(x, y, button)
        
        # Verify the underlying tool was called with the exact coordinates
        call_args = mock_click.call_args
        assert call_args[0][0] == x  # First positional arg is x
        assert call_args[0][1] == y  # Second positional arg is y
        assert call_args[0][2] == button  # Third positional arg is button
    
    @settings(max_examples=100)
    @given(text=text_inputs(), interval=st.floats(min_value=0.01, max_value=0.2))
    @patch('src.rpa_engine.type_text')
    def test_property_16_typing_action_execution(self, mock_type, text, interval):
        """
        Feature: rpa-backend, Property 16: Typing Action Execution
        
        For any typing action with text input, the RPA engine must send
        keystrokes for each character in the text to the active window.
        
        Validates: Requirements 5.2
        """
        # Mock successful typing
        mock_type.return_value = ToolResult(
            success=True,
            data={"text_length": len(text), "interval": interval}
        )
        
        engine = RPAEngine(max_retries=3)
        result = engine.execute_type(text, interval)
        
        # Verify typing was executed
        assert result.success is True
        mock_type.assert_called_once_with(text, interval)
        
        # Verify the underlying tool was called with the exact text
        call_args = mock_type.call_args
        assert call_args[0][0] == text  # First positional arg is text
        assert call_args[0][1] == interval  # Second positional arg is interval
    
    @settings(max_examples=100)
    @given(key=key_names(), modifiers=modifier_keys())
    @patch('src.rpa_engine.press_key')
    def test_property_17_key_press_execution(self, mock_press, key, modifiers):
        """
        Feature: rpa-backend, Property 17: Key Press Execution
        
        For any key press action with a key combination, the RPA engine must
        send the correct modifier keys followed by the main key.
        
        Validates: Requirements 5.3
        """
        # Mock successful key press
        mock_press.return_value = ToolResult(
            success=True,
            data={"key": key, "modifiers": modifiers}
        )
        
        engine = RPAEngine(max_retries=3)
        result = engine.execute_key_press(key, modifiers)
        
        # Verify key press was executed
        assert result.success is True
        mock_press.assert_called_once_with(key, modifiers)
        
        # Verify the underlying tool was called with correct key and modifiers
        call_args = mock_press.call_args
        assert call_args[0][0] == key  # First positional arg is key
        assert call_args[0][1] == modifiers  # Second positional arg is modifiers
    
    @settings(max_examples=100)
    @given(
        coords=screen_coordinates(),
        button=mouse_buttons(),
        failure_count=st.integers(min_value=1, max_value=2)
    )
    @patch('src.rpa_engine.click_element')
    @patch('src.rpa_engine.time.sleep')
    def test_property_20_retry_on_failure(
        self, mock_sleep, mock_click, coords, button, failure_count
    ):
        """
        Feature: rpa-backend, Property 20: Retry on Failure
        
        For any action that fails verification, the system must retry the action
        up to 3 times with exponential backoff (1s, 2s, 4s) before marking it as failed.
        
        Validates: Requirements 6.3
        """
        x, y = coords
        
        # Create a sequence of failures followed by success
        failures = [
            ToolResult(success=False, error=f"Attempt {i} failed")
            for i in range(failure_count)
        ]
        success = ToolResult(success=True, data={"x": x, "y": y})
        mock_click.side_effect = failures + [success]
        
        engine = RPAEngine(max_retries=3)
        result = engine.execute_click(x, y, button)
        
        # Verify the action eventually succeeded
        assert result.success is True
        assert result.retry_count == failure_count
        
        # Verify retry attempts
        assert mock_click.call_count == failure_count + 1
        
        # Verify exponential backoff delays were used
        expected_delays = [1, 2, 4][:failure_count]
        assert mock_sleep.call_count == failure_count
        
        for i, expected_delay in enumerate(expected_delays):
            actual_delay = mock_sleep.call_args_list[i][0][0]
            assert actual_delay == expected_delay
    
    @settings(max_examples=100)
    @given(coords=screen_coordinates(), button=mouse_buttons())
    @patch('src.rpa_engine.click_element')
    @patch('src.rpa_engine.time.sleep')
    def test_property_20_retry_exhaustion(self, mock_sleep, mock_click, coords, button):
        """
        Feature: rpa-backend, Property 20: Retry on Failure (exhaustion case)
        
        For any action that fails all 3 retry attempts, the system must mark
        it as failed and report the error.
        
        Validates: Requirements 6.3
        """
        x, y = coords
        
        # All attempts fail
        mock_click.return_value = ToolResult(success=False, error="Persistent failure")
        
        engine = RPAEngine(max_retries=3)
        result = engine.execute_click(x, y, button)
        
        # Verify the action failed after all retries
        assert result.success is False
        assert result.retry_count == 3
        assert result.error is not None
        
        # Verify all retry attempts were made
        assert mock_click.call_count == 3
        
        # Verify exponential backoff delays (only 2 sleeps for 3 attempts)
        assert mock_sleep.call_count == 2
        delays = [call[0][0] for call in mock_sleep.call_args_list]
        assert delays == [1, 2]  # First and second retry delays
