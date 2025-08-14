#!/usr/bin/env swift

import Foundation

// Utility script to clean up corrupted API keys in UserDefaults
// Run this if you suspect your API keys have been corrupted

enum AIProvider: String, CaseIterable {
    case openai = "OpenAI"
    case anthropic = "Anthropic (Claude)"
    case groq = "Groq"
    case cohere = "Cohere"
    case mistral = "Mistral AI"
    case huggingface = "Hugging Face"
    case ollama = "Ollama (Local)"
    case azure = "Azure OpenAI"
    case google = "Google AI"
    
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
}

func cleanAPIKey(_ rawKey: String) -> String {
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

func isValidAPIKeyFormat(_ key: String, for provider: AIProvider) -> Bool {
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

print("🧹 Cleaning up corrupted API keys...")

let userDefaults = UserDefaults.standard
var cleanedCount = 0

for provider in AIProvider.allCases {
    let keyName = "\(provider.userDefaultsKey)_api_key"
    
    if let savedKey = userDefaults.string(forKey: keyName), !savedKey.isEmpty {
        let cleanedKey = cleanAPIKey(savedKey)
        
        if cleanedKey != savedKey {
            print("🔧 Cleaning corrupted key for \(provider.rawValue)")
            print("   Original: \(savedKey.prefix(20))...")
            print("   Cleaned:  \(cleanedKey.prefix(20))...")
            
            if isValidAPIKeyFormat(cleanedKey, for: provider) {
                userDefaults.set(cleanedKey, forKey: keyName)
                cleanedCount += 1
                print("   ✅ Key cleaned and saved")
            } else {
                print("   ❌ Cleaned key is still invalid - you may need to re-enter it")
            }
        } else if isValidAPIKeyFormat(cleanedKey, for: provider) {
            print("✅ Key for \(provider.rawValue) is already clean and valid")
        } else {
            print("⚠️  Key for \(provider.rawValue) appears to be invalid")
        }
    }
}

userDefaults.synchronize()

if cleanedCount > 0 {
    print("\n🎉 Cleaned \(cleanedCount) corrupted API key(s)")
    print("Please restart LedgerPro to use the cleaned keys")
} else {
    print("\n✨ No corrupted keys found - everything looks good!")
}