#!/usr/bin/env python3
"""
Quick manual test of one MCP server
"""
import asyncio
import json
import subprocess
from pathlib import Path

async def test_openai_server():
    """Test the OpenAI server manually"""
    server_path = Path(__file__).parent / "openai-service" / "openai_server.py"
    venv_python = Path(__file__).parent / "openai-service" / "venv" / "bin" / "python"
    
    if venv_python.exists():
        cmd = [str(venv_python), str(server_path)]
    else:
        cmd = ["python", str(server_path)]
    
    print(f"Starting server: {' '.join(cmd)}")
    
    try:
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        print("Server started, sending initialize...")
        
        # Send initialize
        init_msg = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "test", "version": "1.0.0"}
            }
        }
        
        msg_str = json.dumps(init_msg) + "\n"
        process.stdin.write(msg_str.encode())
        await process.stdin.drain()
        
        # Wait for response
        try:
            response = await asyncio.wait_for(process.stdout.readline(), timeout=3.0)
            print(f"Init response: {response.decode().strip()}")
        except asyncio.TimeoutError:
            print("No init response (this is often normal)")
        
        # Send tools/list
        list_msg = {
            "jsonrpc": "2.0", 
            "id": 2,
            "method": "tools/list",
            "params": {}
        }
        
        msg_str = json.dumps(list_msg) + "\n"
        process.stdin.write(msg_str.encode())
        await process.stdin.drain()
        
        # Wait for response
        try:
            response = await asyncio.wait_for(process.stdout.readline(), timeout=3.0)
            print(f"Tools response: {response.decode().strip()}")
            
            # Parse and show tools
            resp_data = json.loads(response.decode().strip())
            if "result" in resp_data and "tools" in resp_data["result"]:
                tools = resp_data["result"]["tools"]
                print(f"✅ Found {len(tools)} tools:")
                for tool in tools:
                    print(f"   - {tool['name']}: {tool['description']}")
            else:
                print(f"❌ Unexpected response format: {resp_data}")
                
        except asyncio.TimeoutError:
            print("❌ No tools response")
        except json.JSONDecodeError as e:
            print(f"❌ JSON decode error: {e}")
        
        # Cleanup
        process.terminate()
        await asyncio.sleep(0.1)
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_openai_server())