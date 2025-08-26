#!/bin/bash

echo "🔧 LedgerPro CI/CD Fix - One-Click Deployment"
echo "============================================="
echo ""

# Navigate to LedgerPro directory
cd "$(dirname "$0")/LedgerPro"

# Make all scripts executable
echo "📋 Making scripts executable..."
chmod +x verify_range_error_fixes.sh 2>/dev/null || echo "verify_range_error_fixes.sh not found"
chmod +x debug_tests_local.sh 2>/dev/null || echo "debug_tests_local.sh not found"
chmod +x debug_swift_tests.sh 2>/dev/null || echo "debug_swift_tests.sh not found"

echo "✅ Scripts are now executable"
echo ""

# Check current git status
echo "📊 Current Git Status:"
echo "====================="
git status --porcelain | head -10
echo ""

# Option menu
echo "🎯 Choose action:"
echo "================"
echo "1) Test fixes locally (recommended first)"
echo "2) Commit and push fixes"
echo "3) Just show what will be committed"
echo "4) Exit"
echo ""

read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo "🧪 Testing fixes locally..."
        echo "=========================="
        if [ -f "verify_range_error_fixes.sh" ]; then
            ./verify_range_error_fixes.sh
        else
            echo "❌ Test script not found, running basic tests..."
            swift test --filter CriticalWorkflowTests
        fi
        ;;
    2)
        echo ""
        echo "🚀 Committing and pushing fixes..."
        echo "================================="
        
        # Add all changes
        git add .
        
        # Commit with detailed message
        git commit -m "fix: Resolve range errors and CI/CD issues

- Fix unsafe string operations in Transaction model
- Add safe bounds checking for string/array operations  
- Update GitHub Actions to use macOS 14 instead of macos-latest
- Re-enable Critical Workflow Tests that were disabled
- Add comprehensive error handling in CI pipeline
- Create debugging scripts for future troubleshooting

Fixes:
- Transaction.safeTruncateDescription() prevents string range errors
- Transaction.safePrefix() prevents array range errors
- Safe String.Index usage with limitedBy parameter
- Proper empty string handling in ID generation
- Enhanced CI with better error isolation and reporting

This resolves the 'Process completed with exit code 1' CI failures
and eliminates the macOS version migration warnings."
        
        # Push changes
        echo ""
        echo "📤 Pushing to GitHub..."
        if git push; then
            echo ""
            echo "🎉 SUCCESS: Changes pushed to GitHub!"
            echo "🔍 Monitor CI/CD results at:"
            echo "    https://github.com/$(git config remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^.]*\).*/\1/')/actions"
            echo ""
            echo "✅ Expected results:"
            echo "   - swift-tests: PASSING (no exit code 1)"
            echo "   - No macOS version warnings"
            echo "   - All test suites executing successfully"
        else
            echo "❌ Push failed. Check your branch and try again."
        fi
        ;;
    3)
        echo ""
        echo "📋 Files that will be committed:"
        echo "==============================="
        git diff --name-only --cached
        echo ""
        echo "📝 Commit message preview:"
        echo "========================="
        echo "fix: Resolve range errors and CI/CD issues"
        echo ""
        echo "Key files:"
        echo "- Sources/LedgerPro/Models/Transaction.swift (range error fixes)"
        echo "- Tests/.../CriticalWorkflowTests.swift (re-enabled tests)"
        echo "- .github/workflows/test.yml (macOS 14 + error handling)"
        ;;
    4)
        echo "👋 Exiting without changes"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "💡 Next Steps:"
echo "============="
echo "1. Monitor GitHub Actions for green checkmarks"
echo "2. If tests still fail, check logs for specific errors"
echo "3. Use debug_tests_local.sh for local troubleshooting"
echo "4. Check CICD_FIX_SUMMARY.md for detailed fix documentation"
