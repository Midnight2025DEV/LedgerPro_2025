import Foundation
import OSLog

extension MCPBridge {
    /// Enhanced server readiness check with initialization verification
    func waitForServersToInitialize(maxAttempts: Int = 30) async throws {
        let initLogger = AppLogger.shared
        initLogger.info("⏳ Waiting for MCP servers to fully initialize...", category: "MCP")
        
        for attempt in 1...maxAttempts {
            // First check basic connection
            if !areServersReady() {
                initLogger.info("🔄 Servers not connected yet... (\(attempt)/\(maxAttempts))", category: "MCP")
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                continue
            }
            
            // Then verify initialization by calling list_tools on each server
            var allInitialized = true
            var serverStatuses: [String] = []
            
            for (serverId, server) in servers where server.isConnected {
                let serverName = server.info.name
                do {
                    initLogger.info("🔍 Testing \(serverName) readiness...", category: "MCP")
                    
                    // Call list_tools as initialization check with timeout
                    let response = try await withTimeout(seconds: 5) {
                        try await self.sendRequest(
                            to: serverId,
                            method: .listTools,
                            params: nil
                        )
                    }
                    
                    if let error = response.error {
                        initLogger.warning("⚠️ Server \(serverName) returned error: \(error)", category: "MCP")
                        allInitialized = false
                        serverStatuses.append("\(serverName): Error")
                        break
                    } else {
                        initLogger.info("✅ Server \(serverName) responding correctly", category: "MCP")
                        serverStatuses.append("\(serverName): OK")
                    }
                } catch {
                    initLogger.warning("⚠️ Failed to verify \(serverName) initialization: \(error)", category: "MCP")
                    allInitialized = false
                    serverStatuses.append("\(serverName): Failed")
                    
                    // Don't break immediately for Financial Analyzer - give it extra time
                    if serverName.contains("financial") && attempt < maxAttempts {
                        initLogger.info("🔄 Giving Financial Analyzer extra time...", category: "MCP")
                        continue
                    }
                    break
                }
            }
            
            if allInitialized {
                initLogger.info("✅ All MCP servers fully initialized and ready!", category: "MCP")
                initLogger.info("📊 Server status: \(serverStatuses.joined(separator: ", "))", category: "MCP")
                return
            }
            
            initLogger.info("🔄 Waiting for full initialization... (\(attempt)/\(maxAttempts))", category: "MCP")
            initLogger.info("📊 Current status: \(serverStatuses.joined(separator: ", "))", category: "MCP")
            
            // Progressive delay - wait longer for later attempts
            let delay = attempt < 10 ? 1_000_000_000 : 2_000_000_000 // 1s then 2s
            try? await Task.sleep(nanoseconds: UInt64(delay))
        }
        
        throw MCPRPCError(code: -32603, message: "MCP servers failed to initialize after \(maxAttempts) attempts")
    }
    
    /// Executes an async operation with a timeout, using Swift's structured concurrency.
    /// - Parameters:
    ///   - seconds: Maximum time to wait before timing out
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation if it completes before timeout
    /// - Throws: MCPRPCError if the operation times out or fails
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation task
            group.addTask {
                try await operation()
            }
            
            // Add timeout task that throws after specified duration
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw MCPRPCError(code: -32603, message: "Operation timed out after \(seconds) seconds")
            }
            
            // Use for-await-in pattern for safe iteration
            for try await result in group {
                // First result wins - cancel remaining tasks
                group.cancelAll()
                return result
            }
            
            // This code should never be reached, but we handle it gracefully
            throw MCPRPCError(code: -32603, message: "Unexpected task group state - no tasks completed")
        }
    }
}