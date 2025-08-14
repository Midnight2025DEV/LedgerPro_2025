import Foundation

class ChatService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    
    func sendMessage(_ message: String) async throws -> String {
        // Get current AI provider configuration
        guard let provider = getCurrentProvider(),
              let apiKey = getAPIKey(for: provider),
              let model = getModel(for: provider) else {
            throw ChatError.noConfiguration
        }
        
        // Debug logging
        print("ChatService: Using provider: \(provider.rawValue)")
        print("ChatService: Using model: \(model)")
        print("ChatService: API key present: \(apiKey.isEmpty ? "NO" : "YES")")
        
        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            let response = try await makeAPIRequest(
                message: message,
                provider: provider,
                apiKey: apiKey,
                model: model
            )
            return response
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    private func getCurrentProvider() -> AIProvider? {
        // Check which provider has a valid API key
        for provider in AIProvider.allCases {
            if let _ = getAPIKey(for: provider) {
                return provider
            }
        }
        return nil
    }
    
    private func getAPIKey(for provider: AIProvider) -> String? {
        let key = "\(provider.userDefaultsKey)_api_key"
        if let apiKey = userDefaults.string(forKey: key), !apiKey.isEmpty {
            // Clean the API key to remove any corruption
            let cleanedKey = cleanAPIKey(apiKey)
            print("ChatService: Retrieved API key for \(provider.rawValue) with key '\(key)' - original length: \(apiKey.count), cleaned length: \(cleanedKey.count)")
            
            // If the key was corrupted, save the cleaned version
            if cleanedKey != apiKey {
                print("🧹 API key was corrupted for \(provider.rawValue), saving cleaned version")
                userDefaults.set(cleanedKey, forKey: key)
                userDefaults.synchronize()
            }
            
            // Validate key format
            if !isValidAPIKeyFormat(cleanedKey, for: provider) {
                print("❌ Invalid API key format for \(provider.rawValue). Key starts with: '\(String(cleanedKey.prefix(8)))...'")
                return nil
            }
            
            return cleanedKey
        }
        return nil
    }
    
    private func getModel(for provider: AIProvider) -> String? {
        let key = "\(provider.userDefaultsKey)_model"
        return userDefaults.string(forKey: key) ?? provider.models.first
    }
    
    private func makeAPIRequest(message: String, provider: AIProvider, apiKey: String, model: String) async throws -> String {
        switch provider {
        case .openai:
            return try await callOpenAI(message: message, apiKey: apiKey, model: model)
        case .anthropic:
            return try await callAnthropic(message: message, apiKey: apiKey, model: model)
        case .groq:
            return try await callGroq(message: message, apiKey: apiKey, model: model)
        case .cohere:
            return try await callCohere(message: message, apiKey: apiKey, model: model)
        default:
            throw ChatError.unsupportedProvider(provider.rawValue)
        }
    }
    
    // MARK: - API Implementations
    
    private func callOpenAI(message: String, apiKey: String, model: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": message]
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ChatError.apiError("OpenAI API request failed")
        }
        
        let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return result.choices.first?.message.content ?? "No response"
    }
    
    private func callAnthropic(message: String, apiKey: String, model: String) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let payload: [String: Any] = [
            "model": model,
            "max_tokens": 2000,
            "messages": [
                ["role": "user", "content": message]
            ]
        ]
        
        print("Anthropic API - Model: \(model)")
        print("Anthropic API - API Key prefix: \(String(apiKey.prefix(10)))...")
        print("Anthropic API - API Key length: \(apiKey.count)")
        print("Anthropic API - API Key has sk-ant- prefix: \(apiKey.hasPrefix("sk-ant-"))")
        print("Anthropic API - API Key trimmed length: \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).count)")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.apiError("Invalid response from Anthropic API")
        }
        
        if httpResponse.statusCode != 200 {
            // Log the response for debugging
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("Anthropic API Error Response (\(httpResponse.statusCode)): \(responseString)")
            
            // Try to decode error message
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String,
               let errorType = error["type"] as? String {
                throw ChatError.apiError("Anthropic API error (\(errorType)): \(message)")
            }
            throw ChatError.apiError("Anthropic API request failed with status \(httpResponse.statusCode). Response: \(responseString)")
        }
        
        let result = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        return result.content.first?.text ?? "No response"
    }
    
    private func callGroq(message: String, apiKey: String, model: String) async throws -> String {
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": message]
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ChatError.apiError("Groq API request failed")
        }
        
        let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return result.choices.first?.message.content ?? "No response"
    }
    
    private func callCohere(message: String, apiKey: String, model: String) async throws -> String {
        let url = URL(string: "https://api.cohere.ai/v1/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": model,
            "prompt": message,
            "max_tokens": 2000,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ChatError.apiError("Cohere API request failed")
        }
        
        let result = try JSONDecoder().decode(CohereResponse.self, from: data)
        return result.generations.first?.text ?? "No response"
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

// MARK: - Error Types

enum ChatError: LocalizedError {
    case noConfiguration
    case unsupportedProvider(String)
    case apiError(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .noConfiguration:
            return "No AI provider configured. Please set up an API key in Settings."
        case .unsupportedProvider(let provider):
            return "Provider \(provider) is not yet supported for chat."
        case .apiError(let message):
            return "API Error: \(message)"
        case .networkError:
            return "Network connection error."
        }
    }
}

// MARK: - Response Models

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

struct OpenAIMessage: Codable {
    let content: String
}

struct AnthropicResponse: Codable {
    let content: [AnthropicContent]
}

struct AnthropicContent: Codable {
    let text: String
}

struct CohereResponse: Codable {
    let generations: [CohereGeneration]
}

struct CohereGeneration: Codable {
    let text: String
}