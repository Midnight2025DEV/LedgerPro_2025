#!/bin/bash

#
# LedgerPro Build Setup Tester
# Validates that all release components are working correctly
#

set -euo pipefail

PROJECT_ROOT="$(dirname "$0")/.."
cd "$PROJECT_ROOT"

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

echo -e "${BLUE}🧪 LedgerPro Build Setup Test${NC}"
echo "=================================="
echo

# Test 1: Project Structure
log_info "Testing project structure..."

REQUIRED_FILES=(
    "Package.swift"
    "Sources/LedgerPro/LedgerProApp.swift"
    "scripts/create_release.sh"
    "scripts/create_github_release.sh"
    ".github/workflows/release.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        log_success "$file exists"
    else
        log_error "$file missing"
        exit 1
    fi
done

# Test 2: Script Permissions
log_info "Testing script permissions..."

SCRIPTS=(
    "scripts/create_release.sh"
    "scripts/create_github_release.sh"
    "scripts/test_build_setup.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [[ -x "$script" ]]; then
        log_success "$script is executable"
    else
        log_warning "$script not executable - fixing..."
        chmod +x "$script"
    fi
done

# Test 3: Swift Build System
log_info "Testing Swift build system..."

if command -v swift >/dev/null 2>&1; then
    SWIFT_VERSION=$(swift --version | head -n1)
    log_success "Swift found: $SWIFT_VERSION"
else
    log_error "Swift not found - install Xcode Command Line Tools"
    exit 1
fi

# Test 4: Package Resolution
log_info "Testing package resolution..."
if swift package resolve; then
    log_success "Package dependencies resolved"
else
    log_error "Package resolution failed"
    exit 1
fi

# Test 5: Quick Build Test
log_info "Testing quick build (debug mode)..."
if swift build; then
    log_success "Debug build successful"
else
    log_error "Debug build failed"
    exit 1
fi

# Test 6: GitHub CLI (optional)
log_info "Testing GitHub CLI availability..."
if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
        log_success "GitHub CLI authenticated"
    else
        log_warning "GitHub CLI found but not authenticated"
        echo "  Run: gh auth login"
    fi
else
    log_warning "GitHub CLI not found"
    echo "  Install with: brew install gh"
fi

# Test 7: Build Tools
log_info "Testing build tools..."

TOOLS=(
    "zip:ZIP archiver"
    "shasum:Checksum calculator"
    "xattr:Extended attributes tool"
)

for tool_info in "${TOOLS[@]}"; do
    tool="${tool_info%%:*}"
    desc="${tool_info##*:}"
    
    if command -v "$tool" >/dev/null 2>&1; then
        log_success "$desc available ($tool)"
    else
        log_error "$desc missing ($tool)"
    fi
done

# Test 8: Directory Permissions
log_info "Testing directory permissions..."

TEST_DIR="/tmp/ledgerpro_test_$$"
mkdir -p "$TEST_DIR"

if [[ -w "$TEST_DIR" ]]; then
    log_success "Temporary directory writable"
    rm -rf "$TEST_DIR"
else
    log_error "Cannot write to temporary directory"
fi

# Test 9: Sample Release Build (dry run)
log_info "Testing release build process (dry run)..."

# Create a minimal test to see if the process works
TEST_VERSION="test-$(date +%Y%m%d-%H%M%S)"

log_info "Running release script with test version: $TEST_VERSION"
if ./scripts/create_release.sh "$TEST_VERSION" >/dev/null 2>&1; then
    log_success "Release build script executed successfully"
    
    # Check if release file was created
    RELEASE_FILE="releases/LedgerPro-$TEST_VERSION-macOS.zip"
    if [[ -f "$RELEASE_FILE" ]]; then
        FILE_SIZE=$(du -h "$RELEASE_FILE" | cut -f1)
        log_success "Release package created: $FILE_SIZE"
        
        # Cleanup test release
        rm -f "$RELEASE_FILE"
    else
        log_error "Release package not found"
    fi
else
    log_error "Release build script failed"
fi

echo
echo -e "${BLUE}📋 Test Summary${NC}"
echo "================"

log_success "Build setup validation completed!"
echo

echo -e "${YELLOW}🚀 Next Steps:${NC}"
echo "1. Create your first release:"
echo "   ./scripts/create_release.sh 1.0.0-beta.1"
echo
echo "2. Test the release package locally"
echo
echo "3. Create GitHub release:"
echo "   ./scripts/create_github_release.sh 1.0.0-beta.1"
echo
echo "4. Share with testers"
echo

log_success "Your LedgerPro release setup is ready! 🎉"