import Foundation
import OSLog
import Combine
import AppKit

/// MCP Server Launcher - Manages lifecycle of external MCP servers
@MainActor
class MCPServerLauncher: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var launchedServers: [String: LaunchedServer] = [:]
    @Published var isLaunching: Bool = false
    @Published var lastError: MCPLauncherError?
    @Published var launchStatus: LaunchStatus = .idle
    
    // Per-server launch state tracking to prevent conflicts
    private var serverLaunchStates: [String: Bool] = [:]
    private var coreServersLaunchInProgress: Bool = false
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.ledgerpro.mcp", category: "MCPServerLauncher")
    private let mcpBridge: MCPBridge
    private var serverProcesses: [String: Process] = [:]
    private let mcpToolsPath = NSHomeDirectory() + "/mcp-tools"
    
    // MARK: - Types
    
    enum LaunchStatus {
        case idle
        case launching(serverType: ServerType)
        case running(activeServers: Int)
        case error(MCPLauncherError)
    }
    
    struct LaunchedServer {
        let type: ServerType
        let process: Process
        let port: Int
        let startTime: Date
        var isHealthy: Bool = false
        var lastHealthCheck: Date?
        
        var uptime: TimeInterval {
            return Date().timeIntervalSince(startTime)
        }
    }
    
    // MARK: - Initialization
    
    init(mcpBridge: MCPBridge) {
        self.mcpBridge = mcpBridge
        setupCleanupHandler()
    }
    
    deinit {
        // Note: Cannot call async methods in deinit
        // Server cleanup will be handled by setupCleanupHandler
    }
    
    // MARK: - Server Lifecycle Management
    
    /// Launch a specific MCP server type
    func launchServer(_ type: ServerType) async throws {
        logger.info("🚀 Launching \(type.displayName) server...")
        
        // Check if server is already running or being launched
        if isServerRunning(type) {
            throw MCPLauncherError.serverAlreadyRunning(type.displayName)
        }
        
        if serverLaunchStates[type.rawValue] == true {
            logger.info("⚠️ Server \(type.displayName) is already being launched, skipping...")
            return
        }
        
        // Ensure server is properly cleaned up before relaunch
        if !isServerProperlyCleanedUp(type) {
            logger.warning("⚠️ Server \(type.displayName) not properly cleaned up, forcing cleanup...")
            stopServer(type)
            // Wait a moment for cleanup to complete
            try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        }
        
        // Set per-server launch state
        serverLaunchStates[type.rawValue] = true
        defer {
            serverLaunchStates[type.rawValue] = false
        }
        
        isLaunching = true
        launchStatus = .launching(serverType: type)
        
        do {
            let process = try createServerProcess(for: type)
            let server = LaunchedServer(
                type: type,
                process: process,
                port: type.port,
                startTime: Date()
            )
            
            // Store the launched server
            launchedServers[type.rawValue] = server
            serverProcesses[type.rawValue] = process
            
            // Start the process
            try process.run()
            
            // Wait for server to be ready
            try await waitForServerReady(type)
            
            // Connect MCPBridge to the existing process we just launched
            try await mcpBridge.connectToExistingServer(type: type)
            
            // Update status
            launchedServers[type.rawValue]?.isHealthy = true
            launchedServers[type.rawValue]?.lastHealthCheck = Date()
            
            updateLaunchStatus()
            isLaunching = false
            lastError = nil
            
            logger.info("✅ Successfully launched \(type.displayName) server on port \(type.port)")
            
        } catch {
            isLaunching = false
            
            // Provide detailed error information
            logger.error("❌ Failed to launch \(type.displayName):")
            logger.error("   Original error: \(error.localizedDescription)")
            
            if let mcpError = error as? MCPLauncherError {
                logger.error("   MCP Launcher error: \(mcpError.errorDescription ?? "Unknown MCP error")")
            }
            if let connectionError = error as? MCPConnectionError {
                logger.error("   Connection error: \(connectionError.errorDescription ?? "Unknown connection error")")
            }
            if let processError = error as? CocoaError {
                logger.error("   Process error: \(processError.localizedDescription)")
            }
            
            let mcpError = MCPLauncherError.launchFailed(type.displayName, error.localizedDescription)
            lastError = mcpError
            launchStatus = .error(mcpError)
            
            // Cleanup on failure - but wait for launch state to clear first
            await cleanupFailedServer(type)
            
            throw mcpError
        }
    }
    
    /// Stop a specific MCP server
    func stopServer(_ type: ServerType) {
        logger.info("🛑 Stopping \(type.displayName) server...")
        
        // Remove from MCPBridge
        Task {
            await mcpBridge.removeServer(type: type)
        }
        
        // Terminate process and wait for proper cleanup
        if let process = serverProcesses[type.rawValue] {
            process.terminate()
            
            // Wait for graceful termination synchronously
            let deadline = Date().addingTimeInterval(2.0)
            while process.isRunning && Date() < deadline {
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            // Force kill if still running
            if process.isRunning {
                process.interrupt()
                Thread.sleep(forTimeInterval: 0.5) // Give time for interrupt to take effect
            }
        }
        
        // Cleanup after process is properly terminated
        launchedServers.removeValue(forKey: type.rawValue)
        serverProcesses.removeValue(forKey: type.rawValue)
        
        updateLaunchStatus()
        
        logger.info("✅ Stopped \(type.displayName) server")
    }
    
    /// Stop all running servers
    func stopAllServers() {
        logger.info("🛑 Stopping all MCP servers...")
        
        for type in Array(launchedServers.keys).compactMap({ ServerType(rawValue: $0) }) {
            stopServer(type)
        }
        
        launchStatus = .idle
        logger.info("✅ All MCP servers stopped")
    }
    
    /// Launch core servers (Financial Analyzer + OpenAI Service + PDF Processor)
    func launchCoreServers() async throws {
        // Prevent concurrent core server launches
        if coreServersLaunchInProgress {
            logger.info("⚠️ Core servers launch already in progress, skipping...")
            return
        }
        
        coreServersLaunchInProgress = true
        defer {
            coreServersLaunchInProgress = false
        }
        
        logger.info("🚀 Launching core MCP servers...")
        
        let coreServers: [ServerType] = [.financialAnalyzer, .openAIService, .pdfProcessor]
        var launchResults: [String: Result<Void, Error>] = [:]
        
        for serverType in coreServers {
            if !isServerRunning(serverType) && serverLaunchStates[serverType.rawValue] != true {
                var retryCount = 0
                let maxRetries = 2
                
                while retryCount <= maxRetries {
                    do {
                        if retryCount > 0 {
                            logger.info("🔄 Retry \(retryCount)/\(maxRetries) for \(serverType.displayName)")
                            // Wait longer before retry
                            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        }
                        
                        try await launchServer(serverType)
                        launchResults[serverType.displayName] = .success(())
                        logger.info("✅ Successfully launched \(serverType.displayName)")
                        break // Success, exit retry loop
                        
                    } catch {
                        retryCount += 1
                        
                        if retryCount <= maxRetries {
                            logger.warning("⚠️ Attempt \(retryCount) failed for \(serverType.displayName): \(error.localizedDescription)")
                        } else {
                            // Final failure after all retries
                            launchResults[serverType.displayName] = .failure(error)
                            logger.error("❌ Failed to launch \(serverType.displayName) after \(maxRetries) retries: \(error.localizedDescription)")
                            
                            // Log specific error types for better debugging
                            if let mcpError = error as? MCPLauncherError {
                                logger.error("   Error type: \(mcpError)")
                            }
                            if let connectionError = error as? MCPConnectionError {
                                logger.error("   Connection error: \(connectionError.localizedDescription)")
                            }
                            
                            // Continue with other servers instead of terminating the loop
                            logger.info("🔄 Continuing with remaining servers...")
                        }
                    }
                }
                
                // Small delay between different servers
                if launchResults[serverType.displayName] != nil {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                }
            } else {
                launchResults[serverType.displayName] = .success(())
                logger.info("⚠️ Server \(serverType.displayName) already running or launching, skipping")
            }
        }
        
        // Summary of launch results
        let successCount = launchResults.values.filter { if case .success = $0 { return true }; return false }.count
        let failureCount = launchResults.count - successCount
        
        if failureCount > 0 {
            logger.warning("⚠️ Core server launch completed with \(successCount)/\(launchResults.count) servers successful")
            
            // Log failed servers
            for (serverName, result) in launchResults {
                if case .failure(let error) = result {
                    logger.error("   ❌ \(serverName): \(error.localizedDescription)")
                }
            }
        } else {
            logger.info("✅ All \(successCount) core MCP servers launched successfully")
        }
    }
    
    // MARK: - Server Status
    
    /// Check if a server type is currently running
    func isServerRunning(_ type: ServerType) -> Bool {
        return launchedServers[type.rawValue]?.process.isRunning == true
    }
    
    /// Check if server process is properly cleaned up before relaunch
    private func isServerProperlyCleanedUp(_ type: ServerType) -> Bool {
        // Check if no entries exist in tracking dictionaries
        let noLaunchedServer = launchedServers[type.rawValue] == nil
        let noServerProcess = serverProcesses[type.rawValue] == nil
        let notLaunching = serverLaunchStates[type.rawValue] != true
        
        return noLaunchedServer && noServerProcess && notLaunching
    }
    
    /// Get health status of all servers
    func getHealthStatus() -> [ServerHealthStatus] {
        return launchedServers.values.map { server in
            ServerHealthStatus(
                type: server.type,
                isRunning: server.process.isRunning,
                isHealthy: server.isHealthy,
                uptime: server.uptime,
                port: server.port,
                lastHealthCheck: server.lastHealthCheck
            )
        }
    }
    
    /// Perform health check on all running servers
    func performHealthCheck() async {
        for (_, server) in launchedServers {
            if server.process.isRunning {
                let isHealthy = await checkServerHealth(server.type)
                launchedServers[server.type.rawValue]?.isHealthy = isHealthy
                launchedServers[server.type.rawValue]?.lastHealthCheck = Date()
            }
        }
        updateLaunchStatus()
    }
    
    // MARK: - Private Methods
    
    private func createServerProcess(for type: ServerType) throws -> Process {
        // Use the new resolver
        return try createServerProcessWithResolver(for: type)
    }
    
    private func createPythonServerProcess(script: String, port: Int) throws -> Process {
        let process = Process()
        let scriptPath = URL(fileURLWithPath: script, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
        
        // Check if script exists
        guard FileManager.default.fileExists(atPath: scriptPath.path) else {
            throw MCPLauncherError.scriptNotFound(scriptPath.path)
        }
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [scriptPath.path, "--port", "\(port)"]
        process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        // Setup environment
        var environment = ProcessInfo.processInfo.environment
        environment["MCP_SERVER_PORT"] = "\(port)"
        environment["PYTHONPATH"] = scriptPath.deletingLastPathComponent().path
        process.environment = environment
        
        // Setup pipes for output
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Log server output
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                self.logger.info("📊 \(script): \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let error = String(data: data, encoding: .utf8) {
                self.logger.error("⚠️ \(script): \(error.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }
        
        return process
    }
    
    /// Cleanup failed server with proper state management
    private func cleanupFailedServer(_ type: ServerType) async {
        // Wait for any pending launch operations to complete
        while serverLaunchStates[type.rawValue] == true {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        // Now safely cleanup
        stopServer(type)
    }
    
    private func waitForServerReady(_ type: ServerType, timeout: TimeInterval = 10.0) async throws {
        // Wait for process to start
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Check if process started successfully
        guard let server = launchedServers[type.rawValue],
              server.process.isRunning else {
            throw MCPLauncherError.serverStartupTimeout(type.displayName)
        }
        
        logger.info("✅ MCP server \(type.displayName) process started successfully")
    }
    
    private func checkServerHealth(_ type: ServerType) async -> Bool {
        // MCP servers communicate via stdio, not HTTP
        // Check if the process is running
        guard let server = launchedServers[type.rawValue],
              server.process.isRunning else {
            return false
        }
        
        // Process is running = server is healthy
        return true
    }
    
    private func updateLaunchStatus() {
        let activeServers = launchedServers.values.filter { $0.process.isRunning }.count
        
        if activeServers > 0 {
            launchStatus = .running(activeServers: activeServers)
        } else {
            launchStatus = .idle
        }
    }
    
    private func setupCleanupHandler() {
        // Cleanup servers when app terminates
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                self.stopAllServers()
            }
        }
    }
}

// MARK: - Supporting Types

struct ServerHealthStatus {
    let type: ServerType
    let isRunning: Bool
    let isHealthy: Bool
    let uptime: TimeInterval
    let port: Int
    let lastHealthCheck: Date?
    
    var statusDescription: String {
        if isRunning && isHealthy {
            return "✅ Healthy (\(formattedUptime))"
        } else if isRunning {
            return "⚠️ Running but unhealthy"
        } else {
            return "❌ Stopped"
        }
    }
    
    private var formattedUptime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: uptime) ?? "0s"
    }
}

enum MCPLauncherError: LocalizedError {
    case serverAlreadyRunning(String)
    case launchFailed(String, String)
    case scriptNotFound(String)
    case serverStartupTimeout(String)
    case unsupportedServerType(String)
    
    var errorDescription: String? {
        switch self {
        case .serverAlreadyRunning(let server):
            return "Server \(server) is already running"
        case .launchFailed(let server, let reason):
            return "Failed to launch \(server): \(reason)"
        case .scriptNotFound(let path):
            return "Server script not found: \(path)"
        case .serverStartupTimeout(let server):
            return "\(server) failed to start within timeout"
        case .unsupportedServerType(let type):
            return "Unsupported server type: \(type)"
        }
    }
}