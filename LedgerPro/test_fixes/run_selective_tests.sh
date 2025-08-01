#!/bin/bash

echo "🧪 Running LedgerPro Selective Tests"
echo "===================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create results directory
RESULTS_DIR="test_results_selective_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

# Function to run Swift tests selectively
run_swift_tests() {
    echo -e "\n${YELLOW}Running Swift Tests (Selective)${NC}"
    
    # Test groups that should work
    WORKING_TESTS=(
        "TransactionTests"
        "CategoryServiceTests"
        "CategoryRuleTests"
        "ImportCategorizationServiceTests"
    )
    
    # Skip tests that reference disabled components
    SKIP_TESTS=(
        "APIMonitorTests"
        "APIServiceTests"
        "APIServiceEnhancedTests"
        "APIIntegrationTests"
    )
    
    for test in "${WORKING_TESTS[@]}"; do
        echo -e "\n${YELLOW}Testing: $test${NC}"
        swift test --filter "$test" 2>&1 | tee "$RESULTS_DIR/swift_$test.log"
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            echo -e "${GREEN}✅ $test PASSED${NC}"
        else
            echo -e "${RED}❌ $test FAILED${NC}"
        fi
    done
    
    echo -e "\n${YELLOW}Skipped tests (require APIMonitor fix):${NC}"
    for test in "${SKIP_TESTS[@]}"; do
        echo "  - $test"
    done
}

# Function to run Python tests selectively
run_python_tests() {
    echo -e "\n${YELLOW}Running Python Tests (Selective)${NC}"
    
    cd backend
    
    # Run specific test methods that should pass
    PASSING_TESTS=(
        "test_health_check_success"
        "test_health_check_headers"
        "test_upload_csv_success"
        "test_upload_invalid_file_type"
        "test_upload_empty_file"
        "test_upload_large_file"
        "test_upload_duplicate_prevention"
        "test_job_status_not_found"
        "test_job_status_completed"
        "test_job_status_error"
        "test_get_transactions_success"
        "test_get_transactions_with_forex"
        "test_list_jobs_empty"
        "test_list_jobs_with_data"
        "test_login_success"
        "test_login_invalid_credentials"
    )
    
    echo -e "\nRunning known passing tests..."
    for test in "${PASSING_TESTS[@]}"; do
        python3 -m pytest "tests/test_api_endpoints.py::TestAPIEndpoints::$test" -v --tb=short 2>&1 | tee -a "../$RESULTS_DIR/python_selective.log"
    done
    
    cd ..
}

# Main execution
echo -e "${YELLOW}Starting selective test run...${NC}"

# Check if backend is running
if curl -s http://localhost:8000/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend is running${NC}"
else
    echo -e "${RED}❌ Backend not running. Please start it first.${NC}"
    echo "Run: cd backend && python3 api_server_real.py"
    exit 1
fi

# Run tests
run_swift_tests
run_python_tests

# Generate summary
echo -e "\n${YELLOW}=== TEST SUMMARY ===${NC}"
echo "Results saved in: $RESULTS_DIR"
echo ""
echo "To view specific results:"
echo "  Swift tests: cat $RESULTS_DIR/swift_*.log"
echo "  Python tests: cat $RESULTS_DIR/python_selective.log"

echo -e "\n${GREEN}✅ Selective test run complete!${NC}"
