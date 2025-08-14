import SwiftUI
import Foundation

struct APIKeysSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedProvider: AIProvider = .openai
    @State private var apiKeys: [AIProvider: String] = [:]
    @State private var selectedModels: [AIProvider: String] = [:]
    @State private var isKeyVisible: Bool = false
    @State private var testResults: [AIProvider: TestResult] = [:]
    @State private var isTesting: Bool = false
    @State private var showingKeyHelp: Bool = false
    @State private var configurationSaved: Bool = false
    
    // Computed property to check if any AI provider is configured
    private var isAnyProviderConfigured: Bool {
        hasValidKey()
    }
    
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
        NavigationView {
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
                                    set: { newValue in
                                        // Clean the input to prevent corruption
                                        let cleanedValue = cleanAPIKey(newValue)
                                        apiKeys[selectedProvider] = cleanedValue
                                    }
                                ))
                            } else {
                                SecureField(selectedProvider.placeholder, text: Binding(
                                    get: { apiKeys[selectedProvider] ?? "" },
                                    set: { newValue in
                                        // Clean the input to prevent corruption
                                        let cleanedValue = cleanAPIKey(newValue)
                                        apiKeys[selectedProvider] = cleanedValue
                                    }
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
                        featureRow("Smart Categorization", enabled: isAnyProviderConfigured)
                        featureRow("Financial Analysis", enabled: isAnyProviderConfigured)
                        featureRow("Enhanced PDF Processing", enabled: isAnyProviderConfigured)
                        featureRow("Bank Detection", enabled: isAnyProviderConfigured)
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
        .navigationTitle("API Keys Configuration")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    saveConfiguration()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            loadConfiguration()
        }
        .onExitCommand {
            dismiss()
        }
        .sheet(isPresented: $showingKeyHelp) {
            APIKeyHelpView()
        }
        }
    }
    
    // MARK: - Views
    
    private var statusIndicator: some View {
        HStack {
            Circle()
                .fill(isAnyProviderConfigured ? .green : .red)
                .frame(width: 8, height: 8)
            Text(isAnyProviderConfigured ? "Active" : "Not Configured")
                .font(.caption)
                .foregroundColor(isAnyProviderConfigured ? .green : .red)
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
    
    private func isProviderConfigured(_ provider: AIProvider) -> Bool {
        // Check in-memory state first
        if let key = apiKeys[provider], !key.isEmpty {
            switch provider {
            case .openai: return key.hasPrefix("sk-")
            case .anthropic: return key.hasPrefix("sk-ant-")
            case .groq: return key.hasPrefix("gsk_")
            case .cohere: return key.hasPrefix("co-")
            case .huggingface: return key.hasPrefix("hf_")
            case .ollama: return true
            case .mistral, .azure, .google: return !key.isEmpty
            }
        }
        
        // Check UserDefaults
        let providerKey = "\(provider.userDefaultsKey)_api_key"
        if let savedKey = UserDefaults.standard.string(forKey: providerKey), !savedKey.isEmpty {
            switch provider {
            case .openai: return savedKey.hasPrefix("sk-")
            case .anthropic: return savedKey.hasPrefix("sk-ant-")
            case .groq: return savedKey.hasPrefix("gsk_")
            case .cohere: return savedKey.hasPrefix("co-")
            case .huggingface: return savedKey.hasPrefix("hf_")
            case .ollama: return true
            case .mistral, .azure, .google: return !savedKey.isEmpty
            }
        }
        
        return false
    }
    
    // MARK: - Functions
    
    private func hasValidKey() -> Bool {
        // Check if ANY provider has been configured
        for provider in AIProvider.allCases {
            if let key = apiKeys[provider], !key.isEmpty {
                switch provider {
                case .openai: 
                    if key.hasPrefix("sk-") { return true }
                case .anthropic: 
                    if key.hasPrefix("sk-ant-") { return true }
                case .groq: 
                    if key.hasPrefix("gsk_") { return true }
                case .cohere: 
                    if key.hasPrefix("co-") { return true }
                case .huggingface: 
                    if key.hasPrefix("hf_") { return true }
                case .ollama: 
                    return true // Local service, no key validation needed
                case .mistral, .azure, .google: 
                    if !key.isEmpty { return true }
                }
            }
        }
        
        // Also check UserDefaults for saved configuration
        if let savedProvider = UserDefaults.standard.string(forKey: "selected_ai_provider"),
           let provider = AIProvider.allCases.first(where: { $0.rawValue == savedProvider }) {
            let providerKey = "\(provider.userDefaultsKey)_api_key"
            if let savedKey = UserDefaults.standard.string(forKey: providerKey), !savedKey.isEmpty {
                switch provider {
                case .openai: return savedKey.hasPrefix("sk-")
                case .anthropic: return savedKey.hasPrefix("sk-ant-")
                case .groq: return savedKey.hasPrefix("gsk_")
                case .cohere: return savedKey.hasPrefix("co-")
                case .huggingface: return savedKey.hasPrefix("hf_")
                case .ollama: return true
                case .mistral, .azure, .google: return !savedKey.isEmpty
                }
            }
        }
        
        return false
    }
    
    private func testAPIKey() {
        guard let rawApiKey = apiKeys[selectedProvider], !rawApiKey.isEmpty else { return }
        
        // Clean and validate the API key
        let apiKey = cleanAPIKey(rawApiKey)
        
        // Validate key format
        if !isValidAPIKeyFormat(apiKey, for: selectedProvider) {
            testResults[selectedProvider] = .failure("Invalid API key format for \(selectedProvider.rawValue)")
            return
        }
        
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
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
        guard let rawApiKey = apiKeys[selectedProvider], !rawApiKey.isEmpty else { return }
        
        // Clean and validate the API key
        let apiKey = cleanAPIKey(rawApiKey)
        
        // Validate key format before saving
        if !isValidAPIKeyFormat(apiKey, for: selectedProvider) {
            testResults[selectedProvider] = .failure("Invalid API key format for \(selectedProvider.rawValue)")
            print("❌ API key validation failed for \(selectedProvider.rawValue): Invalid format")
            return
        }
        
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
            // Ensure directory exists
            let directory = envPath.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory,
                                                  withIntermediateDirectories: true,
                                                  attributes: nil)
            
            // Write .env file
            try envContent.write(to: envPath, atomically: true, encoding: .utf8)
            
            // Save to UserDefaults for app use
            UserDefaults.standard.set(selectedProvider.rawValue, forKey: "selected_ai_provider")
            UserDefaults.standard.set(apiKey, forKey: "\(selectedProvider.userDefaultsKey)_api_key")
            UserDefaults.standard.set(selectedModels[selectedProvider], forKey: "\(selectedProvider.userDefaultsKey)_model")
            
            // Force synchronize UserDefaults
            UserDefaults.standard.synchronize()
            
            // Update the in-memory state to ensure UI reflects the saved state
            apiKeys[selectedProvider] = apiKey
            
            // Show success feedback
            testResults[selectedProvider] = .success
            
            // Force UI update
            configurationSaved = true
            
            // Log success
            print("✅ API configuration saved successfully")
            print("   Provider: \(selectedProvider.rawValue)")
            print("   .env path: \(envPath.path)")
            print("   UserDefaults keys saved")
            
        } catch {
            testResults[selectedProvider] = .failure("Failed to save: \(error.localizedDescription)")
            print("❌ Failed to save API configuration: \(error)")
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
            let providerKey = "\(provider.userDefaultsKey)_api_key"
            let modelKey = "\(provider.userDefaultsKey)_model"
            
            if let savedKey = UserDefaults.standard.string(forKey: providerKey), !savedKey.isEmpty {
                let cleanedKey = cleanAPIKey(savedKey)
                apiKeys[provider] = cleanedKey
                print("📥 Loaded API key for \(provider.rawValue): \(cleanedKey.prefix(10))...")
                
                // Warn if we had to clean the key
                if cleanedKey != savedKey {
                    print("⚠️  API key was cleaned for \(provider.rawValue) - original had corrupted content")
                    // Re-save the cleaned key
                    UserDefaults.standard.set(cleanedKey, forKey: providerKey)
                    UserDefaults.standard.synchronize()
                }
            }
            
            if let savedModel = UserDefaults.standard.string(forKey: modelKey), !savedModel.isEmpty {
                selectedModels[provider] = savedModel
            } else {
                selectedModels[provider] = provider.models.first ?? ""
            }
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
        // Check if we're in development or production
        if Bundle.main.bundlePath.contains(".app") {
            // Production: Use Application Support directory
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory,
                                                        in: .userDomainMask).first {
                let ledgerProDir = appSupport
                    .appendingPathComponent("LedgerPro")
                    .appendingPathComponent("mcp-servers")
                    .appendingPathComponent("openai-service")
                
                // Create directory if it doesn't exist
                try? FileManager.default.createDirectory(at: ledgerProDir,
                                                       withIntermediateDirectories: true)
                return ledgerProDir
            }
        }
        
        // Development: Use project directory
        let projectRoot = FileManager.default.currentDirectoryPath
        let devPaths = [
            URL(fileURLWithPath: projectRoot).appendingPathComponent("mcp-servers/openai-service"),
            URL(fileURLWithPath: projectRoot).appendingPathComponent("LedgerPro/mcp-servers/openai-service"),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents/Cursor_AI/LedgerPro_Main/LedgerPro/mcp-servers/openai-service")
        ]
        
        for path in devPaths {
            if FileManager.default.fileExists(atPath: path.path) {
                return path
            }
        }
        
        // Fallback to temp directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LedgerPro")
            .appendingPathComponent("mcp-servers")
            .appendingPathComponent("openai-service")
        
        try? FileManager.default.createDirectory(at: tempDir,
                                               withIntermediateDirectories: true)
        return tempDir
    }
    
    // MARK: - API Key Cleaning and Validation
    
    private func cleanAPIKey(_ rawKey: String) -> String {
        // Remove common corruption patterns
        let trimmed = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove known corruption prefixes
        let corruptionPrefixes = ["KEYFOCUS: ", "KEYFOCUS:", "DEBUG: ", "API_KEY: ", "Key: "]
        var cleaned = trimmed
        
        for prefix in corruptionPrefixes {
            if cleaned.hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                print("🧹 Removed corruption prefix '\(prefix)' from API key")
            }
        }
        
        // Remove any control characters or non-printable characters
        cleaned = cleaned.components(separatedBy: .controlCharacters).joined()
        
        // Final trim
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func isValidAPIKeyFormat(_ key: String, for provider: AIProvider) -> Bool {
        guard !key.isEmpty else { return false }
        
        switch provider {
        case .openai:
            return key.hasPrefix("sk-") && key.count > 10
        case .anthropic:
            return key.hasPrefix("sk-ant-") && key.count > 15
        case .groq:
            return key.hasPrefix("gsk_") && key.count > 10
        case .cohere:
            return key.hasPrefix("co-") && key.count > 10
        case .huggingface:
            return key.hasPrefix("hf_") && key.count > 10
        case .ollama:
            return key.contains(":") || key.hasPrefix("http") // URL format
        case .mistral, .azure, .google:
            return key.count > 5 // Basic length check
        }
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