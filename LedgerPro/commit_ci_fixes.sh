#!/bin/bash

# Script to commit CI workflow fixes

echo "🔧 Preparing CI Workflow Fixes"
echo "=============================="

# Check git status
echo ""
echo "📋 Current git status:"
git status --short

# Add the CI workflow changes
echo ""
echo "📦 Adding CI workflow files..."
git add .github/workflows/ci.yml
git add .github/workflows/test.yml
git add backend/api_server_ci.py
git add Package.swift

# Add our previous fixes if not already committed
git add backend/processors/python/csv_processor_enhanced.py
git add Tests/LedgerProTests/API/APIIntegrationTests.swift

# Create commit
echo ""
echo "💾 Creating commit..."

COMMIT_MSG="Fix CI workflows: Add backend setup for API integration tests

Problem: PR #4 tests were failing because CI doesn't start the backend server

Changes:
1. Updated CI workflows to install Python and backend dependencies
2. Start backend server before running Swift tests
3. Added proper health check waiting logic
4. Created api_server_ci.py for CI-friendly server (no reload)
5. Added backend log uploads on test failure
6. Proper cleanup of backend process after tests

CI Workflow improvements:
- Install Python 3.9 on macOS runner
- Install backend requirements with specific versions
- Start backend and wait for health check
- Upload backend logs as artifacts on failure
- Stop backend server in cleanup step

This ensures API integration tests can run successfully in CI just like they do locally.

Related to PR #4 test failures"

git commit -m "$COMMIT_MSG"

echo ""
echo "✅ Changes committed!"
echo ""
echo "Next steps:"
echo "1. Push to your branch: git push origin HEAD"
echo "2. The CI should now pass with these changes"
