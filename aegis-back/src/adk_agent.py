"""
ADK Agent Manager for AEGIS Backend.

This module manages the Google Agent Development Kit (ADK) agent powered by Gemini.
It handles agent initialization, tool registration, instruction execution, and error handling.

Validates: Requirements 1.1, 1.2, 1.3, 1.4
"""

import os
import time
import json
import re
import logging
from typing import AsyncIterator, List, Dict, Any, Optional
from datetime import datetime
import google.generativeai as genai

from src.models import StatusUpdate, Subtask, SubtaskStatus, ToolResult
from src.rpa_tools import TOOLS

# Configure logging
logger = logging.getLogger(__name__)


class ADKAgentManager:
    """
    Manages the Google ADK agent with Gemini for cognitive task interpretation.
    
    This class initializes the Gemini model, registers RPA tools as function declarations,
    and orchestrates the execution of natural language instructions by delegating to
    the AI agent for planning and tool invocation.
    
    Includes multi-app orchestration support with application identification and context tracking.
    """
    
    def __init__(
        self,
        api_key: Optional[str] = None,
        model_name: Optional[str] = None,
        timeout: Optional[int] = None
    ):
        """
        Initialize the ADK Agent Manager.
        
        Args:
            api_key: Google API key (defaults to GOOGLE_ADK_API_KEY env var)
            model_name: Gemini model name (defaults to GEMINI_MODEL env var or gemini-1.5-pro)
            timeout: Request timeout in seconds (defaults to ADK_TIMEOUT env var or 30)
        """
        self.api_key = api_key or os.getenv("GOOGLE_ADK_API_KEY")
        self.model_name = model_name or os.getenv("GEMINI_MODEL", "gemini-1.5-pro")
        self.timeout = timeout or int(os.getenv("ADK_TIMEOUT", "30"))
        self.model = None
        self.tools = []
        self.tool_map = {}
        self.active_application = None  # Track currently active application
        self.application_context = {}  # Store application-specific context
        
        if not self.api_key:
            raise ValueError(
                "Google API key not provided. Set GOOGLE_ADK_API_KEY environment variable "
                "or pass api_key parameter."
            )
        
        logger.info(f"Initializing ADK Agent Manager with model: {self.model_name}")
    
    def initialize_agent(self) -> None:
        """
        Initialize the Google Gemini agent with configuration.
        
        Configures the generative AI client and creates a model instance
        ready for function calling with the registered RPA toolbox.
        
        Validates: Requirement 1.1
        """
        try:
            # Configure the API
            genai.configure(api_key=self.api_key)
            
            # Register tools first
            self.register_toolbox(TOOLS)
            
            # Create the model
            self.model = genai.GenerativeModel(model_name=self.model_name)
            
            logger.info(f"ADK agent initialized successfully with {len(self.tool_map)} tools")
            
        except Exception as e:
            logger.error(f"Failed to initialize ADK agent: {e}")
            raise RuntimeError(f"ADK agent initialization failed: {e}")
    
    def register_toolbox(self, tools: List[callable]) -> None:
        """
        Register RPA toolbox functions with the ADK agent.
        
        Stores tool functions in a map for later invocation during task execution.
        
        Args:
            tools: List of tool functions to register
        
        Validates: Requirement 1.2
        """
        for tool_func in tools:
            func_name = tool_func.__name__
            self.tool_map[func_name] = tool_func
        
        logger.info(f"Registered {len(self.tool_map)} tools with ADK agent")
    
    async def execute_instruction(
        self,
        instruction: str,
        session_id: str
    ) -> AsyncIterator[StatusUpdate]:
        """
        Execute a natural language instruction using the ADK agent.
        
        Delegates the instruction to the Gemini agent, which generates an execution
        plan and invokes RPA tools. Streams status updates as execution progresses.
        
        Args:
            instruction: Natural language task instruction
            session_id: Unique session identifier
        
        Yields:
            StatusUpdate: Real-time execution status updates
        
        Validates: Requirements 1.3, 1.4, 1.5
        """
        if not self.model:
            raise RuntimeError("ADK agent not initialized. Call initialize_agent() first.")
        
        logger.info(f"Executing instruction for session {session_id}: {instruction}")
        
        try:
            # Identify applications mentioned in the instruction
            identified_apps = self._identify_applications(instruction)
            
            # Create system prompt for RPA context with tool descriptions
            tool_descriptions = self._generate_tool_descriptions()
            
            # Add multi-app orchestration guidance if multiple apps detected
            multi_app_guidance = ""
            if len(identified_apps) > 1:
                multi_app_guidance = f"""

IMPORTANT - Multi-Application Task Detected:
This task involves multiple applications: {', '.join(identified_apps)}

When switching between applications:
1. Use list_open_windows to check which applications are running
2. Use launch_application if an application is not running
3. Use focus_window to bring the target application to foreground before actions
4. Use copy_to_clipboard and paste_from_clipboard for data transfer between apps
5. Track which application is currently active

Example multi-app workflow:
{{"tool": "list_open_windows", "args": {{}}}}
{{"tool": "launch_application", "args": {{"app_name": "notepad", "wait_time": 5}}}}
{{"tool": "focus_window", "args": {{"window_title": "notepad"}}}}
{{"tool": "type_text", "args": {{"text": "Hello", "interval": 0.05}}}}
{{"tool": "copy_to_clipboard", "args": {{"text": "Hello"}}}}
{{"tool": "focus_window", "args": {{"window_title": "chrome"}}}}
{{"tool": "paste_from_clipboard", "args": {{}}}}
"""
            
            system_prompt = f"""You are an RPA (Robotic Process Automation) agent that executes desktop automation tasks.
You have access to the following tools:

{tool_descriptions}

When given a task instruction:
1. Break it down into clear, sequential subtasks
2. For each subtask, output a JSON object with the tool to use and its parameters
3. Format: {{"tool": "tool_name", "args": {{"param1": "value1", "param2": "value2"}}}}
4. Output one tool call per line
5. Be specific with coordinates, text, and parameters
{multi_app_guidance}

Task: {instruction}

Generate the execution plan as a series of tool calls in JSON format:"""
            
            # Generate content from Gemini
            response = self.model.generate_content(system_prompt)
            
            # Parse the response to extract tool calls
            tool_calls = self._parse_tool_calls(response.text)
            
            if not tool_calls:
                # No tool calls found, treat as simple completion
                yield StatusUpdate(
                    session_id=session_id,
                    subtask=None,
                    overall_status="completed",
                    message="Task completed (no actions required)",
                    timestamp=datetime.now()
                )
                return
            
            # Execute each tool call
            for idx, tool_call in enumerate(tool_calls, 1):
                func_name = tool_call.get("tool")
                func_args = tool_call.get("args", {})
                
                # Check if we need to focus an application before this action
                app_to_focus = self._should_focus_application(func_name, func_args)
                if app_to_focus and func_name != "focus_window":
                    # Automatically focus the application if needed
                    logger.info(f"Auto-focusing application: {app_to_focus}")
                    focus_func = self.tool_map.get("focus_window")
                    if focus_func:
                        focus_result = focus_func(window_title=app_to_focus)
                        if focus_result.success:
                            self._update_active_application(app_to_focus)
                
                # Update active application context for certain tools
                if func_name == "launch_application":
                    app_name = func_args.get("app_name", "unknown")
                    self._update_active_application(app_name)
                elif func_name == "focus_window":
                    window_title = func_args.get("window_title", "unknown")
                    self._update_active_application(window_title)
                
                # Create subtask
                subtask = Subtask(
                    id=f"{session_id}_subtask_{idx}",
                    description=f"Execute {func_name} with args: {func_args}",
                    status=SubtaskStatus.IN_PROGRESS,
                    tool_name=func_name,
                    tool_args=func_args,
                    timestamp=datetime.now()
                )
                
                # Yield status update for subtask start
                yield StatusUpdate(
                    session_id=session_id,
                    subtask=subtask,
                    overall_status="in_progress",
                    message=f"Starting subtask: {func_name}",
                    window_state="minimal" if idx == 1 else None,  # Minimize on first action
                    timestamp=datetime.now()
                )
                
                # Execute the tool function
                try:
                    tool_func = self.tool_map.get(func_name)
                    if not tool_func:
                        raise ValueError(f"Tool '{func_name}' not found in toolbox")
                    
                    # Call the tool
                    result = tool_func(**func_args)
                    
                    # Update subtask with result
                    if result.success:
                        subtask.status = SubtaskStatus.COMPLETED
                        subtask.result = result.data
                    else:
                        subtask.status = SubtaskStatus.FAILED
                        subtask.error = result.error
                    
                    # Yield status update for subtask completion
                    yield StatusUpdate(
                        session_id=session_id,
                        subtask=subtask,
                        overall_status="in_progress" if result.success else "failed",
                        message=f"Completed subtask: {func_name}" if result.success else f"Failed: {result.error}",
                        timestamp=datetime.now()
                    )
                    
                    # If subtask failed, stop execution
                    if not result.success:
                        logger.error(f"Subtask failed: {result.error}")
                        # Send window restore command
                        yield StatusUpdate(
                            session_id=session_id,
                            subtask=None,
                            overall_status="failed",
                            message="Execution failed, restoring window",
                            window_state="normal",
                            timestamp=datetime.now()
                        )
                        return
                    
                except Exception as e:
                    logger.error(f"Error executing tool {func_name}: {e}")
                    subtask.status = SubtaskStatus.FAILED
                    subtask.error = str(e)
                    
                    yield StatusUpdate(
                        session_id=session_id,
                        subtask=subtask,
                        overall_status="failed",
                        message=f"Error executing {func_name}: {e}",
                        window_state="normal",
                        timestamp=datetime.now()
                    )
                    return
            
            # Final status update with window restore
            yield StatusUpdate(
                session_id=session_id,
                subtask=None,
                overall_status="completed",
                message="Task execution completed successfully",
                window_state="normal",
                timestamp=datetime.now()
            )
            
            logger.info(f"Instruction execution completed for session {session_id}")
            
        except Exception as e:
            logger.error(f"Error during instruction execution: {e}")
            
            # Retry logic with exponential backoff
            max_retries = 1
            retry_delay = 2
            
            # Check if we should retry (simple heuristic)
            if "timeout" in str(e).lower() or "connection" in str(e).lower():
                logger.info(f"Retrying instruction execution after {retry_delay}s delay")
                time.sleep(retry_delay)
                # Recursive retry
                async for update in self.execute_instruction(instruction, session_id):
                    yield update
            else:
                # Final failure
                yield StatusUpdate(
                    session_id=session_id,
                    subtask=None,
                    overall_status="failed",
                    message=f"ADK agent error: {str(e)}",
                    window_state="normal",
                    timestamp=datetime.now()
                )
    
    def _generate_tool_descriptions(self) -> str:
        """Generate human-readable descriptions of available tools."""
        descriptions = []
        for tool_name, tool_func in self.tool_map.items():
            doc = tool_func.__doc__ or f"Execute {tool_name}"
            # Get first line of docstring
            first_line = doc.strip().split('\n')[0]
            descriptions.append(f"- {tool_name}: {first_line}")
        return "\n".join(descriptions)
    
    def _identify_applications(self, instruction: str) -> List[str]:
        """
        Identify applications mentioned in the instruction.
        
        Args:
            instruction: Natural language task instruction
        
        Returns:
            List of identified application names
        
        Validates: Requirements 11.1
        """
        # Common application keywords
        app_keywords = {
            "notepad": ["notepad"],
            "chrome": ["chrome", "browser", "google chrome"],
            "firefox": ["firefox", "mozilla"],
            "edge": ["edge", "microsoft edge"],
            "outlook": ["outlook", "email"],
            "excel": ["excel", "spreadsheet"],
            "word": ["word", "document"],
            "powerpoint": ["powerpoint", "presentation", "slides"],
            "calculator": ["calculator", "calc"],
            "explorer": ["explorer", "file explorer", "files"],
            "cmd": ["cmd", "command prompt", "terminal"],
            "paint": ["paint", "mspaint"]
        }
        
        instruction_lower = instruction.lower()
        identified_apps = []
        
        for app_name, keywords in app_keywords.items():
            for keyword in keywords:
                if keyword in instruction_lower:
                    if app_name not in identified_apps:
                        identified_apps.append(app_name)
                    break
        
        logger.info(f"Identified applications in instruction: {identified_apps}")
        return identified_apps
    
    def _update_active_application(self, app_name: str) -> None:
        """
        Update the currently active application context.
        
        Args:
            app_name: Name of the application now active
        
        Validates: Requirements 11.5
        """
        self.active_application = app_name
        if app_name not in self.application_context:
            self.application_context[app_name] = {
                "first_accessed": datetime.now(),
                "action_count": 0
            }
        
        self.application_context[app_name]["last_accessed"] = datetime.now()
        self.application_context[app_name]["action_count"] += 1
        
        logger.debug(f"Active application updated to: {app_name}")
    
    def _should_focus_application(self, tool_name: str, tool_args: Dict[str, Any]) -> Optional[str]:
        """
        Determine if an application needs to be focused before executing a tool.
        
        Args:
            tool_name: Name of the tool to execute
            tool_args: Arguments for the tool
        
        Returns:
            Application name to focus, or None if no focus needed
        
        Validates: Requirements 11.2
        """
        # Tools that require application focus
        focus_required_tools = ["click_element", "type_text", "press_key", "scroll"]
        
        if tool_name not in focus_required_tools:
            return None
        
        # Check if we have an app_name in the context or args
        if "app_name" in tool_args:
            return tool_args["app_name"]
        
        # Return current active application if set
        return self.active_application
    
    def _parse_tool_calls(self, response_text: str) -> List[Dict[str, Any]]:
        """
        Parse tool calls from Gemini response text.
        
        Extracts JSON objects representing tool calls from the response.
        
        Args:
            response_text: Raw text response from Gemini
        
        Returns:
            List of tool call dictionaries
        """
        tool_calls = []
        
        # Split by lines and try to parse each line as JSON
        lines = response_text.split('\n')
        for line in lines:
            line = line.strip()
            if not line or not line.startswith('{'):
                continue
            
            try:
                # Try to parse as JSON
                obj = json.loads(line)
                if isinstance(obj, dict) and "tool" in obj:
                    tool_calls.append(obj)
            except json.JSONDecodeError:
                # Try to extract JSON from the line
                # Look for {...} pattern
                match = re.search(r'\{.*\}', line)
                if match:
                    try:
                        obj = json.loads(match.group())
                        if isinstance(obj, dict) and "tool" in obj:
                            tool_calls.append(obj)
                    except json.JSONDecodeError:
                        continue
        
        # If no JSON found, try to extract from code blocks
        if not tool_calls:
            code_block_pattern = r'```(?:json)?\s*(\{.*?\})\s*```'
            code_matches = re.findall(code_block_pattern, response_text, re.DOTALL)
            for match in code_matches:
                try:
                    # Try to parse each line in the code block
                    for line in match.split('\n'):
                        line = line.strip()
                        if line.startswith('{'):
                            obj = json.loads(line)
                            if isinstance(obj, dict) and "tool" in obj:
                                tool_calls.append(obj)
                except json.JSONDecodeError:
                    continue
        
        logger.info(f"Parsed {len(tool_calls)} tool calls from response")
        return tool_calls
