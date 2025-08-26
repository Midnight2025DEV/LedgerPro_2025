import Foundation

/// Rule for automatic transaction categorization
struct CategoryRule: Codable, Identifiable, Hashable {
    let id: UUID
    var ruleName: String
    var categoryId: UUID
    var isActive: Bool = true
    var isSystem: Bool = false
    var priority: Int = 50
    var confidence: Double = 0.8
    
    // Matching conditions
    var merchantContains: String?
    var merchantExact: String?
    var descriptionContains: String?
    var amountMin: Double?
    var amountMax: Double?
    var accountType: String?
    var dayOfWeek: Int?
    var amountSign: AmountSign?
    var regexPattern: String?
    
    // Learning/tracking
    var matchCount: Int = 0
    var lastMatchDate: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    enum AmountSign: String, Codable, CaseIterable {
        case positive = "positive"
        case negative = "negative"
    }
    
    init(id: UUID = UUID(), categoryId: UUID, ruleName: String) {
        self.id = id
        self.categoryId = categoryId
        self.ruleName = ruleName
    }
    
    /// Check if this rule matches a transaction
    func matches(transaction: Transaction) -> Bool {
        // Merchant name checks
        if let merchantContains = merchantContains,
           !transaction.description.localizedCaseInsensitiveContains(merchantContains) {
            return false
        }
        
        if let merchantExact = merchantExact,
           transaction.description.localizedCaseInsensitiveCompare(merchantExact) != .orderedSame {
            return false
        }
        
        // Description checks
        if let descriptionContains = descriptionContains,
           !transaction.description.localizedCaseInsensitiveContains(descriptionContains) {
            return false
        }
        
        // Amount range checks
        // FIXED: Amount range checks should work with actual transaction amounts
        if let amountMin = amountMin, let amountMax = amountMax {
            // Ensure min <= max
            let minVal = min(amountMin, amountMax)
            let maxVal = max(amountMin, amountMax)
            
            // Check if transaction amount is within range
            if transaction.amount < minVal || transaction.amount > maxVal {
                return false
            }
        } else {
            // Handle cases where only min or max is set
            if let amountMin = amountMin {
                if amountMin < 0 {
                    // For negative min, transaction must be >= min (less negative)
                    if transaction.amount < amountMin {
                        return false
                    }
                } else {
                    // For positive min, use absolute value comparison
                    if abs(transaction.amount) < amountMin {
                        return false
                    }
                }
            }
            
            if let amountMax = amountMax {
                if amountMax < 0 {
                    // For negative max, transaction must be <= max (more negative)
                    if transaction.amount > amountMax {
                        return false
                    }
                } else {
                    // For positive max, use absolute value comparison
                    if abs(transaction.amount) > amountMax {
                        return false
                    }
                }
            }
        }
        
        // Amount sign check
        if let amountSign = amountSign {
            switch amountSign {
            case .positive:
                if transaction.amount <= 0 { return false }
            case .negative:
                if transaction.amount >= 0 { return false }
            }
        }
        
        // Regex pattern matching
        if let regexPattern = regexPattern {
            do {
                let regex = try NSRegularExpression(pattern: regexPattern, options: .caseInsensitive)
                let range = NSRange(location: 0, length: transaction.description.utf16.count)
                if regex.firstMatch(in: transaction.description, options: [], range: range) == nil {
                    return false
                }
            } catch {
                // Invalid regex pattern, skip this check
            }
        }
        
        return true
    }
    
    /// Calculate match confidence for a transaction
    func matchConfidence(for transaction: Transaction) -> Double {
        var confidence = self.confidence
        
        // Exact match gets bonus confidence
        if let merchantExact = merchantExact,
           transaction.description.localizedCaseInsensitiveCompare(merchantExact) == .orderedSame {
            confidence = min(confidence + 0.1, 1.0)
        }
        
        // Multiple criteria matched gets bonus
        var criteriaMatched = 0
        if merchantContains != nil { criteriaMatched += 1 }
        if merchantExact != nil { criteriaMatched += 1 }
        if descriptionContains != nil { criteriaMatched += 1 }
        if amountMin != nil || amountMax != nil { criteriaMatched += 1 }
        if regexPattern != nil { criteriaMatched += 1 }
        
        if criteriaMatched > 2 {
            confidence = min(confidence + 0.05, 1.0)
        }
        
        return confidence
    }
    
    // Learning methods
    mutating func recordMatch() {
        matchCount += 1
        lastMatchDate = Date()
        confidence = min(confidence + 0.01, 0.99)
        updatedAt = Date()
    }
    
    mutating func recordCorrection() {
        confidence = max(confidence - 0.05, 0.1)
        updatedAt = Date()
    }
    
    // MARK: - Validation
    var isValid: Bool {
        // Rule must have a name
        guard !ruleName.isEmpty else { return false }
        
        // If both min and max are set, min should be <= max
        if let min = amountMin, let max = amountMax {
            return min <= max
        }
        
        return true
    }
    
    // MARK: - Compatibility
    var lastMatched: Date? {
        return lastMatchDate
    }
    
    /// Returns a human-readable description of this rule
    var ruleDescription: String {
        var components: [String] = []
        
        if let merchantContains = merchantContains {
            components.append("Merchant contains '\(merchantContains)'")
        }
        
        if let descriptionContains = descriptionContains {
            components.append("Description contains '\(descriptionContains)'")
        }
        
        if let amountMin = amountMin, let amountMax = amountMax {
            components.append("Amount between \(amountMin) and \(amountMax)")
        } else if let amountMin = amountMin {
            components.append("Amount ≥ \(amountMin)")
        } else if let amountMax = amountMax {
            components.append("Amount ≤ \(amountMax)")
        }
        
        if let amountSign = amountSign {
            switch amountSign {
            case .positive:
                components.append("Amount is positive")
            case .negative:
                components.append("Amount is negative")
            }
        }
        
        return components.isEmpty ? "No conditions set" : components.joined(separator: " AND ")
    }
}

// MARK: - Helper Extension
extension CategoryRule {
    func with(_ block: (inout CategoryRule) -> Void) -> CategoryRule {
        var copy = self
        block(&copy)
        return copy
    }
}

// MARK: - Common Rule Templates
extension CategoryRule {
    static let commonRuleTemplates: [CategoryRule] = systemRules
}

