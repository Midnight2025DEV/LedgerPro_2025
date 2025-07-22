#!/bin/bash

echo "🔧 Committing Enhanced CI Fixes"
echo "==============================="

# Add all the CI-related files
echo "📦 Staging CI fix files..."
git add .github/workflows/ci.yml
git add .github/workflows/test.yml
git add backend/api_server_ci.py
git add backend/test_backend_startup.py

# Create comprehensive commit message
COMMIT_MSG="Fix CI: Enhanced backend setup with proper dependencies and diagnostics

Based on f311f5b failure analysis, adding comprehensive fixes:

1. System Dependencies (macOS):
   - Install ghostscript (required by camelot-py)
   - Install poppler (for PDF processing)
   - Install opencv (for image processing)

2. Enhanced CI Server Script:
   - Better Python path handling
   - Explicit import verification
   - Detailed error messages
   - Working directory management

3. Backend Startup Test:
   - Pre-flight verification script
   - Tests all imports before server start
   - Health check validation
   - Detailed diagnostics on failure

4. CI Workflow Improvements:
   - Verify Python package installations
   - Test critical imports (fastapi, pandas, cv2)
   - Run startup test before main server
   - Better error logging and diagnostics

5. Debugging Enhancements:
   - Upload backend logs on failure
   - Show installed packages
   - Display Python environment info
   - Capture stderr and stdout

This should resolve import errors and backend startup failures in CI."

git commit -m "$COMMIT_MSG"

echo ""
echo "✅ Enhanced CI fixes committed!"
echo ""
echo "Push with: git push origin HEAD"
