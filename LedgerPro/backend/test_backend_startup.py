#!/usr/bin/env python3
"""
Backend Startup Test for CI/CD
Validates that all dependencies can be imported and the server can start
"""

import sys
import traceback
from pathlib import Path


def test_imports():
    """Test that all required imports work"""
    print("🔍 Testing Python imports...")

    required_modules = [
        ("fastapi", "FastAPI"),
        ("uvicorn", "Uvicorn"),
        ("pandas", "Pandas"),
        ("numpy", "NumPy"),
        ("cv2", "OpenCV"),
        ("slowapi", "SlowAPI"),
        ("pydantic", "Pydantic"),
    ]

    failed_imports = []

    for module_name, display_name in required_modules:
        try:
            __import__(module_name)
            print(f"✅ {display_name} imported successfully")
        except ImportError as e:
            print(f"❌ {display_name} import failed: {e}")
            failed_imports.append(module_name)
        except Exception as e:
            print(f"⚠️  {display_name} import error: {e}")
            failed_imports.append(module_name)

    return failed_imports


def test_camelot_import():
    """Test Camelot import separately as it has complex dependencies"""
    print("\n🔍 Testing Camelot import...")
    try:
        import camelot

        print("✅ Camelot imported successfully")
        return False
    except ImportError as e:
        print(f"❌ Camelot import failed: {e}")
        print("This may be due to missing system dependencies (ghostscript, poppler)")
        return True
    except Exception as e:
        print(f"⚠️  Camelot import error: {e}")
        return True


def test_server_creation():
    """Test that the FastAPI server can be created"""
    print("\n🔍 Testing server creation...")
    try:
        # Try to import and create the secure server
        from api_server_secure import app

        print("✅ Secure API server created successfully")

        # Test that the server has expected routes
        route_paths = [route.path for route in app.routes]
        expected_routes = ["/api/health", "/api/upload", "/api/auth/login"]

        missing_routes = [
            route for route in expected_routes if route not in route_paths
        ]
        if missing_routes:
            print(f"⚠️  Missing expected routes: {missing_routes}")
            return True

        print("✅ All expected routes found")
        return False

    except Exception as e:
        print(f"❌ Server creation failed: {e}")
        traceback.print_exc()
        return True


def test_processor_creation():
    """Test that processors can be imported and created"""
    print("\n🔍 Testing processor creation...")

    try:
        from processors.python.csv_processor_enhanced import EnhancedCSVProcessor

        processor = EnhancedCSVProcessor()
        print("✅ Enhanced CSV processor created successfully")
    except Exception as e:
        print(f"❌ CSV processor creation failed: {e}")
        return True

    # Test Camelot processor separately
    try:
        from processors.python.camelot_processor import CamelotFinancialProcessor

        CamelotFinancialProcessor()
        print("✅ Camelot processor created successfully")
    except Exception as e:
        print(f"⚠️  Camelot processor creation failed: {e}")
        print("This is expected if system dependencies are missing")
        # Don't fail CI for this - it's a known issue in some environments

    return False


def main():
    """Run all startup tests"""
    print("🚀 Backend Startup Test")
    print("=" * 50)

    # Track any failures
    has_failures = False

    # Test imports
    failed_imports = test_imports()
    if failed_imports:
        print(f"\n❌ Failed imports: {failed_imports}")
        has_failures = True

    # Test Camelot (don't fail CI for this)
    camelot_failed = test_camelot_import()
    if camelot_failed:
        print("\n⚠️  Camelot dependencies missing - this is non-critical for CI")

    # Test server creation
    server_failed = test_server_creation()
    if server_failed:
        has_failures = True

    # Test processor creation
    processor_failed = test_processor_creation()
    if processor_failed:
        has_failures = True

    print("\n" + "=" * 50)
    if has_failures:
        print("❌ Backend startup test FAILED")
        print("Some critical dependencies or components are not working")
        sys.exit(1)
    else:
        print("✅ Backend startup test PASSED")
        print("All critical components are working correctly")
        sys.exit(0)


if __name__ == "__main__":
    main()
