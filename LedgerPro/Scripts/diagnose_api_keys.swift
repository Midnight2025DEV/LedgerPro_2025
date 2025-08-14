#!/usr/bin/env swift

import Foundation

// Diagnostic script to check API key status and detect corruption patterns
// Run this to diagnose API key issues

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
    
    var expectedPrefix: String? {
        switch self {
        case .openai: return "sk-"
        case .anthropic: return "sk-ant-"
        case .groq: return "gsk_"
        case .cohere: return "co-"
        case .huggingface: return "hf_"
        case .ollama: return nil // URL format, no specific prefix
        case .mistral, .azure, .google: return nil // Variable formats
        }
    }
}

func analyzeAPIKey(_ key: String, for provider: AIProvider) -> (isValid: Bool, issues: [String]) {
    var issues: [String] = []
    let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Check for common corruption patterns
    let corruptionPrefixes = ["KEYFOCUS: ", "KEYFOCUS:", "DEBUG: ", "API_KEY: ", "Key: "]
    for prefix in corruptionPrefixes {
        if key.hasPrefix(prefix) {
            issues.append("Contains corruption prefix: '\(prefix)'")
        }
    }
    
    // Check for whitespace/newline corruption
    if key != trimmed {
        issues.append("Contains leading/trailing whitespace or newlines")
    }
    
    // Check for control characters
    let controlCharacterSet = CharacterSet.controlCharacters
    if key.rangeOfCharacter(from: controlCharacterSet) != nil {
        issues.append("Contains control characters")
    }
    
    // Check expected format
    if let expectedPrefix = provider.expectedPrefix {
        if !trimmed.hasPrefix(expectedPrefix) {
            issues.append("Missing expected prefix '\(expectedPrefix)'")
        }
    }
    
    // Check minimum length
    let minLength = provider.expectedPrefix?.count ?? 5
    if trimmed.count < minLength + 5 {
        issues.append("Too short (expected at least \(minLength + 5) characters)")
    }
    
    return (isValid: issues.isEmpty, issues: issues)
}

print("🔍 Diagnosing API Key Status...")
print("=====================================")

let userDefaults = UserDefaults.standard
var foundKeys = 0
var corruptedKeys = 0

for provider in AIProvider.allCases {
    let keyName = "\(provider.userDefaultsKey)_api_key"
    let modelName = "\(provider.userDefaultsKey)_model"
    
    print("\n📋 \(provider.rawValue) (\(provider.userDefaultsKey))")
    print("   Key name: \(keyName)")
    
    if let savedKey = userDefaults.string(forKey: keyName) {
        foundKeys += 1
        print("   ✅ API key found")
        print("   📏 Length: \(savedKey.count) characters")
        print("   🔤 First 10 chars: '\(String(savedKey.prefix(10)))'")
        print("   🔤 Last 10 chars: '...\(String(savedKey.suffix(10)))'")
        
        // Analyze for corruption
        let analysis = analyzeAPIKey(savedKey, for: provider)
        
        if analysis.isValid {
            print("   ✅ Status: VALID")
        } else {
            corruptedKeys += 1
            print("   ❌ Status: CORRUPTED")
            for issue in analysis.issues {
                print("      • \(issue)")
            }
        }
        
        // Check if there's a saved model
        if let savedModel = userDefaults.string(forKey: modelName) {
            print("   🤖 Model: \(savedModel)")
        } else {
            print("   🤖 Model: Not set")
        }
        
    } else {
        print("   ⚪ No API key stored")
    }
}

print("\n=====================================")
print("📊 Summary:")
print("   Total providers: \(AIProvider.allCases.count)")
print("   Keys found: \(foundKeys)")
print("   Corrupted keys: \(corruptedKeys)")
print("   Valid keys: \(foundKeys - corruptedKeys)")

if corruptedKeys > 0 {
    print("\n⚠️  RECOMMENDATION:")
    print("   Run the cleanup script: swift clean_corrupted_api_keys.swift")
    print("   Or manually re-enter corrupted API keys in the app settings.")
} else if foundKeys > 0 {
    print("\n✨ All stored API keys appear to be valid!")
} else {
    print("\n💡 No API keys configured yet. Set them up in Settings > API Keys.")
}

// Also check for the selected provider
if let selectedProvider = userDefaults.string(forKey: "selected_ai_provider") {
    print("\n🎯 Currently selected provider: \(selectedProvider)")
} else {
    print("\n🎯 No provider currently selected")
}