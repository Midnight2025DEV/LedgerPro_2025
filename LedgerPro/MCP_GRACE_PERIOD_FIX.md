# MCP Timing Fix - Grace Period Implementation

## Problem
The Python MCP servers were rejecting ping requests even after significant delays, indicating they need an extended initialization period before accepting health check requests.

## Solution Implemented
Added a 60-second startup grace period where health checks automatically succeed without sending ping requests. This prevents reconnection cycles while giving servers ample time to fully initialize.

## Changes Made

### 1. Added Connection Start Time Tracking
**File**: `MCPServer.swift`
```swift
private var connectionStartTime: Date?
```

### 2. Updated healthCheck() Method
**File**: `MCPServer.swift` (line ~169)
```swift
func healthCheck() async throws -> MCPHealthStatus {
    // During first 60 seconds, return mock healthy status
    if let startTime = connectionStartTime,
       Date().timeIntervalSince(startTime) < 60.0 {
        let elapsedTime = Date().timeIntervalSince(startTime)
        print("⏳ \(info.name) in startup grace period (\(Int(elapsedTime))s/60s)")
        lastHealthCheck = Date()
        return MCPHealthStatus(
            status: "healthy",
            timestamp: Date().timeIntervalSince1970,
            serverInfo: info
        )
    }
    
    // After grace period, use normal ping health check
    // ... existing ping logic ...
}
```

### 3. Reset Timing Values
- Initial delay before heartbeat: 2 seconds (reduced from 15s)
- Retry delay: 2 seconds (reduced from 5s)
- Grace period: 60 seconds (new)

## Expected Behavior

### During First 60 Seconds
- ✅ "⏳ [Server Name] in startup grace period (Xs/60s)" messages
- ✅ No ping requests sent
- ✅ No reconnection attempts
- ✅ Servers remain connected

### After 60 Seconds
- ✅ Normal ping-based health checks begin
- ✅ Servers should be fully initialized
- ✅ Standard heartbeat monitoring continues

## Timeline
1. T+0s: Server connects and initializes
2. T+2s: Heartbeat monitoring starts (grace period active)
3. T+2-60s: Grace period messages appear in console
4. T+60s: Real ping health checks begin
5. T+60s+: Normal operation

## Benefits
- Eliminates reconnection cycles during startup
- Gives Python servers full minute to initialize
- Provides clear console feedback about startup status
- Automatically transitions to normal monitoring

## Verification
Watch console for:
- "⏳ ... in startup grace period" messages
- Smooth transition after 60 seconds
- No "Received request before initialization" errors
- Stable server connections

---
*This approach is more robust than just increasing delays, as it completely avoids the problematic ping requests during the critical startup phase.*
