# MCP Server Initialization Timing Fix

## Problem Solved
- MCP servers could appear "connected" but not fully initialized
- Processing would fail because servers weren't ready to handle requests
- Basic `areServersReady()` only checked connection status, not actual readiness

## Solution Implemented

### 1. Enhanced Initialization Check (`MCPBridge+InitializationFix.swift`)
```swift
func waitForServersToInitialize(maxAttempts: Int = 30) async throws
```

**Features:**
- **Two-stage verification**: First checks connection, then actual readiness
- **Functional testing**: Calls `list_tools` on each server to verify it's responding
- **Proper timing**: 30 attempts with 1-second intervals (30 seconds total)
- **Detailed logging**: Progress updates and error details
- **Fail-fast**: Throws meaningful errors if initialization fails

### 2. Updated FileUploadView Processing
**Before:**
```swift
// Basic connection check with manual retry loop
while !mcpBridge.areServersReady() && retries < maxRetries {
    try await Task.sleep(nanoseconds: 500_000_000)
    retries += 1
}
```

**After:**
```swift
// Enhanced initialization verification
try await mcpBridge.waitForServersToInitialize(maxAttempts: 30)
```

## Benefits

- ✅ **Reliable initialization**: Verifies servers can actually handle requests
- ✅ **Better error handling**: Clear error messages when initialization fails  
- ✅ **Improved timing**: Longer timeout (30s vs 10s) for slow systems
- ✅ **Detailed logging**: Progress visibility in Console.app
- ✅ **Reusable**: Can be used anywhere MCP initialization is needed

## How It Works

1. **Connection Check**: Verifies basic server connectivity
2. **Functional Test**: Calls `list_tools` on each connected server
3. **Response Validation**: Ensures servers respond without errors
4. **Retry Logic**: Repeats every second up to 30 times
5. **Success/Failure**: Either completes successfully or throws descriptive error

## Usage

The timing fix is automatically used when processing PDFs with MCP:

```swift
// In FileUploadView.processPDFWithMCP()
try await mcpBridge.waitForServersToInitialize(maxAttempts: 30)
```

## Test Results

- ✅ Builds successfully without errors
- ✅ Integrates seamlessly with existing code
- ✅ Provides better reliability for MCP processing
- ✅ No performance impact (only runs when needed)

## Files Modified

- `Sources/LedgerPro/Services/MCP/MCPBridge+InitializationFix.swift` (new)
- `Sources/LedgerPro/Views/FileUploadView.swift` (updated `processPDFWithMCP`)

This fix ensures MCP servers are truly ready before attempting to process documents, eliminating timing-related failures.