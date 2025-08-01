#!/bin/bash

# LedgerPro UI Tests Runner for Xcode/SPM
# This script runs UI tests for the LedgerPro application

set -e

echo "🧪 Running LedgerPro UI Tests..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    echo -e "${RED}❌ Error: Package.swift not found. Please run this script from the LedgerPro root directory.${NC}"
    exit 1
fi

# Function to check if app is running
check_app_running() {
    if pgrep -f "LedgerPro" > /dev/null; then
        echo -e "${YELLOW}⚠️  LedgerPro app is already running. Stopping it first...${NC}"
        pkill -f "LedgerPro" || true
        sleep 2
    fi
}

# Function to start the app in test mode
start_app_in_test_mode() {
    echo -e "${BLUE}🚀 Starting LedgerPro in test mode...${NC}"
    
    # Build the app first
    echo -e "${BLUE}🔨 Building LedgerPro...${NC}"
    swift build -c release
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Build failed. Please fix build errors first.${NC}"
        exit 1
    fi
    
    # Start the app with test arguments in background
    echo -e "${BLUE}📱 Launching app with --uitesting flag...${NC}"
    ./.build/release/LedgerPro --uitesting &
    APP_PID=$!
    
    # Give the app time to start
    echo -e "${BLUE}⏳ Waiting for app to start...${NC}"
    sleep 5
    
    # Check if app started successfully
    if ! kill -0 $APP_PID 2>/dev/null; then
        echo -e "${RED}❌ Failed to start LedgerPro app${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ LedgerPro started successfully with PID: $APP_PID${NC}"
}

# Function to run UI tests
run_ui_tests() {
    echo -e "${BLUE}🧪 Running UI Tests...${NC}"
    
    # Run only UI tests using swift test with filter
    swift test --filter LedgerProUITests
    TEST_RESULT=$?
    
    return $TEST_RESULT
}

# Function to cleanup
cleanup() {
    echo -e "${BLUE}🧹 Cleaning up...${NC}"
    if [ ! -z "$APP_PID" ]; then
        echo -e "${BLUE}🛑 Stopping LedgerPro app (PID: $APP_PID)...${NC}"
        kill $APP_PID 2>/dev/null || true
        wait $APP_PID 2>/dev/null || true
    fi
    
    # Also kill any remaining LedgerPro processes
    pkill -f "LedgerPro" 2>/dev/null || true
}

# Set up cleanup trap
trap cleanup EXIT

# Main execution
main() {
    echo -e "${GREEN}🎯 LedgerPro UI Tests Runner${NC}"
    echo -e "${GREEN}================================${NC}"
    
    # Check for running instances
    check_app_running
    
    # Start app in test mode
    start_app_in_test_mode
    
    # Run the UI tests
    echo -e "${BLUE}🔍 Running UI Test Suite...${NC}"
    if run_ui_tests; then
        echo -e "${GREEN}✅ All UI tests passed!${NC}"
        EXIT_CODE=0
    else
        echo -e "${RED}❌ Some UI tests failed.${NC}"
        EXIT_CODE=1
    fi
    
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}🏁 UI Tests completed${NC}"
    
    exit $EXIT_CODE
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "LedgerPro UI Tests Runner"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --list         List available UI tests"
        echo "  --verbose      Run tests with verbose output"
        echo ""
        echo "This script will:"
        echo "1. Build the LedgerPro app"
        echo "2. Start it in test mode (--uitesting)"
        echo "3. Run all UI tests"
        echo "4. Clean up processes when done"
        ;;
    --list)
        echo -e "${BLUE}📋 Available UI Tests:${NC}"
        swift test list --filter LedgerProUITests | grep "LedgerProUITests\." | sort
        ;;
    --verbose)
        set -x
        main
        ;;
    *)
        main
        ;;
esac