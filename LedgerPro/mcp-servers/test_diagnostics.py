#!/usr/bin/env python3
"""
Test script to run the financial API diagnostics directly
"""

import asyncio
import sys
import os
sys.path.append('/Users/jonathanhernandez/Documents/Cursor_AI/AI_Financial_Accountant/mcp-servers/financial-api-diagnostics')

from server import APIEndpointScanner, WebSocketDiagnostics, HTTPDiagnostics

async def run_diagnostics():
    print("🔍 Financial API Diagnostics")
    print("=" * 50)
    
    # 1. Scan API endpoints
    print("\n1. Scanning API Endpoints...")
    scanner = APIEndpointScanner()
    backend_routes = scanner.scan_fastapi_routes()
    frontend_calls = scanner.scan_frontend_api_calls()
    
    print(f"📋 Found {len(backend_routes)} backend routes")
    print(f"📋 Found {len(frontend_calls)} frontend API calls")
    
    print("\n🔗 Backend Routes:")
    for route in backend_routes:
        print(f"  {route['method']} {route['path']} ({route['type']})")
    
    print("\n🔗 Frontend API Calls:")
    for call in frontend_calls:
        print(f"  {call['method']} {call['url']} ({call['type']})")
    
    # 2. Check for mismatches
    print("\n2. Checking for URL Mismatches...")
    backend_paths = {route["path"] for route in backend_routes}
    mismatches = []
    
    for call in frontend_calls:
        url = call["url"]
        if url.startswith("http"):
            from urllib.parse import urlparse
            parsed = urlparse(url)
            path = parsed.path
        else:
            path = url
        
        if path not in backend_paths:
            similar = [bp for bp in backend_paths if bp.replace("/v1", "") == path.replace("/v1", "")]
            mismatches.append({
                "frontend_call": path,
                "similar_backend_paths": similar
            })
    
    if mismatches:
        print("❌ URL Mismatches Found:")
        for mismatch in mismatches:
            print(f"  Frontend calls: {mismatch['frontend_call']}")
            print(f"  Similar backend: {mismatch['similar_backend_paths']}")
    else:
        print("✅ No URL mismatches found")
    
    # 3. Test HTTP endpoints
    print("\n3. Testing HTTP Endpoints...")
    http_diagnostics = HTTPDiagnostics()
    
    endpoints_to_test = [
        "http://127.0.0.1:8000/api/health",
        "http://127.0.0.1:8000/api/upload",
        "http://127.0.0.1:8000/api/v1/upload"
    ]
    
    for url in endpoints_to_test:
        method = "POST" if "upload" in url else "GET"
        result = await http_diagnostics.test_http_endpoint(url, method)
        expected_status = 422 if method == "POST" else 200  # 422 = missing file data
        status_icon = "✅" if result.get("status") in [200, 422] else "❌"
        print(f"  {status_icon} {url} ({method}) - Status: {result.get('status', 'ERROR')}")
        if result.get("error"):
            print(f"    Error: {result['error']}")
    
    # 4. Test WebSocket connections
    print("\n4. Testing WebSocket Connections...")
    ws_diagnostics = WebSocketDiagnostics()
    
    ws_urls = [
        "ws://127.0.0.1:8000/api/ws/progress/test-job",
        "ws://127.0.0.1:8000/api/v1/ws/progress/test-job"
    ]
    
    for url in ws_urls:
        result = await ws_diagnostics.test_websocket_connection(url)
        status_icon = "✅" if result.get("connected") else "❌"
        print(f"  {status_icon} {url} - Connected: {result.get('connected')}")
        if result.get("error"):
            print(f"    Error: {result['error']}")
    
    # 5. Summary and recommendations
    print("\n5. Summary & Recommendations")
    print("=" * 30)
    
    if mismatches:
        print("🚨 Issues Found:")
        print("  - URL mismatches between frontend and backend")
        print("  - Frontend may be calling wrong endpoints")
        
        print("\n💡 Recommendations:")
        print("  1. Update backend to support /api/v1/ endpoints")
        print("  2. Or update frontend to use /api/ endpoints")
        print("  3. Ensure WebSocket URLs match between frontend and backend")
    else:
        print("✅ No major issues detected in endpoint mapping")
    
    print("\n🔧 Next Steps:")
    print("  1. Verify backend server is running on port 8000")
    print("  2. Check browser console for WebSocket connection logs")
    print("  3. Test file upload with corrected endpoints")

if __name__ == "__main__":
    asyncio.run(run_diagnostics())