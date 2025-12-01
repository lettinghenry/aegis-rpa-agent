"""
Action Observer for AEGIS Backend.

This module provides the ActionObserver class that captures screen states,
verifies action success through visual comparison, and detects error dialogs.
"""

import logging
import base64
from typing import Optional, Tuple
from io import BytesIO
from PIL import Image, ImageChops
import pyautogui

# Optional OCR support
try:
    import pytesseract
    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False
    logging.warning("pytesseract not available - OCR functionality will be disabled")

logger = logging.getLogger(__name__)


class ScreenState:
    """
    Represents a captured screen state at a point in time.
    
    Attributes:
        image: PIL Image object of the screenshot
        timestamp: When the screenshot was captured
        base64_data: Base64-encoded PNG data for storage/transmission
    """
    
    def __init__(self, image: Image.Image, timestamp: float):
        """
        Initialize a ScreenState.
        
        Args:
            image: PIL Image object
            timestamp: Timestamp when captured
        """
        self.image = image
        self.timestamp = timestamp
        self.base64_data = self._encode_image(image)
    
    def _encode_image(self, image: Image.Image) -> str:
        """
        Encode PIL Image to base64 string.
        
        Args:
            image: PIL Image to encode
        
        Returns:
            Base64-encoded PNG string
        """
        buffer = BytesIO()
        image.save(buffer, format="PNG")
        buffer.seek(0)
        return base64.b64encode(buffer.read()).decode('utf-8')
    
    def get_region(self, region: Tuple[int, int, int, int]) -> Image.Image:
        """
        Extract a region from the screen state.
        
        Args:
            region: (x, y, width, height) tuple
        
        Returns:
            Cropped PIL Image
        """
        x, y, width, height = region
        return self.image.crop((x, y, x + width, y + height))


class ErrorInfo:
    """
    Information about a detected error dialog or message.
    
    Attributes:
        error_type: Type of error detected
        message: Error message text (if available)
        location: Screen coordinates of the error dialog
    """
    
    def __init__(self, error_type: str, message: Optional[str] = None, 
                 location: Optional[Tuple[int, int, int, int]] = None):
        """
        Initialize ErrorInfo.
        
        Args:
            error_type: Type of error (e.g., "dialog", "popup", "message")
            message: Error message text
            location: (x, y, width, height) of error dialog
        """
        self.error_type = error_type
        self.message = message
        self.location = location


class ActionObserver:
    """
    Observer that captures screen states and verifies action success.
    
    This class provides:
    - Screen state capture using screenshots
    - Action verification through before/after comparison
    - Error dialog detection using OCR
    """
    
    def __init__(self, similarity_threshold: float = 0.95):
        """
        Initialize the Action Observer.
        
        Args:
            similarity_threshold: Threshold for considering images similar (0-1)
        """
        self.similarity_threshold = similarity_threshold
        logger.info(f"ActionObserver initialized with similarity_threshold={similarity_threshold}")
    
    def capture_state(self, region: Optional[Tuple[int, int, int, int]] = None) -> ScreenState:
        """
        Capture the current screen state.
        
        Args:
            region: Optional (x, y, width, height) tuple to capture specific region
        
        Returns:
            ScreenState object containing the captured screen
        """
        import time
        
        try:
            logger.debug(f"Capturing screen state, region={region}")
            
            if region:
                x, y, width, height = region
                screenshot = pyautogui.screenshot(region=(x, y, width, height))
            else:
                screenshot = pyautogui.screenshot()
            
            timestamp = time.time()
            state = ScreenState(screenshot, timestamp)
            
            logger.debug(f"Screen state captured successfully at {timestamp}")
            return state
            
        except Exception as e:
            logger.error(f"Failed to capture screen state: {e}")
            raise
    
    def verify_action(
        self, 
        before: ScreenState, 
        after: ScreenState,
        expected_change: str,
        region: Optional[Tuple[int, int, int, int]] = None
    ) -> bool:
        """
        Verify that an action produced the expected change.
        
        This method compares before and after screen states to determine
        if the action was successful. The verification strategy depends on
        the expected_change parameter.
        
        Args:
            before: Screen state before the action
            after: Screen state after the action
            expected_change: Description of expected change (e.g., "click", "type", "window_open")
            region: Optional region to focus comparison on
        
        Returns:
            True if action succeeded, False otherwise
        """
        try:
            logger.debug(f"Verifying action with expected_change='{expected_change}'")
            
            # Get images to compare
            if region:
                before_img = before.get_region(region)
                after_img = after.get_region(region)
            else:
                before_img = before.image
                after_img = after.image
            
            # Ensure images are the same size
            if before_img.size != after_img.size:
                logger.warning(f"Image size mismatch: {before_img.size} vs {after_img.size}")
                # Resize to match
                after_img = after_img.resize(before_img.size)
            
            # Calculate difference between images
            diff = ImageChops.difference(before_img, after_img)
            
            # Calculate similarity score
            # Convert to grayscale and get histogram
            diff_gray = diff.convert('L')
            histogram = diff_gray.histogram()
            
            # Calculate percentage of pixels that are identical
            total_pixels = sum(histogram)
            identical_pixels = histogram[0]  # Pixels with 0 difference
            similarity = identical_pixels / total_pixels if total_pixels > 0 else 0
            
            logger.debug(f"Image similarity: {similarity:.4f}")
            
            # Determine if action succeeded based on expected change
            if expected_change in ["click", "type", "key_press", "scroll"]:
                # For these actions, we expect some change (similarity < threshold)
                action_succeeded = similarity < self.similarity_threshold
                logger.info(f"Action verification: expected change detected={action_succeeded}")
                return action_succeeded
            
            elif expected_change == "no_change":
                # For verification that nothing changed
                action_succeeded = similarity >= self.similarity_threshold
                logger.info(f"Action verification: no change confirmed={action_succeeded}")
                return action_succeeded
            
            else:
                # Default: assume change is expected
                action_succeeded = similarity < self.similarity_threshold
                logger.info(f"Action verification (default): change detected={action_succeeded}")
                return action_succeeded
                
        except Exception as e:
            logger.error(f"Failed to verify action: {e}")
            # On error, assume action failed
            return False
    
    def detect_error_dialogs(self, state: Optional[ScreenState] = None) -> Optional[ErrorInfo]:
        """
        Check for error dialogs or messages on screen.
        
        This method uses OCR to detect common error indicators like:
        - "Error" text in dialog boxes
        - "Failed" messages
        - "Exception" text
        - Windows error dialog patterns
        
        Args:
            state: Optional ScreenState to analyze (captures new one if not provided)
        
        Returns:
            ErrorInfo if error detected, None otherwise
        """
        if not OCR_AVAILABLE:
            logger.warning("OCR not available - cannot detect error dialogs")
            return None
        
        try:
            # Capture current state if not provided
            if state is None:
                state = self.capture_state()
            
            logger.debug("Detecting error dialogs using OCR")
            
            # Perform OCR on the screen
            text = pytesseract.image_to_string(state.image)
            text_lower = text.lower()
            
            # Check for common error indicators
            error_keywords = [
                "error",
                "failed",
                "exception",
                "could not",
                "unable to",
                "cannot",
                "not found",
                "access denied",
                "permission denied"
            ]
            
            for keyword in error_keywords:
                if keyword in text_lower:
                    logger.warning(f"Error dialog detected with keyword: '{keyword}'")
                    
                    # Try to extract error message (simple heuristic)
                    lines = text.split('\n')
                    error_message = None
                    for i, line in enumerate(lines):
                        if keyword in line.lower():
                            # Take this line and next few lines as error message
                            error_message = ' '.join(lines[i:min(i+3, len(lines))]).strip()
                            break
                    
                    return ErrorInfo(
                        error_type="dialog",
                        message=error_message,
                        location=None  # Could be enhanced with image processing
                    )
            
            logger.debug("No error dialogs detected")
            return None
            
        except Exception as e:
            logger.error(f"Failed to detect error dialogs: {e}")
            return None
    
    def calculate_image_similarity(self, img1: Image.Image, img2: Image.Image) -> float:
        """
        Calculate similarity score between two images.
        
        Args:
            img1: First PIL Image
            img2: Second PIL Image
        
        Returns:
            Similarity score between 0 and 1 (1 = identical)
        """
        try:
            # Ensure same size
            if img1.size != img2.size:
                img2 = img2.resize(img1.size)
            
            # Calculate difference
            diff = ImageChops.difference(img1, img2)
            diff_gray = diff.convert('L')
            histogram = diff_gray.histogram()
            
            # Calculate similarity
            total_pixels = sum(histogram)
            identical_pixels = histogram[0]
            similarity = identical_pixels / total_pixels if total_pixels > 0 else 0
            
            return similarity
            
        except Exception as e:
            logger.error(f"Failed to calculate image similarity: {e}")
            return 0.0
