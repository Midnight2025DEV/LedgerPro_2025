import Foundation

enum AIProvider: String, CaseIterable {
    case openai = "openai"
    case anthropic = "anthropic" 
    case google = "google"
    case ollama = "ollama"
    
    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .google: return "Google"
        case .ollama: return "Ollama"
        }
    }
    
    var userDefaultsKey: String {
        return rawValue
    }
    
    var defaultModel: String {
        switch self {
        case .openai: return "gpt-3.5-turbo"
        case .anthropic: return "claude-3-haiku-20240307"
        case .google: return "gemini-pro"
        case .ollama: return "llama2"
        }
    }
    
    var costInfo: String {
        switch self {
        case .openai:
            return "GPT-4, GPT-3.5 Turbo - Advanced language models"
        case .anthropic:
            return "Claude 3 - Haiku, Sonnet, Opus models available"
        case .google:
            return "Gemini Pro - Google's latest language model"
        case .ollama:
            return "Local models - Run entirely on your device"
        }
    }
}