#!/bin/bash
# End-to-End PDF Import Test for LedgerPro

echo "🧪 LedgerPro PDF Import Test Suite"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test Prerequisites
echo -e "${BLUE}📋 Checking Prerequisites...${NC}"

# 1. Check if Python servers are installed
echo -n "1. Python MCP servers: "
if [ -d "mcp-servers/pdf-processor/venv" ]; then
    echo -e "${GREEN}✓ Installed${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "   Run: cd mcp-servers/pdf-processor && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
fi

# 2. Check for test PDF
echo -n "2. Test PDF file: "
TEST_PDF="Tests/TestData/sample_bank_statement.pdf"
if [ -f "$TEST_PDF" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Missing${NC}"
    echo "   Add a test PDF to: $TEST_PDF"
    echo "   Or use any bank statement PDF for testing"
fi

# 3. Check if app builds
echo -n "3. App builds: "
if swift build &>/dev/null; then
    echo -e "${GREEN}✓ Success${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    echo "   Run: swift build"
fi

echo ""
echo -e "${BLUE}🚀 Test Steps:${NC}"
echo ""
echo "1. Launch LedgerPro app"
echo "2. Go to Settings → AI Services → Manage Servers"
echo "3. Start the PDF Processor server (should show green status)"
echo "4. Go back to main view and click Import"
echo "5. Select your test PDF file"
echo ""
echo "Expected Results:"
echo "- PDF Processor server starts and shows 'Healthy' status"
echo "- Import progress shows: 'Extracting transactions...'"
echo "- Transactions appear with blue 'AUTO' badges"
echo "- Category suggestions show confidence dots"
echo "- Stats banner shows '% Auto-categorized'"
echo ""
echo -e "${BLUE}📊 Validation Checklist:${NC}"
echo "[ ] MCP server launches without errors"
echo "[ ] PDF parsing extracts correct transactions"
echo "[ ] Auto-categorization applies rules"
echo "[ ] Visual feedback displays correctly"
echo "[ ] No crashes or hangs during import"
echo ""
echo -e "${BLUE}🔍 Debug Commands:${NC}"
echo "# Check if MCP servers are running:"
echo "ps aux | grep -E '(pdf_processor|analyzer|openai)' | grep -v grep"
echo ""
echo "# Check server logs:"
echo "tail -f ~/Library/Logs/LedgerPro/*.log"
echo ""
echo "# Test PDF processor directly:"
echo "cd mcp-servers/pdf-processor && source venv/bin/activate"
echo "python pdf_processor_server.py --port 8003"
