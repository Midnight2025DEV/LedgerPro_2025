import SwiftUI
import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case anthropic = "Anthropic (Claude)"
    case groq = "Groq"
    case cohere = "Cohere"
    case mistral = "Mistral AI"
    case huggingface = "Hugging Face"
    case ollama = "Ollama (Local)"
    case azure = "Azure OpenAI"
    case google = "Google AI"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .openai: return "brain.head.profile"
        case .anthropic: return "bubble.left.and.bubble.right"
        case .groq: return "bolt.fill"
        case .cohere: return "waveform"
        case .mistral: return "wind"
        case .huggingface: return "face.smiling"
        case .ollama: return "desktopcomputer"
        case .azure: return "cloud.fill"
        case .google: return "magnifyingglass"
        }
    }
    
    var placeholder: String {
        switch self {
        case .openai: return "sk-..."
        case .anthropic: return "sk-ant-..."
        case .groq: return "gsk_..."
        case .cohere: return "co-..."
        case .mistral: return "..."
        case .huggingface: return "hf_..."
        case .ollama: return "http://localhost:11434"
        case .azure: return "your-azure-key"
        case .google: return "AI..."
        }
    }
    
    var models: [String] {
        switch self {
        case .openai:
            return ["gpt-4o", "gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"]
        case .anthropic:
            return ["claude-3-5-sonnet-20241022", "claude-3-haiku-20240307", "claude-3-opus-20240229"]
        case .groq:
            return ["llama-3.1-8b-instant", "llama-3.1-70b-versatile", "mixtral-8x7b-32768"]
        case .cohere:
            return ["command-r", "command-r-plus", "command"]
        case .mistral:
            return ["mistral-large-latest", "mistral-small-latest", "codestral-latest"]
        case .huggingface:
            return ["meta-llama/Llama-2-7b-chat-hf", "microsoft/DialoGPT-medium", "google/flan-t5-large"]
        case .ollama:
            return ["llama3", "llama2", "codellama", "mistral", "phi3"]
        case .azure:
            return ["gpt-4", "gpt-35-turbo", "text-davinci-003"]
        case .google:
            return ["gemini-pro", "gemini-pro-vision", "palm-2"]
        }
    }
    
    var costInfo: String {
        switch self {
        case .openai:
            return "💰💰 Premium - GPT-4: ~$30/1M tokens, GPT-3.5: ~$1/1M"
        case .anthropic:
            return "💰💰💰 Premium - Claude-3: ~$15-75/1M tokens"
        case .groq:
            return "💰 Very Fast & Affordable - ~$0.27-2.80/1M tokens"
        case .cohere:
            return "💰 Competitive - ~$1-15/1M tokens"
        case .mistral:
            return "💰💰 Mid-range - ~$2-8/1M tokens"
        case .huggingface:
            return "💰 Variable - Free tier available, paid from $0.60/hour"
        case .ollama:
            return "🆓 FREE - Runs locally on your machine"
        case .azure:
            return "💰💰 Enterprise - Similar to OpenAI pricing"
        case .google:
            return "💰 Competitive - Gemini Pro: ~$0.50-7/1M tokens"
        }
    }
    
    var description: String {
        switch self {
        case .openai:
            return "Industry leader in conversational AI and GPT models"
        case .anthropic:
            return "High-quality, helpful, harmless, and honest AI"
        case .groq:
            return "Ultra-fast inference with competitive quality"
        case .cohere:
            return "Enterprise-focused language models"
        case .mistral:
            return "Open-source European AI with strong performance"
        case .huggingface:
            return "Open-source model hub with thousands of options"
        case .ollama:
            return "Run LLMs locally - completely private and free"
        case .azure:
            return "Microsoft's enterprise AI platform"
        case .google:
            return "Google's advanced multimodal AI models"
        }
    }
}

struct APIKeysSettingsView: View {
    @State private var selectedProvider: AIProvider = .openai
    @State private var apiKeys: [AIProvider: String] = [:]
    @State private var selectedModels: [AIProvider: String] = [:]
    @State private var isKeyVisible: Bool = false
    @State private var testResults: [AIProvider: TestResult] = [:]
    @State private var isTesting: Bool = false
    @State private var showingKeyHelp: Bool = false
    
    enum TestResult {
        case none, testing, success, failure(String)
        
        var color: Color {
            switch self {
            case .none: return .secondary
            case .testing: return .blue
            case .success: return .green
            case .failure: return .red
            }
        }
        
        var message: String {
            switch self {
            case .none: return "Not tested"
            case .testing: return "Testing..."
            case .success: return "✅ API key valid"
            case .failure(let error): return "❌ \(error)"
            }
        }
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose your preferred AI provider for enhanced financial analysis, transaction categorization, and PDF processing.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button("Get API Keys") {
                            showingKeyHelp = true
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Compare Providers") {
                            NSWorkspace.shared.open(URL(string: "https://artificialanalysis.ai/leaderboards/models")!)
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.blue)
                    }
                }
            } header: {
                Text("AI Services Configuration")
            }
            
            Section {
                Picker("AI Provider", selection: $selectedProvider) {
                    ForEach(AIProvider.allCases) { provider in
                        HStack {
                            Image(systemName: provider.icon)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(provider.rawValue)
                                    .fontWeight(.medium)
                                Text(provider.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tag(provider)
                    }
                }
                .pickerStyle(.menu)
                
                Text(selectedProvider.costInfo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Choose Provider")
            }
            
            Section {
                // API Key Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(selectedProvider.rawValue) API Key")
                        .fontWeight(.medium)
                    
                    HStack {
                        Group {
                            if isKeyVisible {
                                TextField(selectedProvider.placeholder, text: Binding(
                                    get: { apiKeys[selectedProvider] ?? "" },
                                    set: { apiKeys[selectedProvider] = $0 }
                                ))
                            } else {
                                SecureField(selectedProvider.placeholder, text: Binding(
                                    get: { apiKeys[selectedProvider] ?? "" },
                                    set: { apiKeys[selectedProvider] = $0 }
                                ))
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        
                        Button {
                            isKeyVisible.toggle()
                        } label: {
                            Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    Text(testResults[selectedProvider]?.message ?? "Not tested")
                        .font(.caption)
                        .foregroundColor(testResults[selectedProvider]?.color ?? .secondary)
                }
                
                // Model Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Model")
                        .fontWeight(.medium)
                    
                    Picker("Model", selection: Binding(
                        get: { selectedModels[selectedProvider] ?? selectedProvider.models.first ?? "" },
                        set: { selectedModels[selectedProvider] = $0 }
                    )) {
                        ForEach(selectedProvider.models, id: \.self) { model in
                            Text(model)
                                .tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if selectedProvider == .ollama {
                        Text("💡 Make sure Ollama is running locally with: ollama serve")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                // Test & Save Buttons
                HStack {
                    Button("Test Connection") {
                        testAPIKey()
                    }
                    .disabled((apiKeys[selectedProvider]?.isEmpty ?? true) || isTesting)
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Save Configuration") {
                        saveConfiguration()
                    }
                    .disabled(apiKeys[selectedProvider]?.isEmpty ?? true)
                    .buttonStyle(.borderedProminent)
                }
            } header: {
                Text("\(selectedProvider.rawValue) Configuration")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("AI Features Status")
                            .fontWeight(.medium)
                        Spacer()
                        statusIndicator
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        featureRow("Smart Categorization", enabled: hasValidKey())
                        featureRow("Financial Analysis", enabled: hasValidKey())
                        featureRow("Enhanced PDF Processing", enabled: hasValidKey())
                        featureRow("Bank Detection", enabled: hasValidKey())
                    }
                }
            } header: {
                Text("Feature Status")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 **Cost Optimization Tips:**")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("• Use gpt-3.5-turbo for basic categorization (~90% cheaper)")
                    Text("• Use gpt-4-turbo for complex financial analysis")  
                    Text("• Lower max tokens (1000) to reduce costs")
                    Text("• API usage is only charged when AI features are used")
                        .foregroundColor(.blue)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            } header: {
                Text("Cost Information")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("API Keys")
        .onAppear {
            loadConfiguration()
        }
        .sheet(isPresented: $showingKeyHelp) {
            APIKeyHelpView()
        }
    }
    
    // MARK: - Views
    
    private var statusIndicator: some View {
        HStack {
            Circle()
                .fill(hasValidKey() ? .green : .red)
                .frame(width: 8, height: 8)
            Text(hasValidKey() ? "Active" : "Not Configured")
                .font(.caption)
                .foregroundColor(hasValidKey() ? .green : .red)
        }
    }
    
    private func featureRow(_ feature: String, enabled: Bool) -> some View {
        HStack {
            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(enabled ? .green : .red)
            Text(feature)
                .font(.caption)
            Spacer()
        }
    }
    
    // MARK: - Functions
    
    private func hasValidKey() -> Bool {
        guard let key = apiKeys[selectedProvider], !key.isEmpty else { return false }
        
        switch selectedProvider {
        case .openai: return key.hasPrefix("sk-")
        case .anthropic: return key.hasPrefix("sk-ant-")
        case .groq: return key.hasPrefix("gsk_")
        case .cohere: return key.hasPrefix("co-")
        case .huggingface: return key.hasPrefix("hf_")
        case .ollama: return true // Local service, no key validation needed
        case .mistral, .azure, .google: return !key.isEmpty
        }
    }
    
    private func testAPIKey() {
        guard let apiKey = apiKeys[selectedProvider], !apiKey.isEmpty else { return }
        
        isTesting = true
        testResults[selectedProvider] = .testing
        
        Task {
            do {
                let success = try await testProviderConnection(provider: selectedProvider, apiKey: apiKey)
                await MainActor.run {
                    testResults[selectedProvider] = success ? .success : .failure("Invalid API key")
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResults[selectedProvider] = .failure(error.localizedDescription)
                    isTesting = false
                }
            }
        }
    }
    
    private func testProviderConnection(provider: AIProvider, apiKey: String) async throws -> Bool {
        switch provider {
        case .openai:
            let url = URL(string: "https://api.openai.com/v1/models")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
            
        case .anthropic:
            let url = URL(string: "https://api.anthropic.com/v1/messages")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode != 401
            
        case .groq:
            let url = URL(string: "https://api.groq.com/openai/v1/models")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
            
        case .ollama:
            let url = URL(string: "\(apiKey)/api/tags")! // apiKey is the base URL for Ollama
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
            
        case .cohere:
            let url = URL(string: "https://api.cohere.ai/v1/models")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
            
        case .huggingface:
            let url = URL(string: "https://api-inference.huggingface.co/models")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
            
        default:
            // For other providers, just check if key exists
            return !apiKey.isEmpty
        }
    }
    
    private func saveConfiguration() {
        guard let apiKey = apiKeys[selectedProvider], !apiKey.isEmpty else { return }
        
        // Generate environment content for all providers
        var envContent = "# AI Provider Configuration\n"
        envContent += "AI_PROVIDER=\(selectedProvider.rawValue.lowercased().replacingOccurrences(of: " ", with: "_"))\n"
        
        // Add provider-specific configuration
        switch selectedProvider {
        case .openai:
            envContent += "OPENAI_API_KEY=\(apiKey)\n"
            envContent += "OPENAI_MODEL=\(selectedModels[selectedProvider] ?? "gpt-4-turbo")\n"
        case .anthropic:
            envContent += "ANTHROPIC_API_KEY=\(apiKey)\n"
            envContent += "ANTHROPIC_MODEL=\(selectedModels[selectedProvider] ?? "claude-3-5-sonnet-20241022")\n"
        case .groq:
            envContent += "GROQ_API_KEY=\(apiKey)\n"
            envContent += "GROQ_MODEL=\(selectedModels[selectedProvider] ?? "llama-3.1-8b-instant")\n"
        case .ollama:
            envContent += "OLLAMA_BASE_URL=\(apiKey)\n"
            envContent += "OLLAMA_MODEL=\(selectedModels[selectedProvider] ?? "llama3")\n"
        case .cohere:
            envContent += "COHERE_API_KEY=\(apiKey)\n"
            envContent += "COHERE_MODEL=\(selectedModels[selectedProvider] ?? "command-r")\n"
        case .huggingface:
            envContent += "HUGGINGFACE_API_KEY=\(apiKey)\n"
            envContent += "HUGGINGFACE_MODEL=\(selectedModels[selectedProvider] ?? "meta-llama/Llama-2-7b-chat-hf")\n"
        case .mistral:
            envContent += "MISTRAL_API_KEY=\(apiKey)\n"
            envContent += "MISTRAL_MODEL=\(selectedModels[selectedProvider] ?? "mistral-large-latest")\n"
        case .azure:
            envContent += "AZURE_OPENAI_KEY=\(apiKey)\n"
            envContent += "AZURE_OPENAI_MODEL=\(selectedModels[selectedProvider] ?? "gpt-4")\n"
        case .google:
            envContent += "GOOGLE_API_KEY=\(apiKey)\n"
            envContent += "GOOGLE_MODEL=\(selectedModels[selectedProvider] ?? "gemini-pro")\n"
        }
        
        envContent += "\n# General AI Configuration\n"
        envContent += "AI_TEMPERATURE=0.7\n"
        envContent += "AI_MAX_TOKENS=2000\n"
        
        let envPath = getMCPServicePath().appendingPathComponent(".env")
        
        do {
            try envContent.write(to: envPath, atomically: true, encoding: .utf8)
            
            // Save to UserDefaults for app use
            UserDefaults.standard.set(selectedProvider.rawValue, forKey: "selected_ai_provider")
            UserDefaults.standard.set(apiKey, forKey: "\(selectedProvider.rawValue.lowercased())_api_key")
            UserDefaults.standard.set(selectedModels[selectedProvider], forKey: "\(selectedProvider.rawValue.lowercased())_model")
            
            // Show success feedback
            testResults[selectedProvider] = .success
            
        } catch {
            testResults[selectedProvider] = .failure("Failed to save configuration")
        }
    }
    
    private func loadConfiguration() {
        // Load selected provider
        if let providerString = UserDefaults.standard.string(forKey: "selected_ai_provider"),
           let provider = AIProvider.allCases.first(where: { $0.rawValue == providerString }) {
            selectedProvider = provider
        }
        
        // Load all API keys and models from UserDefaults
        for provider in AIProvider.allCases {
            let providerKey = "\(provider.rawValue.lowercased())_api_key"
            let modelKey = "\(provider.rawValue.lowercased())_model"
            
            apiKeys[provider] = UserDefaults.standard.string(forKey: providerKey) ?? ""
            selectedModels[provider] = UserDefaults.standard.string(forKey: modelKey) ?? provider.models.first ?? ""
        }
        
        // Try to load from .env file as fallback
        let envPath = getMCPServicePath().appendingPathComponent(".env")
        if let envContent = try? String(contentsOf: envPath) {
            let lines = envContent.components(separatedBy: .newlines)
            
            for line in lines {
                if line.hasPrefix("OPENAI_API_KEY=") && (apiKeys[.openai]?.isEmpty ?? true) {
                    apiKeys[.openai] = String(line.dropFirst("OPENAI_API_KEY=".count))
                } else if line.hasPrefix("ANTHROPIC_API_KEY=") && (apiKeys[.anthropic]?.isEmpty ?? true) {
                    apiKeys[.anthropic] = String(line.dropFirst("ANTHROPIC_API_KEY=".count))
                } else if line.hasPrefix("GROQ_API_KEY=") && (apiKeys[.groq]?.isEmpty ?? true) {
                    apiKeys[.groq] = String(line.dropFirst("GROQ_API_KEY=".count))
                }
                // Add more providers as needed
            }
        }
    }
    
    private func getMCPServicePath() -> URL {
        let bundle = Bundle.main.bundleURL
        return bundle
            .appendingPathComponent("Contents")
            .appendingPathComponent("Resources")
            .appendingPathComponent("mcp-servers")
            .appendingPathComponent("openai-service")
    }
}

// MARK: - Help View

struct APIKeyHelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How to Get API Keys")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Provider-specific instructions
                    ForEach(AIProvider.allCases) { provider in
                        providerInstructions(for: provider)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Security Notes")
                            .font(.headline)
                        
                        Text("• Your API key is stored locally and never shared")
                        Text("• You control your OpenAI usage and billing")
                        Text("• You can revoke the key anytime from OpenAI dashboard")
                        Text("• LedgerPro only uses AI when you explicitly use AI features")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cost Comparison")
                            .font(.headline)
                        
                        Text("🆓 **FREE**: Ollama (local)")
                        Text("💰 **Budget**: Groq (~$0.27/1M tokens)")
                        Text("💰💰 **Balanced**: OpenAI GPT-3.5 (~$1/1M tokens)")
                        Text("💰💰💰 **Premium**: OpenAI GPT-4, Claude (~$15-30/1M)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("API Key Setup")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func providerInstructions(for provider: AIProvider) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: provider.icon)
                Text(provider.rawValue)
                    .fontWeight(.bold)
            }
            .font(.headline)
            
            Text(getInstructionsText(for: provider))
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let url = getProviderURL(for: provider) {
                Button("Get \(provider.rawValue) API Key") {
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.bottom, 8)
    }
    
    private func getInstructionsText(for provider: AIProvider) -> String {
        switch provider {
        case .openai:
            return "Go to platform.openai.com → API Keys → Create new secret key"
        case .anthropic:
            return "Go to console.anthropic.com → API Keys → Create Key"
        case .groq:
            return "Go to console.groq.com → API Keys → Create API Key"
        case .cohere:
            return "Go to dashboard.cohere.ai → API Keys → Create New Key"
        case .mistral:
            return "Go to console.mistral.ai → API Keys → Create new key"
        case .huggingface:
            return "Go to huggingface.co → Settings → Access Tokens → Create new token"
        case .ollama:
            return "Install Ollama locally, then run 'ollama serve'. No API key needed!"
        case .azure:
            return "Go to Azure Portal → AI Services → Create OpenAI resource → Keys and Endpoint"
        case .google:
            return "Go to console.cloud.google.com → AI Platform → Create API Key"
        }
    }
    
    private func getProviderURL(for provider: AIProvider) -> URL? {
        switch provider {
        case .openai:
            return URL(string: "https://platform.openai.com/api-keys")
        case .anthropic:
            return URL(string: "https://console.anthropic.com/")
        case .groq:
            return URL(string: "https://console.groq.com/keys")
        case .cohere:
            return URL(string: "https://dashboard.cohere.ai/api-keys")
        case .mistral:
            return URL(string: "https://console.mistral.ai/")
        case .huggingface:
            return URL(string: "https://huggingface.co/settings/tokens")
        case .ollama:
            return URL(string: "https://ollama.ai/download")
        case .azure:
            return URL(string: "https://portal.azure.com/")
        case .google:
            return URL(string: "https://console.cloud.google.com/")
        }
    }
    
}

#Preview {
    APIKeysSettingsView()
}