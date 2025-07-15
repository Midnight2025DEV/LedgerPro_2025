#!/bin/bash

echo "🚀 Setting up GitHub repository for LedgerPro"
echo "============================================"
echo ""
echo "Repository: https://github.com/Jihp760/LedgerPro"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found. Install it with: brew install gh"
    echo "Then run: gh auth login"
    exit 1
fi

echo "📋 Recommended GitHub Settings:"
echo ""
echo "1. Go to: https://github.com/Jihp760/LedgerPro/settings"
echo ""
echo "2. General Settings:"
echo "   - Add topics: swift, macos, finance, swiftui, ai, mcp"
echo "   - Add description: Privacy-focused financial management for Mac with AI-powered categorization"
echo ""
echo "3. Branch Protection (Settings → Branches):"
echo "   - Protect 'main' branch"
echo "   - Require pull request reviews"
echo "   - Require status checks (Tests, Security)"
echo "   - Require branches to be up to date"
echo ""
echo "4. Actions Settings (Settings → Actions → General):"
echo "   - Allow all actions"
echo "   - Enable 'Allow GitHub Actions to create pull requests'"
echo ""
echo "5. Pages (Settings → Pages):"
echo "   - Source: Deploy from a branch"
echo "   - Branch: gh-pages (will be created by docs workflow)"
echo ""
echo "6. Secrets (Settings → Secrets → Actions):"
echo "   Add if needed:"
echo "   - CODECOV_TOKEN (from codecov.io)"
echo ""

# Try to set some settings via CLI
echo "🔧 Attempting to configure via GitHub CLI..."

# Set repository description and topics
gh repo edit Jihp760/LedgerPro \
    --description "Privacy-focused financial management for Mac with AI-powered categorization" \
    --add-topic swift \
    --add-topic macos \
    --add-topic finance \
    --add-topic swiftui \
    --add-topic ai \
    --add-topic mcp \
    2>/dev/null && echo "✅ Repository metadata updated" || echo "⚠️  Could not update metadata"

echo ""
echo "📝 Next Steps:"
echo "1. Push your code: git push origin main"
echo "2. Watch Actions tab: https://github.com/Jihp760/LedgerPro/actions"
echo "3. Add Codecov: https://codecov.io/gh/Jihp760/LedgerPro"
echo "4. Check badges in README after first CI run"
echo ""
echo "✅ Setup instructions complete!"