import SwiftUI
import Foundation

struct APIKeysSettingsView: View {
    @State private var openAIKey: String = ""
    @State private var openAIModel: String = "gpt-4-turbo"
    @State private var isKeyVisible: Bool = false
    @State private var testResult: TestResult = .none
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
    
    let availableModels = [
        "gpt-3.5-turbo",
        "gpt-4",
        "gpt-4-turbo",
        "gpt-4o"
    ]
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enable AI-powered transaction categorization, financial analysis, and enhanced PDF processing.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button("Get OpenAI API Key") {
                            NSWorkspace.shared.open(URL(string: "https://platform.openai.com/api-keys")!)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Help") {
                            showingKeyHelp = true
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.blue)
                    }
                }
            } header: {
                Text("AI Services Configuration")
            }
            
            Section {
                // API Key Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("OpenAI API Key")
                        .fontWeight(.medium)
                    
                    HStack {
                        Group {
                            if isKeyVisible {
                                TextField("sk-...", text: $openAIKey)
                            } else {
                                SecureField("sk-...", text: $openAIKey)
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
                    
                    Text(testResult.message)
                        .font(.caption)
                        .foregroundColor(testResult.color)
                }
                
                // Model Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Model")
                        .fontWeight(.medium)
                    
                    Picker("Model", selection: $openAIModel) {
                        ForEach(availableModels, id: \.self) { model in
                            VStack(alignment: .leading) {
                                Text(model)
                                Text(modelDescription(model))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text(modelCostInfo(openAIModel))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Test & Save Buttons
                HStack {
                    Button("Test Connection") {
                        testAPIKey()
                    }
                    .disabled(openAIKey.isEmpty || isTesting)
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Save Configuration") {
                        saveConfiguration()
                    }
                    .disabled(openAIKey.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            } header: {
                Text("OpenAI Configuration")
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
        return !openAIKey.isEmpty && openAIKey.hasPrefix("sk-")
    }
    
    private func modelDescription(_ model: String) -> String {
        switch model {
        case "gpt-3.5-turbo":
            return "Fast, cost-effective"
        case "gpt-4":
            return "High quality, slower"
        case "gpt-4-turbo":
            return "Best balance of speed/quality"
        case "gpt-4o":
            return "Fastest GPT-4 model"
        default:
            return ""
        }
    }
    
    private func modelCostInfo(_ model: String) -> String {
        switch model {
        case "gpt-3.5-turbo":
            return "💰 Most cost-effective (~$0.001 per 1K tokens)"
        case "gpt-4":
            return "💰💰💰 Premium pricing (~$0.03 per 1K tokens)"
        case "gpt-4-turbo":
            return "💰💰 Balanced pricing (~$0.01 per 1K tokens)"
        case "gpt-4o":
            return "💰💰 Similar to GPT-4 Turbo pricing"
        default:
            return ""
        }
    }
    
    private func testAPIKey() {
        guard !openAIKey.isEmpty else { return }
        
        isTesting = true
        testResult = .testing
        
        Task {
            do {
                let success = try await testOpenAIConnection()
                await MainActor.run {
                    testResult = success ? .success : .failure("Invalid API key")
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = .failure(error.localizedDescription)
                    isTesting = false
                }
            }
        }
    }
    
    private func testOpenAIConnection() async throws -> Bool {
        // Simple test API call to validate the key
        let url = URL(string: "https://api.openai.com/v1/models")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode == 200
        }
        
        return false
    }
    
    private func saveConfiguration() {
        // Save to environment file for MCP servers
        let envContent = """
        # OpenAI API Configuration
        OPENAI_API_KEY=\(openAIKey)
        OPENAI_MODEL=\(openAIModel)
        OPENAI_TEMPERATURE=0.7
        OPENAI_MAX_TOKENS=2000
        
        # MCP Server Configuration
        MCP_SERVER_NAME=openai-service
        MCP_SERVER_VERSION=0.1.0
        """
        
        let envPath = getMCPServicePath().appendingPathComponent(".env")
        
        do {
            try envContent.write(to: envPath, atomically: true, encoding: .utf8)
            
            // Also save to UserDefaults for app use
            UserDefaults.standard.set(openAIKey, forKey: "openai_api_key")
            UserDefaults.standard.set(openAIModel, forKey: "openai_model")
            
            // Show success feedback
            testResult = .success
            
        } catch {
            testResult = .failure("Failed to save configuration")
        }
    }
    
    private func loadConfiguration() {
        // Load from UserDefaults
        openAIKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        openAIModel = UserDefaults.standard.string(forKey: "openai_model") ?? "gpt-4-turbo"
        
        // Try to load from .env file
        let envPath = getMCPServicePath().appendingPathComponent(".env")
        if let envContent = try? String(contentsOf: envPath) {
            if let keyLine = envContent.components(separatedBy: .newlines).first(where: { $0.hasPrefix("OPENAI_API_KEY=") }) {
                let key = String(keyLine.dropFirst("OPENAI_API_KEY=".count))
                if !key.isEmpty && openAIKey.isEmpty {
                    openAIKey = key
                }
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
                    Text("How to Get Your OpenAI API Key")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Group {
                        stepView(
                            number: 1,
                            title: "Visit OpenAI Platform",
                            description: "Go to platform.openai.com and sign in or create an account"
                        )
                        
                        stepView(
                            number: 2,
                            title: "Navigate to API Keys",
                            description: "Click on 'API Keys' in the left sidebar"
                        )
                        
                        stepView(
                            number: 3,
                            title: "Create New Key",
                            description: "Click 'Create new secret key' and give it a name"
                        )
                        
                        stepView(
                            number: 4,
                            title: "Copy & Save",
                            description: "Copy the key (starts with 'sk-') and paste it above. Store it securely!"
                        )
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
                        Text("Cost Estimates")
                            .font(.headline)
                        
                        Text("• Processing 100 transactions: ~$0.10 with GPT-3.5")
                        Text("• Processing 100 transactions: ~$1.00 with GPT-4")
                        Text("• PDF analysis: ~$0.05-0.20 per document")
                        Text("• Monthly usage for active user: ~$2-10")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("API Key Help")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func stepView(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(.blue))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    APIKeysSettingsView()
}