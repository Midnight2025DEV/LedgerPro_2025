#!/usr/bin/env python3
"""
CI-friendly version of the API server that runs without reload
"""
import os
import sys

# Get the absolute path to the backend directory
backend_dir = os.path.dirname(os.path.abspath(__file__))

# Add backend directory to Python path
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

# Change to backend directory to ensure relative imports work
os.chdir(backend_dir)

# Now we can import everything properly
try:
    # Import processors first to ensure they're available
    from processors.python.camelot_processor import CamelotFinancialProcessor
    from processors.python.csv_processor_enhanced import EnhancedCSVProcessor
    print("✅ Successfully imported processors")
except ImportError as e:
    print(f"❌ Failed to import processors: {e}")
    print(f"Current directory: {os.getcwd()}")
    print(f"Python path: {sys.path}")
    sys.exit(1)

# Now import the FastAPI app
try:
    # Import the entire module first
    import api_server_real
    app = api_server_real.app
    print("✅ Successfully imported FastAPI app")
except ImportError as e:
    print(f"❌ Failed to import API server: {e}")
    sys.exit(1)

if __name__ == "__main__":
    import uvicorn
    
    print("🚀 Starting API Server for CI...")
    print("📊 Backend: http://127.0.0.1:8000")
    print("🏥 Health Check: http://127.0.0.1:8000/api/health")
    print(f"📁 Working directory: {os.getcwd()}")
    
    # Run without reload for CI
    try:
        uvicorn.run(
            app,
            host="127.0.0.1",
            port=8000,
            log_level="info"
        )
    except Exception as e:
        print(f"❌ Failed to start server: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
