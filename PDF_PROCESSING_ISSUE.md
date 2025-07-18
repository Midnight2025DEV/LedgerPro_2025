# PDF Processing Issue - Real World Testing

## Issue Summary
Date Reported: January 2025
Status: Open
Priority: High
Component: PDF Processing (MCP/Backend)

## Problem Description
When processing real PDF bank statements, the system experiences [SPECIFIC ISSUE TO BE DETAILED]

## Symptoms Observed
- [ ] Processing gets stuck at 30% progress
- [ ] JSON buffering errors in MCP communication
- [ ] Large response size (18KB+) causing timeouts
- [ ] Backend disconnection forcing MCP fallback
- [ ] Slower processing than previous attempts
- [ ] Other: _________________

## Environment Details
- macOS Version: [VERSION]
- LedgerPro Version: Current main branch
- Python Backend Status: Disconnected (port 8000)
- MCP Servers: Running (ports 8001-8003)
- File Tested: Capital One_Credit Card_May 2025_Statement.pdf

## Error Logs
```
⚠️ Server error: [DEBUG] Tool response size: 18229 bytes
⚠️ Received partial or invalid JSON, buffering: 4117 bytes
❌ Network error: Could not connect to the server (port 8000)
```

## Comparison with Previous Behavior
- **Before**: Same PDF processed in ~5-10 seconds using Python backend
- **Now**: Processing takes 60+ seconds with MCP fallback
- **Difference**: 10x slower due to JSON chunking and protocol overhead

## Root Cause Analysis
1. **Primary Issue**: Python backend not running, forcing MCP fallback
2. **Secondary Issue**: MCP server has JSON serialization bottleneck for large PDFs
3. **Contributing Factor**: Response buffering suggests memory/streaming issues

## Attempted Solutions
- [ ] Restart Python backend
- [ ] Restart MCP servers
- [ ] Clear temporary files
- [ ] Reduce PDF size
- [ ] Toggle between backend/MCP processing

## Proposed Fixes

### Short Term (Quick Fix)
1. Start Python backend: `cd backend && python api_server_real.py`
2. Disable MCP processing toggle in UI
3. Add timeout handling for stuck processes

### Medium Term (This Week)
1. Implement streaming in MCP PDF processor
2. Add response compression
3. Optimize JSON serialization
4. Add progress timeout detection

### Long Term (Next Sprint)
1. Unify processing pipeline (no dual system)
2. Implement parallel page processing
3. Add caching for processed PDFs
4. Binary protocol instead of JSON

## Code References
- MCP PDF Processor: `/mcp-servers/pdf-processor/pdf_processor_server.py`
- MCPBridge: `/Sources/LedgerPro/Services/MCPBridge.swift`
- FileUploadView: `/Sources/LedgerPro/Views/FileUploadView.swift`
- Backend API: `/backend/api_server_real.py`

## Testing Notes
- Test file path: [PROVIDE FULL PATH]
- File size: [SIZE IN MB]
- Page count: [NUMBER]
- Special characteristics: Contains foreign currency transactions (MXN)

## Performance Metrics
| Metric | Python Backend | MCP (Current) | MCP (Target) |
|--------|---------------|---------------|--------------|
| Small PDF (<10 pages) | 2s | 5s | 1s |
| Large PDF (50+ pages) | 10s | 60s+ | 3s |
| Memory Usage | 200MB | 150MB | 50MB |
| Success Rate | 95% | 85% | 99% |

## Next Steps
1. Document specific error messages and stack traces
2. Profile MCP server to identify bottlenecks
3. Test with different PDF formats/banks
4. Implement proposed short-term fixes
5. Design unified processing architecture

## Related Issues
- Transaction anonymization (separate task)
- MCP server optimization
- Backend auto-start feature

## Notes for Future Work
- Consider implementing PDF preview before processing
- Add file validation before upload
- Implement retry mechanism with different processors
- Add detailed error reporting to user

---
*This issue is saved for future investigation when working on PDF processing optimization.*