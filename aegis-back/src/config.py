"""
AEGIS RPA Backend - Configuration Module

This module loads and validates environment variables for the application.
It provides a centralized configuration object with type-safe access to
all configuration parameters.

Validates: Requirement 1.1
"""

import os
from typing import Optional
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class ConfigurationError(Exception):
    """Raised when required configuration is missing or invalid"""
    pass


class Config:
    """
    Application configuration loaded from environment variables.
    
    This class provides type-safe access to all configuration parameters
    and validates that required settings are present.
    """
    
    # ADK Configuration
    GOOGLE_ADK_API_KEY: str
    GEMINI_MODEL: str
    ADK_TIMEOUT: int
    
    # Server Configuration
    HOST: str
    PORT: int
    LOG_LEVEL: str
    
    # Storage Configuration
    HISTORY_DIR: Path
    CACHE_DIR: Path
    MAX_CACHE_SIZE: int
    
    # Performance Configuration
    MAX_CONCURRENT_SESSIONS: int
    REQUEST_QUEUE_SIZE: int
    WEBSOCKET_PING_INTERVAL: int
    
    # Optional Configuration
    USE_JSON_LOGS: bool
    LOG_FILE: Optional[str]
    
    def __init__(self):
        """Initialize configuration from environment variables"""
        self._load_configuration()
        self._validate_configuration()
        self._create_directories()
    
    def _load_configuration(self):
        """Load all configuration from environment variables"""
        
        # ADK Configuration
        self.GOOGLE_ADK_API_KEY = os.getenv("GOOGLE_ADK_API_KEY", "")
        self.GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-1.5-pro")
        self.ADK_TIMEOUT = int(os.getenv("ADK_TIMEOUT", "30"))
        
        # Server Configuration
        self.HOST = os.getenv("HOST", "0.0.0.0")
        self.PORT = int(os.getenv("PORT", "8000"))
        self.LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
        
        # Storage Configuration
        self.HISTORY_DIR = Path(os.getenv("HISTORY_DIR", "./data/history"))
        self.CACHE_DIR = Path(os.getenv("CACHE_DIR", "./data/cache"))
        self.MAX_CACHE_SIZE = int(os.getenv("MAX_CACHE_SIZE", "100"))
        
        # Performance Configuration
        self.MAX_CONCURRENT_SESSIONS = int(os.getenv("MAX_CONCURRENT_SESSIONS", "1"))
        self.REQUEST_QUEUE_SIZE = int(os.getenv("REQUEST_QUEUE_SIZE", "10"))
        self.WEBSOCKET_PING_INTERVAL = int(os.getenv("WEBSOCKET_PING_INTERVAL", "30"))
        
        # Optional Configuration
        self.USE_JSON_LOGS = os.getenv("USE_JSON_LOGS", "false").lower() == "true"
        self.LOG_FILE = os.getenv("LOG_FILE", None)
    
    def _validate_configuration(self):
        """
        Validate that all required configuration is present and valid.
        
        Raises:
            ConfigurationError: If required configuration is missing or invalid
        """
        errors = []
        
        # Validate required ADK configuration
        if not self.GOOGLE_ADK_API_KEY:
            errors.append("GOOGLE_ADK_API_KEY is required but not set")
        
        if not self.GEMINI_MODEL:
            errors.append("GEMINI_MODEL cannot be empty")
        
        if self.ADK_TIMEOUT <= 0:
            errors.append(f"ADK_TIMEOUT must be positive, got: {self.ADK_TIMEOUT}")
        
        # Validate server configuration
        if self.PORT < 1 or self.PORT > 65535:
            errors.append(f"PORT must be between 1 and 65535, got: {self.PORT}")
        
        valid_log_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
        if self.LOG_LEVEL not in valid_log_levels:
            errors.append(
                f"LOG_LEVEL must be one of {valid_log_levels}, got: {self.LOG_LEVEL}"
            )
        
        # Validate storage configuration
        if self.MAX_CACHE_SIZE <= 0:
            errors.append(f"MAX_CACHE_SIZE must be positive, got: {self.MAX_CACHE_SIZE}")
        
        # Validate performance configuration
        if self.MAX_CONCURRENT_SESSIONS < 1:
            errors.append(
                f"MAX_CONCURRENT_SESSIONS must be at least 1, got: {self.MAX_CONCURRENT_SESSIONS}"
            )
        
        if self.REQUEST_QUEUE_SIZE < 1:
            errors.append(
                f"REQUEST_QUEUE_SIZE must be at least 1, got: {self.REQUEST_QUEUE_SIZE}"
            )
        
        if self.WEBSOCKET_PING_INTERVAL <= 0:
            errors.append(
                f"WEBSOCKET_PING_INTERVAL must be positive, got: {self.WEBSOCKET_PING_INTERVAL}"
            )
        
        # Raise exception if any validation errors
        if errors:
            error_message = "Configuration validation failed:\n" + "\n".join(f"  - {e}" for e in errors)
            raise ConfigurationError(error_message)
    
    def _create_directories(self):
        """Create required directories if they don't exist"""
        try:
            self.HISTORY_DIR.mkdir(parents=True, exist_ok=True)
            self.CACHE_DIR.mkdir(parents=True, exist_ok=True)
        except Exception as e:
            raise ConfigurationError(f"Failed to create required directories: {e}")
    
    def get_summary(self) -> dict:
        """
        Get a summary of the current configuration (safe for logging).
        
        Returns:
            Dictionary with configuration summary (sensitive values masked)
        """
        return {
            "adk": {
                "api_key_set": bool(self.GOOGLE_ADK_API_KEY),
                "model": self.GEMINI_MODEL,
                "timeout": self.ADK_TIMEOUT
            },
            "server": {
                "host": self.HOST,
                "port": self.PORT,
                "log_level": self.LOG_LEVEL
            },
            "storage": {
                "history_dir": str(self.HISTORY_DIR),
                "cache_dir": str(self.CACHE_DIR),
                "max_cache_size": self.MAX_CACHE_SIZE
            },
            "performance": {
                "max_concurrent_sessions": self.MAX_CONCURRENT_SESSIONS,
                "request_queue_size": self.REQUEST_QUEUE_SIZE,
                "websocket_ping_interval": self.WEBSOCKET_PING_INTERVAL
            }
        }


# Global configuration instance
# This will be initialized when the module is imported
try:
    config = Config()
except ConfigurationError as e:
    # Re-raise with helpful message
    print(f"\n❌ Configuration Error:\n{e}\n")
    print("Please ensure all required environment variables are set.")
    print("Copy .env.example to .env and fill in your values.\n")
    raise


# Convenience function for accessing config
def get_config() -> Config:
    """
    Get the global configuration instance.
    
    Returns:
        Config: The application configuration
    """
    return config
