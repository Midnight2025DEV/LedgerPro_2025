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
    
    // Consistent key generation for UserDefaults
    var userDefaultsKey: String {
        switch self {
        case .openai: return "openai"
        case .anthropic: return "anthropic"
        case .groq: return "groq"
        case .cohere: return "cohere"
        case .mistral: return "mistral"
        case .huggingface: return "huggingface"
        case .ollama: return "ollama"
        case .azure: return "azure"
        case .google: return "google"
        }
    }
    
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
            return ["claude-3-5-sonnet-20241022", "claude-3-5-haiku-20241022", "claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307", "claude-2.1", "claude-2.0"]
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
            return "💰💰💰 Premium - Claude 3.5 Sonnet: ~$3-15/1M, Opus: ~$15-75/1M tokens"
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