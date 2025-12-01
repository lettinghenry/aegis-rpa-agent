"""
AEGIS RPA Backend Setup Script

This script helps set up the development environment.
"""

from setuptools import setup, find_packages

setup(
    name="aegis-rpa-backend",
    version="0.1.0",
    description="Cognitive, intent-driven RPA automation engine",
    author="AEGIS Team",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.10",
    install_requires=[
        "fastapi>=0.104.1",
        "uvicorn[standard]>=0.24.0",
        "pydantic>=2.5.0",
        "pydantic-settings>=2.1.0",
        "google-generativeai>=0.3.1",
        "pyautogui>=0.9.54",
        "python-dotenv>=1.0.0",
        "pillow>=10.1.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.4.3",
            "pytest-asyncio>=0.21.1",
            "hypothesis>=6.92.1",
            "pytest-cov>=4.1.0",
            "black>=23.11.0",
            "flake8>=6.1.0",
            "mypy>=1.7.0",
            "isort>=5.12.0",
        ],
    },
)
