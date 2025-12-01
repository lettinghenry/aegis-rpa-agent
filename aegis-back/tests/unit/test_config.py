"""
Unit tests for configuration module.

Tests configuration loading, validation, and error handling.
"""

import os
import pytest
from pathlib import Path
from unittest.mock import patch

from src.config import Config, ConfigurationError


class TestConfig:
    """Test suite for Config class"""
    
    def test_config_loads_from_environment(self):
        """Test that configuration loads from environment variables"""
        with patch.dict(os.environ, {
            "GOOGLE_ADK_API_KEY": "test_api_key",
            "GEMINI_MODEL": "gemini-1.5-pro",
            "ADK_TIMEOUT": "30",
            "HOST": "127.0.0.1",
            "PORT": "8080",
            "LOG_LEVEL": "DEBUG",
            "HISTORY_DIR": "./test_history",
            "CACHE_DIR": "./test_cache",
            "MAX_CACHE_SIZE": "50",
            "MAX_CONCURRENT_SESSIONS": "2",
            "REQUEST_QUEUE_SIZE": "20",
            "WEBSOCKET_PING_INTERVAL": "60"
        }):
            config = Config()
            
            assert config.GOOGLE_ADK_API_KEY == "test_api_key"
            assert config.GEMINI_MODEL == "gemini-1.5-pro"
            assert config.ADK_TIMEOUT == 30
            assert config.HOST == "127.0.0.1"
            assert config.PORT == 8080
            assert config.LOG_LEVEL == "DEBUG"
            assert config.HISTORY_DIR == Path("./test_history")
            assert config.CACHE_DIR == Path("./test_cache")
            assert config.MAX_CACHE_SIZE == 50
            assert config.MAX_CONCURRENT_SESSIONS == 2
            assert config.REQUEST_QUEUE_SIZE == 20
            assert config.WEBSOCKET_PING_INTERVAL == 60
    
    def test_config_uses_defaults(self):
        """Test that configuration uses default values when env vars not set"""
        with patch.dict(os.environ, {
            "GOOGLE_ADK_API_KEY": "test_key"
        }, clear=True):
            config = Config()
            
            assert config.GEMINI_MODEL == "gemini-1.5-pro"
            assert config.ADK_TIMEOUT == 30
            assert config.HOST == "0.0.0.0"
            assert config.PORT == 8000
            assert config.LOG_LEVEL == "INFO"
            assert config.MAX_CACHE_SIZE == 100
            assert config.MAX_CONCURRENT_SESSIONS == 1
            assert config.REQUEST_QUEUE_SIZE == 10
            assert config.WEBSOCKET_PING_INTERVAL == 30
    
    def test_config_validates_required_api_key(self):
        """Test that missing API key raises ConfigurationError"""
        with patch.dict(os.environ, {}, clear=True):
            with pytest.raises(ConfigurationError) as exc_info:
                Config()
            
            assert "GOOGLE_ADK_API_KEY is required" in str(exc_info.value)
    
    def test_config_validates_port_range(self):
        """Test that invalid port raises ConfigurationError"""
        with patch.dict(os.environ, {
            "GOOGLE_ADK_API_KEY": "test_key",
            "PORT": "99999"
        }):
            with pytest.raises(ConfigurationError) as exc_info:
                Config()
            
            assert "PORT must be between 1 and 65535" in str(exc_info.value)
    
    def test_config_validates_log_level(self):
        """Test that invalid log level raises ConfigurationError"""
        with patch.dict(os.environ, {
            "GOOGLE_ADK_API_KEY": "test_key",
            "LOG_LEVEL": "INVALID"
        }):
            with pytest.raises(ConfigurationError) as exc_info:
                Config()
            
            assert "LOG_LEVEL must be one of" in str(exc_info.value)
    
    def test_config_validates_positive_timeout(self):
        """Test that negative timeout raises ConfigurationError"""
        with patch.dict(os.environ, {
            "GOOGLE_ADK_API_KEY": "test_key",
            "ADK_TIMEOUT": "-5"
        }):
            with pytest.raises(ConfigurationError) as exc_info:
                Config()
            
            assert "ADK_TIMEOUT must be positive" in str(exc_info.value)
    
    def test_config_validates_positive_cache_size(self):
        """Test that non-positive cache size raises ConfigurationError"""
        with patch.dict(os.environ, {
            "GOOGLE_ADK_API_KEY": "test_key",
            "MAX_CACHE_SIZE": "0"
        }):
            with pytest.raises(ConfigurationError) as exc_info:
                Config()
            
            assert "MAX_CACHE_SIZE must be positive" in str(exc_info.value)
    
    def test_config_validates_concurrent_sessions(self):
        """Test that invalid concurrent sessions raises ConfigurationError"""
        with patch.dict(os.environ, {
            "GOOGLE_ADK_API_KEY": "test_key",
            "MAX_CONCURRENT_SESSIONS": "0"
        }):
            with pytest.raises(ConfigurationError) as exc_info:
                Config()
            
            assert "MAX_CONCURRENT_SESSIONS must be at least 1" in str(exc_info.value)
    
    def test_config_validates_queue_size(self):
        """Test that invalid queue size raises ConfigurationError"""
        with patch.dict(os.environ, {
            "GOOGLE_ADK_API_KEY": "test_key",
            "REQUEST_QUEUE_SIZE": "0"
        }):
            with pytest.raises(ConfigurationError) as exc_info:
                Config()
            
            assert "REQUEST_QUEUE_SIZE must be at least 1" in str(exc_info.value)
    
    def test_config_validates_ping_interval(self):
        """Test that invalid ping interval raises ConfigurationError"""
        with patch.dict(os.environ, {
            "GOOGLE_ADK_API_KEY": "test_key",
            "WEBSOCKET_PING_INTERVAL": "-10"
        }):
            with pytest.raises(ConfigurationError) as exc_info:
                Config()
            
            assert "WEBSOCKET_PING_INTERVAL must be positive" in str(exc_info.value)
    
    def test_config_creates_directories(self, tmp_path):
        """Test that configuration creates required directories"""
        history_dir = tmp_path / "history"
        cache_dir = tmp_path / "cache"
        
        with patch.dict(os.environ, {
            "GOOGLE_ADK_API_KEY": "test_key",
            "HISTORY_DIR": str(history_dir),
            "CACHE_DIR": str(cache_dir)
        }):
            config = Config()
            
            assert history_dir.exists()
            assert cache_dir.exists()
    
    def test_config_get_summary_masks_api_key(self):
        """Test that get_summary masks sensitive information"""
        with patch.dict(os.environ, {
            "GOOGLE_ADK_API_KEY": "secret_key_12345"
        }):
            config = Config()
            summary = config.get_summary()
            
            # API key should not be in summary
            assert "secret_key_12345" not in str(summary)
            # But should indicate if it's set
            assert summary["adk"]["api_key_set"] is True
            # Other values should be present
            assert summary["adk"]["model"] == "gemini-1.5-pro"
            assert summary["server"]["port"] == 8000
    
    def test_config_handles_optional_settings(self):
        """Test that optional settings are handled correctly"""
        with patch.dict(os.environ, {
            "GOOGLE_ADK_API_KEY": "test_key",
            "USE_JSON_LOGS": "true",
            "LOG_FILE": "/var/log/aegis.log"
        }):
            config = Config()
            
            assert config.USE_JSON_LOGS is True
            assert config.LOG_FILE == "/var/log/aegis.log"
    
    def test_config_handles_missing_optional_settings(self):
        """Test that missing optional settings use defaults"""
        with patch.dict(os.environ, {
            "GOOGLE_ADK_API_KEY": "test_key"
        }, clear=True):
            config = Config()
            
            assert config.USE_JSON_LOGS is False
            assert config.LOG_FILE is None
    
    def test_config_multiple_validation_errors(self):
        """Test that multiple validation errors are reported together"""
        with patch.dict(os.environ, {
            "PORT": "99999",
            "LOG_LEVEL": "INVALID",
            "ADK_TIMEOUT": "-5"
        }, clear=True):
            with pytest.raises(ConfigurationError) as exc_info:
                Config()
            
            error_msg = str(exc_info.value)
            # Should contain multiple errors
            assert "GOOGLE_ADK_API_KEY is required" in error_msg
            assert "PORT must be between" in error_msg
            assert "LOG_LEVEL must be one of" in error_msg
            assert "ADK_TIMEOUT must be positive" in error_msg
