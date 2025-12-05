"""
Unit tests for app_mappings.json configuration file.
"""

import json
import os
import pytest


class TestAppMappings:
    """Test the app_mappings.json configuration file."""
    
    def test_app_mappings_file_exists(self):
        """Test that the app_mappings.json file exists."""
        assert os.path.exists('config/app_mappings.json')
    
    def test_app_mappings_valid_json(self):
        """Test that the file contains valid JSON."""
        with open('config/app_mappings.json', 'r') as f:
            data = json.load(f)
        
        assert isinstance(data, dict)
    
    def test_app_mappings_structure(self):
        """Test that mappings have correct structure."""
        with open('config/app_mappings.json', 'r') as f:
            data = json.load(f)
        
        # Each key should map to a list of strings
        for canonical_name, variations in data.items():
            assert isinstance(canonical_name, str)
            assert isinstance(variations, list)
            assert len(variations) > 0
            for variation in variations:
                assert isinstance(variation, str)
    
    def test_app_mappings_required_apps(self):
        """Test that required applications are present."""
        with open('config/app_mappings.json', 'r') as f:
            data = json.load(f)
        
        required_apps = ['chrome', 'excel', 'word', 'notepad']
        for app in required_apps:
            assert app in data, f"Required app '{app}' not found in mappings"
    
    def test_app_mappings_chrome(self):
        """Test Chrome mappings."""
        with open('config/app_mappings.json', 'r') as f:
            data = json.load(f)
        
        chrome_variations = data['chrome']
        assert 'chrome' in chrome_variations
        assert 'google chrome' in chrome_variations
        assert 'browser' in chrome_variations
    
    def test_app_mappings_excel(self):
        """Test Excel mappings."""
        with open('config/app_mappings.json', 'r') as f:
            data = json.load(f)
        
        excel_variations = data['excel']
        assert 'excel' in excel_variations
        assert 'spreadsheet' in excel_variations
        assert 'ms excel' in excel_variations
    
    def test_app_mappings_word(self):
        """Test Word mappings."""
        with open('config/app_mappings.json', 'r') as f:
            data = json.load(f)
        
        word_variations = data['word']
        assert 'word' in word_variations
        assert 'document' in word_variations
        assert 'ms word' in word_variations
    
    def test_app_mappings_notepad(self):
        """Test Notepad mappings."""
        with open('config/app_mappings.json', 'r') as f:
            data = json.load(f)
        
        notepad_variations = data['notepad']
        assert 'notepad' in notepad_variations
        assert 'text editor' in notepad_variations
        assert 'note pad' in notepad_variations
    
    def test_app_mappings_no_duplicates(self):
        """Test that no variation appears in multiple canonical names."""
        with open('config/app_mappings.json', 'r') as f:
            data = json.load(f)
        
        all_variations = []
        for variations in data.values():
            all_variations.extend(variations)
        
        # Check for duplicates
        seen = set()
        duplicates = []
        for variation in all_variations:
            if variation in seen:
                duplicates.append(variation)
            seen.add(variation)
        
        assert len(duplicates) == 0, f"Duplicate variations found: {duplicates}"
