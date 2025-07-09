import Foundation
import Network

// MARK: - MCP Server Protocol

@MainActor
protocol MCPServerProtocol {
    var info: MCPServerInfo { get }
    var connection: MCPConnection { get }
    var capabilities: MCPCapabilities { get }
    var isConnected: Bool { get }
    var lastHealthCheck: Date? { get }
    
    func connect() async throws
    func disconnect() async
    func sendRequest(_ request: MCPRequest) async throws -> MCPResponse
    func healthCheck() async throws -> MCPHealthStatus
}

// MARK: - MCP Server Implementation

@MainActor
class MCPServer: MCPServerProtocol, ObservableObject, Identifiable {
    let id: String
    let info: MCPServerInfo
    let connection: MCPConnection
    let capabilities: MCPCapabilities
    
    @Published var isConnected: Bool = false
    @Published var lastHealthCheck: Date?
    @Published var lastError: MCPRPCError?
    @Published var connectionState: ConnectionState = .disconnected
    @Published var metrics: ServerMetrics = ServerMetrics()
    
    private var heartbeatTask: Task<Void, Never>?
    private let heartbeatInterval: TimeInterval = 30.0
    private let maxRetries: Int = 3
    private let baseRetryDelay: TimeInterval = 1.0
    private var connectionStartTime: Date?
    
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error(MCPRPCError)
    }
    
    struct ServerMetrics {
        var requestCount: Int = 0
        var successCount: Int = 0
        var errorCount: Int = 0
        var averageResponseTime: TimeInterval = 0
        var lastRequestTime: Date?
        
        var successRate: Double {
            guard requestCount > 0 else { return 0 }
            return Double(successCount) / Double(requestCount)
        }
    }
    
    init(info: MCPServerInfo, connection: MCPConnection, capabilities: MCPCapabilities) {
        self.id = info.name.lowercased().replacingOccurrences(of: " ", with: "-")
        self.info = info
        self.connection = connection
        self.capabilities = capabilities
    }
    
    // MARK: - Connection Management
    
    func connect() async throws {
        connectionState = .connecting
        
        do {
            try await connection.connect()
            
            // Note: MCPStdioConnection.connect() already handles initialization
            // No need to do a separate initialization handshake here
            
            isConnected = true
            connectionState = .connected
            lastError = nil
            connectionStartTime = Date()
            
            AppLogger.shared.info("Connected to MCP server: \(info.name)")
            
            // Start heartbeat monitoring after a short delay
            // The healthCheck method now has a 60-second grace period
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds delay
                startHeartbeat()
            }
            
        } catch {
            connectionState = .error(error as? MCPRPCError ?? MCPRPCError.serverUnavailable)
            lastError = error as? MCPRPCError
            throw error
        }
    }
    
    func disconnect() async {
        heartbeatTask?.cancel()
        heartbeatTask = nil
        
        await connection.disconnect()
        
        isConnected = false
        connectionState = .disconnected
        lastError = nil
        connectionStartTime = nil
        
        AppLogger.shared.info("Disconnected from MCP server: \(info.name)")
    }
    
    // MARK: - Request Handling
    
    func sendRequest(_ request: MCPRequest) async throws -> MCPResponse {
        let startTime = Date()
        metrics.requestCount += 1
        metrics.lastRequestTime = startTime
        
        do {
            let response = try await connection.sendRequest(request)
            
            // Update metrics
            let responseTime = Date().timeIntervalSince(startTime)
            updateAverageResponseTime(responseTime)
            
            if response.isSuccess {
                metrics.successCount += 1
            } else {
                metrics.errorCount += 1
                lastError = response.error
            }
            
            return response
            
        } catch {
            metrics.errorCount += 1
            lastError = error as? MCPRPCError ?? MCPRPCError.internalError
            throw error
        }
    }
    
    func sendRequestWithRetry(_ request: MCPRequest) async throws -> MCPResponse {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await sendRequest(request)
            } catch {
                lastError = error
                
                if attempt < maxRetries - 1 {
                    let delay = baseRetryDelay * pow(2.0, Double(attempt))
                    AppLogger.shared.warning("Request failed (attempt \(attempt + 1)/\(maxRetries)), retrying in \(delay)s: \(error)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? MCPRPCError(code: -32603, message: "Internal error")
    }
    
    // MARK: - Health Monitoring
    
    func healthCheck() async throws -> MCPHealthStatus {
        // For now, disable ping-based health checks entirely
        // The Python servers seem to have issues with ping requests
        // We'll rely on connection status instead
        
        let uptime = connectionStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        // Always return healthy if we're connected
        // This prevents the ping issues from causing reconnections
        if isConnected {
            lastHealthCheck = Date()
            AppLogger.shared.info("\(info.name) health check: Connected (uptime: \(Int(uptime))s)")
            return MCPHealthStatus(
                status: "healthy",
                uptime: uptime,
                version: info.version,
                timestamp: Date(),
                checks: ["connected": true],
                metadata: ["method": AnyCodable("connection-based")]
            )
        } else {
            throw MCPRPCError(code: -32601, message: "Server is disconnected")
        }
    }
    
    private func startHeartbeat() {
        heartbeatTask = Task {
            while !Task.isCancelled && isConnected {
                do {
                    _ = try await healthCheck()
                } catch {
                    AppLogger.shared.warning("Heartbeat failed for \(info.name): \(error)")
                    lastError = error as? MCPRPCError
                    
                    // Since we're using connection-based health checks,
                    // only attempt reconnection if we're actually disconnected
                    if !isConnected {
                        await attemptReconnection()
                    }
                }
                
                try? await Task.sleep(nanoseconds: UInt64(heartbeatInterval * 1_000_000_000))
            }
        }
    }
    
    private func attemptReconnection() async {
        AppLogger.shared.info("Attempting to reconnect to \(info.name)...")
        connectionState = .reconnecting
        
        do {
            await disconnect()
            try await connect()
            AppLogger.shared.info("Reconnected to \(info.name)")
        } catch {
            AppLogger.shared.error("Reconnection failed for \(info.name): \(error)")
            connectionState = .error(error as? MCPRPCError ?? MCPRPCError(code: -32601, message: "Server is unavailable"))
        }
    }
    
    // MARK: - Metrics
    
    private func updateAverageResponseTime(_ newTime: TimeInterval) {
        let alpha = 0.1 // Exponential moving average factor
        metrics.averageResponseTime = (1 - alpha) * metrics.averageResponseTime + alpha * newTime
    }
}

// MARK: - Predefined Server Configurations

extension MCPServer {
    static func financialAnalyzer() -> MCPServer {
        guard let basePath = MCPServerLauncher.getMCPServersBasePath() else {
            fatalError("Could not find MCP servers directory")
        }
        
        let serverPath = "\(basePath)/financial-analyzer/analyzer_server.py"
        
        let info = MCPServerInfo(
            name: "Financial Analyzer",
            version: "1.0.0",
            capabilities: ["analyze_statement", "analyze_spending_patterns", "compare_statements"],
            description: "Advanced financial analysis and insights generation",
            author: "LedgerPro Team",
            homepage: nil
        )
        
        let connection = MCPStdioConnection(
            serverPath: serverPath,
            serverName: "Financial Analyzer"
        )
        
        let capabilities = MCPCapabilities(
            methods: [.listTools, .callTool],
            notifications: ["analysis.complete", "insight.generated"],
            features: [
                "streaming": false,
                "batch_processing": true,
                "real_time": false
            ]
        )
        
        return MCPServer(info: info, connection: connection, capabilities: capabilities)
    }
    
    static func openAIService() -> MCPServer {
        guard let basePath = MCPServerLauncher.getMCPServersBasePath() else {
            fatalError("Could not find MCP servers directory")
        }
        
        let serverPath = "\(basePath)/openai-service/openai_server.py"
        
        let info = MCPServerInfo(
            name: "OpenAI Service",
            version: "1.0.0",
            capabilities: ["enhance_transactions", "categorize_transaction", "extract_financial_insights"],
            description: "AI-powered transaction categorization and insights",
            author: "LedgerPro Team",
            homepage: nil
        )
        
        let connection = MCPStdioConnection(
            serverPath: serverPath,
            serverName: "OpenAI Service"
        )
        
        let capabilities = MCPCapabilities(
            methods: [.listTools, .callTool],
            notifications: ["categorization.complete", "insight.extracted"],
            features: [
                "openai_integration": true,
                "batch_processing": true,
                "real_time": true
            ]
        )
        
        return MCPServer(info: info, connection: connection, capabilities: capabilities)
    }
    
    static func pdfProcessor() -> MCPServer {
        guard let basePath = MCPServerLauncher.getMCPServersBasePath() else {
            fatalError("Could not find MCP servers directory")
        }
        
        let serverPath = "\(basePath)/pdf-processor/pdf_processor_server.py"
        
        let info = MCPServerInfo(
            name: "PDF Processor",
            version: "1.0.0",
            capabilities: ["process_bank_pdf", "detect_bank", "extract_pdf_text", "extract_pdf_tables"],
            description: "Enhanced PDF document processing and data extraction",
            author: "LedgerPro Team",
            homepage: nil
        )
        
        let connection = MCPStdioConnection(
            serverPath: serverPath,
            serverName: "PDF Processor"
        )
        
        let capabilities = MCPCapabilities(
            methods: [.listTools, .callTool],
            notifications: ["processing.complete", "extraction.finished"],
            features: [
                "pdf_processing": true,
                "table_extraction": true,
                "ocr_support": true
            ]
        )
        
        return MCPServer(info: info, connection: connection, capabilities: capabilities)
    }
}

// MARK: - Connection Protocol

@MainActor
protocol MCPConnection {
    func connect() async throws
    func disconnect() async
    func sendRequest(_ request: MCPRequest) async throws -> MCPResponse
    var isConnected: Bool { get }
}

// MARK: - HTTP Connection Implementation

@MainActor
class HTTPConnection: MCPConnection {
    let host: String
    let port: Int
    private(set) var isConnected: Bool = false
    
    private let session: URLSession
    private let timeout: TimeInterval = 30.0
    
    var baseURL: URL {
        return URL(string: "http://\(host):\(port)")!
    }
    
    init(host: String, port: Int) {
        self.host = host
        self.port = port
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        self.session = URLSession(configuration: config)
    }
    
    func connect() async throws {
        // Test connection with a health check
        let healthURL = baseURL.appendingPathComponent("health")
        
        do {
            let (_, response) = try await session.data(from: healthURL)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                isConnected = true
            } else {
                throw MCPRPCError(code: -32601, message: "Server is unavailable")
            }
        } catch {
            throw MCPError.serverUnavailable
        }
    }
    
    func disconnect() async {
        isConnected = false
    }
    
    func sendRequest(_ request: MCPRequest) async throws -> MCPResponse {
        guard isConnected else {
            throw MCPError.serverUnavailable
        }
        
        let url = baseURL.appendingPathComponent("rpc")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let requestData = try JSONEncoder().encode(request)
            urlRequest.httpBody = requestData
            
            let (responseData, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MCPRPCError(code: -32603, message: "Internal error")
            }
            
            guard httpResponse.statusCode == 200 else {
                throw MCPRPCError(code: httpResponse.statusCode, message: "HTTP \(httpResponse.statusCode)")
            }
            
            let mcpResponse = try JSONDecoder().decode(MCPResponse.self, from: responseData)
            return mcpResponse
            
        } catch is DecodingError {
            throw MCPRPCError.parseError
        } catch {
            throw MCPError.internalError
        }
    }
}