"""
Configuration loader for AEGIS RPA Backend.

This module provides utilities for loading configuration from environment variables
with appropriate defaults and type conversion.
"""

import os
from typing import Optional
from src.models import LauncherConfig


def get_env_bool(key: str, default: bool = False) -> bool:
    """Get boolean value from environment variable."""
    value = os.getenv(key, str(default)).lower()
    return value in ('true', '1', 'yes', 'on')


def get_env_float(key: str, default: float) -> float:
    """Get float value from environment variable."""
    try:
        return float(os.getenv(key, str(default)))
    except (ValueError, TypeError):
        return default


def get_env_int(key: str, default: int) -> int:
    """Get integer value from environment variable."""
    try:
        return int(os.getenv(key, str(default)))
    except (ValueError, TypeError):
        return default


def get_env_str(key: str, default: str) -> str:
    """Get string value from environment variable."""
    return os.getenv(key, default)


def load_launcher_config() -> LauncherConfig:
    """
    Load Local App Launcher configuration from environment variables.
    
    Returns:
        LauncherConfig: Configuration object with values from environment or defaults.
    """
    return LauncherConfig(
        mapping_file=get_env_str('LOCAL_LAUNCHER_MAPPING_FILE', 'config/app_mappings.json'),
        menu_open_delay=get_env_float('LOCAL_LAUNCHER_MENU_DELAY', 1.0),
        typing_interval=get_env_float('LOCAL_LAUNCHER_TYPING_INTERVAL', 0.1),
        search_delay=get_env_float('LOCAL_LAUNCHER_SEARCH_DELAY', 1.0),
        launch_delay=get_env_float('LOCAL_LAUNCHER_LAUNCH_DELAY', 2.0),
        verification_timeout=get_env_float('LOCAL_LAUNCHER_VERIFICATION_TIMEOUT', 5.0),
        max_instruction_words=get_env_int('LOCAL_LAUNCHER_MAX_WORDS', 10)
    )


def is_launcher_enabled() -> bool:
    """
    Check if Local App Launcher feature is enabled.
    
    Returns:
        bool: True if enabled, False otherwise.
    """
    return get_env_bool('LOCAL_LAUNCHER_ENABLED', True)
