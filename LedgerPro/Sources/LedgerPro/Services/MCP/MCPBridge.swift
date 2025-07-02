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
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.ledgerpro.mcp", category: "MCPBridge")
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
        logger.info("MCPBridge initialized with \(self.servers.count) configured servers")
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
        ]
        
        for server in defaultServers {
            servers[server.id] = server
        }
    }
    
    func registerServer(_ server: MCPServer) {
        servers[server.id] = server
        logger.info("Registered MCP server: \(server.info.name)")
        updateConnectionStatus()
    }
    
    func unregisterServer(id: String) async {
        if let server = servers[id] {
            await server.disconnect()
            servers.removeValue(forKey: id)
            logger.info("Unregistered MCP server: \(server.info.name)")
            updateConnectionStatus()
        }
    }
    
    // MARK: - Connection Management
    
    func connectAll() async {
        connectionStatus = .connecting
        logger.info("Connecting to all MCP servers...")
        
        await withTaskGroup(of: Void.self) { group in
            for server in servers.values {
                group.addTask {
                    do {
                        try await server.connect()
                        await MainActor.run {
                            self.logger.info("✅ Connected to \(server.info.name)")
                        }
                    } catch {
                        await MainActor.run {
                            self.logger.error("❌ Failed to connect to \(server.info.name): \(error)")
                        }
                    }
                }
            }
        }
        
        updateConnectionStatus()
        startHealthMonitoring()
    }
    
    func disconnect() async {
        healthCheckTask?.cancel()
        healthCheckTask = nil
        
        await withTaskGroup(of: Void.self) { group in
            for server in servers.values {
                group.addTask {
                    await server.disconnect()
                }
            }
        }
        
        isConnected = false
        connectionStatus = .disconnected
        metrics.activeConnections = 0
        
        logger.info("Disconnected from all MCP servers")
    }
    
    private func updateConnectionStatus() {
        let connectedServers = servers.values.filter { $0.isConnected }
        let totalServers = servers.count
        let activeCount = connectedServers.count
        
        metrics.activeConnections = activeCount
        isConnected = activeCount > 0
        
        if activeCount == 0 {
            connectionStatus = .disconnected
        } else if activeCount == totalServers {
            connectionStatus = .connected(activeServers: activeCount, totalServers: totalServers)
        } else {
            connectionStatus = .degraded(activeServers: activeCount, totalServers: totalServers)
        }
    }
    
    // MARK: - Request Handling
    
    func sendRequest(to serverId: String, method: MCPMethod, params: [String: AnyCodable]? = nil) async throws -> MCPResponse {
        guard let server = servers[serverId] else {
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
                    lastError = error
                }
            }
            
            logger.debug("Request completed: \(method.rawValue) -> \(serverId) (\(responseTime)s)")
            return response
            
        } catch {
            metrics.failedRequests += 1
            let rpcError = MCPRPCError(code: -32603, message: "Internal error: \(error.localizedDescription)")
            lastError = rpcError
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
        guard let openAIServer = servers.values.first(where: { $0.info.name.contains("OpenAI") }),
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
        guard let pdfServer = servers.values.first(where: { $0.info.name.contains("PDF") }),
              pdfServer.isConnected else {
            throw MCPRPCError(code: -32601, message: "Server not available: PDF Processor")
        }
        
        let fileData = try Data(contentsOf: fileURL)
        let params: [String: AnyCodable] = [
            "filename": AnyCodable(fileURL.lastPathComponent),
            "data": AnyCodable(fileData.base64EncodedString()),
            "options": AnyCodable([
                "extract_tables": true,
                "ocr_enabled": true,
                "auto_categorize": true
            ])
        ]
        
        let response = try await sendRequest(to: pdfServer.id, method: .processDocument, params: params)
        return try response.decodeResult(as: DocumentProcessingResult.self)
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
        let previouslyConnected = servers.values.filter { $0.isConnected }.count
        
        await withTaskGroup(of: Void.self) { group in
            for server in servers.values {
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
        
        let currentlyConnected = servers.values.filter { $0.isConnected }.count
        
        if currentlyConnected != previouslyConnected {
            updateConnectionStatus()
            logger.info("Connection status changed: \(currentlyConnected)/\(self.servers.count) servers connected")
        }
        
        metrics.updateUptime()
    }
    
    // MARK: - Server Discovery
    
    func discoverServers(portRange: ClosedRange<Int> = 8000...8010) async {
        logger.info("Discovering MCP servers on ports \(portRange)...")
        
        await withTaskGroup(of: MCPServerInfo?.self) { group in
            for port in portRange {
                group.addTask {
                    await self.tryDiscoverServer(port: port)
                }
            }
            
            for await serverInfo in group {
                if let info = serverInfo {
                    let connection = HTTPConnection(host: "127.0.0.1", port: Int(info.homepage?.components(separatedBy: ":").last ?? "8000") ?? 8000)
                    let capabilities = MCPCapabilities(methods: [], notifications: [], features: [:])
                    let server = MCPServer(info: info, connection: connection, capabilities: capabilities)
                    
                    await MainActor.run {
                        self.registerServer(server)
                        self.logger.info("Discovered server: \(info.name)")
                    }
                }
            }
        }
    }
    
    private func tryDiscoverServer(port: Int) async -> MCPServerInfo? {
        do {
            let url = URL(string: "http://127.0.0.1:\(port)/info")!
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                return try JSONDecoder().decode(MCPServerInfo.self, from: data)
            }
        } catch {
            // Server not found on this port
        }
        
        return nil
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
}

// MARK: - Supporting Types

struct MCPAnalysisResult: Codable {
    let type: String
    let title: String
    let description: String
    let confidence: Double
    let data: [String: AnyCodable]
    let timestamp: Date
    var serverId: String?
    
    init(type: String, title: String, description: String, confidence: Double, data: [String: AnyCodable] = [:], timestamp: Date = Date()) {
        self.type = type
        self.title = title
        self.description = description
        self.confidence = confidence
        self.data = data
        self.timestamp = timestamp
    }
}

struct DocumentProcessingResult: Codable {
    let transactions: [Transaction]
    let metadata: ProcessingMetadata
    let extractedTables: [[String: String]]?
    let ocrText: String?
    let confidence: Double
    
    struct ProcessingMetadata: Codable {
        let filename: String
        let processedAt: Date
        let transactionCount: Int
        let processingTime: TimeInterval
        let method: String
    }
}

struct ServerStatus {
    let isConnected: Bool
    let lastHealthCheck: Date?
    let metrics: ServerStatusMetrics
    let connectionState: String
}

struct ServerStatusMetrics {
    let requestCount: Int
    let successRate: Double
    let averageResponseTime: TimeInterval
}

// MARK: - Extensions

extension MCPServer.ConnectionState {
    var description: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .reconnecting:
            return "Reconnecting"
        case .error(let error):
            return "Error: \(error.message)"
        }
    }
}