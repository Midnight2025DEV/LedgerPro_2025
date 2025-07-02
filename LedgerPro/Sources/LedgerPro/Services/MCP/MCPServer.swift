import Foundation
import Network

// MARK: - MCP Server Protocol

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
            
            // Perform initialization handshake
            let initRequest = MCPRequest.initialize(capabilities: [
                "jsonrpc": AnyCodable("2.0"),
                "client": AnyCodable("LedgerPro"),
                "version": AnyCodable("1.0.0")
            ])
            
            let response = try await sendRequest(initRequest)
            guard response.isSuccess else {
                throw response.error ?? MCPRPCError.internalError
            }
            
            isConnected = true
            connectionState = .connected
            lastError = nil
            
            // Start heartbeat monitoring
            startHeartbeat()
            
            print("✅ Connected to MCP server: \(info.name)")
            
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
        
        print("❌ Disconnected from MCP server: \(info.name)")
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
                    print("⚠️ Request failed (attempt \(attempt + 1)/\(maxRetries)), retrying in \(delay)s: \(error)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? MCPRPCError(code: -32603, message: "Internal error")
    }
    
    // MARK: - Health Monitoring
    
    func healthCheck() async throws -> MCPHealthStatus {
        let pingRequest = MCPRequest.ping()
        let response = try await sendRequest(pingRequest)
        
        if response.isSuccess {
            let healthStatus = try response.decodeResult(as: MCPHealthStatus.self)
            lastHealthCheck = Date()
            return healthStatus
        } else {
            throw response.error ?? MCPRPCError(code: -32601, message: "Server is unavailable")
        }
    }
    
    private func startHeartbeat() {
        heartbeatTask = Task {
            while !Task.isCancelled && isConnected {
                do {
                    _ = try await healthCheck()
                } catch {
                    print("⚠️ Heartbeat failed for \(info.name): \(error)")
                    lastError = error as? MCPRPCError
                    
                    // Attempt reconnection if health check fails
                    if isConnected {
                        await attemptReconnection()
                    }
                }
                
                try? await Task.sleep(nanoseconds: UInt64(heartbeatInterval * 1_000_000_000))
            }
        }
    }
    
    private func attemptReconnection() async {
        print("🔄 Attempting to reconnect to \(info.name)...")
        connectionState = .reconnecting
        
        do {
            await disconnect()
            try await connect()
            print("✅ Reconnected to \(info.name)")
        } catch {
            print("❌ Reconnection failed for \(info.name): \(error)")
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
    static func financialAnalyzer(port: Int = 8001) -> MCPServer {
        let info = MCPServerInfo(
            name: "Financial Analyzer",
            version: "1.0.0",
            capabilities: ["analysis", "insights", "anomaly-detection"],
            description: "Advanced financial analysis and insights generation",
            author: "LedgerPro Team",
            homepage: "https://github.com/LedgerPro/financial-analyzer"
        )
        
        let connection = HTTPConnection(host: "127.0.0.1", port: port)
        
        let capabilities = MCPCapabilities(
            methods: [.analyzeTransactions, .generateInsights, .detectAnomalies],
            notifications: ["analysis.complete", "insight.generated"],
            features: [
                "streaming": false,
                "batch_processing": true,
                "real_time": false
            ]
        )
        
        return MCPServer(info: info, connection: connection, capabilities: capabilities)
    }
    
    static func openAIService(port: Int = 8002) -> MCPServer {
        let info = MCPServerInfo(
            name: "OpenAI Service",
            version: "1.0.0",
            capabilities: ["ai", "nlp", "classification"],
            description: "AI-powered transaction categorization and insights",
            author: "LedgerPro Team",
            homepage: nil
        )
        
        let connection = HTTPConnection(host: "127.0.0.1", port: port)
        
        let capabilities = MCPCapabilities(
            methods: [.chatCompletion, .embedding, .classification, .categorizeTransactions],
            notifications: ["ai.processing", "categorization.complete"],
            features: [
                "streaming": true,
                "batch_processing": true,
                "real_time": true
            ]
        )
        
        return MCPServer(info: info, connection: connection, capabilities: capabilities)
    }
    
    static func pdfProcessor(port: Int = 8003) -> MCPServer {
        let info = MCPServerInfo(
            name: "PDF Processor",
            version: "1.0.0",
            capabilities: ["document-processing", "ocr", "table-extraction"],
            description: "Enhanced PDF document processing and data extraction",
            author: "LedgerPro Team",
            homepage: nil
        )
        
        let connection = HTTPConnection(host: "127.0.0.1", port: port)
        
        let capabilities = MCPCapabilities(
            methods: [.processDocument, .extractTables, .ocrDocument],
            notifications: ["processing.progress", "extraction.complete"],
            features: [
                "streaming": false,
                "batch_processing": true,
                "real_time": false
            ]
        )
        
        return MCPServer(info: info, connection: connection, capabilities: capabilities)
    }
}

// MARK: - Connection Protocol

protocol MCPConnection {
    func connect() async throws
    func disconnect() async
    func sendRequest(_ request: MCPRequest) async throws -> MCPResponse
    var isConnected: Bool { get }
}

// MARK: - HTTP Connection Implementation

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
            
        } catch let error as DecodingError {
            throw MCPRPCError.parseError
        } catch {
            throw MCPError.internalError
        }
    }
}