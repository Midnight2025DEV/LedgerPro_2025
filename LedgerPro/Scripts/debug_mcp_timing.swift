#!/usr/bin/env swift

import Foundation

// Debug script to test MCP connection timing issues
print("🧪 Testing MCP Connection Timing")
print("=" * 50)

// MARK: - Analysis of the Issue
print("\n📍 Issue Analysis:")
print("1. The MCP servers are failing ping requests immediately after initialization")
print("2. Error: 'Received request before initialization was complete'")
print("3. This causes an endless reconnection cycle")

print("\n📍 Current Flow:")
print("1. connect() → sends initialize request")
print("2. Server responds to initialize request")
print("3. startHeartbeat() is called after 2 seconds")
print("4. ping request is sent")
print("5. Server rejects ping - still processing initialization")
print("6. Heartbeat fails → triggers reconnection → cycle repeats")

print("\n📍 Root Cause:")
print("The Python MCP servers need more time after responding to 'initialize'")
print("before they're ready to accept other requests like 'ping'")

// MARK: - Proposed Solutions
print("\n💡 Proposed Solutions:")

print("\n1. Increase Initial Delay (Quick Fix):")
print("   - Change the 2-second delay to 5 seconds in MCPServer.connect()")
print("   - This gives servers more time to complete initialization")

print("\n2. Smart Initialization Check (Better Solution):")
print("   - After initialize response, wait for a 'ready' signal")
print("   - Or implement a 'get_status' check before starting heartbeat")

print("\n3. Retry Logic for Early Pings (Robust Solution):")
print("   - Don't immediately fail on ping errors")
print("   - Retry a few times with delays before considering it a failure")

// MARK: - Timing Test
print("\n⏱️ Timing Test Simulation:")
let timings = [
    ("Initialize request sent", 0.0),
    ("Initialize response received", 0.5),
    ("Server internal setup", 2.0),  // This is what we're missing
    ("Server ready for requests", 3.0),
    ("Current heartbeat starts", 2.0),  // Too early!
    ("Recommended heartbeat start", 5.0)
]

for (event, time) in timings {
    print(String(format: "  %.1fs: %@", time, event))
}

// MARK: - Code Changes Needed
print("\n📝 Required Code Changes:")

print("\n1. In MCPServer.swift, update connect() method:")
print("""
    // Change from:
    Task {
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        startHeartbeat()
    }
    
    // To:
    Task {
        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        startHeartbeat()
    }
""")

print("\n2. Or better, in startHeartbeat() method, add retry logic:")
print("""
    private func startHeartbeat() {
        heartbeatTask = Task {
            var retryCount = 0
            let maxInitialRetries = 3
            
            while !Task.isCancelled && isConnected {
                do {
                    _ = try await healthCheck()
                    retryCount = 0  // Reset on success
                } catch {
                    if retryCount < maxInitialRetries {
                        // During initial retries, just wait longer
                        retryCount += 1
                        print("⏳ Initial heartbeat attempt \\(retryCount), waiting...")
                        try? await Task.sleep(nanoseconds: UInt64(5 * 1_000_000_000))
                        continue
                    }
                    
                    // After initial retries, handle as before
                    print("⚠️ Heartbeat failed for \\(info.name): \\(error)")
                    lastError = error as? MCPRPCError
                    
                    if isConnected {
                        await attemptReconnection()
                    }
                }
                
                try? await Task.sleep(nanoseconds: UInt64(heartbeatInterval * 1_000_000_000))
            }
        }
    }
""")

print("\n✅ Debug analysis complete!")
print("\n🎯 Recommendation: Implement the retry logic solution for robustness")
