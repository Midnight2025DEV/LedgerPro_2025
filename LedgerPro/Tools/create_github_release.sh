#!/bin/bash

#
# GitHub Release Creator for LedgerPro
# Creates a GitHub release using the GitHub CLI
#
# Prerequisites:
# - GitHub CLI installed (brew install gh)
# - Authenticated with GitHub (gh auth login)
# - Release package already built
#
# Usage: ./scripts/create_github_release.sh [version]
#

set -euo pipefail

# Configuration
DEFAULT_VERSION="1.0.0-beta.1"
PROJECT_ROOT="$(dirname "$0")/.."
RELEASE_DIR="$PROJECT_ROOT/releases"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Parse arguments
VERSION="${1:-$DEFAULT_VERSION}"
RELEASE_ZIP="$RELEASE_DIR/LedgerPro-$VERSION-macOS.zip"

log_info "Creating GitHub release for LedgerPro v$VERSION"

# Validate prerequisites
if ! command -v gh >/dev/null 2>&1; then
    log_error "GitHub CLI not found. Install with: brew install gh"
    exit 1
fi

# Check authentication
if ! gh auth status >/dev/null 2>&1; then
    log_error "Not authenticated with GitHub. Run: gh auth login"
    exit 1
fi

# Check if release package exists
if [[ ! -f "$RELEASE_ZIP" ]]; then
    log_error "Release package not found: $RELEASE_ZIP"
    log_info "Run ./scripts/create_release.sh first to build the package"
    exit 1
fi

# Get package information
FILE_SIZE=$(du -h "$RELEASE_ZIP" | cut -f1)
FILE_SHA256=$(shasum -a 256 "$RELEASE_ZIP" | cut -d' ' -f1)

log_info "Release package found:"
log_info "  File: $RELEASE_ZIP"
log_info "  Size: $FILE_SIZE"
log_info "  SHA256: $FILE_SHA256"

# Check if release already exists
if gh release view "v$VERSION" >/dev/null 2>&1; then
    log_warning "Release v$VERSION already exists"
    read -p "Delete existing release and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deleting existing release..."
        gh release delete "v$VERSION" --yes
    else
        log_info "Cancelled"
        exit 0
    fi
fi

# Determine if this is a prerelease
PRERELEASE_FLAG=""
if [[ "$VERSION" == *"beta"* ]] || [[ "$VERSION" == *"alpha"* ]] || [[ "$VERSION" == *"rc"* ]]; then
    PRERELEASE_FLAG="--prerelease"
    log_info "Marking as pre-release (contains beta/alpha/rc)"
fi

# Create release notes
RELEASE_NOTES_FILE="/tmp/ledgerpro_release_notes_$$.md"
cat > "$RELEASE_NOTES_FILE" << EOF
## 🎉 LedgerPro v$VERSION

**Unsigned macOS build for testing**

### 📦 Package Information
- **File**: LedgerPro-$VERSION-macOS.zip
- **Size**: $FILE_SIZE
- **SHA256**: \`$FILE_SHA256\`
- **Platform**: macOS 14.0+ (Universal Binary)

### 🚀 Installation
1. Download and extract the ZIP file
2. Run \`Install_LedgerPro.command\` for automatic installation
3. Or manually copy \`LedgerPro.app\` to Applications folder

### 🔒 Security Note
This is an unsigned build. You'll need to:
1. Right-click the app and select "Open"
2. Or go to System Preferences > Security & Privacy and click "Open Anyway"

### 📊 Test Data Included
- Sample transactions CSV (15 realistic transactions)
- Foreign currency test data with exchange rates
- Python script to generate large test datasets

### 🧪 What to Test
- [ ] File upload (CSV/PDF import)
- [ ] Transaction categorization
- [ ] Account detection and management
- [ ] Performance with large datasets (1000+ transactions)
- [ ] Foreign currency handling
- [ ] UI responsiveness and dark mode

### 🐛 Reporting Issues
Please report bugs with:
- Steps to reproduce
- Expected vs actual behavior
- macOS version and hardware details
- Sample data that causes issues

---

**Build Information**
- Build Date: $(date)
- Swift Version: $(swift --version | head -n1)
EOF

# Create the release
log_info "Creating GitHub release..."

gh release create "v$VERSION" \
    "$RELEASE_ZIP" \
    --title "LedgerPro v$VERSION" \
    --notes-file "$RELEASE_NOTES_FILE" \
    $PRERELEASE_FLAG

if [[ $? -eq 0 ]]; then
    log_success "GitHub release created successfully!"
    
    echo
    echo -e "${BLUE}📋 Release Information:${NC}"
    echo "Version: v$VERSION"
    echo "URL: $(gh release view "v$VERSION" --json url -q .url)"
    echo
    
    echo -e "${YELLOW}📨 Share with Testers:${NC}"
    echo "Direct download link:"
    echo "$(gh release view "v$VERSION" --json assets -q '.assets[0].browserDownloadUrl')"
    echo
    
    echo -e "${GREEN}🎉 Release is ready for testing!${NC}"
    
    # Open release page
    read -p "Open release page in browser? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gh release view "v$VERSION" --web
    fi
    
else
    log_error "Failed to create GitHub release"
    exit 1
fi

# Cleanup
rm -f "$RELEASE_NOTES_FILE"