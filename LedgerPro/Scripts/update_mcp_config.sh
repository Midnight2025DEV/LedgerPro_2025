#!/bin/bash
# File: Scripts/update_mcp_config.sh
# Dynamic MCP Configuration Generator

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/mcp-servers/claude_desktop_config.json"

echo "🔧 Updating MCP configuration with dynamic paths..."
echo "📁 Project root: $PROJECT_ROOT"

# Ensure mcp-servers directory exists
mkdir -p "$(dirname "$CONFIG_FILE")"

# Generate configuration with current project paths
cat > "$CONFIG_FILE" << EOF
{
  "mcpServers": {
    "openai-service": {
      "command": "$PROJECT_ROOT/mcp-servers/openai-service/venv/bin/python",
      "args": ["$PROJECT_ROOT/mcp-servers/openai-service/openai_server.py"],
      "env": {
        "OPENAI_API_KEY": "\${OPENAI_API_KEY:-your-api-key-here}",
        "PYTHONPATH": "$PROJECT_ROOT",
        "PROJECT_ROOT": "$PROJECT_ROOT"
      }
    },
    "pdf-processor": {
      "command": "$PROJECT_ROOT/mcp-servers/pdf-processor/venv/bin/python",
      "args": ["$PROJECT_ROOT/mcp-servers/pdf-processor/pdf_processor_server.py"],
      "env": {
        "PYTHONPATH": "$PROJECT_ROOT:$PROJECT_ROOT/backend",
        "PROJECT_ROOT": "$PROJECT_ROOT"
      }
    },
    "financial-analyzer": {
      "command": "$PROJECT_ROOT/mcp-servers/financial-analyzer/venv/bin/python",
      "args": ["$PROJECT_ROOT/mcp-servers/financial-analyzer/analyzer_server.py"],
      "env": {
        "PYTHONPATH": "$PROJECT_ROOT:$PROJECT_ROOT/backend",
        "PROJECT_ROOT": "$PROJECT_ROOT"
      }
    }
  }
}
EOF

echo "✅ Updated MCP config with current project paths"
echo "📄 Configuration saved to: $CONFIG_FILE"

# Verify the configuration was created
if [ -f "$CONFIG_FILE" ]; then
    echo "🔍 Configuration file created successfully"
    echo "📊 File size: $(wc -c < "$CONFIG_FILE") bytes"
else
    echo "❌ Failed to create configuration file"
    exit 1
fi

# Check if virtual environments exist
echo ""
echo "🐍 Checking virtual environments..."
for server in openai-service pdf-processor financial-analyzer; do
    VENV_PATH="$PROJECT_ROOT/mcp-servers/$server/venv"
    if [ -d "$VENV_PATH" ]; then
        echo "  ✅ $server venv exists at $VENV_PATH"
    else
        echo "  ⚠️  $server venv missing at $VENV_PATH"
        echo "     Run: make mcp-setup"
    fi
done

echo ""
echo "🎯 MCP configuration update complete!"
echo "💡 Next steps:"
echo "   1. Run 'make mcp-setup' if any venvs are missing"
echo "   2. Run 'make test-mcp' to verify functionality"