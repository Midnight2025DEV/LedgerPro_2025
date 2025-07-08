#!/bin/bash
# Bundle MCP servers with the app for distribution

echo "📦 Preparing MCP servers for distribution..."

# This script should be added as a Build Phase in Xcode:
# 1. Select LedgerPro target
# 2. Build Phases → + → New Run Script Phase
# 3. Add this script

RESOURCES_DIR="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
MCP_SOURCE="${SRCROOT}/mcp-servers"
MCP_DEST="${RESOURCES_DIR}/mcp-servers"

# Create destination
mkdir -p "${MCP_DEST}"

# Copy each server
for server in "financial-analyzer" "openai-service" "pdf-processor"; do
    if [ -d "${MCP_SOURCE}/${server}" ]; then
        echo "Copying ${server}..."
        cp -R "${MCP_SOURCE}/${server}" "${MCP_DEST}/"
        
        # Remove unnecessary files to reduce app size
        find "${MCP_DEST}/${server}" -name "*.pyc" -delete
        find "${MCP_DEST}/${server}" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
        find "${MCP_DEST}/${server}" -name ".pytest_cache" -type d -exec rm -rf {} + 2>/dev/null || true
        
        # Keep venv but remove unnecessary parts
        if [ -d "${MCP_DEST}/${server}/venv" ]; then
            find "${MCP_DEST}/${server}/venv" -name "*.pyc" -delete
            rm -rf "${MCP_DEST}/${server}/venv/lib/python*/site-packages/pip*" 2>/dev/null || true
        fi
    fi
done

echo "✅ MCP servers bundled successfully"

# Create a version file
echo "Build Date: $(date)" > "${MCP_DEST}/VERSION.txt"
echo "Servers: $(ls -d ${MCP_DEST}/*/ | wc -l)" >> "${MCP_DEST}/VERSION.txt"
