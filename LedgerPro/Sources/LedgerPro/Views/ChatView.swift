import SwiftUI

struct ChatView: View {
    @StateObject private var chatService = ChatService()
    @State private var currentSession = ChatSession()
    @State private var messageText = ""
    @State private var showingSettings = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Messages
            messagesView
            
            // Input area
            inputView
        }
        .navigationTitle("AI Chat")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            APIKeysSettingsView()
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentSession.title)
                        .font(.headline)
                    Text(providerInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button("New Chat") {
                    startNewChat()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var messagesView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if currentSession.messages.isEmpty {
                    emptyStateView
                } else {
                    ForEach(currentSession.messages) { message in
                        MessageBubbleView(message: message)
                    }
                }
                
                if chatService.isLoading {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Thinking...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .background(Color(NSColor.textBackgroundColor))
    }
    
    private var inputView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField("Ask me anything about your finances...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.isEmpty ? .secondary : .accentColor)
                }
                .disabled(messageText.isEmpty || chatService.isLoading)
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Start a conversation")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Ask questions about your finances, get insights, or chat about anything!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Try asking:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                ForEach(sampleQuestions, id: \.self) { question in
                    Button(question) {
                        messageText = question
                        isTextFieldFocused = true
                        sendMessage()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .frame(maxWidth: 400)
        .padding(.top, 60)
    }
    
    private var providerInfo: String {
        let provider = getCurrentProvider()
        let model = getCurrentModel()
        
        if let provider = provider, let model = model {
            return "Using \(provider.rawValue) • \(model)"
        } else {
            return "No AI provider configured"
        }
    }
    
    private let sampleQuestions = [
        "What were my biggest expenses last month?",
        "How can I improve my spending habits?",
        "Show me my transaction patterns",
        "Help me create a budget"
    ]
    
    // MARK: - Functions
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(
            content: messageText,
            isFromUser: true,
            provider: getCurrentProvider()?.rawValue,
            model: getCurrentModel()
        )
        
        currentSession.addMessage(userMessage)
        let messageToSend = messageText
        messageText = ""
        
        Task {
            do {
                let response = try await chatService.sendMessage(messageToSend)
                
                await MainActor.run {
                    let aiMessage = ChatMessage(
                        content: response,
                        isFromUser: false,
                        provider: getCurrentProvider()?.rawValue,
                        model: getCurrentModel()
                    )
                    currentSession.addMessage(aiMessage)
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        content: "Sorry, I encountered an error: \(error.localizedDescription)",
                        isFromUser: false
                    )
                    currentSession.addMessage(errorMessage)
                }
            }
        }
    }
    
    private func startNewChat() {
        currentSession = ChatSession()
    }
    
    private func getCurrentProvider() -> AIProvider? {
        for provider in AIProvider.allCases {
            let key = "\(provider.userDefaultsKey)_api_key"
            if let apiKey = UserDefaults.standard.string(forKey: key), !apiKey.isEmpty {
                return provider
            }
        }
        return nil
    }
    
    private func getCurrentModel() -> String? {
        guard let provider = getCurrentProvider() else { return nil }
        let key = "\(provider.userDefaultsKey)_model"
        return UserDefaults.standard.string(forKey: key) ?? provider.models.first
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Text(message.timestamp.formatted(.dateTime.hour().minute()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if let provider = message.provider {
                            Text(provider)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(message.content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Text(message.timestamp.formatted(.dateTime.hour().minute()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationView {
        ChatView()
    }
}