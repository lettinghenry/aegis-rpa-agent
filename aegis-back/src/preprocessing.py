"""
Pre-Processing Layer for AEGIS RPA Backend.

This module provides validation and sanitization of task instructions before
they are sent to the ADK agent, minimizing unnecessary API calls and costs.

Validates: Requirements 2.1, 2.2
"""

import re
from typing import Optional
from src.models import ValidationResult


class PreProcessor:
    """
    Pre-processing layer that validates and sanitizes task instructions
    before invoking the ADK agent.
    
    This component helps minimize costs by rejecting invalid requests locally
    without making expensive calls to the remote Gemini-based ADK agent.
    """
    
    # Configuration constants
    MIN_INSTRUCTION_LENGTH = 1
    MAX_INSTRUCTION_LENGTH = 1000
    
    def __init__(self):
        """Initialize the PreProcessor."""
        pass
    
    def validate_instruction(self, instruction: str) -> ValidationResult:
        """
        Validate task instruction format and content.
        
        Performs the following validations:
        - Checks if instruction is empty or only whitespace
        - Checks if instruction exceeds maximum length
        - Checks for malformed content (e.g., only special characters)
        
        Args:
            instruction: The task instruction string to validate
            
        Returns:
            ValidationResult with is_valid flag and optional error_message
            
        Examples:
            >>> preprocessor = PreProcessor()
            >>> result = preprocessor.validate_instruction("Open notepad")
            >>> result.is_valid
            True
            
            >>> result = preprocessor.validate_instruction("")
            >>> result.is_valid
            False
        """
        # Check if instruction is None
        if instruction is None:
            return ValidationResult(
                is_valid=False,
                error_message="Instruction cannot be None"
            )
        
        # Check if instruction is empty or only whitespace
        if not instruction or not instruction.strip():
            return ValidationResult(
                is_valid=False,
                error_message="Instruction cannot be empty or contain only whitespace"
            )
        
        # Check minimum length (after stripping)
        stripped_instruction = instruction.strip()
        if len(stripped_instruction) < self.MIN_INSTRUCTION_LENGTH:
            return ValidationResult(
                is_valid=False,
                error_message=f"Instruction must be at least {self.MIN_INSTRUCTION_LENGTH} character(s) long"
            )
        
        # Check maximum length
        if len(instruction) > self.MAX_INSTRUCTION_LENGTH:
            return ValidationResult(
                is_valid=False,
                error_message=f"Instruction exceeds maximum length of {self.MAX_INSTRUCTION_LENGTH} characters"
            )
        
        # Check for malformed content (only special characters, no alphanumeric)
        if not re.search(r'[a-zA-Z0-9]', stripped_instruction):
            return ValidationResult(
                is_valid=False,
                error_message="Instruction must contain at least one alphanumeric character"
            )
        
        # All validations passed
        return ValidationResult(is_valid=True)
    
    def sanitize_instruction(self, instruction: str) -> str:
        """
        Clean and normalize instruction text.
        
        Performs the following sanitization:
        - Strips leading and trailing whitespace
        - Normalizes internal whitespace (multiple spaces to single space)
        - Removes control characters
        - Normalizes line breaks to spaces
        
        Args:
            instruction: The task instruction string to sanitize
            
        Returns:
            Sanitized instruction string
            
        Examples:
            >>> preprocessor = PreProcessor()
            >>> preprocessor.sanitize_instruction("  Open   notepad  ")
            'Open notepad'
            
            >>> preprocessor.sanitize_instruction("Open\\nnotepad\\tand\\rtype")
            'Open notepad and type'
        """
        if not instruction:
            return ""
        
        # Remove control characters (except common whitespace)
        # Keep spaces, tabs, newlines temporarily for normalization
        sanitized = ''.join(
            char if char.isprintable() or char in [' ', '\t', '\n', '\r'] else ' '
            for char in instruction
        )
        
        # Normalize line breaks and tabs to spaces
        sanitized = sanitized.replace('\n', ' ').replace('\r', ' ').replace('\t', ' ')
        
        # Normalize multiple spaces to single space
        sanitized = re.sub(r'\s+', ' ', sanitized)
        
        # Strip leading and trailing whitespace
        sanitized = sanitized.strip()
        
        return sanitized
    
    def validate_and_sanitize(self, instruction: str) -> tuple[ValidationResult, Optional[str]]:
        """
        Convenience method that both validates and sanitizes an instruction.
        
        First sanitizes the instruction, then validates the sanitized version.
        This is the recommended method to use for processing instructions.
        
        Args:
            instruction: The task instruction string to process
            
        Returns:
            Tuple of (ValidationResult, sanitized_instruction or None)
            If validation fails, sanitized_instruction will be None
            
        Examples:
            >>> preprocessor = PreProcessor()
            >>> result, sanitized = preprocessor.validate_and_sanitize("  Open notepad  ")
            >>> result.is_valid
            True
            >>> sanitized
            'Open notepad'
        """
        # First sanitize
        sanitized = self.sanitize_instruction(instruction)
        
        # Then validate the sanitized version
        validation_result = self.validate_instruction(sanitized)
        
        # Return both results
        if validation_result.is_valid:
            return validation_result, sanitized
        else:
            return validation_result, None
