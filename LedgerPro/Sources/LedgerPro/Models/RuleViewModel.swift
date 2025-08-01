import Foundation
import SwiftUI

@MainActor
class RuleViewModel: ObservableObject {
    @Published var rules: [CategoryRule] = []
    @Published var filteredRules: [CategoryRule] = []
    @Published var searchText = ""
    @Published var filterActive = false
    @Published var filterCustomOnly = false
    @Published var sortOrder = SortOrder.priority
    @Published var isLoading = false
    @Published var ruleSuggestions: [RuleSuggestion] = []
    @Published var isGeneratingSuggestions = false
    
    @AppStorage("dismissedSuggestions") private var dismissedSuggestionIDs: String = ""
    
    enum SortOrder: String, CaseIterable {
        case priority = "Priority"
        case name = "Name"
        case lastUsed = "Last Used"
        case successRate = "Success Rate"
    }
    
    private let ruleStorage = RuleStorageService.shared
    private let categoryService = CategoryService.shared
    private let dataManager = FinancialDataManager()
    private let suggestionEngine: RuleSuggestionEngine
    
    init() {
        self.suggestionEngine = RuleSuggestionEngine(categoryService: categoryService)
        loadRules()
        generateSuggestions()
    }
    
    func loadRules() {
        isLoading = true
        rules = ruleStorage.allRules
        applyFilters()
        isLoading = false
    }
    
    func applyFilters() {
        var filtered = rules
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { rule in
                rule.ruleName.localizedCaseInsensitiveContains(searchText) ||
                rule.merchantContains?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        // Active filter
        if filterActive {
            filtered = filtered.filter { $0.isActive }
        }
        
        // Custom only filter
        if filterCustomOnly {
            filtered = filtered.filter { rule in
                // System rules are those with priority > 50 and in the systemRules list
                !CategoryRule.systemRules.contains { $0.id == rule.id }
            }
        }
        
        // Sort
        switch sortOrder {
        case .priority:
            filtered.sort { $0.priority > $1.priority }
        case .name:
            filtered.sort { $0.ruleName < $1.ruleName }
        case .lastUsed:
            filtered.sort(by: { ($0.lastMatchDate ?? Date.distantPast) > ($1.lastMatchDate ?? Date.distantPast) })
        case .successRate:
            filtered.sort { $0.confidence > $1.confidence }
        }
        
        filteredRules = filtered
    }
    
    func createRule(from transaction: Transaction) -> CategoryRule {
        var rule = CategoryRule(
            categoryId: UUID(), // Will be set by user
            ruleName: "\(transaction.description.prefix(20)) Rule"
        )
        
        // Extract merchant name
        if let merchant = extractMerchant(from: transaction.description) {
            rule.merchantContains = merchant
        }
        
        // Set amount range if consistent
        if transaction.amount < 0 {
            rule.amountMin = abs(transaction.amount) * 0.8
            rule.amountMax = abs(transaction.amount) * 1.2
        }
        
        return rule
    }
    
    private func extractMerchant(from description: String) -> String? {
        // Simple extraction - can be enhanced
        let components = description.components(separatedBy: .whitespaces)
        return components.first?.uppercased()
    }
    
    func saveRule(_ rule: CategoryRule) {
        ruleStorage.saveRule(rule)
        loadRules() // Refresh the list
    }
    
    func getAvailableCategories() -> [Category] {
        return Category.systemCategories
    }
    
    func getSampleTransactions() -> [Transaction] {
        // Return a subset of transactions for testing, or create demo data
        if dataManager.transactions.isEmpty {
            // Create some demo transactions for testing
            return [
                Transaction(date: "2025-01-15", description: "STARBUCKS #1234", amount: -5.50, category: "Other"),
                Transaction(date: "2025-01-15", description: "AMAZON.COM MARKETPLACE", amount: -89.99, category: "Other"),
                Transaction(date: "2025-01-15", description: "UBER EATS DELIVERY", amount: -25.30, category: "Other"),
                Transaction(date: "2025-01-15", description: "CHEVRON GAS STATION", amount: -45.00, category: "Other"),
                Transaction(date: "2025-01-15", description: "WALMART SUPERCENTER", amount: -156.43, category: "Other"),
                Transaction(date: "2025-01-15", description: "PAYROLL DEPOSIT", amount: 3000.00, category: "Other"),
                Transaction(date: "2025-01-15", description: "APPLE.COM/BILL", amount: -9.99, category: "Other"),
                Transaction(date: "2025-01-15", description: "MCDONALDS #3425", amount: -12.75, category: "Other")
            ]
        }
        return Array(dataManager.transactions.prefix(20)) // Return first 20 for testing
    }
    
    // MARK: - Rule Suggestions
    
    func generateSuggestions() {
        // Use real transactions from dataManager
        let uncategorizedTransactions = dataManager.transactions.filter { 
            $0.category == "Other" || 
            ($0.confidence ?? 0) < 0.5
        }
        
        // If no real transactions, fall back to sample data for demo
        if uncategorizedTransactions.isEmpty {
            generateSuggestions(from: getSampleTransactions())
        } else {
            generateSuggestions(from: uncategorizedTransactions)
        }
    }
    
    func generateSuggestions(from transactions: [Transaction]) {
        isGeneratingSuggestions = true
        
        Task {
            let allSuggestions = suggestionEngine.generateSuggestions(from: transactions)
            
            // Filter out dismissed suggestions
            let dismissedPatterns = Set(dismissedSuggestionIDs.split(separator: ",").map(String.init))
            let filteredSuggestions = allSuggestions.filter { suggestion in
                !dismissedPatterns.contains(suggestion.merchantPattern)
            }
            
            await MainActor.run {
                self.ruleSuggestions = filteredSuggestions
                self.isGeneratingSuggestions = false
            }
        }
    }
    
    func createRuleFromSuggestion(_ suggestion: RuleSuggestion) {
        let rule = suggestion.toCategoryRule()
        saveRule(rule)
        
        // Remove the suggestion after creating the rule
        ruleSuggestions.removeAll { $0.id == suggestion.id }
    }
    
    func dismissSuggestion(_ suggestion: RuleSuggestion) {
        ruleSuggestions.removeAll { $0.id == suggestion.id }
        
        // Store dismissed merchant pattern
        var dismissedPatterns = dismissedSuggestionIDs.split(separator: ",").map(String.init)
        if !dismissedPatterns.contains(suggestion.merchantPattern) {
            dismissedPatterns.append(suggestion.merchantPattern)
            dismissedSuggestionIDs = dismissedPatterns.joined(separator: ",")
        }
    }
    
    func refreshSuggestions() {
        generateSuggestions()
    }
    
    func clearDismissedSuggestions() {
        dismissedSuggestionIDs = ""
        generateSuggestions()
    }
}