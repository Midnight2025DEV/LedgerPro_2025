import Foundation

@MainActor
class MCPService: ObservableObject {
    
    @Published var isConnected = false
    @Published var availableServers: [MCPServer] = []
    @Published var lastInsights: [MCPInsight] = []
    
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
        var activeCount = 0
        
        for server in availableServers {
            do {
                let isHealthy = try await pingServer(server)
                if isHealthy {
                    activeCount += 1
                }
            } catch {
                print("Server \(server.name) is unreachable: \(error)")
            }
        }
        
        isConnected = activeCount > 0
        print("MCP Health Check: \(activeCount)/\(availableServers.count) servers active")
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
        let analyzer = availableServers.first { $0.id == "financial-analyzer" }
        guard let server = analyzer else {
            throw MCPError.serverNotAvailable("Financial Analyzer")
        }
        
        let insights = try await requestInsights(from: server, transactions: transactions)
        lastInsights = insights
        return insights
    }
    
    func categorizeTransactions(_ transactions: [Transaction]) async throws -> [Transaction] {
        let openaiService = availableServers.first { $0.id == "openai-service" }
        guard let server = openaiService else {
            throw MCPError.serverNotAvailable("OpenAI Service")
        }
        
        return try await requestCategorization(from: server, transactions: transactions)
    }
    
    func processDocument(at url: URL) async throws -> [Transaction] {
        let pdfProcessor = availableServers.first { $0.id == "pdf-processor" }
        guard let server = pdfProcessor else {
            throw MCPError.serverNotAvailable("PDF Processor")
        }
        
        return try await requestDocumentProcessing(from: server, fileURL: url)
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
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
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
    case requestFailed
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .serverNotAvailable(let serverName):
            return "Server \(serverName) is not available"
        case .requestFailed:
            return "MCP request failed"
        case .decodingError:
            return "Failed to decode MCP response"
        }
    }
}