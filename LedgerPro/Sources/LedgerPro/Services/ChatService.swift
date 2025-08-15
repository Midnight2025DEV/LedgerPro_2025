import Foundation
import SwiftUI

@MainActor
class ChatService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing = false
    @Published var isLoading = false
    @Published var currentProvider: AIProvider?
    
    private let apiService = AITransactionService()
    
    init() {
        // Initialize with first available provider
        currentProvider = AIProvider.allCases.first
    }
    
    func sendMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(content: content, isFromUser: true)
        messages.append(userMessage)
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Simple echo response for now
            let response = "I received your message: \(content)"
            let assistantMessage = ChatMessage(
                content: response,
                isFromUser: false,
                provider: currentProvider?.rawValue,
                model: currentProvider?.defaultModel
            )
            messages.append(assistantMessage)
        } catch {
            let errorMessage = ChatMessage(
                content: "Sorry, I encountered an error: \(error.localizedDescription)",
                isFromUser: false
            )
            messages.append(errorMessage)
        }
    }
    
    func setProvider(_ provider: AIProvider) {
        currentProvider = provider
    }
    
    func clearMessages() {
        messages.removeAll()
    }
}