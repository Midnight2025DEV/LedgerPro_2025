import Foundation

struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let provider: String?
    let model: String?
    
    init(content: String, isFromUser: Bool, provider: String? = nil, model: String? = nil) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.provider = provider
        self.model = model
    }
}

struct ChatSession: Identifiable, Codable {
    let id = UUID()
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date
    var title: String
    
    init(title: String = "New Chat") {
        self.messages = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.title = title
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