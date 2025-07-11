#!/bin/bash
# File: Scripts/validate_mcp_setup.sh
# MCP Setup Validation Script

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔍 Validating MCP Setup..."
echo "📁 Project root: $PROJECT_ROOT"
echo ""

# Check if mcp-servers directory exists
if [ ! -d "$PROJECT_ROOT/mcp-servers" ]; then
    echo "❌ mcp-servers directory not found at $PROJECT_ROOT/mcp-servers"
    echo "💡 Make sure you're running this from the correct directory"
    exit 1
fi

echo "✅ mcp-servers directory found"
echo ""

# Check Python installations for each server
SERVERS=("pdf-processor" "financial-analyzer" "openai-service")
MISSING_VENVS=()
MISSING_MCP=()

echo "🐍 Checking Python virtual environments..."
for server in "${SERVERS[@]}"; do
    VENV_PATH="$PROJECT_ROOT/mcp-servers/$server/venv"
    echo -n "  Checking $server... "
    
    if [ -d "$VENV_PATH" ]; then
        echo "✅ venv exists"
        
        # Check if MCP package is installed
        if "$VENV_PATH/bin/pip" show mcp >/dev/null 2>&1; then
            echo "    ✅ MCP package installed"
        else
            echo "    ❌ MCP package missing"
            MISSING_MCP+=("$server")
        fi
        
        # Check if server script exists
        SERVER_SCRIPT=""
        case $server in
            "pdf-processor")
                SERVER_SCRIPT="pdf_processor_server.py"
                ;;
            "financial-analyzer")
                SERVER_SCRIPT="analyzer_server.py"
                ;;
            "openai-service")
                SERVER_SCRIPT="openai_server.py"
                ;;
        esac
        
        if [ -f "$PROJECT_ROOT/mcp-servers/$server/$SERVER_SCRIPT" ]; then
            echo "    ✅ Server script exists: $SERVER_SCRIPT"
        else
            echo "    ⚠️  Server script missing: $SERVER_SCRIPT"
        fi
        
    else
        echo "❌ venv missing"
        MISSING_VENVS+=("$server")
    fi
done

echo ""

# Test Python imports
echo "📦 Testing Python imports..."
for server in "${SERVERS[@]}"; do
    VENV_PATH="$PROJECT_ROOT/mcp-servers/$server/venv"
    if [ -d "$VENV_PATH" ]; then
        echo -n "  Testing $server imports... "
        if "$VENV_PATH/bin/python" -c "import mcp.server; print('OK')" 2>/dev/null; then
            echo "✅"
        else
            echo "❌ Import failed"
        fi
    fi
done

echo ""

# Check configuration file
echo "⚙️  Checking configuration..."
CONFIG_FILE="$PROJECT_ROOT/mcp-servers/claude_desktop_config.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "  ✅ Configuration file exists"
    
    # Check if paths in config are valid
    echo "  🔍 Validating paths in configuration..."
    
    # Extract Python paths from config and check them
    for server in "${SERVERS[@]}"; do
        # This is a simple check - extract the path for each server
        PYTHON_PATH=$(grep -A 3 "\"$server\"" "$CONFIG_FILE" | grep "command" | sed 's/.*": "\(.*\)".*/\1/')
        if [ -n "$PYTHON_PATH" ] && [ -f "$PYTHON_PATH" ]; then
            echo "    ✅ $server Python path valid: $PYTHON_PATH"
        else
            echo "    ❌ $server Python path invalid or missing: $PYTHON_PATH"
        fi
    done
else
    echo "  ⚠️  Configuration file missing at $CONFIG_FILE"
    echo "     Run: ./Scripts/update_mcp_config.sh"
fi

echo ""

# Port availability check
echo "🔌 Checking port availability..."
PORTS=(8001 8002 8003)
for port in "${PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "  ⚠️  Port $port is in use"
    else
        echo "  ✅ Port $port is available"
    fi
done

echo ""

# Summary and recommendations
echo "📋 Summary:"
if [ ${#MISSING_VENVS[@]} -eq 0 ] && [ ${#MISSING_MCP[@]} -eq 0 ]; then
    echo "✅ All MCP servers are properly set up!"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Run the LedgerPro app to test MCP integration"
    echo "   2. Upload a PDF and choose 'Use Local MCP Processing'"
    echo "   3. Check the MCP status indicator in the toolbar"
else
    echo "⚠️  Setup issues found:"
    
    if [ ${#MISSING_VENVS[@]} -gt 0 ]; then
        echo "   Missing virtual environments: ${MISSING_VENVS[*]}"
        echo "   💡 Run: make mcp-setup"
    fi
    
    if [ ${#MISSING_MCP[@]} -gt 0 ]; then
        echo "   Missing MCP packages: ${MISSING_MCP[*]}"
        echo "   💡 Run the following commands:"
        for server in "${MISSING_MCP[@]}"; do
            echo "      cd $PROJECT_ROOT/mcp-servers/$server"
            echo "      ./venv/bin/pip install mcp"
        done
    fi
fi

echo ""
echo "🔧 Troubleshooting commands:"
echo "   make mcp-setup     # Setup all MCP server environments"
echo "   make check-mcp     # Check running MCP processes"
echo "   make clean-mcp     # Clean MCP artifacts"
echo "   ./Scripts/update_mcp_config.sh  # Update configuration paths"

exit 0