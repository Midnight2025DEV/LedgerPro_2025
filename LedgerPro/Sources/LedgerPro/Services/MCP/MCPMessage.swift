import Foundation

// MARK: - JSON-RPC 2.0 Message Types

/// JSON-RPC 2.0 Request Message
struct MCPRequest: Codable {
    var jsonrpc: String = "2.0"
    let id: String
    let method: MCPMethod
    let params: [String: AnyCodable]?
    
    init(id: String = UUID().uuidString, method: MCPMethod, params: [String: AnyCodable]? = nil) {
        self.id = id
        self.method = method
        self.params = params
    }
}

/// JSON-RPC 2.0 Notification Message (no response expected)
struct MCPNotification: Codable {
    var jsonrpc: String = "2.0"
    let method: String
    let params: [String: AnyCodable]?
    
    init(method: String, params: [String: AnyCodable]? = nil) {
        self.method = method
        self.params = params
    }
}

/// JSON-RPC 2.0 Response Message
struct MCPResponse: Codable {
    var jsonrpc: String = "2.0"
    let id: String
    let result: AnyCodable?
    let error: MCPRPCError?
    
    init(id: String, result: AnyCodable? = nil, error: MCPRPCError? = nil) {
        self.id = id
        self.result = result
        self.error = error
    }
    
    var isSuccess: Bool {
        return error == nil
    }
}

/// JSON-RPC 2.0 Error Object
struct MCPRPCError: Codable, LocalizedError {
    let code: Int
    let message: String
    let data: AnyCodable?
    
    init(code: Int, message: String, data: AnyCodable? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
    
    var errorDescription: String? {
        return message
    }
    
    // Standard JSON-RPC error codes
    static let parseError = MCPRPCError(code: -32700, message: "Parse error")
    static let invalidRequest = MCPRPCError(code: -32600, message: "Invalid Request")
    static let methodNotFound = MCPRPCError(code: -32601, message: "Method not found")
    static let invalidParams = MCPRPCError(code: -32602, message: "Invalid params")
    static let internalError = MCPRPCError(code: -32603, message: "Internal error")
    
    // MCP-specific error codes
    static let serverUnavailable = MCPRPCError(code: -32000, message: "Server unavailable")
    static let authenticationRequired = MCPRPCError(code: -32001, message: "Authentication required")
    static let rateLimited = MCPRPCError(code: -32002, message: "Rate limited")
    static let resourceNotFound = MCPRPCError(code: -32003, message: "Resource not found")
}

/// MCP Method Enumeration
enum MCPMethod: String, Codable, CaseIterable {
    // Core MCP Methods
    case initialize = "initialize"
    case ping = "ping"
    case listCapabilities = "listCapabilities"
    case listTools = "tools/list"
    case callTool = "tools/call"
    
    // Financial Analysis Methods
    case analyzeTransactions = "financial/analyze"
    case generateInsights = "financial/insights"
    case detectAnomalies = "financial/anomalies"
    case categorizeTransactions = "financial/categorize"
    
    // Document Processing Methods
    case processDocument = "document/process"
    case extractTables = "document/extractTables"
    case ocrDocument = "document/ocr"
    
    // AI/OpenAI Methods
    case chatCompletion = "ai/chat"
    case embedding = "ai/embedding"
    case classification = "ai/classify"
    case sentiment = "ai/sentiment"
    
    // Data Management Methods
    case exportData = "data/export"
    case importData = "data/import"
    case validateData = "data/validate"
    
    // Notification Methods (server-to-client)
    case notification = "notification"
    case statusUpdate = "status/update"
    case progress = "progress"
    
    var requiresAuth: Bool {
        switch self {
        case .ping, .listCapabilities:
            return false
        default:
            return true
        }
    }
    
    var timeout: TimeInterval {
        switch self {
        case .ping:
            return 5.0
        case .processDocument, .ocrDocument:
            return 120.0
        case .analyzeTransactions, .generateInsights:
            return 60.0
        default:
            return 30.0
        }
    }
}

/// Type-safe wrapper for any Codable value
struct AnyCodable: Codable {
    let value: Any
    
    init<T: Codable>(_ value: T) {
        self.value = value
    }
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable value cannot be decoded"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let encodableArray = array.map { AnyCodable($0) }
            try container.encode(encodableArray)
        case let dictionary as [String: Any]:
            let encodableDict = dictionary.mapValues { AnyCodable($0) }
            try container.encode(encodableDict)
        case let codable as Codable:
            // Try to encode any Codable type directly
            try codable.encode(to: encoder)
        default:
            // As a last resort, try to convert to string representation
            let stringValue = String(describing: value)
            try container.encode(stringValue)
        }
    }
}

// MARK: - MCP Message Utilities

extension MCPRequest {
    /// Create a request for server initialization
    static func initialize(capabilities: [String: AnyCodable]) -> MCPRequest {
        return MCPRequest(method: .initialize, params: ["capabilities": AnyCodable(capabilities)])
    }
    
    /// Create a ping request
    static func ping() -> MCPRequest {
        return MCPRequest(method: .ping)
    }
    
    /// Create a transaction analysis request
    static func analyzeTransactions(_ transactions: [Transaction]) -> MCPRequest {
        return MCPRequest(
            method: .analyzeTransactions,
            params: ["transactions": AnyCodable(transactions)]
        )
    }
    
    /// Create a document processing request
    static func processDocument(filename: String, data: Data) -> MCPRequest {
        return MCPRequest(
            method: .processDocument,
            params: [
                "filename": AnyCodable(filename),
                "data": AnyCodable(data.base64EncodedString())
            ]
        )
    }
}

extension MCPResponse {
    /// Create a success response
    static func success<T: Codable>(id: String, result: T) -> MCPResponse {
        return MCPResponse(id: id, result: AnyCodable(result))
    }
    
    /// Create an error response
    static func error(id: String, error: MCPRPCError) -> MCPResponse {
        return MCPResponse(id: id, error: error)
    }
    
    /// Decode the result to a specific type
    func decodeResult<T: Codable>(as type: T.Type) throws -> T {
        guard let result = result else {
            throw MCPRPCError.internalError
        }
        
        let data = try JSONEncoder().encode(result)
        return try JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Common MCP Response Types

struct MCPServerInfo: Codable {
    let name: String
    let version: String
    let capabilities: [String]
    let description: String?
    let author: String?
    let homepage: String?
}

struct MCPCapabilities: Codable {
    let methods: [MCPMethod]
    let notifications: [String]
    let features: [String: Bool]
}

struct MCPProgress: Codable {
    let requestId: String
    let stage: String
    let progress: Double // 0.0 to 1.0
    let message: String?
    let estimatedTimeRemaining: TimeInterval?
}

struct MCPHealthStatus: Codable {
    let status: String // "healthy", "degraded", "unhealthy"
    let uptime: TimeInterval
    let version: String
    let timestamp: Date
    let checks: [String: Bool]
    let metadata: [String: AnyCodable]?
}