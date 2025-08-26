import Foundation
import OSLog
import Combine
import AppKit
import Darwin

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
    
    private let logger = AppLogger.shared
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
        
        // Retry logic with exponential backoff
        let maxRetries = 3
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            logger.info("🔄 Launch attempt \(attempt)/\(maxRetries) for \(type.displayName)")
            
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
                logger.debug("Process launched, PID: \(process.processIdentifier)", category: "MCP-Launch")
                
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
                
                logger.info("✅ Successfully launched \(type.displayName) server on port \(type.port) (attempt \(attempt))")
                return
                
            } catch {
                lastError = error
                logger.warning("❌ Launch attempt \(attempt) failed for \(type.displayName): \(error.localizedDescription)")
                
                // Provide detailed error information on first attempt
                if attempt == 1 {
                    if let mcpError = error as? MCPLauncherError {
                        logger.error("   MCP Launcher error: \(mcpError.errorDescription ?? "Unknown MCP error")")
                    }
                    if let connectionError = error as? MCPConnectionError {
                        logger.error("   Connection error: \(connectionError.errorDescription ?? "Unknown connection error")")
                    }
                    if let processError = error as? CocoaError {
                        logger.error("   Process error: \(processError.localizedDescription)")
                    }
                }
                
                // Cleanup failed attempt
                await cleanupFailedServer(type)
                
                // Don't retry on the last attempt
                if attempt < maxRetries {
                    // Exponential backoff: 1s, 2s, 4s
                    let delay = TimeInterval(1 << (attempt - 1))
                    logger.info("⏳ Retrying in \(delay)s...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // All retries failed
        isLaunching = false
        let mcpError = MCPLauncherError.launchFailed(type.displayName, lastError?.localizedDescription ?? "Unknown error")
        self.lastError = mcpError
        launchStatus = .error(mcpError)
        
        logger.error("❌ Failed to launch \(type.displayName) after \(maxRetries) attempts")
        logger.error("   Final error: \(lastError?.localizedDescription ?? "Unknown error")")
        
        throw mcpError
    }
    
    /// Stop a specific MCP server with enhanced cleanup
    func stopServer(_ type: ServerType) {
        logger.info("🛑 Stopping \(type.displayName) server...")
        
        // Remove from MCPBridge
        Task {
            await mcpBridge.removeServer(type: type)
        }
        
        // Enhanced process termination with monitoring
        if let process = serverProcesses[type.rawValue] {
            let pid = process.processIdentifier
            logger.debug("Terminating process PID: \(pid)", category: "MCP-Cleanup")
            
            // Step 1: Graceful termination
            process.terminate()
            
            // Step 2: Wait for graceful termination with better monitoring
            let deadline = Date().addingTimeInterval(5.0) // Increased timeout
            var checkCount = 0
            
            while process.isRunning && Date() < deadline {
                checkCount += 1
                if checkCount % 10 == 0 { // Log every 1 second
                    logger.debug("Waiting for graceful termination... (\(checkCount/10)s)", category: "MCP-Cleanup")
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            // Step 3: Force kill if still running
            if process.isRunning {
                logger.warning("⚠️ Process still running after graceful termination, forcing kill", category: "MCP-Cleanup")
                process.interrupt()
                
                // Wait for interrupt to take effect
                let forceDeadline = Date().addingTimeInterval(2.0)
                while process.isRunning && Date() < forceDeadline {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                
                // Step 4: System kill as last resort
                if process.isRunning {
                    logger.error("❌ Process still running after interrupt, attempting system kill", category: "MCP-Cleanup")
                    
                    // Use Darwin.kill with SIGKILL for force termination
                    let killResult = Darwin.kill(pid, SIGKILL)
                    if killResult == 0 {
                        logger.info("✅ Successfully killed process with system call", category: "MCP-Cleanup")
                    } else {
                        logger.error("❌ Failed to kill process with system call (errno: \(errno))", category: "MCP-Cleanup")
                    }
                }
            }
            
            // Step 5: Final verification
            if process.isRunning {
                logger.error("❌ Process \(pid) is still running after all termination attempts", category: "MCP-Cleanup")
            } else {
                logger.info("✅ Process \(pid) terminated successfully", category: "MCP-Cleanup")
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
                Task { @MainActor in
                    self.logger.info("📊 \(script): \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let error = String(data: data, encoding: .utf8) {
                Task { @MainActor in
                    self.logger.error("⚠️ \(script): \(error.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
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
    
    private func waitForServerReady(_ type: ServerType, timeout: TimeInterval = 30.0) async throws {
        let startTime = Date()
        logger.info("🔄 Waiting for \(type.displayName) server to be ready (timeout: \(timeout)s)...")
        
        // Phase 1: Wait for process to start (up to 5 seconds)
        logger.debug("Phase 1: Waiting for process to start...", category: "MCP-Startup")
        var processStarted = false
        let processTimeout = min(5.0, timeout)
        
        for attempt in 1...Int(processTimeout) {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            guard let server = launchedServers[type.rawValue] else {
                logger.warning("Attempt \(attempt): Server not found in launched servers", category: "MCP-Startup")
                continue
            }
            
            if server.process.isRunning {
                logger.info("✅ Phase 1 complete: Process started after \(attempt)s", category: "MCP-Startup")
                processStarted = true
                break
            } else {
                logger.debug("Attempt \(attempt): Process not running yet", category: "MCP-Startup")
            }
        }
        
        guard processStarted else {
            logger.error("❌ Process failed to start within \(processTimeout)s", category: "MCP-Startup")
            throw MCPLauncherError.serverStartupTimeout(type.displayName)
        }
        
        // Phase 2: Wait for server to be ready to accept connections
        logger.debug("Phase 2: Waiting for server to be ready for connections...", category: "MCP-Startup")
        let remainingTimeout = timeout - Date().timeIntervalSince(startTime)
        
        var serverReady = false
        let maxAttempts = Int(remainingTimeout / 0.5) // Check every 500ms
        
        for attempt in 1...maxAttempts {
            try await Task.sleep(nanoseconds: 500_000_000) // 500ms
            
            // Check if process is still running
            guard let server = launchedServers[type.rawValue],
                  server.process.isRunning else {
                logger.error("❌ Process died during startup", category: "MCP-Startup")
                throw MCPLauncherError.serverStartupTimeout(type.displayName)
            }
            
            // Try to communicate with server using basic MCP protocol
            if await testServerCommunication(type) {
                logger.info("✅ Phase 2 complete: Server ready after \(String(format: "%.1f", Date().timeIntervalSince(startTime)))s", category: "MCP-Startup")
                serverReady = true
                break
            } else {
                logger.debug("Attempt \(attempt): Server not ready for communication", category: "MCP-Startup")
            }
        }
        
        guard serverReady else {
            logger.error("❌ Server failed to be ready within \(timeout)s", category: "MCP-Startup")
            throw MCPLauncherError.serverStartupTimeout(type.displayName)
        }
        
        logger.info("✅ MCP server \(type.displayName) fully ready in \(String(format: "%.1f", Date().timeIntervalSince(startTime)))s")
    }
    
    private func testServerCommunication(_ type: ServerType) async -> Bool {
        // Test basic MCP communication by sending a simple ping
        guard let server = launchedServers[type.rawValue],
              server.process.isRunning else {
            return false
        }
        
        // For MCP servers, we can test by checking if the process is accepting input
        // and hasn't crashed during initialization
        do {
            // Give a small delay to allow any startup logging to complete
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            // Check if process is still running and hasn't crashed
            if server.process.isRunning {
                // Additional check: see if process has been running for at least 1 second
                // This indicates it got past initial startup phase
                let uptime = Date().timeIntervalSince(server.startTime)
                return uptime >= 1.0
            }
            
            return false
        } catch {
            return false
        }
    }
    
    private func checkServerHealth(_ type: ServerType) async -> Bool {
        // Enhanced health check with communication test
        guard let server = launchedServers[type.rawValue],
              server.process.isRunning else {
            return false
        }
        
        // Test basic communication
        return await testServerCommunication(type)
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