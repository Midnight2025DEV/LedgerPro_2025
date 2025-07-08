import Foundation

// MARK: - MCP Supporting Types


// MARK: - Supporting Types

/// Server type enumeration for MCPServerLauncher
enum ServerType: String, CaseIterable {
    case financialAnalyzer = "financial-analyzer"
    case openAIService = "openai-service"
    case pdfProcessor = "pdf-processor"
    case custom
    
    var displayName: String {
        switch self {
        case .financialAnalyzer:
            return "Financial Analyzer"
        case .openAIService:
            return "OpenAI Service"
        case .pdfProcessor:
            return "PDF Processor"
        case .custom:
            return "Custom Server"
        }
    }
    
    var port: Int {
        switch self {
        case .financialAnalyzer:
            return 8001
        case .openAIService:
            return 8002
        case .pdfProcessor:
            return 8003
        case .custom:
            return 8000
        }
    }
}

/// Server configuration for MCPServerLauncher
struct ServerConfiguration {
    let name: String
    let factory: () -> MCPServer
    let description: String
    
    func createServer() -> MCPServer {
        return factory()
    }
}

/// Detailed server status information for MCPServerLauncher
struct ServerStatusInfo {
    let type: ServerType
    let isConnected: Bool
    let connectionState: String
    let lastHealthCheck: Date?
    let metrics: ServerStatusMetrics
    let capabilities: [String]
    
    var statusDescription: String {
        if isConnected {
            return "✅ \(type.displayName) - Connected"
        } else {
            return "❌ \(type.displayName) - \(connectionState)"
        }
    }
}

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