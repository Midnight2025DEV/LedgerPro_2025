#!/usr/bin/env python3
"""
Financial API Diagnostics MCP Server
====================================

Diagnoses API endpoint mismatches, WebSocket connection issues, and performance bottlenecks
in the AI Financial Accountant application.
"""

import asyncio
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Any
import websockets
import aiohttp
import ast

# MCP imports
from mcp.server.models import InitializationOptions
from mcp.server import NotificationOptions, Server
from mcp.types import (
    Resource, Tool, TextContent, ImageContent, EmbeddedResource
)
import mcp.types as types
import mcp.server.stdio

# Initialize MCP server
server = Server("financial-api-diagnostics")

# Project paths (adjust these to your actual paths)
PROJECT_ROOT = Path("/Users/jonathanhernandez/Documents/Cursor_AI/AI_Financial_Accountant")
BACKEND_PATH = PROJECT_ROOT / "financial_advisor"
FRONTEND_PATH = PROJECT_ROOT / "web-frontend"

class APIEndpointScanner:
    """Scans backend FastAPI routes and frontend API calls"""
    
    def __init__(self):
        self.backend_endpoints = []
        self.frontend_calls = []
        
    def scan_fastapi_routes(self) -> List[Dict[str, Any]]:
        """Scan FastAPI routes from the backend"""
        routes = []
        
        # Look for Python files with FastAPI routes
        for py_file in BACKEND_PATH.rglob("*.py"):
            try:
                with open(py_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Find FastAPI route decorators
                route_patterns = [
                    r'@app\.(get|post|put|delete|websocket)\(["\']([^"\']+)["\']',
                    r'@router\.(get|post|put|delete|websocket)\(["\']([^"\']+)["\']'
                ]
                
                for pattern in route_patterns:
                    matches = re.findall(pattern, content)
                    for method, path in matches:
                        routes.append({
                            "method": method.upper(),
                            "path": path,
                            "file": str(py_file.relative_to(PROJECT_ROOT)),
                            "type": "websocket" if method == "websocket" else "http"
                        })
                        
            except Exception as e:
                print(f"Error scanning {py_file}: {e}")
                
        return routes
    
    def scan_frontend_api_calls(self) -> List[Dict[str, Any]]:
        """Scan TypeScript/JavaScript API calls from frontend"""
        calls = []
        
        # Look for TypeScript/JavaScript files
        for js_file in FRONTEND_PATH.rglob("*.ts"):
            try:
                with open(js_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Find API endpoint calls
                patterns = [
                    r'fetch\([\'"`]([^\'"`]+)[\'"`]',
                    r'axios\.(get|post|put|delete)\([\'"`]([^\'"`]+)[\'"`]',
                    r'new WebSocket\([\'"`]([^\'"`]+)[\'"`]',
                    r'request<[^>]*>\([\'"`]([^\'"`]+)[\'"`]',
                    r'this\.baseURL\s*\+\s*[\'"`]([^\'"`]+)[\'"`]',
                    r'`\${[^}]*baseURL}([^`]+)`'
                ]
                
                for pattern in patterns:
                    matches = re.findall(pattern, content)
                    for match in matches:
                        if isinstance(match, tuple):
                            if len(match) == 2:  # method, url
                                method, url = match
                                calls.append({
                                    "method": method.upper(),
                                    "url": url,
                                    "file": str(js_file.relative_to(PROJECT_ROOT)),
                                    "type": "websocket" if "ws://" in url or "wss://" in url else "http"
                                })
                            else:
                                url = match[0]
                                calls.append({
                                    "method": "UNKNOWN",
                                    "url": url,
                                    "file": str(js_file.relative_to(PROJECT_ROOT)),
                                    "type": "websocket" if "ws://" in url or "wss://" in url else "http"
                                })
                        else:
                            calls.append({
                                "method": "UNKNOWN", 
                                "url": match,
                                "file": str(js_file.relative_to(PROJECT_ROOT)),
                                "type": "websocket" if "ws://" in match or "wss://" in match else "http"
                            })
                            
            except Exception as e:
                print(f"Error scanning {js_file}: {e}")
                
        return calls

class WebSocketDiagnostics:
    """WebSocket connection testing and diagnostics"""
    
    @staticmethod
    async def test_websocket_connection(url: str, timeout: float = 5.0) -> Dict[str, Any]:
        """Test WebSocket connection"""
        result = {
            "url": url,
            "connected": False,
            "error": None,
            "response_time": None
        }
        
        try:
            import time
            start_time = time.time()
            
            async with websockets.connect(url) as websocket:
                result["connected"] = True
                result["response_time"] = time.time() - start_time
                
                # Try to send a ping
                await websocket.send("ping")
                response = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                result["ping_response"] = response
                
        except Exception as e:
            result["error"] = str(e)
            
        return result

class HTTPDiagnostics:
    """HTTP endpoint testing and diagnostics"""
    
    @staticmethod
    async def test_http_endpoint(url: str, method: str = "GET") -> Dict[str, Any]:
        """Test HTTP endpoint availability"""
        result = {
            "url": url,
            "method": method,
            "status": None,
            "error": None,
            "response_time": None
        }
        
        try:
            import time
            start_time = time.time()
            
            async with aiohttp.ClientSession() as session:
                async with session.request(method, url) as response:
                    result["status"] = response.status
                    result["response_time"] = time.time() - start_time
                    result["headers"] = dict(response.headers)
                    
        except Exception as e:
            result["error"] = str(e)
            
        return result

# MCP Tools
@server.list_tools()
async def handle_list_tools() -> List[Tool]:
    """List available diagnostic tools"""
    return [
        Tool(
            name="scan_api_endpoints",
            description="Scan and compare backend routes with frontend API calls",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": []
            }
        ),
        Tool(
            name="test_websocket_connections", 
            description="Test WebSocket endpoint connectivity",
            inputSchema={
                "type": "object",
                "properties": {
                    "job_id": {
                        "type": "string",
                        "description": "Job ID to test WebSocket connection with"
                    }
                },
                "required": []
            }
        ),
        Tool(
            name="test_http_endpoints",
            description="Test HTTP endpoint availability",
            inputSchema={
                "type": "object", 
                "properties": {
                    "base_url": {
                        "type": "string",
                        "description": "Base URL to test (default: http://127.0.0.1:8000)"
                    }
                },
                "required": []
            }
        ),
        Tool(
            name="diagnose_upload_issue",
            description="Comprehensive diagnosis of upload and processing issues",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": []
            }
        ),
        Tool(
            name="check_server_status",
            description="Check if backend server is running and responsive",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": []
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: Dict[str, Any]) -> List[types.TextContent]:
    """Handle tool execution"""
    
    if name == "scan_api_endpoints":
        scanner = APIEndpointScanner()
        backend_routes = scanner.scan_fastapi_routes()
        frontend_calls = scanner.scan_frontend_api_calls()
        
        # Find mismatches
        mismatches = []
        backend_paths = {route["path"] for route in backend_routes}
        
        for call in frontend_calls:
            url = call["url"]
            # Extract path from URL (remove base URL if present)
            if url.startswith("http"):
                from urllib.parse import urlparse
                parsed = urlparse(url)
                path = parsed.path
            else:
                path = url
            
            # Check for exact match
            if path not in backend_paths:
                # Look for similar paths
                similar = [bp for bp in backend_paths if bp.replace("/v1", "") == path.replace("/v1", "")]
                mismatches.append({
                    "frontend_call": call,
                    "expected_path": path,
                    "similar_backend_paths": similar
                })
        
        result = {
            "backend_routes": backend_routes,
            "frontend_calls": frontend_calls,
            "mismatches": mismatches,
            "summary": {
                "total_backend_routes": len(backend_routes),
                "total_frontend_calls": len(frontend_calls),
                "mismatches_found": len(mismatches)
            }
        }
        
        return [types.TextContent(
            type="text",
            text=f"API Endpoint Analysis:\n\n{json.dumps(result, indent=2)}"
        )]
    
    elif name == "test_websocket_connections":
        job_id = arguments.get("job_id", "test-job-123")
        diagnostics = WebSocketDiagnostics()
        
        # Test both /api/ and /api/v1/ WebSocket endpoints
        urls_to_test = [
            f"ws://127.0.0.1:8000/api/ws/progress/{job_id}",
            f"ws://127.0.0.1:8000/api/v1/ws/progress/{job_id}"
        ]
        
        results = []
        for url in urls_to_test:
            result = await diagnostics.test_websocket_connection(url)
            results.append(result)
        
        return [types.TextContent(
            type="text",
            text=f"WebSocket Connection Tests:\n\n{json.dumps(results, indent=2)}"
        )]
    
    elif name == "test_http_endpoints":
        base_url = arguments.get("base_url", "http://127.0.0.1:8000")
        diagnostics = HTTPDiagnostics()
        
        # Test key endpoints
        endpoints_to_test = [
            f"{base_url}/api/health",
            f"{base_url}/api/upload",
            f"{base_url}/api/v1/upload",
            f"{base_url}/api/jobs",
            f"{base_url}/api/v1/jobs"
        ]
        
        results = []
        for url in endpoints_to_test:
            result = await diagnostics.test_http_endpoint(url)
            results.append(result)
        
        return [types.TextContent(
            type="text", 
            text=f"HTTP Endpoint Tests:\n\n{json.dumps(results, indent=2)}"
        )]
    
    elif name == "diagnose_upload_issue":
        # Comprehensive diagnosis
        scanner = APIEndpointScanner()
        backend_routes = scanner.scan_fastapi_routes()
        frontend_calls = scanner.scan_frontend_api_calls()
        
        http_diagnostics = HTTPDiagnostics()
        ws_diagnostics = WebSocketDiagnostics()
        
        # Test upload endpoints
        upload_test = await http_diagnostics.test_http_endpoint("http://127.0.0.1:8000/api/v1/upload", "POST")
        
        # Test WebSocket
        ws_test = await ws_diagnostics.test_websocket_connection("ws://127.0.0.1:8000/api/v1/ws/progress/test-job")
        
        diagnosis = {
            "issue_analysis": {
                "upload_endpoint_status": upload_test,
                "websocket_status": ws_test,
                "detected_issues": []
            },
            "recommendations": []
        }
        
        # Analyze issues
        if upload_test.get("status") == 404:
            diagnosis["issue_analysis"]["detected_issues"].append("Upload endpoint returning 404 - URL mismatch")
            diagnosis["recommendations"].append("Check frontend is calling /api/v1/upload endpoint")
        
        if not ws_test.get("connected"):
            diagnosis["issue_analysis"]["detected_issues"].append("WebSocket connection failed")
            diagnosis["recommendations"].append("Verify WebSocket endpoint exists and is accessible")
        
        return [types.TextContent(
            type="text",
            text=f"Upload Issue Diagnosis:\n\n{json.dumps(diagnosis, indent=2)}"
        )]
    
    elif name == "check_server_status":
        diagnostics = HTTPDiagnostics()
        health_check = await diagnostics.test_http_endpoint("http://127.0.0.1:8000/api/health")
        
        # Check if server is running
        try:
            result = subprocess.run(["lsof", "-i", ":8000"], capture_output=True, text=True)
            port_status = {
                "port_8000_in_use": "python" in result.stdout.lower(),
                "process_details": result.stdout.strip()
            }
        except:
            port_status = {"error": "Could not check port status"}
        
        status = {
            "health_check": health_check,
            "port_status": port_status
        }
        
        return [types.TextContent(
            type="text",
            text=f"Server Status:\n\n{json.dumps(status, indent=2)}"
        )]
    
    else:
        return [types.TextContent(
            type="text",
            text=f"Unknown tool: {name}"
        )]

async def main():
    # Run the server using stdin/stdout streams
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="financial-api-diagnostics",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )

if __name__ == "__main__":
    asyncio.run(main())