"""
Strategy Selection Module for AEGIS RPA Backend.

This module determines the appropriate interaction strategy (coordinate-based vs element-based)
for each subtask based on the target application and UI element characteristics.
"""

import logging
from typing import Literal, Optional, Dict, Any
from enum import Enum

# Platform-specific imports for accessibility
try:
    import pytesseract
    from PIL import Image
    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False
    logging.warning("pytesseract not available. OCR functionality will be disabled.")

try:
    import win32gui
    import win32con
    WINDOWS_AVAILABLE = True
except ImportError:
    WINDOWS_AVAILABLE = False
    logging.warning("pywin32 not available. Windows-specific features will be disabled.")


logger = logging.getLogger(__name__)


class InteractionStrategy(str, Enum):
    """Enumeration of interaction strategies."""
    COORDINATE_BASED = "coordinate_based"
    ELEMENT_BASED = "element_based"


class TargetType(str, Enum):
    """Enumeration of target element types."""
    DESKTOP_ICON = "desktop_icon"
    FIXED_UI_ELEMENT = "fixed_ui_element"
    WEB_PAGE = "web_page"
    DYNAMIC_APPLICATION = "dynamic_application"
    UNKNOWN = "unknown"


class StrategyModule:
    """
    Module for selecting the appropriate interaction strategy for RPA subtasks.
    
    Determines whether to use coordinate-based or element-based strategies based on
    the target application type and UI element characteristics.
    """
    
    def __init__(self):
        """Initialize the strategy module."""
        self.logger = logging.getLogger(__name__)
        
        # Known application types and their preferred strategies
        self.app_strategy_map = {
            # Web browsers - prefer element-based
            "chrome": InteractionStrategy.ELEMENT_BASED,
            "firefox": InteractionStrategy.ELEMENT_BASED,
            "edge": InteractionStrategy.ELEMENT_BASED,
            "safari": InteractionStrategy.ELEMENT_BASED,
            "browser": InteractionStrategy.ELEMENT_BASED,
            
            # Desktop applications - prefer coordinate-based
            "notepad": InteractionStrategy.COORDINATE_BASED,
            "calculator": InteractionStrategy.COORDINATE_BASED,
            "explorer": InteractionStrategy.COORDINATE_BASED,
            "desktop": InteractionStrategy.COORDINATE_BASED,
            
            # Office applications - context-dependent, default to element-based
            "excel": InteractionStrategy.ELEMENT_BASED,
            "word": InteractionStrategy.ELEMENT_BASED,
            "powerpoint": InteractionStrategy.ELEMENT_BASED,
            "outlook": InteractionStrategy.ELEMENT_BASED,
        }
        
        # Keywords that suggest coordinate-based strategy
        self.coordinate_keywords = [
            "desktop icon",
            "taskbar",
            "system tray",
            "notification area",
            "start menu",
            "fixed position",
            "screen corner",
            "specific coordinates"
        ]
        
        # Keywords that suggest element-based strategy
        self.element_keywords = [
            "web page",
            "website",
            "browser",
            "form",
            "button",
            "link",
            "input field",
            "dropdown",
            "checkbox",
            "dynamic content"
        ]
    
    def analyze_subtask(
        self,
        subtask_description: str,
        tool_name: Optional[str] = None,
        tool_args: Optional[Dict[str, Any]] = None,
        context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Analyze a subtask and determine the appropriate interaction strategy.
        
        Args:
            subtask_description: Natural language description of the subtask
            tool_name: Name of the RPA tool to be used (optional)
            tool_args: Arguments for the tool (optional)
            context: Additional context about the execution environment (optional)
        
        Returns:
            Dictionary containing:
                - strategy: The selected InteractionStrategy
                - target_type: The identified TargetType
                - confidence: Confidence score (0-1)
                - reasoning: Explanation of the strategy selection
                - fallback_strategy: Alternative strategy if primary fails
                - ocr_required: Whether OCR is needed for visual identification
                - xpath_support: Whether XPath/accessibility IDs are available
        """
        description_lower = subtask_description.lower()
        context = context or {}
        
        # Initialize result
        result = {
            "strategy": InteractionStrategy.ELEMENT_BASED,  # Default
            "target_type": TargetType.UNKNOWN,
            "confidence": 0.5,
            "reasoning": "",
            "fallback_strategy": InteractionStrategy.COORDINATE_BASED,
            "ocr_required": False,
            "xpath_support": False
        }
        
        # Step 1: Check for explicit coordinate-based indicators
        if self._is_coordinate_based_target(description_lower, tool_args):
            result["strategy"] = InteractionStrategy.COORDINATE_BASED
            result["target_type"] = self._identify_target_type(description_lower, is_coordinate=True)
            result["confidence"] = 0.9
            result["reasoning"] = "Target identified as fixed UI element or desktop icon"
            result["fallback_strategy"] = InteractionStrategy.ELEMENT_BASED
            self.logger.info(f"Selected coordinate-based strategy for: {subtask_description}")
            return result
        
        # Step 2: Check for explicit element-based indicators
        if self._is_element_based_target(description_lower, context):
            result["strategy"] = InteractionStrategy.ELEMENT_BASED
            result["target_type"] = self._identify_target_type(description_lower, is_coordinate=False)
            result["confidence"] = 0.9
            result["reasoning"] = "Target identified as web page or dynamic application"
            result["fallback_strategy"] = InteractionStrategy.COORDINATE_BASED
            result["xpath_support"] = self._check_xpath_support(context)
            self.logger.info(f"Selected element-based strategy for: {subtask_description}")
            return result
        
        # Step 3: Analyze application context
        app_name = context.get("application", "").lower()
        if app_name and app_name in self.app_strategy_map:
            result["strategy"] = self.app_strategy_map[app_name]
            result["confidence"] = 0.8
            result["reasoning"] = f"Strategy based on known application type: {app_name}"
            result["target_type"] = self._identify_target_type(description_lower, 
                                                               is_coordinate=(result["strategy"] == InteractionStrategy.COORDINATE_BASED))
            self.logger.info(f"Selected {result['strategy']} strategy based on application: {app_name}")
            return result
        
        # Step 4: Check if OCR is needed for visual identification
        if self._requires_ocr(description_lower):
            result["ocr_required"] = True
            result["strategy"] = InteractionStrategy.COORDINATE_BASED
            result["confidence"] = 0.7
            result["reasoning"] = "Visual identification required, using coordinate-based strategy with OCR"
            result["target_type"] = TargetType.FIXED_UI_ELEMENT
            self.logger.info(f"OCR required for: {subtask_description}")
            return result
        
        # Step 5: Default to element-based with warning
        result["strategy"] = InteractionStrategy.ELEMENT_BASED
        result["confidence"] = 0.5
        result["reasoning"] = "Unable to determine optimal strategy, defaulting to element-based"
        result["target_type"] = TargetType.UNKNOWN
        self.logger.warning(f"Could not determine optimal strategy for: {subtask_description}. Defaulting to element-based.")
        
        return result
    
    def _is_coordinate_based_target(self, description: str, tool_args: Optional[Dict[str, Any]]) -> bool:
        """
        Check if the target suggests coordinate-based interaction.
        
        Args:
            description: Lowercase subtask description
            tool_args: Tool arguments that may contain coordinates
        
        Returns:
            True if coordinate-based strategy is appropriate
        """
        # Check for coordinate keywords
        for keyword in self.coordinate_keywords:
            if keyword in description:
                return True
        
        # Check if tool args contain explicit coordinates
        if tool_args and ("x" in tool_args and "y" in tool_args):
            return True
        
        # Check for desktop-related terms
        desktop_terms = ["desktop", "taskbar", "system tray", "start button", "icon"]
        return any(term in description for term in desktop_terms)
    
    def _is_element_based_target(self, description: str, context: Dict[str, Any]) -> bool:
        """
        Check if the target suggests element-based interaction.
        
        Args:
            description: Lowercase subtask description
            context: Execution context
        
        Returns:
            True if element-based strategy is appropriate
        """
        # Check for element keywords
        for keyword in self.element_keywords:
            if keyword in description:
                return True
        
        # Check if context indicates web browser
        app_name = context.get("application", "").lower()
        web_browsers = ["chrome", "firefox", "edge", "safari", "browser"]
        if any(browser in app_name for browser in web_browsers):
            return True
        
        return False
    
    def _identify_target_type(self, description: str, is_coordinate: bool) -> TargetType:
        """
        Identify the specific type of target element.
        
        Args:
            description: Lowercase subtask description
            is_coordinate: Whether coordinate-based strategy was selected
        
        Returns:
            TargetType enum value
        """
        if "desktop icon" in description or "desktop shortcut" in description:
            return TargetType.DESKTOP_ICON
        
        if is_coordinate:
            if any(term in description for term in ["taskbar", "system tray", "start menu"]):
                return TargetType.FIXED_UI_ELEMENT
            return TargetType.FIXED_UI_ELEMENT
        else:
            if any(term in description for term in ["web", "browser", "website", "url"]):
                return TargetType.WEB_PAGE
            return TargetType.DYNAMIC_APPLICATION
    
    def _requires_ocr(self, description: str) -> bool:
        """
        Check if OCR is needed for visual identification.
        
        Args:
            description: Lowercase subtask description
        
        Returns:
            True if OCR is required
        """
        ocr_indicators = [
            "find text",
            "locate text",
            "read text",
            "identify text",
            "search for text",
            "visual identification",
            "screen text"
        ]
        return any(indicator in description for indicator in ocr_indicators)
    
    def _check_xpath_support(self, context: Dict[str, Any]) -> bool:
        """
        Check if XPath or accessibility IDs are available in the current context.
        
        Args:
            context: Execution context
        
        Returns:
            True if XPath/accessibility support is available
        """
        # Check if we're in a web browser context
        app_name = context.get("application", "").lower()
        web_browsers = ["chrome", "firefox", "edge", "safari"]
        
        if any(browser in app_name for browser in web_browsers):
            return True
        
        # Check if accessibility APIs are available
        if WINDOWS_AVAILABLE and context.get("accessibility_enabled", False):
            return True
        
        return False
    
    def perform_ocr(self, image_data: bytes, region: Optional[tuple] = None) -> Optional[str]:
        """
        Perform OCR on image data to extract text.
        
        Args:
            image_data: Raw image bytes
            region: Optional (x, y, width, height) region to focus on
        
        Returns:
            Extracted text or None if OCR fails
        """
        if not OCR_AVAILABLE:
            self.logger.error("OCR requested but pytesseract is not available")
            return None
        
        try:
            from io import BytesIO
            image = Image.open(BytesIO(image_data))
            
            if region:
                x, y, width, height = region
                image = image.crop((x, y, x + width, y + height))
            
            text = pytesseract.image_to_string(image)
            return text.strip()
        
        except Exception as e:
            self.logger.error(f"OCR failed: {str(e)}")
            return None
    
    def find_element_by_xpath(self, xpath: str, context: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Find element using XPath (for web contexts).
        
        Args:
            xpath: XPath expression
            context: Execution context with browser information
        
        Returns:
            Element information or None if not found
        """
        # This is a placeholder for future Selenium/Playwright integration
        self.logger.warning("XPath support not yet implemented. Requires Selenium/Playwright integration.")
        return None
    
    def find_element_by_accessibility_id(self, accessibility_id: str) -> Optional[Dict[str, Any]]:
        """
        Find element using accessibility ID (Windows UI Automation).
        
        Args:
            accessibility_id: Accessibility identifier
        
        Returns:
            Element information or None if not found
        """
        if not WINDOWS_AVAILABLE:
            self.logger.error("Accessibility ID lookup requires Windows platform")
            return None
        
        # This is a placeholder for future UI Automation integration
        self.logger.warning("Accessibility ID support not yet implemented. Requires UI Automation integration.")
        return None

