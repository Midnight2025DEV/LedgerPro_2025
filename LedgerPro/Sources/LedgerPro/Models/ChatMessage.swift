import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let provider: String?
    let model: String?
    
    init(content: String, isFromUser: Bool, provider: String? = nil, model: String? = nil) {
        self.id = UUID()
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.provider = provider
        self.model = model
    }
    
    enum CodingKeys: String, CodingKey {
        case id, content, isFromUser, timestamp, provider, model
    }
}

struct ChatSession: Identifiable, Codable {
    let id: UUID
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date
    var title: String
    
    init(title: String = "New Chat") {
        self.id = UUID()
        self.messages = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.title = title
    }
    
    enum CodingKeys: String, CodingKey {
        case id, messages, createdAt, updatedAt, title
    }
    
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        updatedAt = Date()
        
        if title == "New Chat" && !messages.isEmpty {
            let firstUserMessage = messages.first { $0.isFromUser }?.content ?? "Chat"
            title = String(firstUserMessage.prefix(30))
        }
    }
}