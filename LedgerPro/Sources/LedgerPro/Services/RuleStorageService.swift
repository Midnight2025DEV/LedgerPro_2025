import Foundation

@MainActor
class RuleStorageService: ObservableObject {
    static let shared = RuleStorageService()
    
    @Published private(set) var customRules: [CategoryRule] = []
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, 
                                                             in: .userDomainMask).first!
    private let rulesFileURL: URL
    
    init() {
        rulesFileURL = documentsDirectory.appendingPathComponent("custom_category_rules.json")
        loadRules()
    }
    
    // Get all rules (system + custom)
    var allRules: [CategoryRule] {
        return CategoryRule.systemRules + customRules
    }
    
    func saveRule(_ rule: CategoryRule) {
        customRules.append(rule)
        saveRulesToDisk()
    }
    
    func updateRule(_ rule: CategoryRule) {
        if let index = customRules.firstIndex(where: { $0.id == rule.id }) {
            customRules[index] = rule
            saveRulesToDisk()
        }
    }
    
    func deleteRule(id: UUID) {
        customRules.removeAll { $0.id == id }
        saveRulesToDisk()
    }
    
    private func saveRulesToDisk() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(customRules)
            try data.write(to: rulesFileURL)
            AppLogger.shared.debug("Saved \(customRules.count) custom rules")
        } catch {
            AppLogger.shared.error("Failed to save rules: \(error)")
        }
    }
    
    private func loadRules() {
        guard FileManager.default.fileExists(atPath: rulesFileURL.path) else {
            AppLogger.shared.debug("No custom rules file found")
            return
        }
        
        do {
            let data = try Data(contentsOf: rulesFileURL)
            let decoder = JSONDecoder()
            customRules = try decoder.decode([CategoryRule].self, from: data)
            AppLogger.shared.debug("Loaded \(customRules.count) custom rules")
        } catch {
            AppLogger.shared.error("Failed to load rules: \(error)")
        }
    }
}