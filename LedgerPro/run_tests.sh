#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create a test results directory if it doesn't exist
RESULTS_DIR="test_results"
mkdir -p "$RESULTS_DIR"

# Generate timestamp for unique filename
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULT_FILE="$RESULTS_DIR/api_integration_tests_$TIMESTAMP.txt"
SUMMARY_FILE="$RESULTS_DIR/test_summary_$TIMESTAMP.txt"

echo -e "${BLUE}🧪 Running API Integration Tests...${NC}"
echo -e "${YELLOW}📁 Results will be saved to: $RESULT_FILE${NC}"
echo ""

# Run tests and save output
swift test --filter APIIntegrationTests 2>&1 | tee "$RESULT_FILE"

# Extract summary information
echo -e "\n${BLUE}📊 Generating test summary...${NC}"
{
    echo "Test Run Summary - $(date)"
    echo "================================"
    echo ""
    echo "Test Results:"
    grep -c "passed" "$RESULT_FILE" | xargs echo "✅ Passed: "
    grep -c "failed" "$RESULT_FILE" | xargs echo "❌ Failed: "
    echo ""
    echo "Failed Tests:"
    grep -B1 "error:" "$RESULT_FILE" | grep "Test Case" | sed 's/Test Case/  •/g'
    echo ""
    echo "Full results saved to: $RESULT_FILE"
} > "$SUMMARY_FILE"

# Display summary
cat "$SUMMARY_FILE"

# Verify files were created
echo -e "\n${GREEN}✓ Test results saved successfully!${NC}"
echo -e "${BLUE}📍 File locations:${NC}"
echo "   • Full results: $(pwd)/$RESULT_FILE"
echo "   • Summary: $(pwd)/$SUMMARY_FILE"
echo ""
echo -e "${YELLOW}📋 File sizes:${NC}"
ls -lh "$RESULT_FILE" "$SUMMARY_FILE" | awk '{print "   • " $9 ": " $5}'

# Show last 5 test result files
echo -e "\n${BLUE}📚 Recent test results:${NC}"
ls -lt "$RESULTS_DIR"/*.txt 2>/dev/null | head -5 | awk '{print "   • " $9 " (" $6 " " $7 " " $8 ")"}'

# Optionally open in default text editor (uncomment if desired)
# echo -e "\n${YELLOW}Would you like to open the results? (y/n)${NC}"
# read -n 1 -r
# echo
# if [[ $REPLY =~ ^[Yy]$ ]]; then
#     open "$RESULT_FILE"
# fi
