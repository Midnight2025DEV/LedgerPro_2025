# conftest.py - pytest configuration
"""
Pytest configuration to ensure clean test environment
without problematic asyncio plugins that cause collection errors.
"""

# Minimal conftest to prevent auto-loading of problematic plugins