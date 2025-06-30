#!/usr/bin/env python3
"""
Test script for MCP servers
Tests all three MCP servers locally before configuring with Claude Desktop
"""
import asyncio
import json
import subprocess
import time
import sys
from pathlib import Path

# Test data
SAMPLE_TRANSACTIONS = [
    {"date": "2024-01-15", "description": "Starbucks Coffee", "amount": -5.75},
    {"date": "2024-01-16", "description": "Salary Deposit", "amount": 3500.00},
    {"date": "2024-01-17", "description": "Grocery Store", "amount": -125.43},
    {"date": "2024-01-18", "description": "Gas Station", "amount": -65.20},
]

class MCPTester:
    """Test MCP servers using JSON-RPC protocol"""
    
    def __init__(self):
        self.test_results = {}
    
    async def test_server(self, server_name: str, server_path: str, tests: list):
        """Test a single MCP server"""
        print(f"\n🧪 Testing {server_name}...")
        print(f"   Server: {server_path}")
        
        results = {
            "server": server_name,
            "status": "unknown",
            "tests": [],
            "errors": []
        }
        
        try:
            # Test if server can start
            process = await self.start_server(server_path)
            if not process:
                results["status"] = "failed_to_start"
                results["errors"].append("Server failed to start")
                return results
            
            # Initialize server
            await self.send_initialize(process)
            
            # Run tests
            for test in tests:
                test_result = await self.run_test(process, test)
                results["tests"].append(test_result)
                
                if test_result["success"]:
                    print(f"   ✅ {test['name']}")
                else:
                    print(f"   ❌ {test['name']}: {test_result.get('error', 'Unknown error')}")
            
            # Cleanup
            process.terminate()
            await asyncio.sleep(0.1)  # Give it time to cleanup
            
            # Determine overall status
            if all(t["success"] for t in results["tests"]):
                results["status"] = "all_tests_passed"
            elif any(t["success"] for t in results["tests"]):
                results["status"] = "some_tests_passed"
            else:
                results["status"] = "all_tests_failed"
                
        except Exception as e:
            results["status"] = "error"
            results["errors"].append(str(e))
            print(f"   💥 Server error: {e}")
        
        return results
    
    async def start_server(self, server_path: str):
        """Start MCP server process"""
        try:
            # Get the server directory to activate virtual environment
            server_dir = Path(server_path).parent
            venv_python = server_dir / "venv" / "bin" / "python"
            
            if venv_python.exists():
                cmd = [str(venv_python), server_path]
            else:
                cmd = ["python", server_path]
            
            import os
            env = dict(os.environ)
            env["PYTHONPATH"] = str(Path(__file__).parent.parent)
            
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                env=env
            )
            
            # Give server time to start
            await asyncio.sleep(1)
            
            if process.returncode is not None:
                # Process already exited
                stderr = await process.stderr.read()
                print(f"   ⚠️  Server exited early: {stderr.decode()}")
                return None
            
            return process
            
        except Exception as e:
            print(f"   ❌ Failed to start server: {e}")
            return None
    
    async def send_initialize(self, process):
        """Send initialization message to MCP server"""
        init_message = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {
                    "name": "test-client",
                    "version": "1.0.0"
                }
            }
        }
        
        message_str = json.dumps(init_message) + "\n"
        process.stdin.write(message_str.encode())
        await process.stdin.drain()
        
        # Read response (optional - some servers might not respond immediately)
        try:
            # Set a short timeout for initialization response
            response = await asyncio.wait_for(
                process.stdout.readline(), 
                timeout=2.0
            )
        except asyncio.TimeoutError:
            # It's okay if init doesn't respond immediately
            pass
    
    async def run_test(self, process, test):
        """Run a single test against the MCP server"""
        test_result = {
            "name": test["name"],
            "success": False,
            "response": None,
            "error": None
        }
        
        try:
            # Send test message
            message = {
                "jsonrpc": "2.0",
                "id": test.get("id", 2),
                "method": test["method"],
                "params": test["params"]
            }
            
            message_str = json.dumps(message) + "\n"
            process.stdin.write(message_str.encode())
            await process.stdin.drain()
            
            # Read response with timeout
            try:
                response_line = await asyncio.wait_for(
                    process.stdout.readline(), 
                    timeout=5.0
                )
                
                if response_line:
                    response = json.loads(response_line.decode().strip())
                    test_result["response"] = response
                    
                    # Check if response indicates success
                    if "error" not in response:
                        test_result["success"] = True
                    else:
                        test_result["error"] = response["error"]
                else:
                    test_result["error"] = "No response received"
                    
            except asyncio.TimeoutError:
                test_result["error"] = "Response timeout"
            except json.JSONDecodeError as e:
                test_result["error"] = f"Invalid JSON response: {e}"
                
        except Exception as e:
            test_result["error"] = str(e)
        
        return test_result

def get_server_tests():
    """Define tests for each server"""
    return {
        "openai-service": [
            {
                "name": "List Tools",
                "method": "tools/list",
                "params": {},
                "id": 10
            }
        ],
        "pdf-processor": [
            {
                "name": "List Tools",
                "method": "tools/list", 
                "params": {},
                "id": 20
            }
        ],
        "financial-analyzer": [
            {
                "name": "List Tools",
                "method": "tools/list",
                "params": {},
                "id": 30
            }
        ]
    }

async def main():
    """Run all MCP server tests"""
    print("🚀 MCP Server Test Suite")
    print("=" * 50)
    
    import os
    
    tester = MCPTester()
    server_tests = get_server_tests()
    
    # Define server paths
    base_path = Path(__file__).parent
    servers = {
        "openai-service": base_path / "openai-service" / "openai_server.py",
        "pdf-processor": base_path / "pdf-processor" / "pdf_processor_server.py", 
        "financial-analyzer": base_path / "financial-analyzer" / "analyzer_server.py"
    }
    
    # Test each server
    all_results = {}
    for server_name, server_path in servers.items():
        if server_path.exists():
            tests = server_tests.get(server_name, [])
            result = await tester.test_server(server_name, str(server_path), tests)
            all_results[server_name] = result
        else:
            print(f"\n❌ {server_name}: Server file not found at {server_path}")
            all_results[server_name] = {
                "status": "file_not_found",
                "errors": [f"Server file not found: {server_path}"]
            }
    
    # Print summary
    print("\n" + "=" * 50)
    print("📊 Test Summary")
    print("=" * 50)
    
    total_servers = len(servers)
    working_servers = 0
    
    for server_name, result in all_results.items():
        status = result["status"]
        if status == "all_tests_passed":
            print(f"✅ {server_name}: All tests passed")
            working_servers += 1
        elif status == "some_tests_passed":
            print(f"⚠️  {server_name}: Some tests passed")
        elif status == "failed_to_start":
            print(f"💥 {server_name}: Failed to start")
        elif status == "file_not_found":
            print(f"📁 {server_name}: File not found")
        else:
            print(f"❌ {server_name}: Tests failed")
        
        # Show errors if any
        if result.get("errors"):
            for error in result["errors"]:
                print(f"   • {error}")
    
    print(f"\n🎯 Overall: {working_servers}/{total_servers} servers working correctly")
    
    # Provide next steps
    print("\n" + "=" * 50)
    print("🔧 Next Steps")
    print("=" * 50)
    
    if working_servers == total_servers:
        print("✅ All servers are working! You can now:")
        print("   1. Copy claude_desktop_config.json to Claude Desktop config")
        print("   2. Update the OPENAI_API_KEY in the config")
        print("   3. Restart Claude Desktop")
        print("   4. Test with: 'Analyze my bank statement at /path/to/statement.pdf'")
    else:
        print("⚠️  Some servers need attention. Check the errors above.")
        print("   1. Ensure all virtual environments are set up correctly")
        print("   2. Check that all dependencies are installed")
        print("   3. Verify file paths are correct")
    
    print(f"\n📝 Config file created at: {base_path / 'claude_desktop_config.json'}")
    print("   Copy this to: ~/Library/Application Support/Claude/claude_desktop_config.json")

if __name__ == "__main__":
    import os
    asyncio.run(main())