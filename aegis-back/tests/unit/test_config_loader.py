"""
Unit tests for configuration loader.
"""

import os
import pytest
from src.config_loader import (
    get_env_bool,
    get_env_float,
    get_env_int,
    get_env_str,
    load_launcher_config,
    is_launcher_enabled
)
from src.models import LauncherConfig


class TestEnvHelpers:
    """Test environment variable helper functions."""
    
    def test_get_env_bool_true_values(self):
        """Test that various true values are recognized."""
        for value in ['true', 'True', 'TRUE', '1', 'yes', 'YES', 'on', 'ON']:
            os.environ['TEST_BOOL'] = value
            assert get_env_bool('TEST_BOOL') is True
        del os.environ['TEST_BOOL']
    
    def test_get_env_bool_false_values(self):
        """Test that non-true values return False."""
        for value in ['false', 'False', '0', 'no', 'off', 'anything']:
            os.environ['TEST_BOOL'] = value
            assert get_env_bool('TEST_BOOL') is False
        del os.environ['TEST_BOOL']
    
    def test_get_env_bool_default(self):
        """Test default value when env var not set."""
        assert get_env_bool('NONEXISTENT_VAR', True) is True
        assert get_env_bool('NONEXISTENT_VAR', False) is False
    
    def test_get_env_float_valid(self):
        """Test parsing valid float values."""
        os.environ['TEST_FLOAT'] = '3.14'
        assert get_env_float('TEST_FLOAT', 0.0) == 3.14
        del os.environ['TEST_FLOAT']
    
    def test_get_env_float_invalid(self):
        """Test that invalid values return default."""
        os.environ['TEST_FLOAT'] = 'not_a_number'
        assert get_env_float('TEST_FLOAT', 2.5) == 2.5
        del os.environ['TEST_FLOAT']
    
    def test_get_env_float_default(self):
        """Test default value when env var not set."""
        assert get_env_float('NONEXISTENT_VAR', 1.5) == 1.5
    
    def test_get_env_int_valid(self):
        """Test parsing valid integer values."""
        os.environ['TEST_INT'] = '42'
        assert get_env_int('TEST_INT', 0) == 42
        del os.environ['TEST_INT']
    
    def test_get_env_int_invalid(self):
        """Test that invalid values return default."""
        os.environ['TEST_INT'] = 'not_a_number'
        assert get_env_int('TEST_INT', 10) == 10
        del os.environ['TEST_INT']
    
    def test_get_env_int_default(self):
        """Test default value when env var not set."""
        assert get_env_int('NONEXISTENT_VAR', 5) == 5
    
    def test_get_env_str(self):
        """Test string value retrieval."""
        os.environ['TEST_STR'] = 'hello'
        assert get_env_str('TEST_STR', 'default') == 'hello'
        del os.environ['TEST_STR']
    
    def test_get_env_str_default(self):
        """Test default value when env var not set."""
        assert get_env_str('NONEXISTENT_VAR', 'default') == 'default'


class TestLauncherConfig:
    """Test launcher configuration loading."""
    
    def test_load_launcher_config_defaults(self):
        """Test loading config with default values."""
        # Clear any existing env vars
        env_vars = [
            'LOCAL_LAUNCHER_MAPPING_FILE',
            'LOCAL_LAUNCHER_MENU_DELAY',
            'LOCAL_LAUNCHER_TYPING_INTERVAL',
            'LOCAL_LAUNCHER_SEARCH_DELAY',
            'LOCAL_LAUNCHER_LAUNCH_DELAY',
            'LOCAL_LAUNCHER_VERIFICATION_TIMEOUT',
            'LOCAL_LAUNCHER_MAX_WORDS'
        ]
        for var in env_vars:
            if var in os.environ:
                del os.environ[var]
        
        config = load_launcher_config()
        
        assert config.mapping_file == 'config/app_mappings.json'
        assert config.menu_open_delay == 1.0
        assert config.typing_interval == 0.1
        assert config.search_delay == 1.0
        assert config.launch_delay == 2.0
        assert config.verification_timeout == 5.0
        assert config.max_instruction_words == 10
    
    def test_load_launcher_config_from_env(self):
        """Test loading config from environment variables."""
        os.environ['LOCAL_LAUNCHER_MAPPING_FILE'] = 'custom/path.json'
        os.environ['LOCAL_LAUNCHER_MENU_DELAY'] = '2.5'
        os.environ['LOCAL_LAUNCHER_TYPING_INTERVAL'] = '0.2'
        os.environ['LOCAL_LAUNCHER_SEARCH_DELAY'] = '1.5'
        os.environ['LOCAL_LAUNCHER_LAUNCH_DELAY'] = '3.0'
        os.environ['LOCAL_LAUNCHER_VERIFICATION_TIMEOUT'] = '10.0'
        os.environ['LOCAL_LAUNCHER_MAX_WORDS'] = '20'
        
        config = load_launcher_config()
        
        assert config.mapping_file == 'custom/path.json'
        assert config.menu_open_delay == 2.5
        assert config.typing_interval == 0.2
        assert config.search_delay == 1.5
        assert config.launch_delay == 3.0
        assert config.verification_timeout == 10.0
        assert config.max_instruction_words == 20
        
        # Cleanup
        for var in ['LOCAL_LAUNCHER_MAPPING_FILE', 'LOCAL_LAUNCHER_MENU_DELAY',
                    'LOCAL_LAUNCHER_TYPING_INTERVAL', 'LOCAL_LAUNCHER_SEARCH_DELAY',
                    'LOCAL_LAUNCHER_LAUNCH_DELAY', 'LOCAL_LAUNCHER_VERIFICATION_TIMEOUT',
                    'LOCAL_LAUNCHER_MAX_WORDS']:
            del os.environ[var]
    
    def test_is_launcher_enabled_default(self):
        """Test that launcher is enabled by default."""
        if 'LOCAL_LAUNCHER_ENABLED' in os.environ:
            del os.environ['LOCAL_LAUNCHER_ENABLED']
        
        assert is_launcher_enabled() is True
    
    def test_is_launcher_enabled_true(self):
        """Test enabling launcher via env var."""
        os.environ['LOCAL_LAUNCHER_ENABLED'] = 'true'
        assert is_launcher_enabled() is True
        del os.environ['LOCAL_LAUNCHER_ENABLED']
    
    def test_is_launcher_enabled_false(self):
        """Test disabling launcher via env var."""
        os.environ['LOCAL_LAUNCHER_ENABLED'] = 'false'
        assert is_launcher_enabled() is False
        del os.environ['LOCAL_LAUNCHER_ENABLED']


class TestLauncherConfigDataclass:
    """Test LauncherConfig dataclass."""
    
    def test_launcher_config_creation(self):
        """Test creating LauncherConfig with default values."""
        config = LauncherConfig()
        
        assert config.mapping_file == 'config/app_mappings.json'
        assert config.menu_open_delay == 1.0
        assert config.typing_interval == 0.1
        assert config.search_delay == 1.0
        assert config.launch_delay == 2.0
        assert config.verification_timeout == 5.0
        assert config.max_instruction_words == 10
    
    def test_launcher_config_custom_values(self):
        """Test creating LauncherConfig with custom values."""
        config = LauncherConfig(
            mapping_file='custom.json',
            menu_open_delay=2.0,
            typing_interval=0.2,
            search_delay=1.5,
            launch_delay=3.0,
            verification_timeout=10.0,
            max_instruction_words=15
        )
        
        assert config.mapping_file == 'custom.json'
        assert config.menu_open_delay == 2.0
        assert config.typing_interval == 0.2
        assert config.search_delay == 1.5
        assert config.launch_delay == 3.0
        assert config.verification_timeout == 10.0
        assert config.max_instruction_words == 15
