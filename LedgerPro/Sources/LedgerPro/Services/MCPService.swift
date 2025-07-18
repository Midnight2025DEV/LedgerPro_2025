import Foundation

/// Legacy MCP Service - now delegates to the new MCPBridge
@MainActor
class MCPService: ObservableObject {
    
    @Published var isConnected = false
    @Published var availableServers: [MCPServer] = []
    @Published var lastInsights: [MCPInsight] = []
    
    // New MCP Bridge instance
    private let mcpBridge = MCPBridge()
    
    struct MCPServer: Identifiable, Codable {
        let id: String
        let name: String
        let description: String
        let port: Int
        let isActive: Bool
        
        var url: String {
            return "http://127.0.0.1:\(port)"
        }
    }
    
    struct MCPInsight: Identifiable, Codable {
        let id: UUID
        let serverName: String
        let type: String
        let title: String
        let description: String
        let confidence: Double
        let timestamp: Date
        let data: [String: String]
        
        init(serverName: String, type: String, title: String, description: String, confidence: Double, timestamp: Date, data: [String: String]) {
            self.id = UUID()
            self.serverName = serverName
            self.type = type
            self.title = title
            self.description = description
            self.confidence = confidence
            self.timestamp = timestamp
            self.data = data
        }
    }
    
    init() {
        loadAvailableServers()
        
        // Observe bridge connection status
        Task {
            for await _ in mcpBridge.$isConnected.values {
                await updateConnectionStatus()
            }
        }
    }
    
    // MARK: - Bridge Integration
    
    private func updateConnectionStatus() async {
        isConnected = mcpBridge.isConnected
        
        // Convert bridge servers to legacy format for compatibility
        let bridgeServers = mcpBridge.servers.values
        availableServers = bridgeServers.map { bridgeServer in
            MCPServer(
                id: bridgeServer.id,
                name: bridgeServer.info.name,
                description: bridgeServer.info.description ?? "",
                port: (bridgeServer.connection as? HTTPConnection)?.port ?? 8000,
                isActive: bridgeServer.isConnected
            )
        }
    }
    
    func connectToBridge() async {
        await mcpBridge.connectAll()
    }
    
    func disconnectFromBridge() async {
        await mcpBridge.disconnect()
    }
    
    private func loadAvailableServers() {
        // Load known MCP servers based on your existing setup
        availableServers = [
            MCPServer(
                id: "financial-analyzer",
                name: "Financial Analyzer",
                description: "Advanced financial analysis and insights",
                port: 8001,
                isActive: true
            ),
            MCPServer(
                id: "openai-service",
                name: "OpenAI Service",
                description: "AI-powered transaction categorization and insights",
                port: 8002,
                isActive: true
            ),
            MCPServer(
                id: "pdf-processor",
                name: "PDF Processor",
                description: "Enhanced PDF document processing",
                port: 8003,
                isActive: true
            )
        ]
    }
    
    func checkServerHealth() async {
        // Delegate to new MCP Bridge - it handles health checks automatically
        await updateConnectionStatus()
        
        let serverStatus = mcpBridge.getServerStatus()
        let activeCount = serverStatus.values.filter { $0.isConnected }.count
        
        AppLogger.shared.info("MCP Health Check: \(activeCount)/\(serverStatus.count) servers active", category: "MCP")
        AppLogger.shared.info("Bridge Status: \(mcpBridge.connectionStatus.description)", category: "MCP")
    }
    
    private func pingServer(_ server: MCPServer) async throws -> Bool {
        guard let url = URL(string: "\(server.url)/health") else {
            throw MCPError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
    
    func generateFinancialInsights(transactions: [Transaction]) async throws -> [MCPInsight] {
        // Delegate to new MCP Bridge
        let analysisResults = try await mcpBridge.analyzeTransactions(transactions)
        
        // Convert bridge results to legacy format
        let insights = analysisResults.map { result in
            MCPInsight(
                serverName: result.serverId ?? "Unknown",
                type: result.type,
                title: result.title,
                description: result.description,
                confidence: result.confidence,
                timestamp: result.timestamp,
                data: result.data.mapValues { $0.value as? String ?? "\($0.value)" }
            )
        }
        
        lastInsights = insights
        return insights
    }
    
    func categorizeTransactions(_ transactions: [Transaction]) async throws -> [Transaction] {
        // Delegate to new MCP Bridge
        return try await mcpBridge.categorizeTransactions(transactions)
    }
    
    func processDocument(at url: URL) async throws -> [Transaction] {
        // Delegate to new MCP Bridge
        let result = try await mcpBridge.processDocument(url)
        return result.transactions
    }
    
    private func requestInsights(from server: MCPServer, transactions: [Transaction]) async throws -> [MCPInsight] {
        guard let url = URL(string: "\(server.url)/analyze") else {
            throw MCPError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = AnalysisRequest(transactions: transactions)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MCPError.requestFailed
        }
        
        let analysisResponse = try JSONDecoder().decode(AnalysisResponse.self, from: data)
        
        return analysisResponse.insights.map { insight in
            MCPInsight(
                serverName: server.name,
                type: insight.type,
                title: insight.title,
                description: insight.description,
                confidence: insight.confidence,
                timestamp: Date(),
                data: insight.data
            )
        }
    }
    
    private func requestCategorization(from server: MCPServer, transactions: [Transaction]) async throws -> [Transaction] {
        guard let url = URL(string: "\(server.url)/categorize") else {
            throw MCPError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = CategorizationRequest(transactions: transactions)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MCPError.requestFailed
        }
        
        let categorizationResponse = try JSONDecoder().decode(CategorizationResponse.self, from: data)
        return categorizationResponse.transactions
    }
    
    private func requestDocumentProcessing(from server: MCPServer, fileURL: URL) async throws -> [Transaction] {
        guard let url = URL(string: "\(server.url)/process") else {
            throw MCPError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let fileData = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent
        
        var body = Data()
        body.append(try "--\(boundary)\r\n".safeUTF8Data())
        body.append(try "Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".safeUTF8Data())
        body.append(try "Content-Type: application/octet-stream\r\n\r\n".safeUTF8Data())
        body.append(fileData)
        body.append(try "\r\n--\(boundary)--\r\n".safeUTF8Data())
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MCPError.requestFailed
        }
        
        let processingResponse = try JSONDecoder().decode(ProcessingResponse.self, from: data)
        return processingResponse.transactions
    }
}

// MARK: - Request/Response Models
struct AnalysisRequest: Codable {
    let transactions: [Transaction]
}

struct AnalysisResponse: Codable {
    let insights: [ServerInsight]
    
    struct ServerInsight: Codable {
        let type: String
        let title: String
        let description: String
        let confidence: Double
        let data: [String: String]
    }
}

struct CategorizationRequest: Codable {
    let transactions: [Transaction]
}

struct CategorizationResponse: Codable {
    let transactions: [Transaction]
}

struct ProcessingResponse: Codable {
    let transactions: [Transaction]
    let metadata: ProcessingMetadata
    
    struct ProcessingMetadata: Codable {
        let filename: String
        let processedAt: String
        let transactionCount: Int
    }
}

// MARK: - Error Types
enum MCPError: LocalizedError {
    case invalidURL
    case serverNotAvailable(String)
    case serverUnavailable
    case requestFailed
    case decodingError
    case internalError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .serverNotAvailable(let serverName):
            return "Server \(serverName) is not available"
        case .serverUnavailable:
            return "Server is unavailable"
        case .requestFailed:
            return "MCP request failed"
        case .decodingError:
            return "Failed to decode MCP response"
        case .internalError:
            return "Internal MCP error"
        }
    }
    
    var message: String {
        return errorDescription ?? "Unknown error"
    }
}