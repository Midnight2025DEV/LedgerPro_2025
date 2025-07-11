#!/usr/bin/env python3
"""Simple MCP stdio communication test"""

import json
import subprocess
import sys
import time
from pathlib import Path

def test_mcp_simple():
    """Test basic MCP communication with timeouts"""
    
    print("🧪 Simple MCP Stdio Test")
    print("=" * 40)
    
    # Path to the PDF processor server
    server_path = Path(__file__).parent.parent / "mcp-servers" / "pdf-processor" / "pdf_processor_server.py"
    venv_python = Path(__file__).parent.parent / "mcp-servers" / "pdf-processor" / "venv" / "bin" / "python"
    
    if not server_path.exists():
        print(f"❌ Server script not found: {server_path}")
        return
        
    if not venv_python.exists():
        print(f"⚠️  Using system Python")
        venv_python = sys.executable
    
    print(f"📄 Server: {server_path.name}")
    print(f"🐍 Python: {venv_python}")
    
    # Start the MCP server process
    print("\n🚀 Starting MCP server...")
    try:
        process = subprocess.Popen(
            [str(venv_python), str(server_path)],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Wait a moment for server to start
        time.sleep(1)
        
        # Check if process is running
        if process.poll() is not None:
            stdout, stderr = process.communicate()
            print(f"❌ Server failed to start")
            print(f"STDOUT: {stdout}")
            print(f"STDERR: {stderr}")
            return
            
        print("✅ Server started successfully")
        
        # Test simple initialization
        print("\n📤 Testing initialization...")
        init_request = {
            "jsonrpc": "2.0",
            "id": "test-1",
            "method": "initialize", 
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "test", "version": "1.0"}
            }
        }
        
        # Send request
        request_json = json.dumps(init_request) + "\n"
        print(f"📤 Sending: {request_json.strip()}")
        
        process.stdin.write(request_json)
        process.stdin.flush()
        
        # Try to read response with timeout
        print("📥 Waiting for response...")
        try:
            # Use communicate with timeout
            stdout, stderr = process.communicate(timeout=10)
            if stdout:
                print(f"📥 Response: {stdout.strip()}")
            if stderr:
                print(f"⚠️  Errors: {stderr.strip()}")
        except subprocess.TimeoutExpired:
            print("⏱️  Response timeout")
            process.kill()
            stdout, stderr = process.communicate()
            print(f"Partial STDOUT: {stdout}")
            print(f"Partial STDERR: {stderr}")
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        try:
            if 'process' in locals() and process.poll() is None:
                process.terminate()
                process.wait(timeout=5)
        except:
            pass
    
    print("\n✅ Test complete")

if __name__ == "__main__":
    test_mcp_simple()