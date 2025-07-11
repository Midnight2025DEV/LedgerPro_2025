#!/usr/bin/env python3
"""
MCP stdio communication fix for large responses
"""
import sys
import json
from pathlib import Path

# Add parent directory to Python path
sys.path.insert(0, str(Path(__file__).parent))

# Monkey patch the MCP server's stdio handling
import mcp.server.stdio

# Store original write function
original_write = None

def patched_write_message(message):
    """Ensure messages are properly written to stdout with explicit flushing"""
    try:
        # Convert message to JSON string
        json_str = json.dumps(message)
        
        # Write to stdout with newline
        sys.stdout.write(json_str + '\n')
        
        # CRITICAL: Force flush to ensure data is sent
        sys.stdout.flush()
        
        # Debug to stderr
        if len(json_str) > 1000:
            print(f"[STDIO] Sent large response: {len(json_str)} bytes", file=sys.stderr)
    except Exception as e:
        print(f"[ERROR] Failed to write message: {e}", file=sys.stderr)
        raise

# Apply the patch before importing the server
if hasattr(mcp.server.stdio, '_write_message'):
    original_write = mcp.server.stdio._write_message
    mcp.server.stdio._write_message = patched_write_message

# Now import and run the server
from pdf_processor_server import server, main
import asyncio

if __name__ == "__main__":
    print("[INFO] Starting PDF processor with stdio fix", file=sys.stderr)
    asyncio.run(main())