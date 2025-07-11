#!/usr/bin/env python3
"""Simple test of MCP tool calls"""

import json
import subprocess
import sys
import select
from pathlib import Path

def test_mcp_tools():
    """Test MCP tool calls with proper timeouts"""
    
    print("🧪 Simple MCP Tools Test")
    print("=" * 40)
    
    # Find PDF
    test_dir = Path.home() / "Documents" / "LedgerPro_Test_Statements"
    pdf_file = None
    for pdf in test_dir.glob("*Capital*One*.pdf"):
        pdf_file = pdf
        break
    
    if not pdf_file:
        print("❌ No PDF found")
        return
    
    # Start server
    server_path = Path(__file__).parent.parent / "mcp-servers" / "pdf-processor" / "pdf_processor_server.py"
    venv_python = Path(__file__).parent.parent / "mcp-servers" / "pdf-processor" / "venv" / "bin" / "python"
    
    if not venv_python.exists():
        venv_python = sys.executable
    
    process = subprocess.Popen(
        [str(venv_python), str(server_path)],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    try:
        # Initialize
        init_req = {
            "jsonrpc": "2.0",
            "id": "1",
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "test", "version": "1.0"}
            }
        }
        
        process.stdin.write(json.dumps(init_req) + "\n")
        process.stdin.flush()
        
        # Read init response
        ready, _, _ = select.select([process.stdout], [], [], 5.0)
        if ready:
            response = process.stdout.readline()
            print(f"✅ Init response: {len(response)} chars")
        else:
            print("❌ Init timeout")
            return
        
        # Send initialized notification
        notif = {"jsonrpc": "2.0", "method": "notifications/initialized"}
        process.stdin.write(json.dumps(notif) + "\n")
        process.stdin.flush()
        
        # Test process_bank_pdf
        print(f"\n📤 Testing process_bank_pdf with {pdf_file.name}")
        tool_req = {
            "jsonrpc": "2.0",
            "id": "2", 
            "method": "tools/call",
            "params": {
                "name": "process_bank_pdf",
                "arguments": {
                    "file_path": str(pdf_file),
                    "processor": "auto"
                }
            }
        }
        
        process.stdin.write(json.dumps(tool_req) + "\n")
        process.stdin.flush()
        print("📤 Request sent, waiting for response...")
        
        # Read response with longer timeout
        ready, _, _ = select.select([process.stdout], [], [], 30.0)
        if ready:
            response = process.stdout.readline()
            print(f"📥 Response received: {len(response)} chars")
            
            try:
                data = json.loads(response)
                if "result" in data:
                    result = data["result"]
                    if isinstance(result, dict) and "content" in result:
                        content = result["content"]
                        if isinstance(content, list) and len(content) > 0:
                            text = content[0].get("text", "")
                            print(f"📦 Text content: {len(text)} chars")
                            
                            # Parse nested JSON
                            try:
                                nested = json.loads(text)
                                if "transactions" in nested:
                                    txns = nested["transactions"]
                                    print(f"🎉 SUCCESS: Found {len(txns)} transactions!")
                                    return True
                                else:
                                    print(f"❌ No transactions, keys: {list(nested.keys())}")
                            except Exception as e:
                                print(f"❌ Nested JSON parse failed: {e}")
                        else:
                            print("❌ No content in result")
                    else:
                        print(f"❌ No content key, result keys: {list(result.keys()) if isinstance(result, dict) else 'not dict'}")
                else:
                    print(f"❌ No result key: {list(data.keys())}")
            except Exception as e:
                print(f"❌ Response parse failed: {e}")
        else:
            print("❌ Response timeout")
        
        return False
        
    finally:
        # Check stderr
        try:
            stderr = process.stderr.read()
            if stderr:
                print(f"\n📊 Server output:\n{stderr}")
        except:
            pass
        
        process.terminate()
        process.wait(timeout=5)

if __name__ == "__main__":
    success = test_mcp_tools()
    print(f"\n{'✅ SUCCESS' if success else '❌ FAILED'}")