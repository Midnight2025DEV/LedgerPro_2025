#!/usr/bin/env python3
"""
Comprehensive MCP Server Diagnostics Tool
Tests each MCP server individually, validates environments, and measures performance
"""

import os
import sys
import json
import time
import subprocess
import asyncio
import tempfile
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import argparse

# Add color support for terminal output
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

class MCPDiagnostics:
    """Comprehensive MCP server diagnostics"""
    
    def __init__(self, base_path: str = None):
        self.base_path = Path(base_path or os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        self.mcp_servers_path = self.base_path / "mcp-servers"
        self.results = {}
        self.total_tests = 0
        self.passed_tests = 0
        
    def log(self, message: str, level: str = "INFO"):
        """Colored logging"""
        color = {
            "INFO": Colors.CYAN,
            "SUCCESS": Colors.GREEN,
            "WARNING": Colors.YELLOW,
            "ERROR": Colors.RED,
            "DEBUG": Colors.MAGENTA
        }.get(level, Colors.WHITE)
        
        print(f"{color}{message}{Colors.END}")
    
    def test_python_environment(self, venv_path: Path) -> Dict[str, any]:
        """Test Python virtual environment"""
        result = {
            "status": "unknown",
            "python_version": None,
            "venv_exists": False,
            "packages": {},
            "missing_packages": [],
            "errors": []
        }
        
        try:
            # Check if venv exists
            if venv_path.exists():
                result["venv_exists"] = True
                
                # Get Python version
                python_exe = venv_path / "bin" / "python"
                if not python_exe.exists():
                    python_exe = venv_path / "Scripts" / "python.exe"  # Windows
                
                if python_exe.exists():
                    try:
                        version_output = subprocess.run(
                            [str(python_exe), "--version"],
                            capture_output=True,
                            text=True,
                            timeout=10
                        )
                        result["python_version"] = version_output.stdout.strip()
                    except subprocess.TimeoutExpired:
                        result["errors"].append("Python version check timed out")
                    except Exception as e:
                        result["errors"].append(f"Python version check failed: {e}")
                
                # Check required packages
                required_packages = [
                    "mcp",
                    "pdfplumber", 
                    "pandas",
                    "httpx",
                    "fastapi",
                    "uvicorn"
                ]
                
                for package in required_packages:
                    try:
                        import_output = subprocess.run(
                            [str(python_exe), "-c", f"import {package}; print('{package}: OK')"],
                            capture_output=True,
                            text=True,
                            timeout=5
                        )
                        if import_output.returncode == 0:
                            result["packages"][package] = "installed"
                        else:
                            result["packages"][package] = "missing"
                            result["missing_packages"].append(package)
                    except subprocess.TimeoutExpired:
                        result["packages"][package] = "timeout"
                        result["errors"].append(f"Package {package} check timed out")
                    except Exception as e:
                        result["packages"][package] = "error"
                        result["errors"].append(f"Package {package} check failed: {e}")
                
                if not result["missing_packages"] and not result["errors"]:
                    result["status"] = "ok"
                elif result["missing_packages"]:
                    result["status"] = "missing_packages"
                else:
                    result["status"] = "error"
            else:
                result["errors"].append("Virtual environment not found")
                result["status"] = "no_venv"
                
        except Exception as e:
            result["errors"].append(f"Environment test failed: {e}")
            result["status"] = "error"
        
        return result
    
    def measure_startup_time(self, server_path: Path) -> Tuple[float, bool, str]:
        """Measure server startup time"""
        start_time = time.time()
        process = None
        
        try:
            # Find Python executable
            venv_path = server_path.parent / "venv"
            python_exe = venv_path / "bin" / "python"
            if not python_exe.exists():
                python_exe = venv_path / "Scripts" / "python.exe"  # Windows
            
            if not python_exe.exists():
                return 0.0, False, "Python executable not found"
            
            # Start the server process
            process = subprocess.Popen(
                [str(python_exe), str(server_path)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1
            )
            
            # Wait for process to be ready (look for startup indicators)
            startup_time = None
            timeout = 30.0  # 30 second timeout
            
            while time.time() - start_time < timeout:
                # Check if process is still running
                if process.poll() is not None:
                    stdout, stderr = process.communicate()
                    return time.time() - start_time, False, f"Process died: {stderr}"
                
                # Check if we can communicate with the process
                # For MCP servers, we'll consider it ready if it's been running for 2 seconds
                # without crashing (basic readiness test)
                if time.time() - start_time >= 2.0 and startup_time is None:
                    startup_time = time.time() - start_time
                    break
                
                time.sleep(0.1)
            
            if startup_time is None:
                return time.time() - start_time, False, "Startup timeout"
            
            return startup_time, True, "Success"
            
        except Exception as e:
            return time.time() - start_time, False, f"Startup test failed: {e}"
        finally:
            if process and process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
    
    def test_json_rpc_communication(self, server_path: Path) -> Dict[str, any]:
        """Test JSON-RPC communication with server"""
        result = {
            "status": "unknown",
            "startup_time": 0.0,
            "communication_successful": False,
            "responses": [],
            "errors": []
        }
        
        try:
            # Find Python executable
            venv_path = server_path.parent / "venv"
            python_exe = venv_path / "bin" / "python"
            if not python_exe.exists():
                python_exe = venv_path / "Scripts" / "python.exe"  # Windows
            
            if not python_exe.exists():
                result["errors"].append("Python executable not found")
                result["status"] = "error"
                return result
            
            # Start server process
            start_time = time.time()
            process = subprocess.Popen(
                [str(python_exe), str(server_path)],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1
            )
            
            try:
                # Wait for process to start
                time.sleep(2.0)
                
                if process.poll() is not None:
                    stdout, stderr = process.communicate()
                    result["errors"].append(f"Process died during startup: {stderr}")
                    result["status"] = "process_died"
                    return result
                
                result["startup_time"] = time.time() - start_time
                
                # Test basic MCP communication
                # Send initialization request
                init_request = {
                    "jsonrpc": "2.0",
                    "id": 1,
                    "method": "initialize",
                    "params": {
                        "protocolVersion": "2024-11-05",
                        "capabilities": {},
                        "clientInfo": {
                            "name": "mcp-diagnostics",
                            "version": "1.0.0"
                        }
                    }
                }
                
                # Send request
                request_json = json.dumps(init_request) + "\n"
                process.stdin.write(request_json)
                process.stdin.flush()
                
                # Wait for response (with timeout)
                response_received = False
                timeout = 10.0
                start_wait = time.time()
                
                while time.time() - start_wait < timeout:
                    if process.poll() is not None:
                        break
                    
                    # Try to read response
                    try:
                        # Set a short timeout for readline
                        import select
                        import sys
                        
                        if sys.platform != "win32":
                            ready, _, _ = select.select([process.stdout], [], [], 0.1)
                            if ready:
                                response_line = process.stdout.readline()
                                if response_line:
                                    try:
                                        response_data = json.loads(response_line.strip())
                                        result["responses"].append(response_data)
                                        result["communication_successful"] = True
                                        response_received = True
                                        break
                                    except json.JSONDecodeError:
                                        # Might be debug output, continue
                                        pass
                        else:
                            # Windows doesn't have select, use a simpler approach
                            time.sleep(0.5)
                            
                    except Exception as e:
                        result["errors"].append(f"Communication error: {e}")
                        break
                
                if not response_received:
                    result["errors"].append("No response received within timeout")
                    result["status"] = "no_response"
                else:
                    result["status"] = "success"
                
            finally:
                # Clean up process
                if process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                
        except Exception as e:
            result["errors"].append(f"JSON-RPC test failed: {e}")
            result["status"] = "error"
        
        return result
    
    def test_server(self, server_name: str, server_path: Path) -> Dict[str, any]:
        """Test a single MCP server comprehensively"""
        self.log(f"\n{'='*60}")
        self.log(f"🧪 Testing {server_name.upper()}", "INFO")
        self.log(f"{'='*60}")
        
        result = {
            "server_name": server_name,
            "server_path": str(server_path),
            "overall_status": "unknown",
            "environment": {},
            "startup": {},
            "communication": {},
            "summary": {
                "total_tests": 0,
                "passed_tests": 0,
                "issues": []
            }
        }
        
        # Test 1: Python Environment
        self.log(f"📋 Test 1: Python Environment", "INFO")
        venv_path = server_path.parent / "venv"
        result["environment"] = self.test_python_environment(venv_path)
        result["summary"]["total_tests"] += 1
        
        if result["environment"]["status"] == "ok":
            self.log(f"  ✅ Environment: OK", "SUCCESS")
            result["summary"]["passed_tests"] += 1
        else:
            self.log(f"  ❌ Environment: {result['environment']['status']}", "ERROR")
            result["summary"]["issues"].append(f"Environment: {result['environment']['status']}")
        
        # Test 2: Startup Time
        self.log(f"📋 Test 2: Startup Performance", "INFO")
        startup_time, startup_success, startup_message = self.measure_startup_time(server_path)
        result["startup"] = {
            "time_seconds": startup_time,
            "success": startup_success,
            "message": startup_message
        }
        result["summary"]["total_tests"] += 1
        
        if startup_success:
            self.log(f"  ✅ Startup: {startup_time:.2f}s", "SUCCESS")
            result["summary"]["passed_tests"] += 1
        else:
            self.log(f"  ❌ Startup: {startup_message}", "ERROR")
            result["summary"]["issues"].append(f"Startup: {startup_message}")
        
        # Test 3: JSON-RPC Communication
        self.log(f"📋 Test 3: JSON-RPC Communication", "INFO")
        result["communication"] = self.test_json_rpc_communication(server_path)
        result["summary"]["total_tests"] += 1
        
        if result["communication"]["status"] == "success":
            self.log(f"  ✅ Communication: OK", "SUCCESS")
            result["summary"]["passed_tests"] += 1
        else:
            self.log(f"  ❌ Communication: {result['communication']['status']}", "ERROR")
            result["summary"]["issues"].append(f"Communication: {result['communication']['status']}")
        
        # Overall status
        if result["summary"]["passed_tests"] == result["summary"]["total_tests"]:
            result["overall_status"] = "success"
            self.log(f"🎉 {server_name.upper()}: ALL TESTS PASSED", "SUCCESS")
        else:
            result["overall_status"] = "failed"
            self.log(f"❌ {server_name.upper()}: {result['summary']['passed_tests']}/{result['summary']['total_tests']} tests passed", "ERROR")
        
        return result
    
    def run_all_tests(self) -> Dict[str, any]:
        """Run diagnostics on all MCP servers"""
        self.log(f"{Colors.BOLD}🚀 MCP Server Comprehensive Diagnostics{Colors.END}")
        self.log(f"Base path: {self.base_path}")
        self.log(f"MCP servers path: {self.mcp_servers_path}")
        
        # Server configurations
        servers = {
            "pdf-processor": self.mcp_servers_path / "pdf-processor" / "pdf_processor_server.py",
            "openai-service": self.mcp_servers_path / "openai-service" / "openai_server.py", 
            "financial-analyzer": self.mcp_servers_path / "financial-analyzer" / "financial_analyzer_server.py"
        }
        
        # Check if servers exist
        for name, path in servers.items():
            if not path.exists():
                self.log(f"⚠️  Server {name} not found at {path}", "WARNING")
        
        # Test each server
        for server_name, server_path in servers.items():
            if server_path.exists():
                self.results[server_name] = self.test_server(server_name, server_path)
                self.total_tests += self.results[server_name]["summary"]["total_tests"]
                self.passed_tests += self.results[server_name]["summary"]["passed_tests"]
            else:
                self.results[server_name] = {
                    "server_name": server_name,
                    "server_path": str(server_path),
                    "overall_status": "not_found",
                    "summary": {"issues": ["Server file not found"]}
                }
        
        return self.results
    
    def generate_report(self) -> str:
        """Generate a comprehensive diagnostic report"""
        report = f"\n{Colors.BOLD}📊 MCP DIAGNOSTICS REPORT{Colors.END}\n"
        report += f"{'='*60}\n"
        
        # Summary
        successful_servers = sum(1 for r in self.results.values() if r["overall_status"] == "success")
        total_servers = len(self.results)
        
        report += f"📈 Overall Results: {successful_servers}/{total_servers} servers working\n"
        report += f"📋 Total Tests: {self.passed_tests}/{self.total_tests} passed\n\n"
        
        # Per-server details
        for server_name, result in self.results.items():
            status_icon = "✅" if result["overall_status"] == "success" else "❌"
            report += f"{status_icon} {server_name.upper()}\n"
            
            if "summary" in result and "issues" in result["summary"]:
                if result["summary"]["issues"]:
                    report += f"  Issues:\n"
                    for issue in result["summary"]["issues"]:
                        report += f"    • {issue}\n"
                else:
                    report += f"  All tests passed!\n"
            
            # Environment details
            if "environment" in result:
                env = result["environment"]
                if env["status"] != "ok":
                    report += f"  Environment: {env['status']}\n"
                    if env["missing_packages"]:
                        report += f"    Missing packages: {', '.join(env['missing_packages'])}\n"
            
            # Startup details
            if "startup" in result:
                startup = result["startup"]
                if startup["success"]:
                    report += f"  Startup time: {startup['time_seconds']:.2f}s\n"
                else:
                    report += f"  Startup failed: {startup['message']}\n"
            
            report += "\n"
        
        # Recommendations
        report += f"{Colors.BOLD}🔧 RECOMMENDATIONS{Colors.END}\n"
        report += f"{'='*60}\n"
        
        failed_servers = [name for name, result in self.results.items() if result["overall_status"] != "success"]
        
        if not failed_servers:
            report += "🎉 All servers are working correctly!\n"
            report += "✅ MCP integration should work properly in the Swift app.\n"
        else:
            report += f"❌ {len(failed_servers)} server(s) need attention:\n"
            for server in failed_servers:
                report += f"  • {server}\n"
            
            report += "\n📋 Next Steps:\n"
            report += "1. Check virtual environment setup:\n"
            report += "   cd mcp-servers/{server-name}\n"
            report += "   python -m venv venv\n"
            report += "   source venv/bin/activate\n"
            report += "   pip install -r requirements.txt\n"
            report += "\n2. Test individual server:\n"
            report += "   python {server-name}_server.py\n"
            report += "\n3. Check the Swift app MCPServerLauncher logs\n"
        
        return report
    
    def save_results(self, filename: str = "mcp_diagnostics_results.json"):
        """Save detailed results to JSON file"""
        output_path = self.mcp_servers_path / filename
        
        # Add timestamp and metadata
        diagnostic_data = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "base_path": str(self.base_path),
            "total_tests": self.total_tests,
            "passed_tests": self.passed_tests,
            "results": self.results
        }
        
        with open(output_path, 'w') as f:
            json.dump(diagnostic_data, f, indent=2)
        
        self.log(f"📄 Detailed results saved to: {output_path}", "INFO")
        return output_path

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="MCP Server Diagnostics Tool")
    parser.add_argument("--base-path", help="Base path to LedgerPro project")
    parser.add_argument("--server", help="Test specific server only")
    parser.add_argument("--save-results", action="store_true", help="Save detailed results to JSON")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose output")
    
    args = parser.parse_args()
    
    # Create diagnostics instance
    diagnostics = MCPDiagnostics(args.base_path)
    
    # Run tests
    if args.server:
        # Test specific server
        server_path = diagnostics.mcp_servers_path / args.server / f"{args.server.replace('-', '_')}_server.py"
        if server_path.exists():
            result = diagnostics.test_server(args.server, server_path)
            diagnostics.results[args.server] = result
            diagnostics.total_tests = result["summary"]["total_tests"]
            diagnostics.passed_tests = result["summary"]["passed_tests"]
        else:
            print(f"❌ Server {args.server} not found at {server_path}")
            sys.exit(1)
    else:
        # Test all servers
        diagnostics.run_all_tests()
    
    # Generate and display report
    report = diagnostics.generate_report()
    print(report)
    
    # Save results if requested
    if args.save_results:
        diagnostics.save_results()
    
    # Exit code based on results
    if diagnostics.passed_tests == diagnostics.total_tests:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()