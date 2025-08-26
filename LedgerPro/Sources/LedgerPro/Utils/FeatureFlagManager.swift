import Foundation

/// Global type alias for easier access
public typealias FeatureFlag = FeatureFlagManager.FeatureFlag

/// Feature flag system for controlling feature rollout
public class FeatureFlagManager: ObservableObject {
    static let shared = FeatureFlagManager()
    
    @Published private var flags: [String: Bool] = [:]
    
    private init() {
        loadFlags()
    }
    
    /// Available feature flags
    public enum FeatureFlag: String, CaseIterable {
        case debugMenu = "debug_menu"
        case advancedAnimations = "advanced_animations"
        case experimentalUI = "experimental_ui"
        case aiCategorization = "ai_categorization"
        case darkMode = "dark_mode"
        case hapticFeedback = "haptic_feedback"
        
        var displayName: String {
            switch self {
            case .debugMenu: return "Debug Menu"
            case .advancedAnimations: return "Advanced Animations"
            case .experimentalUI: return "Experimental UI"
            case .aiCategorization: return "AI Categorization"
            case .darkMode: return "Dark Mode"
            case .hapticFeedback: return "Haptic Feedback"
            }
        }
        
        var description: String {
            switch self {
            case .debugMenu: return "Show debug menu in settings"
            case .advancedAnimations: return "Enable advanced UI animations"
            case .experimentalUI: return "Show experimental UI features"
            case .aiCategorization: return "Use AI for transaction categorization"
            case .darkMode: return "Enable dark mode support"
            case .hapticFeedback: return "Enable haptic feedback"
            }
        }
        
        var name: String {
            return displayName
        }
        
        var rolloutPercentage: Double? {
            switch self {
            case .debugMenu: return nil
            case .advancedAnimations: return 0.8
            case .experimentalUI: return 0.2
            case .aiCategorization: return 0.6
            case .darkMode: return 1.0
            case .hapticFeedback: return 0.9
            }
        }
        
        var defaultValue: Bool {
            switch self {
            case .debugMenu: return false
            case .advancedAnimations: return true
            case .experimentalUI: return false
            case .aiCategorization: return true
            case .darkMode: return true
            case .hapticFeedback: return true
            }
        }
    }
    
    /// Check if a feature flag is enabled
    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        flags[flag.rawValue] ?? flag.defaultValue
    }
    
    /// Toggle a feature flag
    public func toggle(_ flag: FeatureFlag) {
        flags[flag.rawValue] = !isEnabled(flag)
        saveFlags()
    }
    
    /// Set a feature flag value
    public func setValue(_ flag: FeatureFlag, enabled: Bool) {
        flags[flag.rawValue] = enabled
        saveFlags()
    }
    
    /// Set a feature flag value (alternative method name for compatibility)
    public func setEnabled(_ flag: FeatureFlag, _ enabled: Bool) {
        setValue(flag, enabled: enabled)
    }
    
    /// Reset all flags to defaults
    public func resetToDefaults() {
        flags.removeAll()
        saveFlags()
    }
    
    // MARK: - Persistence
    
    private var flagsURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                      in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("feature_flags.json")
    }
    
    private func loadFlags() {
        guard let data = try? Data(contentsOf: flagsURL),
              let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) else {
            return
        }
        flags = decoded
    }
    
    private func saveFlags() {
        guard let data = try? JSONEncoder().encode(flags) else { return }
        try? data.write(to: flagsURL)
    }
}
