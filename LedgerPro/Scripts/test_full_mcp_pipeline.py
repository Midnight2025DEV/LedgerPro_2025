#!/usr/bin/env python3
"""Test the complete MCP pipeline that mimics Swift app behavior"""

import json
import subprocess
import sys
import time
from pathlib import Path

def test_full_mcp_pipeline():
    """Test the complete MCP pipeline exactly like Swift does"""
    
    print("🧪 Full MCP Pipeline Test (Swift-like)")
    print("=" * 50)
    
    # Find Capital One PDF
    test_dir = Path.home() / "Documents" / "LedgerPro_Test_Statements"
    capital_one_pdf = None
    
    for pdf in test_dir.glob("*Capital*One*.pdf"):
        capital_one_pdf = pdf
        break
    
    if not capital_one_pdf:
        print("❌ No Capital One PDF found")
        return
    
    print(f"📄 Testing with: {capital_one_pdf.name}")
    
    # Start MCP server
    server_path = Path(__file__).parent.parent / "mcp-servers" / "pdf-processor" / "pdf_processor_server.py"
    venv_python = Path(__file__).parent.parent / "mcp-servers" / "pdf-processor" / "venv" / "bin" / "python"
    
    if not venv_python.exists():
        venv_python = sys.executable
    
    print(f"\n🚀 Starting MCP server...")
    process = subprocess.Popen(
        [str(venv_python), str(server_path)],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=0
    )
    
    try:
        # Step 1: Initialize (like Swift MCPStdioConnection.initialize())
        print("\n📤 Step 1: Initialize MCP server...")
        init_request = {
            "jsonrpc": "2.0",
            "id": "init-123",
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "roots": {"listChanged": False},
                    "sampling": {},
                    "prompts": {"listChanged": False},
                    "resources": {"subscribe": False, "listChanged": False},
                    "tools": {"listChanged": False}
                },
                "clientInfo": {
                    "name": "LedgerPro",
                    "version": "1.0.0"
                }
            }
        }
        
        # Send initialize request
        request_json = json.dumps(init_request) + "\n"
        process.stdin.write(request_json)
        process.stdin.flush()
        
        # Read response
        response_line = process.stdout.readline()
        if response_line:
            response = json.loads(response_line)
            if "result" in response:
                print("✅ Initialize successful")
            else:
                print(f"❌ Initialize failed: {response}")
                return
        
        # Step 2: Send initialized notification (like our protocol fix)
        print("\n📤 Step 2: Send initialized notification...")
        init_notif = {
            "jsonrpc": "2.0",
            "method": "notifications/initialized"
        }
        notif_json = json.dumps(init_notif) + "\n"
        process.stdin.write(notif_json)
        process.stdin.flush()
        
        # Step 3: Call process_bank_pdf tool (like Swift MCPBridge.processDocument())
        print(f"\n📤 Step 3: Call process_bank_pdf tool...")
        tool_request = {
            "jsonrpc": "2.0",
            "id": "process-456",
            "method": "tools/call",
            "params": {
                "name": "process_bank_pdf",
                "arguments": {
                    "file_path": str(capital_one_pdf),
                    "processor": "auto"
                }
            }
        }
        
        request_json = json.dumps(tool_request) + "\n"
        print(f"📤 Request size: {len(request_json)} bytes")
        process.stdin.write(request_json)
        process.stdin.flush()
        
        # Step 4: Read large response (like Swift buffer handling)
        print(f"\n📥 Step 4: Reading response...")
        start_time = time.time()
        
        # Read response with buffer accumulation
        buffer = ""
        response_complete = False
        
        while not response_complete and time.time() - start_time < 30:
            try:
                # Read character by character to simulate Swift buffer handling
                char = process.stdout.read(1)
                if char:
                    buffer += char
                    if char == '\n':
                        response_complete = True
                else:
                    time.sleep(0.1)
            except:
                break
        
        processing_time = time.time() - start_time
        print(f"⏱️  Response time: {processing_time:.2f} seconds")
        print(f"📏 Response size: {len(buffer)} bytes")
        
        if response_complete:
            # Parse the response
            try:
                response = json.loads(buffer.strip())
                print("✅ Response parsed successfully")
                
                # Analyze response structure (like Swift debugging)
                print(f"\n🔍 Response analysis:")
                print(f"   - Has 'result': {'result' in response}")
                
                if "result" in response:
                    result = response["result"]
                    print(f"   - Result keys: {list(result.keys()) if isinstance(result, dict) else 'Not a dict'}")
                    
                    if isinstance(result, dict) and "content" in result:
                        content = result["content"]
                        print(f"   - Content type: {type(content)}")
                        print(f"   - Content length: {len(content) if isinstance(content, list) else 'Not a list'}")
                        
                        if isinstance(content, list) and len(content) > 0:
                            first_content = content[0]
                            print(f"   - First content keys: {list(first_content.keys()) if isinstance(first_content, dict) else 'Not a dict'}")
                            
                            if isinstance(first_content, dict) and "text" in first_content:
                                text_content = first_content["text"]
                                print(f"   - Text content size: {len(text_content)} characters")
                                print(f"   - Text preview: {text_content[:100]}...")
                                
                                # Try to parse the nested JSON (like Swift does)
                                try:
                                    nested_data = json.loads(text_content)
                                    print(f"   - Nested JSON keys: {list(nested_data.keys()) if isinstance(nested_data, dict) else 'Not a dict'}")
                                    
                                    if isinstance(nested_data, dict) and "transactions" in nested_data:
                                        transactions = nested_data["transactions"]
                                        print(f"   - Transaction count: {len(transactions) if isinstance(transactions, list) else 'Not a list'}")
                                        
                                        if isinstance(transactions, list) and len(transactions) > 0:
                                            first_txn = transactions[0]
                                            print(f"   - First transaction keys: {list(first_txn.keys()) if isinstance(first_txn, dict) else 'Not a dict'}")
                                            print(f"✅ PIPELINE SUCCESS: Found {len(transactions)} transactions!")
                                        else:
                                            print("❌ No transactions in response")
                                    else:
                                        print("❌ No 'transactions' key in nested JSON")
                                except json.JSONDecodeError as e:
                                    print(f"❌ Failed to parse nested JSON: {e}")
                            else:
                                print("❌ No 'text' key in first content")
                        else:
                            print("❌ Content is empty or not a list")
                    else:
                        print("❌ No 'content' key in result")
                else:
                    print("❌ No 'result' key in response")
                    if "error" in response:
                        print(f"   Error: {response['error']}")
                        
            except json.JSONDecodeError as e:
                print(f"❌ Failed to parse response JSON: {e}")
                print(f"Raw response: {buffer[:500]}...")
        else:
            print("❌ Response incomplete or timeout")
            
    finally:
        # Check stderr for debug output
        try:
            stderr_output = process.stderr.read()
            if stderr_output:
                print(f"\n📊 Server debug output:")
                for line in stderr_output.strip().split('\n'):
                    if line.strip():
                        print(f"   {line}")
        except:
            pass
            
        # Clean up
        process.terminate()
        process.wait(timeout=5)
        
    print("\n✅ Pipeline test complete")

if __name__ == "__main__":
    test_full_mcp_pipeline()