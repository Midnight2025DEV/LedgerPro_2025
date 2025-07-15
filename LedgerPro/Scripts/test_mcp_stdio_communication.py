#!/usr/bin/env python3
"""Test MCP stdio communication to debug response issues"""

import asyncio
import json
import subprocess
import sys
from pathlib import Path

async def test_mcp_communication():
    """Test the MCP server stdio communication"""
    
    print("🧪 Testing MCP Stdio Communication")
    print("=" * 50)
    
    # Path to the PDF processor server
    server_path = Path(__file__).parent.parent / "mcp-servers" / "pdf-processor" / "pdf_processor_server.py"
    venv_python = Path(__file__).parent.parent / "mcp-servers" / "pdf-processor" / "venv" / "bin" / "python"
    
    if not server_path.exists():
        print(f"❌ Server script not found: {server_path}")
        return
        
    if not venv_python.exists():
        print(f"⚠️  Using system Python (venv not found)")
        venv_python = sys.executable
    
    print(f"📄 Server: {server_path.name}")
    print(f"🐍 Python: {venv_python}")
    
    # Start the MCP server process
    print("\n🚀 Starting MCP server process...")
    process = subprocess.Popen(
        [str(venv_python), str(server_path)],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=0  # Unbuffered
    )
    
    try:
        # Test 1: Initialize
        print("\n📤 Sending initialize request...")
        init_request = {
            "jsonrpc": "2.0",
            "id": "test-init",
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {"listChanged": False}
                },
                "clientInfo": {
                    "name": "test-client",
                    "version": "1.0.0"
                }
            }
        }
        
        # Send request
        request_str = json.dumps(init_request) + "\n"
        process.stdin.write(request_str)
        process.stdin.flush()
        
        # Read response
        response_line = process.stdout.readline()
        if response_line:
            print(f"📥 Response: {response_line.strip()}")
            response = json.loads(response_line)
            if "result" in response:
                print("✅ Initialize successful")
            else:
                print(f"❌ Initialize failed: {response}")
        else:
            print("❌ No response received")
            
        # Send initialized notification
        print("\n📤 Sending initialized notification...")
        init_notif = {
            "jsonrpc": "2.0",
            "method": "notifications/initialized"
        }
        notif_str = json.dumps(init_notif) + "\n"
        process.stdin.write(notif_str)
        process.stdin.flush()
        
        # Test 2: List tools
        print("\n📤 Sending tools/list request...")
        list_request = {
            "jsonrpc": "2.0",
            "id": "test-list",
            "method": "tools/list"
        }
        
        request_str = json.dumps(list_request) + "\n"
        process.stdin.write(request_str)
        process.stdin.flush()
        
        # Read response
        response_line = process.stdout.readline()
        if response_line:
            print(f"📥 Response length: {len(response_line)} chars")
            response = json.loads(response_line)
            if "result" in response and "tools" in response["result"]:
                tools = response["result"]["tools"]
                print(f"✅ Found {len(tools)} tools:")
                for tool in tools:
                    print(f"   - {tool['name']}")
            else:
                print(f"❌ List tools failed: {response}")
        
        # Test 3: Small PDF processing request
        print("\n📤 Testing small response...")
        small_request = {
            "jsonrpc": "2.0",
            "id": "test-small",
            "method": "tools/call",
            "params": {
                "name": "extract_pdf_text",
                "arguments": {
                    "file_path": "/nonexistent.pdf"  # Will fail quickly
                }
            }
        }
        
        request_str = json.dumps(small_request) + "\n"
        process.stdin.write(request_str)
        process.stdin.flush()
        
        # Read response with timeout
        import select
        readable, _, _ = select.select([process.stdout], [], [], 5.0)
        if readable:
            response_line = process.stdout.readline()
            print(f"📥 Error response length: {len(response_line)} chars")
            if len(response_line) > 100:
                print(f"📥 First 100 chars: {response_line[:100]}...")
        else:
            print("⏱️  Timeout waiting for response")
        
        # Check stderr for errors
        stderr_output = process.stderr.read()
        if stderr_output:
            print(f"\n⚠️  Server errors:\n{stderr_output}")
            
    finally:
        # Clean up
        print("\n🛑 Terminating server process...")
        process.terminate()
        process.wait(timeout=5)
        
    print("\n✅ Test complete")

if __name__ == "__main__":
    asyncio.run(test_mcp_communication())