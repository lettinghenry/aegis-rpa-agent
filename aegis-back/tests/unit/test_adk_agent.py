"""
Unit tests for ADK Agent Manager.

Tests the initialization, tool registration, and basic functionality
of the ADK Agent Manager component.
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from src.adk_agent import ADKAgentManager
from src.models import ToolResult


class TestADKAgentManager:
    """Test suite for ADK Agent Manager."""
    
    def test_initialization_without_api_key_raises_error(self):
        """Test that initialization fails without API key."""
        with patch.dict('os.environ', {}, clear=True):
            with pytest.raises(ValueError, match="Google API key not provided"):
                ADKAgentManager()
    
    def test_initialization_with_api_key(self):
        """Test successful initialization with API key."""
        manager = ADKAgentManager(api_key="test_key")
        assert manager.api_key == "test_key"
        assert manager.model_name == "gemini-1.5-pro"
        assert manager.timeout == 30
    
    def test_initialization_with_custom_model(self):
        """Test initialization with custom model name."""
        manager = ADKAgentManager(
            api_key="test_key",
            model_name="gemini-1.5-flash",
            timeout=60
        )
        assert manager.model_name == "gemini-1.5-flash"
        assert manager.timeout == 60
    
    def test_initialization_from_env_vars(self):
        """Test initialization from environment variables."""
        with patch.dict('os.environ', {
            'GOOGLE_ADK_API_KEY': 'env_key',
            'GEMINI_MODEL': 'gemini-1.5-flash',
            'ADK_TIMEOUT': '45'
        }):
            manager = ADKAgentManager()
            assert manager.api_key == "env_key"
            assert manager.model_name == "gemini-1.5-flash"
            assert manager.timeout == 45
    
    @patch('google.generativeai.configure')
    @patch('google.generativeai.GenerativeModel')
    def test_initialize_agent_success(self, mock_model_class, mock_configure):
        """Test successful agent initialization."""
        manager = ADKAgentManager(api_key="test_key")
        mock_model_instance = Mock()
        mock_model_class.return_value = mock_model_instance
        
        manager.initialize_agent()
        
        # Verify API was configured
        mock_configure.assert_called_once_with(api_key="test_key")
        
        # Verify model was created
        mock_model_class.assert_called_once()
        assert manager.model == mock_model_instance
    
    @patch('google.generativeai.configure')
    def test_initialize_agent_failure(self, mock_configure):
        """Test agent initialization failure handling."""
        mock_configure.side_effect = Exception("API error")
        manager = ADKAgentManager(api_key="test_key")
        
        with pytest.raises(RuntimeError, match="ADK agent initialization failed"):
            manager.initialize_agent()
    
    def test_register_toolbox(self):
        """Test tool registration."""
        manager = ADKAgentManager(api_key="test_key")
        
        # Create mock tools
        def mock_tool_1(x: int, y: int) -> ToolResult:
            """Mock tool 1"""
            return ToolResult(success=True)
        
        def mock_tool_2(text: str) -> ToolResult:
            """Mock tool 2"""
            return ToolResult(success=True)
        
        tools = [mock_tool_1, mock_tool_2]
        manager.register_toolbox(tools)
        
        # Verify tools were registered
        assert len(manager.tool_map) == 2
        assert "mock_tool_1" in manager.tool_map
        assert "mock_tool_2" in manager.tool_map
        assert manager.tool_map["mock_tool_1"] == mock_tool_1
        assert manager.tool_map["mock_tool_2"] == mock_tool_2
    
    @pytest.mark.asyncio
    async def test_execute_instruction_without_initialization(self):
        """Test that execution fails if agent not initialized."""
        manager = ADKAgentManager(api_key="test_key")
        
        with pytest.raises(RuntimeError, match="ADK agent not initialized"):
            async for _ in manager.execute_instruction("test instruction", "session_1"):
                pass
    
    @pytest.mark.asyncio
    @patch('google.generativeai.configure')
    @patch('google.generativeai.GenerativeModel')
    async def test_execute_instruction_basic_flow(self, mock_model_class, mock_configure):
        """Test basic instruction execution flow."""
        manager = ADKAgentManager(api_key="test_key")
        
        # Setup mock model
        mock_model = Mock()
        mock_response = Mock()
        
        # Mock response with text (no tool calls)
        mock_response.text = "Task completed successfully"
        
        mock_model.generate_content.return_value = mock_response
        mock_model_class.return_value = mock_model
        
        manager.initialize_agent()
        
        # Execute instruction
        updates = []
        async for update in manager.execute_instruction("test task", "session_1"):
            updates.append(update)
        
        # Verify we got at least a completion update
        assert len(updates) >= 1
        assert updates[-1].overall_status == "completed"
        assert updates[-1].session_id == "session_1"
    
    def test_tool_map_stores_functions_correctly(self):
        """Test that tool map correctly stores function references."""
        manager = ADKAgentManager(api_key="test_key")
        
        def test_func(param: str) -> ToolResult:
            """Test function"""
            return ToolResult(success=True, data={"param": param})
        
        manager.register_toolbox([test_func])
        
        # Verify function can be called from tool map
        result = manager.tool_map["test_func"](param="test")
        assert result.success is True
        assert result.data["param"] == "test"
