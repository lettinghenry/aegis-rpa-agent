"""
Integration tests for ADK Agent Manager.

Tests the complete flow of ADK agent initialization, tool registration,
and instruction execution with real tool functions.
"""

import pytest
from unittest.mock import Mock, patch
from src.adk_agent import ADKAgentManager
from src.models import ToolResult


@pytest.mark.asyncio
@patch('google.generativeai.configure')
@patch('google.generativeai.GenerativeModel')
async def test_full_execution_flow_with_tool_calls(mock_model_class, mock_configure):
    """Test complete execution flow with tool calls."""
    # Setup manager
    manager = ADKAgentManager(api_key="test_key")
    
    # Create a mock tool
    def mock_click(x: int, y: int, button: str = "left") -> ToolResult:
        """Mock click tool"""
        return ToolResult(success=True, data={"x": x, "y": y, "button": button})
    
    # Register mock tool
    manager.register_toolbox([mock_click])
    
    # Setup mock model response with tool calls
    mock_model = Mock()
    mock_response = Mock()
    mock_response.text = '''
    Here's the execution plan:
    {"tool": "mock_click", "args": {"x": 100, "y": 200, "button": "left"}}
    {"tool": "mock_click", "args": {"x": 300, "y": 400, "button": "right"}}
    '''
    
    mock_model.generate_content.return_value = mock_response
    mock_model_class.return_value = mock_model
    
    # Initialize agent
    manager.initialize_agent()
    
    # Execute instruction
    updates = []
    async for update in manager.execute_instruction("Click at two locations", "session_test"):
        updates.append(update)
    
    # Verify execution flow
    assert len(updates) >= 5  # Start + 2 tool calls (start + complete each) + final
    
    # Check first tool call
    assert updates[0].subtask is not None
    assert updates[0].subtask.tool_name == "mock_click"
    assert updates[0].subtask.tool_args == {"x": 100, "y": 200, "button": "left"}
    assert updates[0].window_state == "minimal"  # First action minimizes window
    
    # Check completion
    assert updates[-1].overall_status == "completed"
    assert updates[-1].window_state == "normal"  # Final restores window


@pytest.mark.asyncio
@patch('google.generativeai.configure')
@patch('google.generativeai.GenerativeModel')
async def test_execution_with_tool_failure(mock_model_class, mock_configure):
    """Test execution flow when a tool fails."""
    # Setup manager
    manager = ADKAgentManager(api_key="test_key")
    
    # Create a mock tool that fails
    def failing_tool(param: str) -> ToolResult:
        """Mock failing tool"""
        return ToolResult(success=False, error="Tool execution failed")
    
    # Register mock tool
    manager.register_toolbox([failing_tool])
    
    # Setup mock model response
    mock_model = Mock()
    mock_response = Mock()
    mock_response.text = '{"tool": "failing_tool", "args": {"param": "test"}}'
    
    mock_model.generate_content.return_value = mock_response
    mock_model_class.return_value = mock_model
    
    # Initialize agent
    manager.initialize_agent()
    
    # Execute instruction
    updates = []
    async for update in manager.execute_instruction("Execute failing task", "session_fail"):
        updates.append(update)
    
    # Verify failure handling
    assert len(updates) >= 2
    
    # Check that failure was reported
    failed_update = None
    for update in updates:
        if update.subtask and update.subtask.status.value == "failed":
            failed_update = update
            break
    
    assert failed_update is not None
    assert failed_update.subtask.error == "Tool execution failed"
    
    # Check that window was restored
    assert updates[-1].window_state == "normal"


@pytest.mark.asyncio
@patch('google.generativeai.configure')
@patch('google.generativeai.GenerativeModel')
async def test_execution_with_no_tool_calls(mock_model_class, mock_configure):
    """Test execution when no tool calls are needed."""
    # Setup manager
    manager = ADKAgentManager(api_key="test_key")
    
    # Setup mock model response with no tool calls
    mock_model = Mock()
    mock_response = Mock()
    mock_response.text = "This task doesn't require any tools."
    
    mock_model.generate_content.return_value = mock_response
    mock_model_class.return_value = mock_model
    
    # Initialize agent
    manager.initialize_agent()
    
    # Execute instruction
    updates = []
    async for update in manager.execute_instruction("Simple task", "session_simple"):
        updates.append(update)
    
    # Verify simple completion
    assert len(updates) == 1
    assert updates[0].overall_status == "completed"
    assert updates[0].message == "Task completed (no actions required)"
