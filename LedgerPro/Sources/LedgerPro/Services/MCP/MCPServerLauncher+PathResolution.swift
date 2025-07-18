import Foundation
import OSLog

// MARK: - Path Resolution Extension
extension MCPServerLauncher {
    
    /// Enum for different runtime environments
    enum RuntimeEnvironment {
        case development
        case bundled
        case testing
        
        static var current: RuntimeEnvironment {
            // Check if running tests
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                return .testing
            }
            
            // Check if bundled with app
            if Bundle.main.bundlePath.contains(".app") {
                return .bundled
            }
            
            // Default to development for:
            // - Xcode runs
            // - swift run
            // - Command line execution
            return .development
        }
    }
    
    /// Resolve Python path for a specific server type
    static func resolvePythonPath(for serverType: String) -> String? {
        let logger = AppLogger.shared
        
        // First try relative to app bundle
        if let bundlePath = Bundle.main.resourcePath {
            let serverPath = "\(bundlePath)/mcp-servers/\(serverType)/venv/bin/python"
            if FileManager.default.fileExists(atPath: serverPath) {
                logger.info("✅ Found bundled Python at \(serverPath)", category: "MCP")
                return serverPath
            }
        }
        
        // Then try relative to project root (development)
        let projectRoot = FileManager.default.currentDirectoryPath
        let paths = [
            "\(projectRoot)/mcp-servers/\(serverType)/venv/bin/python",
            "\(projectRoot)/../mcp-servers/\(serverType)/venv/bin/python",
            // Add user's home path as fallback
            "\(NSHomeDirectory())/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/mcp-servers/\(serverType)/venv/bin/python"
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                logger.info("✅ Found development Python at \(path)", category: "MCP")
                return path
            }
        }
        
        logger.warning("⚠️ Could not find Python venv for \(serverType)", category: "MCP")
        return nil
    }

    /// Get the correct base path for MCP servers based on environment
    static func getMCPServersBasePath() -> String? {
        let logger = AppLogger.shared
        
        switch RuntimeEnvironment.current {
        case .development:
            // Development paths - check multiple possible locations dynamically
            let projectRoot = FileManager.default.currentDirectoryPath
            let devPaths = [
                // Current working directory
                "\(projectRoot)/mcp-servers",
                // Parent directory (if running from subdirectory)
                "\(projectRoot)/../mcp-servers",
                // Relative to source file
                URL(fileURLWithPath: #file)
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .appendingPathComponent("mcp-servers").path,
                // User's document folder (last resort)
                "\(NSHomeDirectory())/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/mcp-servers"
            ]
            
            for path in devPaths {
                if FileManager.default.fileExists(atPath: path) {
                    logger.info("✅ Development mode: Found MCP servers at \(path)", category: "MCP")
                    return path
                }
            }
            
        case .bundled:
            // Production - servers bundled with app
            if let resourcePath = Bundle.main.resourcePath {
                let bundledPath = "\(resourcePath)/mcp-servers"
                if FileManager.default.fileExists(atPath: bundledPath) {
                    logger.info("✅ Bundled mode: Found MCP servers at \(bundledPath)", category: "MCP")
                    return bundledPath
                }
            }
            
            // Check Application Support directory (for user-installed servers)
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                        in: .userDomainMask).first {
                let appPath = appSupport
                    .appendingPathComponent("LedgerPro")
                    .appendingPathComponent("mcp-servers").path
                if FileManager.default.fileExists(atPath: appPath) {
                    logger.info("✅ User mode: Found MCP servers at \(appPath)", category: "MCP")
                    return appPath
                }
            }
            
        case .testing:
            // Unit tests - use temporary directory
            let testPath = FileManager.default.temporaryDirectory
                .appendingPathComponent("LedgerProTests")
                .appendingPathComponent("mcp-servers").path
            logger.info("✅ Testing mode: Using \(testPath)", category: "MCP")
            return testPath
        }
        
        logger.error("❌ Could not locate MCP servers directory", category: "MCP")
        return nil
    }
    
    /// Check if a specific server is available
    static func isServerAvailable(_ serverType: ServerType) -> Bool {
        guard let basePath = getMCPServersBasePath() else { return false }
        
        let serverPaths: [ServerType: String] = [
            .financialAnalyzer: "financial-analyzer/analyzer_server.py",
            .openAIService: "openai-service/openai_server.py", 
            .pdfProcessor: "pdf-processor/pdf_processor_server.py"
        ]
        
        guard let relativePath = serverPaths[serverType] else { return false }
        let fullPath = "\(basePath)/\(relativePath)"
        
        return FileManager.default.fileExists(atPath: fullPath)
    }
    
    /// Get Python executable path (prefer venv) - Enhanced version
    static func getPythonPath(for serverDir: String) -> String {
        // Extract server type from directory path
        let serverType = URL(fileURLWithPath: serverDir).lastPathComponent
        
        // Try the new dynamic path resolver first
        if let dynamicPath = resolvePythonPath(for: serverType) {
            return dynamicPath
        }
        
        // Fallback to original logic
        let venvPython = "\(serverDir)/venv/bin/python3"
        let venvPythonAlt = "\(serverDir)/venv/bin/python"
        
        if FileManager.default.fileExists(atPath: venvPython) {
            return venvPython
        } else if FileManager.default.fileExists(atPath: venvPythonAlt) {
            return venvPythonAlt
        }
        
        // Fallback to system Python
        return "/usr/bin/python3"
    }
}

// MARK: - Updated Server Process Creation
extension MCPServerLauncher {
    
    /// Create server process with proper path resolution
    func createServerProcessWithResolver(for type: ServerType) throws -> Process {
        guard let basePath = Self.getMCPServersBasePath() else {
            throw MCPLauncherError.scriptNotFound("MCP servers directory not found")
        }
        
        // Debug logging
        let logger = AppLogger.shared
        logger.info("🔍 Debug: MCP base path resolved to: \(basePath)", category: "MCP")
        logger.info("🔍 Debug: Runtime environment: \(String(describing: RuntimeEnvironment.current))", category: "MCP")
        logger.info("🔍 Debug: Current directory: \(FileManager.default.currentDirectoryPath)", category: "MCP")
        
        let serverConfigs: [ServerType: (dir: String, script: String)] = [
            .financialAnalyzer: ("financial-analyzer", "analyzer_server.py"),
            .openAIService: ("openai-service", "openai_server.py"),
            .pdfProcessor: ("pdf-processor", "pdf_processor_server.py")
        ]
        
        guard let config = serverConfigs[type] else {
            throw MCPLauncherError.unsupportedServerType(type.rawValue)
        }
        
        let serverDir = "\(basePath)/\(config.dir)"
        let scriptPath = "\(serverDir)/\(config.script)"
        
        // Debug logging for paths
        logger.info("🔍 Debug: Server type: \(type.rawValue)", category: "MCP")
        logger.info("🔍 Debug: Server directory: \(serverDir)", category: "MCP")
        logger.info("🔍 Debug: Script path: \(scriptPath)", category: "MCP")
        logger.info("🔍 Debug: Script exists: \(FileManager.default.fileExists(atPath: scriptPath))", category: "MCP")
        
        // Verify script exists
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            // Try alternate names (e.g., financial_analyzer_server.py)
            let altScriptPath = "\(serverDir)/\(config.dir.replacingOccurrences(of: "-", with: "_"))_server.py"
            if FileManager.default.fileExists(atPath: altScriptPath) {
                return try createPythonProcess(script: altScriptPath, serverDir: serverDir, port: type.port)
            }
            throw MCPLauncherError.scriptNotFound(scriptPath)
        }
        
        return try createPythonProcess(script: scriptPath, serverDir: serverDir, port: type.port)
    }
    
    private func createPythonProcess(script: String, serverDir: String, port: Int) throws -> Process {
        let process = Process()
        
        // Use appropriate Python executable
        let pythonPath = Self.getPythonPath(for: serverDir)
        
        // Debug logging for Python process
        let logger = AppLogger.shared
        logger.info("🔍 Debug: Python path: \(pythonPath)", category: "MCP")
        logger.info("🔍 Debug: Python exists: \(FileManager.default.fileExists(atPath: pythonPath))", category: "MCP")
        logger.info("🔍 Debug: Working directory: \(serverDir)", category: "MCP")
        logger.info("🔍 Debug: Port: \(port)", category: "MCP")
        
        process.executableURL = URL(fileURLWithPath: pythonPath)
        
        // Set arguments
        process.arguments = [script]
        
        // Set working directory to server directory
        process.currentDirectoryURL = URL(fileURLWithPath: serverDir)
        
        // Setup environment
        var environment = ProcessInfo.processInfo.environment
        environment["MCP_SERVER_PORT"] = "\(port)"
        environment["PYTHONPATH"] = serverDir
        
        // Add PYTHONUNBUFFERED for real-time output
        environment["PYTHONUNBUFFERED"] = "1"
        
        // For OpenAI service, add API key if available
        if script.contains("openai") {
            if let apiKey = UserDefaults.standard.string(forKey: "openai_api_key") {
                environment["OPENAI_API_KEY"] = apiKey
            }
        }
        
        process.environment = environment
        
        // Setup output pipes
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Log output  
        let processLogger = AppLogger.shared
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                processLogger.info("📊 \(script): \(output.trimmingCharacters(in: .whitespacesAndNewlines))", category: "MCP")
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let error = String(data: data, encoding: .utf8) {
                processLogger.error("⚠️ \(script): \(error.trimmingCharacters(in: .whitespacesAndNewlines))", category: "MCP")
            }
        }
        
        return process
    }
}

// MARK: - Bundle Resources Setup (for distribution)
extension MCPServerLauncher {
    
    /// Copy MCP servers to Application Support on first run
    static func setupMCPServersIfNeeded() {
        guard RuntimeEnvironment.current == .bundled else { return }
        
        let logger = AppLogger.shared
        
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory,
                                                        in: .userDomainMask).first else { return }
        
        let ledgerProDir = appSupport.appendingPathComponent("LedgerPro")
        let mcpServersDir = ledgerProDir.appendingPathComponent("mcp-servers")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: ledgerProDir, 
                                                withIntermediateDirectories: true)
        
        // Copy bundled servers if not already present
        if !FileManager.default.fileExists(atPath: mcpServersDir.path),
           let bundledPath = Bundle.main.resourcePath?.appending("/mcp-servers") {
            do {
                try FileManager.default.copyItem(atPath: bundledPath,
                                               toPath: mcpServersDir.path)
                logger.info("✅ Copied MCP servers to Application Support", category: "MCP")
            } catch {
                logger.error("❌ Failed to copy MCP servers: \(error)", category: "MCP")
            }
        }
    }
}
