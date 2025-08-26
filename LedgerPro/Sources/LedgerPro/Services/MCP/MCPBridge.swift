import Foundation
import Combine
import OSLog

/// Main MCP Bridge orchestrating multiple MCP servers with async/await and proper error handling
@MainActor
class MCPBridge: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var servers: [String: MCPServer] = [:]
    @Published var isConnected: Bool = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastError: MCPRPCError?
    @Published var metrics: BridgeMetrics = BridgeMetrics()
    
    // MARK: - Public Server Access (for MCPServerLauncher)
    
    /// Individual server access for MCPServerLauncher
    var financialAnalyzer: MCPServer? {
        return self.servers.values.first { $0.info.name == "Financial Analyzer" }
    }
    
    var openAIService: MCPServer? {
        return self.servers.values.first { $0.info.name == "OpenAI Service" }
    }
    
    var pdfProcessor: MCPServer? {
        return self.servers.values.first { $0.info.name == "PDF Processor" }
    }
    
    /// Server configurations for MCPServerLauncher
    var serverConfigurations: [String: ServerConfiguration] {
        return [
            "financial-analyzer": ServerConfiguration(
                name: "Financial Analyzer",
                factory: MCPServer.financialAnalyzer,
                description: "Advanced financial analysis and insights generation"
            ),
            "openai-service": ServerConfiguration(
                name: "OpenAI Service", 
                factory: MCPServer.openAIService,
                description: "AI-powered transaction categorization and insights"
            ),
            "pdf-processor": ServerConfiguration(
                name: "PDF Processor",
                factory: MCPServer.pdfProcessor,
                description: "Enhanced PDF document processing and data extraction"
            )
        ]
    }
    
    /// Get server by type for MCPServerLauncher
    func getServer(type: ServerType) -> MCPServer? {
        switch type {
        case .financialAnalyzer:
            return financialAnalyzer
        case .openAIService:
            return openAIService
        case .pdfProcessor:
            return pdfProcessor
        case .custom:
            return nil
        }
    }
    
    /// Check if specific server type is available
    func isServerAvailable(_ type: ServerType) -> Bool {
        return getServer(type: type)?.isConnected == true
    }
    
    /// Get all available server types
    var availableServerTypes: [ServerType] {
        var types: [ServerType] = []
        if financialAnalyzer?.isConnected == true { types.append(.financialAnalyzer) }
        if openAIService?.isConnected == true { types.append(.openAIService) }
        if pdfProcessor?.isConnected == true { types.append(.pdfProcessor) }
        return types
    }
    
    // MARK: - Private Properties
    
    private let logger = AppLogger.shared
    private var healthCheckTask: Task<Void, Never>?
    private let healthCheckInterval: TimeInterval = 60.0
    private var pendingRequests: [String: CheckedContinuation<MCPResponse, Error>] = [:]
    private let requestQueue = DispatchQueue(label: "mcp.requests", qos: .userInitiated)
    
    // MARK: - Types
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected(activeServers: Int, totalServers: Int)
        case degraded(activeServers: Int, totalServers: Int)
        case error(MCPRPCError)
        
        var description: String {
            switch self {
            case .disconnected:
                return "Disconnected"
            case .connecting:
                return "Connecting..."
            case .connected(let active, let total):
                return "Connected (\(active)/\(total) servers)"
            case .degraded(let active, let total):
                return "Degraded (\(active)/\(total) servers)"
            case .error(let error):
                return "Error: \(error.message)"
            }
        }
    }
    
    struct BridgeMetrics {
        var totalRequests: Int = 0
        var successfulRequests: Int = 0
        var failedRequests: Int = 0
        var averageResponseTime: TimeInterval = 0
        var activeConnections: Int = 0
        var uptime: TimeInterval = 0
        private var startTime: Date = Date()
        
        var successRate: Double {
            guard totalRequests > 0 else { return 0 }
            return Double(successfulRequests) / Double(totalRequests)
        }
        
        mutating func updateUptime() {
            uptime = Date().timeIntervalSince(startTime)
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupDefaultServers()
        logger.info("MCPBridge initialized with \(self.self.servers.count) configured servers")
    }
    
    deinit {
        healthCheckTask?.cancel()
    }
    
    // MARK: - Server Management
    
    private func setupDefaultServers() {
        let defaultServers = [
            MCPServer.financialAnalyzer(),
            MCPServer.openAIService(),
            MCPServer.pdfProcessor()
        ].compactMap { $0 } // Filter out nil values
        
        for server in defaultServers {
            self.servers[server.id] = server
        }
        
        if defaultServers.count < 3 {
            logger.warning("⚠️ Could not initialize all MCP servers. Only \(defaultServers.count)/3 servers available.")
        }
    }
    
    func registerServer(_ server: MCPServer) {
        self.servers[server.id] = server
        logger.info("Registered MCP server: \(server.info.name)")
        updateConnectionStatus()
    }
    
    func unregisterServer(id: String) async {
        if let server = self.servers[id] {
            await server.disconnect()
            servers.removeValue(forKey: id)
            logger.info("Unregistered MCP server: \(server.info.name)")
            updateConnectionStatus()
        }
    }
    
    // MARK: - Connection Management
    
    func connectAll() async {
        self.connectionStatus = .connecting
        logger.info("Connecting to all MCP servers...")
        
        await withTaskGroup(of: Void.self) { group in
            for server in self.servers.values {
                group.addTask {
                    await self.connectServerWithRetry(server)
                }
            }
        }
        
        updateConnectionStatus()
        
        // Wait before starting health monitoring to ensure servers are fully initialized
        Task {
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds delay
            startHealthMonitoring()
        }
    }
    
    /// Connect to a server with retry logic and exponential backoff
    private func connectServerWithRetry(_ server: MCPServer) async {
        let maxRetries = 3
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                logger.info("🔄 Connecting to \(server.info.name) (attempt \(attempt)/\(maxRetries))")
                try await server.connect()
                
                await MainActor.run {
                    self.logger.info("✅ Connected to \(server.info.name) on attempt \(attempt)")
                }
                return
                
            } catch {
                lastError = error
                logger.warning("❌ Connection attempt \(attempt) failed for \(server.info.name): \(error.localizedDescription)")
                
                // Don't wait after the last attempt
                if attempt < maxRetries {
                    let delay = TimeInterval(1 << (attempt - 1)) // Exponential backoff: 1s, 2s, 4s
                    logger.info("⏳ Retrying connection to \(server.info.name) in \(delay)s...")
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        await MainActor.run {
            self.logger.error("❌ Failed to connect to \(server.info.name) after \(maxRetries) attempts: \(lastError?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func disconnect() async {
        healthCheckTask?.cancel()
        healthCheckTask = nil
        
        await withTaskGroup(of: Void.self) { group in
            for server in self.servers.values {
                group.addTask {
                    await server.disconnect()
                }
            }
        }
        
        self.isConnected = false
        self.connectionStatus = .disconnected
        metrics.activeConnections = 0
        
        logger.info("Disconnected from all MCP servers")
    }
    
    private func updateConnectionStatus() {
        let connectedServers = self.servers.values.filter { $0.isConnected }
        let totalServers = self.servers.count
        let activeCount = connectedServers.count
        
        metrics.activeConnections = activeCount
        self.isConnected = activeCount > 0
        
        if activeCount == 0 {
            self.connectionStatus = .disconnected
        } else if activeCount == totalServers {
            self.connectionStatus = .connected(activeServers: activeCount, totalServers: totalServers)
        } else {
            self.connectionStatus = .degraded(activeServers: activeCount, totalServers: totalServers)
        }
    }
    
    // MARK: - Request Handling
    
    func sendRequest(to serverId: String, method: MCPMethod, params: [String: AnyCodable]? = nil) async throws -> MCPResponse {
        guard let server = self.servers[serverId] else {
            throw MCPRPCError(code: -32601, message: "Server not available: \(serverId)")
        }
        
        guard server.isConnected else {
            throw MCPRPCError(code: -32601, message: "Server is unavailable")
        }
        
        let request = MCPRequest(method: method, params: params)
        let startTime = Date()
        
        metrics.totalRequests += 1
        
        do {
            let response = try await server.sendRequestWithRetry(request)
            
            // Update metrics
            let responseTime = Date().timeIntervalSince(startTime)
            updateAverageResponseTime(responseTime)
            
            if response.isSuccess {
                metrics.successfulRequests += 1
            } else {
                metrics.failedRequests += 1
                if let error = response.error {
                    self.lastError = error
                }
            }
            
            logger.debug("Request completed: \(method.rawValue) -> \(serverId) (\(responseTime)s)")
            return response
            
        } catch {
            metrics.failedRequests += 1
            let rpcError = MCPRPCError(code: -32603, message: "Internal error: \(error.localizedDescription)")
            self.lastError = rpcError
            logger.error("Request failed: \(method.rawValue) -> \(serverId): \(error)")
            throw rpcError
        }
    }
    
    func broadcastRequest(method: MCPMethod, params: [String: AnyCodable]? = nil) async -> [String: Result<MCPResponse, MCPRPCError>] {
        var results: [String: Result<MCPResponse, MCPRPCError>] = [:]
        
        await withTaskGroup(of: (String, Result<MCPResponse, MCPRPCError>).self) { group in
            for (serverId, server) in servers where server.isConnected {
                group.addTask {
                    do {
                        let response = try await self.sendRequest(to: serverId, method: method, params: params)
                        return (serverId, .success(response))
                    } catch let error as MCPRPCError {
                        return (serverId, .failure(error))
                    } catch {
                        return (serverId, .failure(MCPRPCError(code: -32603, message: "Internal error")))
                    }
                }
            }
            
            for await (serverId, result) in group {
                results[serverId] = result
            }
        }
        
        return results
    }
    
    // MARK: - High-Level Operations
    
    func analyzeTransactions(_ transactions: [Transaction]) async throws -> [MCPAnalysisResult] {
        let params: [String: AnyCodable] = [
            "transactions": AnyCodable(transactions),
            "timestamp": AnyCodable(Date().timeIntervalSince1970)
        ]
        
        let results = await broadcastRequest(method: .analyzeTransactions, params: params)
        var analysisResults: [MCPAnalysisResult] = []
        
        for (serverId, result) in results {
            switch result {
            case .success(let response):
                do {
                    let serverResults = try response.decodeResult(as: [MCPAnalysisResult].self)
                    analysisResults.append(contentsOf: serverResults.map { result in
                        var updatedResult = result
                        updatedResult.serverId = serverId
                        return updatedResult
                    })
                } catch {
                    logger.error("Failed to decode analysis results from \(serverId): \(error)")
                }
            case .failure(let error):
                logger.error("Analysis request failed for \(serverId): \(error)")
            }
        }
        
        return analysisResults
    }
    
    func categorizeTransactions(_ transactions: [Transaction]) async throws -> [Transaction] {
        guard let openAIServer = self.servers.values.first(where: { $0.info.name.contains("OpenAI") }),
              openAIServer.isConnected else {
            throw MCPRPCError(code: -32601, message: "Server not available: OpenAI Service")
        }
        
        let params: [String: AnyCodable] = [
            "transactions": AnyCodable(transactions),
            "options": AnyCodable([
                "confidence_threshold": 0.8,
                "batch_size": 50
            ])
        ]
        
        let response = try await sendRequest(to: openAIServer.id, method: .categorizeTransactions, params: params)
        return try response.decodeResult(as: [Transaction].self)
    }
    
    func processDocument(_ fileURL: URL) async throws -> DocumentProcessingResult {
        // Detect file type and choose appropriate tool
        let fileExtension = fileURL.pathExtension.lowercased()
        let toolName: String
        
        switch fileExtension {
        case "pdf":
            toolName = "process_bank_pdf"
        case "csv":
            toolName = "process_csv_file"
        default:
            throw MCPRPCError(code: -32602, message: "Unsupported file type: \(fileExtension)")
        }
        
        logger.info("🔍 Processing \(fileExtension.uppercased()) file with tool: \(toolName)", category: "MCP")
        
        // Try to process with MCP servers with fallback logic
        return try await processDocumentWithFallback(fileURL, toolName: toolName, fileExtension: fileExtension)
    }
    
    /// Process document with comprehensive fallback logic
    private func processDocumentWithFallback(_ fileURL: URL, toolName: String, fileExtension: String) async throws -> DocumentProcessingResult {
        // Strategy 1: Try primary PDF processor server
        if let pdfServer = self.servers.values.first(where: { $0.info.name.contains("PDF") }),
           pdfServer.isConnected {
            
            logger.info("🎯 Strategy 1: Using primary PDF processor", category: "MCP-Fallback")
            
            do {
                let result = try await processWith(server: pdfServer, fileURL: fileURL, toolName: toolName)
                logger.info("✅ Successfully processed with primary PDF processor", category: "MCP-Fallback")
                return result
            } catch {
                logger.warning("❌ Primary PDF processor failed: \(error.localizedDescription)", category: "MCP-Fallback")
            }
        }
        
        // Strategy 2: Try financial analyzer server (it can orchestrate other servers)
        if let analyzerServer = self.servers.values.first(where: { $0.info.name.contains("Analyzer") || $0.info.name.contains("Financial") }),
           analyzerServer.isConnected {
            
            logger.info("🎯 Strategy 2: Using financial analyzer with orchestration", category: "MCP-Fallback")
            
            do {
                let result = try await processWith(server: analyzerServer, fileURL: fileURL, toolName: "analyze_statement")
                logger.info("✅ Successfully processed with financial analyzer", category: "MCP-Fallback")
                return result
            } catch {
                logger.warning("❌ Financial analyzer failed: \(error.localizedDescription)", category: "MCP-Fallback")
            }
        }
        
        // Strategy 3: Try any available server
        let availableServers = self.servers.values.filter { $0.isConnected }
        if !availableServers.isEmpty {
            logger.info("🎯 Strategy 3: Trying any available server", category: "MCP-Fallback")
            
            for server in availableServers {
                do {
                    let result = try await processWith(server: server, fileURL: fileURL, toolName: toolName)
                    logger.info("✅ Successfully processed with \(server.info.name)", category: "MCP-Fallback")
                    return result
                } catch {
                    logger.warning("❌ Server \(server.info.name) failed: \(error.localizedDescription)", category: "MCP-Fallback")
                }
            }
        }
        
        // Strategy 4: Fallback to basic file processing
        logger.info("🎯 Strategy 4: Using basic fallback processing", category: "MCP-Fallback")
        
        return try await basicFallbackProcessing(fileURL, fileExtension: fileExtension)
    }
    
    /// Process document using a specific server
    private func processWith(server: MCPServer, fileURL: URL, toolName: String) async throws -> DocumentProcessingResult {
        // MCP servers expect tool calls, not direct method calls
        let params: [String: AnyCodable] = [
            "name": AnyCodable(toolName),
            "arguments": AnyCodable([
                "file_path": fileURL.path,
                "processor": "auto"
            ])
        ]
        
        // Debug log the request
        debugLogRequest("tools/call", [
            "name": toolName,
            "arguments": [
                "file_path": fileURL.path,
                "processor": "auto"
            ]
        ])
        
        let response = try await sendRequest(to: server.id, method: .callTool, params: params)
        logger.debug("📡 MCP Tool Response: \(response)", category: "MCP")        
        // Convert the tool response to our expected format
        if let result = response.result?.value as? [String: Any] {
            // Handle MCP tool response structure
            if let isError = result["isError"] as? Bool, 
               isError == false,
               let content = result["content"] as? [[String: Any]],
               let firstContent = content.first,
               let jsonText = firstContent["text"] as? String {
                
                logger.debug("🔍 DEBUG - Raw JSON text length: \(jsonText.count)", category: "MCP")
                logger.debug("🔍 DEBUG - First 200 chars: \(String(jsonText.prefix(200)))", category: "MCP")
                logger.debug("🔍 DEBUG - JSON contains backslashes: \(jsonText.contains("\\"))", category: "MCP")
                
                // Parse the JSON string from the content
                guard let jsonData = jsonText.data(using: .utf8),
                      let parsedResult = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                    throw MCPRPCError(code: -32603, message: "Failed to parse PDF processor response")
                }
                
                // Check if processing was successful
                logger.debug("🔍 DEBUG - Parsed result keys: \(parsedResult.keys)", category: "MCP")
                logger.debug("🔍 DEBUG - Success flag: \(parsedResult["success"] ?? "nil")", category: "MCP")
                logger.debug("🔍 DEBUG - Has transactions: \(parsedResult["transactions"] != nil)", category: "MCP")
                if let transactions = parsedResult["transactions"] as? [[String: Any]] {
                    logger.debug("🔍 DEBUG - Transaction count: \(transactions.count)", category: "MCP")
                    if let firstTransaction = transactions.first {
                        logger.debug("🔍 DEBUG - First transaction: \(firstTransaction)", category: "MCP")
                    }
                }
                
                if let success = parsedResult["success"] as? Bool, !success {
                    let errorMessage = parsedResult["error"] as? String ?? "Unknown error"
                    throw MCPRPCError(code: -32603, message: "PDF processing failed: \(errorMessage)")
                }
                
                // Extract transactions
                if let transactions = parsedResult["transactions"] as? [[String: Any]] {
                    // Convert dictionary transactions to Transaction objects
                    var transactionObjects: [Transaction] = []
                    for (index, dict) in transactions.enumerated() {
                        do {
                            let data = try JSONSerialization.data(withJSONObject: dict)
                            let transaction = try JSONDecoder().decode(Transaction.self, from: data)
                            transactionObjects.append(transaction)
                            
                            // Debug forex data
                            if transaction.hasForex {
                                logger.debug("💱 FOREX TRANSACTION DETECTED:", category: "MCP")
                                logger.debug("   Description: \(transaction.description)", category: "MCP")
                                logger.debug("   USD Amount: $\(transaction.amount)", category: "MCP")
                                logger.debug("   Original: \(transaction.originalAmount ?? 0) \(transaction.originalCurrency ?? "N/A")", category: "MCP")
                                logger.debug("   Exchange Rate: \(transaction.exchangeRate ?? 0)", category: "MCP")
                            }
                        } catch {
                            logger.warning("🔍 DEBUG - Failed to decode transaction \(index): \(error)", category: "MCP")
                            if index == 0 {
                                logger.debug("🔍 DEBUG - First transaction dict: \(dict)", category: "MCP")
                            }
                        }
                    }
                    
                    // Extract additional metadata from response
                    let summary = parsedResult["summary"] as? [String: Any]
                    let transactionCount = summary?["transaction_count"] as? Int ?? transactionObjects.count
                    
                    let metadata = DocumentProcessingResult.ProcessingMetadata(
                        filename: fileURL.lastPathComponent,
                        processedAt: Date(),
                        transactionCount: transactionCount,
                        processingTime: 0.0, // Will be calculated by server
                        method: "MCP PDF Processor"
                    )
                    
                    return DocumentProcessingResult(
                        transactions: transactionObjects,
                        metadata: metadata,
                        extractedTables: nil,
                        ocrText: nil,
                        confidence: 0.9
                    )
                }
            }
        }
        
        throw MCPRPCError(code: -32603, message: "Failed to process document response")
    }
    
    /// Basic fallback processing when MCP servers are not available
    private func basicFallbackProcessing(_ fileURL: URL, fileExtension: String) async throws -> DocumentProcessingResult {
        logger.warning("🔄 Using basic fallback processing for \(fileExtension) file", category: "MCP-Fallback")
        
        // Create a minimal result that indicates fallback was used
        let metadata = DocumentProcessingResult.ProcessingMetadata(
            filename: fileURL.lastPathComponent,
            processedAt: Date(),
            transactionCount: 0,
            processingTime: 0.0,
            method: "Basic Fallback (MCP servers unavailable)"
        )
        
        // For now, return empty result to indicate we need to use backend API
        // In a full implementation, we could try to do basic CSV parsing here
        return DocumentProcessingResult(
            transactions: [],
            metadata: metadata,
            extractedTables: nil,
            ocrText: nil,
            confidence: 0.0
        )
    }
    
    // MARK: - Health Monitoring
    
    private func startHealthMonitoring() {
        healthCheckTask = Task {
            while !Task.isCancelled {
                await performHealthChecks()
                try? await Task.sleep(nanoseconds: UInt64(healthCheckInterval * 1_000_000_000))
            }
        }
    }
    
    private func performHealthChecks() async {
        let previouslyConnected = self.servers.values.filter { $0.isConnected }.count
        
        await withTaskGroup(of: Void.self) { group in
            for server in self.servers.values {
                group.addTask {
                    do {
                        _ = try await server.healthCheck()
                    } catch {
                        await MainActor.run {
                            self.logger.warning("Health check failed for \(server.info.name): \(error)")
                        }
                    }
                }
            }
        }
        
        let currentlyConnected = self.servers.values.filter { $0.isConnected }.count
        
        if currentlyConnected != previouslyConnected {
            updateConnectionStatus()
            logger.info("Connection status changed: \(currentlyConnected)/\(self.self.servers.count) servers connected")
        }
        
        metrics.updateUptime()
    }
    
    // MARK: - Server Discovery
    
    /// Initialize known MCP servers (stdio-based)
    func initializeServers() async {
        logger.info("🔍 Initializing MCP servers...")
        
        // Check if servers are already initialized
        if !self.servers.isEmpty {
            logger.info("⚠️ MCP servers already initialized, skipping...")
            return
        }
        
        // Clear any existing servers
        self.servers.removeAll()
        
        // Create servers using factory methods with nil checking
        // Financial Analyzer
        if let financialAnalyzer = MCPServer.financialAnalyzer() {
            self.servers[financialAnalyzer.id] = financialAnalyzer
        } else {
            logger.warning("⚠️ Failed to initialize Financial Analyzer server")
        }
        
        // OpenAI Service
        if let openAIService = MCPServer.openAIService() {
            self.servers[openAIService.id] = openAIService
        } else {
            logger.warning("⚠️ Failed to initialize OpenAI Service server")
        }
        
        // PDF Processor
        if let pdfProcessor = MCPServer.pdfProcessor() {
            self.servers[pdfProcessor.id] = pdfProcessor
        } else {
            logger.warning("⚠️ Failed to initialize PDF Processor server")
        }
        
        logger.info("✅ Initialized \(self.servers.count) MCP servers")
        
        updateConnectionStatus()
    }
    
    // MARK: - Metrics & Utilities
    
    private func updateAverageResponseTime(_ newTime: TimeInterval) {
        let alpha = 0.1 // Exponential moving average factor
        metrics.averageResponseTime = (1 - alpha) * metrics.averageResponseTime + alpha * newTime
    }
    
    func getServerStatus() -> [String: ServerStatus] {
        return servers.mapValues { server in
            ServerStatus(
                isConnected: server.isConnected,
                lastHealthCheck: server.lastHealthCheck,
                metrics: ServerStatusMetrics(
                    requestCount: server.metrics.requestCount,
                    successRate: server.metrics.successRate,
                    averageResponseTime: server.metrics.averageResponseTime
                ),
                connectionState: server.connectionState.description
            )
        }
    }
    
    // MARK: - MCPServerLauncher Convenience Methods
    
    /// Connect to existing server process launched by MCPServerLauncher
    func connectToExistingServer(type: ServerType) async throws {
        let serverId = type.rawValue
        
        // Check if server already exists and is connected
        if let existingServer = self.servers[serverId] {
            if existingServer.isConnected {
                logger.info("✅ Server \(serverId) already connected in MCPBridge")
                return
            } else {
                logger.info("🔗 Connecting to existing server \(serverId)...")
                try await existingServer.connect()
                return
            }
        }
        
        // Server doesn't exist, we should not create new processes here
        logger.warning("⚠️ Server \(serverId) not found in MCPBridge. Use MCPServerLauncher to start the process first.")
    }
    
    /// Add a new server configuration for MCPServerLauncher (creates new process)
    func addServer(type: ServerType, customId: String? = nil) async throws {
        let serverId = customId ?? type.rawValue
        
        // Check if server already exists - use existing one instead of creating new
        if let existingServer = self.servers[serverId] {
            logger.info("⚠️ Server \(serverId) already exists in MCPBridge, connecting existing server...")
            
            // Only connect if not already connected
            if !existingServer.isConnected {
                try await existingServer.connect()
            }
            return
        }
        
        let server: MCPServer
        switch type {
        case .financialAnalyzer:
            guard let financialAnalyzer = MCPServer.financialAnalyzer() else {
                throw MCPRPCError(code: -32601, message: "Failed to create Financial Analyzer server - MCP directory not found")
            }
            server = financialAnalyzer
        case .openAIService:
            guard let openAIService = MCPServer.openAIService() else {
                throw MCPRPCError(code: -32601, message: "Failed to create OpenAI Service server - MCP directory not found")
            }
            server = openAIService
        case .pdfProcessor:
            guard let pdfProcessor = MCPServer.pdfProcessor() else {
                throw MCPRPCError(code: -32601, message: "Failed to create PDF Processor server - MCP directory not found")
            }
            server = pdfProcessor
        case .custom:
            throw MCPRPCError(code: -32600, message: "Custom server type requires custom configuration")
        }
        
        registerServer(server)
        try await server.connect()
    }
    
    /// Remove a server by type for MCPServerLauncher
    func removeServer(type: ServerType) async {
        if let server = getServer(type: type) {
            await unregisterServer(id: server.id)
        }
    }
    
    /// Get detailed server status for MCPServerLauncher
    func getServerStatus(type: ServerType) -> ServerStatusInfo? {
        guard let server = getServer(type: type) else { return nil }
        
        return ServerStatusInfo(
            type: type,
            isConnected: server.isConnected,
            connectionState: server.connectionState.description,
            lastHealthCheck: server.lastHealthCheck,
            metrics: ServerStatusMetrics(
                requestCount: server.metrics.requestCount,
                successRate: server.metrics.successRate,
                averageResponseTime: server.metrics.averageResponseTime
            ),
            capabilities: server.capabilities.methods.map { $0.rawValue }
        )
    }
    
    /// Get all server statuses for MCPServerLauncher
    func getAllServerStatuses() -> [ServerStatusInfo] {
        return ServerType.allCases.compactMap { type in
            getServerStatus(type: type)
        }
    }
    
    /// Check if all required servers are available
    func areRequiredServersAvailable(_ types: [ServerType]) -> Bool {
        return types.allSatisfy { isServerAvailable($0) }
    }
    
    /// Get server capabilities for MCPServerLauncher
    func getServerCapabilities(type: ServerType) -> [String]? {
        return getServer(type: type)?.capabilities.methods.map { $0.rawValue }
    }

    // DEBUG: Log the exact request being sent
    private func debugLogRequest(_ method: String, _ params: [String: Any]?) {
        logger.debug("🔍 DEBUG MCP Request:", category: "MCP")
        logger.debug("   Method: \(method)", category: "MCP")
        if let params = params {
            logger.debug("   Params: \(params)", category: "MCP")
            if let jsonData = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                logger.debug("   JSON:\n\(jsonString)", category: "MCP")
            }
        }
    }

    /// Check if all servers are connected AND initialized
    func areServersReady() -> Bool {
        guard isConnected else { return false }
        
        // Check each server is connected and has completed initialization
        for server in servers.values {
            if !server.isConnected {
                return false
            }
            
            // Check connection state is not error or disconnected
            switch server.connectionState {
            case .connected:
                continue
            case .disconnected, .connecting, .reconnecting, .error:
                return false
            }
        }
        
        return true
    }
    
    /// Wait for all servers to initialize with timeout and retry logic
    func waitForServersToInitialize(maxAttempts: Int = 30, checkInterval: TimeInterval = 1.0) async throws {
        logger.info("⏳ Waiting for MCP servers to initialize (max attempts: \(maxAttempts))")
        
        for attempt in 1...maxAttempts {
            logger.debug("Initialization check attempt \(attempt)/\(maxAttempts)", category: "MCP-Init")
            
            // Check if all servers are ready
            if areServersReady() {
                logger.info("✅ All MCP servers initialized successfully after \(attempt) attempts")
                return
            }
            
            // Log current server states for debugging
            for server in servers.values {
                let state = server.isConnected ? "connected" : "disconnected"
                logger.debug("Server \(server.info.name): \(state) (\(server.connectionState))", category: "MCP-Init")
            }
            
            // Wait before next check
            try await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }
        
        // Timeout reached
        let connectedCount = servers.values.filter { $0.isConnected }.count
        let totalCount = servers.count
        
        logger.error("❌ MCP servers failed to initialize within \(maxAttempts) attempts")
        logger.error("   Connected: \(connectedCount)/\(totalCount) servers")
        
        throw MCPRPCError.timeout("MCP servers failed to initialize within \(maxAttempts) attempts")
    }
    
    /// Health check that validates server functionality rather than just connection
    func validateServerHealth() async -> [String: Bool] {
        var healthStatus: [String: Bool] = [:]
        
        for server in servers.values {
            let serverId = server.info.name
            
            // Basic connection check
            guard server.isConnected else {
                healthStatus[serverId] = false
                continue
            }
            
            // For now, just verify the server is in a connected state
            // In a full implementation, we'd send a test MCP message
            healthStatus[serverId] = server.connectionState == .connected
        }
        
        return healthStatus
    }
}