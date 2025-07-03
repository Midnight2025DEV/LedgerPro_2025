import Foundation

/// Rule-based auto-categorization system for transactions
struct CategoryRule: Identifiable, Codable, Hashable {
    let id: UUID
    let categoryId: UUID
    var ruleName: String
    var priority: Int = 0
    
    // MARK: - Matching Conditions
    
    /// Merchant name contains this string (case-insensitive)
    var merchantContains: String?
    
    /// Merchant name exactly matches this string (case-insensitive)
    var merchantExact: String?
    
    /// Transaction description contains this string (case-insensitive)
    var descriptionContains: String?
    
    /// Minimum transaction amount to match
    var amountMin: Decimal?
    
    /// Maximum transaction amount to match
    var amountMax: Decimal?
    
    /// Account type must match this value
    var accountType: BankAccount.AccountType?
    
    /// Transaction must occur on one of these days (1-7 for Monday-Sunday)
    var dayOfWeek: Set<Int>?
    
    /// Transaction must be recurring (appears multiple times)
    var isRecurring: Bool?
    
    /// Transaction amount must be positive (income) or negative (expense)
    var amountSign: AmountSign?
    
    /// Transaction must match this frequency pattern
    var frequency: TransactionFrequency?
    
    /// Additional regex pattern for advanced matching
    var regexPattern: String?
    
    // MARK: - Rule Metadata
    
    var isActive: Bool = true
    var createdAt: Date = Date()
    var lastMatched: Date?
    var matchCount: Int = 0
    var confidence: Double = 1.0 // 0.0 to 1.0, affects rule priority
    
    // MARK: - Initializers
    
    init(id: UUID = UUID(), categoryId: UUID, ruleName: String, priority: Int = 0) {
        self.id = id
        self.categoryId = categoryId
        self.ruleName = ruleName
        self.priority = priority
        self.createdAt = Date()
    }
    
    // MARK: - Rule Matching
    
    /// Check if a transaction matches this rule
    func matches(transaction: Transaction, accountType: BankAccount.AccountType? = nil) -> Bool {
        guard isActive else { return false }
        
        // Check merchant name conditions
        if let merchantContains = merchantContains,
           !transaction.description.localizedCaseInsensitiveContains(merchantContains) {
            return false
        }
        
        if let merchantExact = merchantExact,
           transaction.description.localizedCaseInsensitiveCompare(merchantExact) != .orderedSame {
            return false
        }
        
        // Check description conditions
        if let descriptionContains = descriptionContains,
           !transaction.description.localizedCaseInsensitiveContains(descriptionContains) {
            return false
        }
        
        // Check amount conditions
        if let amountMin = amountMin,
           Decimal(transaction.amount) < amountMin {
            return false
        }
        
        if let amountMax = amountMax,
           Decimal(transaction.amount) > amountMax {
            return false
        }
        
        // Check amount sign
        if let amountSign = amountSign {
            switch amountSign {
            case .positive:
                if transaction.amount <= 0 { return false }
            case .negative:
                if transaction.amount >= 0 { return false }
            case .any:
                break
            }
        }
        
        // Check account type
        if let requiredAccountType = accountType,
           requiredAccountType != accountType {
            return false
        }
        
        // Check day of week
        if let dayOfWeek = dayOfWeek {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: transaction.formattedDate)
            // Convert Swift's weekday (1=Sunday) to our format (1=Monday)
            let adjustedWeekday = weekday == 1 ? 7 : weekday - 1
            if !dayOfWeek.contains(adjustedWeekday) {
                return false
            }
        }
        
        // Check regex pattern if provided
        if let pattern = regexPattern,
           !pattern.isEmpty {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(location: 0, length: transaction.description.utf16.count)
                if regex.firstMatch(in: transaction.description, options: [], range: range) == nil {
                    return false
                }
            } catch {
                // Invalid regex pattern, skip this condition
                return false
            }
        }
        
        // All conditions passed
        return true
    }
    
    /// Returns a confidence score for how well this rule matches the transaction
    func matchConfidence(for transaction: Transaction, accountType: BankAccount.AccountType? = nil) -> Double {
        guard matches(transaction: transaction, accountType: accountType) else {
            return 0.0
        }
        
        var confidence = self.confidence
        
        // Boost confidence based on specificity
        if merchantExact != nil { confidence += 0.3 }
        if merchantContains != nil { confidence += 0.2 }
        if amountMin != nil || amountMax != nil { confidence += 0.1 }
        if dayOfWeek != nil { confidence += 0.1 }
        if regexPattern != nil { confidence += 0.2 }
        
        // Factor in historical match success
        if matchCount > 0 {
            confidence += min(0.2, Double(matchCount) * 0.01)
        }
        
        return min(1.0, confidence)
    }
    
    // MARK: - Rule Management
    
    /// Records that this rule successfully matched a transaction
    mutating func recordMatch() {
        lastMatched = Date()
        matchCount += 1
        
        // Slightly increase confidence for successful matches
        confidence = min(1.0, confidence + 0.01)
    }
    
    /// Records that this rule was corrected (user changed the categorization)
    mutating func recordCorrection() {
        // Slightly decrease confidence for corrections
        confidence = max(0.1, confidence - 0.05)
    }
    
    /// Returns a human-readable description of this rule
    var ruleDescription: String {
        var components: [String] = []
        
        if let merchantExact = merchantExact {
            components.append("Merchant is '\(merchantExact)'")
        } else if let merchantContains = merchantContains {
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
        
        if let accountType = accountType {
            components.append("Account type is \(accountType.displayName)")
        }
        
        if let dayOfWeek = dayOfWeek, !dayOfWeek.isEmpty {
            let dayNames = dayOfWeek.sorted().map { dayName(for: $0) }
            components.append("On \(dayNames.joined(separator: ", "))")
        }
        
        if let amountSign = amountSign {
            switch amountSign {
            case .positive:
                components.append("Amount is positive")
            case .negative:
                components.append("Amount is negative")
            case .any:
                break
            }
        }
        
        return components.isEmpty ? "No conditions set" : components.joined(separator: " AND ")
    }
    
    private func dayName(for dayNumber: Int) -> String {
        let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        guard dayNumber >= 1 && dayNumber <= 7 else { return "Unknown" }
        return dayNames[dayNumber - 1]
    }
}

// MARK: - Supporting Enums

enum AmountSign: String, Codable, CaseIterable {
    case positive = "positive"
    case negative = "negative"
    case any = "any"
    
    var displayName: String {
        switch self {
        case .positive: return "Income (Positive)"
        case .negative: return "Expense (Negative)"
        case .any: return "Any Amount"
        }
    }
}

enum TransactionFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    case irregular = "irregular"
    case oneTime = "one_time"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        case .irregular: return "Irregular"
        case .oneTime: return "One-time"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 2
        case .biweekly: return 3
        case .monthly: return 4
        case .quarterly: return 5
        case .yearly: return 6
        case .irregular: return 7
        case .oneTime: return 8
        }
    }
}

// MARK: - Default System Rules

extension CategoryRule {
    /// Predefined system rules for common transaction patterns
    static let systemRules: [CategoryRule] = {
        var rules: [CategoryRule] = []
        
        // Income Rules
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.salary,
            ruleName: "Salary Deposits",
            priority: 100
        ).with {
            $0.amountSign = .positive
            $0.merchantContains = "payroll"
            $0.isRecurring = true
        })
        
        // Transportation Rules
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "Gas Stations",
            priority: 90
        ).with {
            $0.merchantContains = "chevron"
            $0.amountSign = .negative
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "Uber/Lyft",
            priority: 90
        ).with {
            $0.merchantContains = "uber"
            $0.amountSign = .negative
        })
        
        // Food & Dining Rules
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Restaurants",
            priority: 80
        ).with {
            $0.merchantContains = "restaurant"
            $0.amountSign = .negative
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Fast Food",
            priority: 80
        ).with {
            $0.merchantContains = "mcdonald"
            $0.amountSign = .negative
        })
        
        // Shopping Rules
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Amazon Purchases",
            priority: 85
        ).with {
            $0.merchantContains = "amazon"
            $0.amountSign = .negative
        })
        
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Walmart",
            priority: 85
        ).with {
            $0.merchantContains = "walmart"
            $0.amountSign = .negative
        })
        
        // Transfer Rules
        rules.append(CategoryRule(
            categoryId: Category.systemCategoryIds.creditCardPayment,
            ruleName: "Credit Card Payments",
            priority: 95
        ).with {
            $0.merchantContains = "capital one"
            $0.descriptionContains = "payment"
            $0.amountSign = .positive
        })
        
        return rules
    }()
    
    /// Common rule templates for popular merchants and transaction patterns
    static let commonRuleTemplates: [CategoryRule] = {
        var templates: [CategoryRule] = []
        
        // Coffee Shops
        templates.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Starbucks",
            priority: 75
        ).with {
            $0.merchantContains = "STARBUCKS"
            $0.amountSign = .negative
        })
        
        templates.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Dunkin Donuts",
            priority: 75
        ).with {
            $0.merchantContains = "DUNKIN"
            $0.amountSign = .negative
        })
        
        // Fast Food Chains
        templates.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "McDonald's",
            priority: 75
        ).with {
            $0.merchantContains = "MCDONALD"
            $0.amountSign = .negative
        })
        
        templates.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Chipotle",
            priority: 75
        ).with {
            $0.merchantContains = "CHIPOTLE"
            $0.amountSign = .negative
        })
        
        templates.append(CategoryRule(
            categoryId: Category.systemCategoryIds.foodDining,
            ruleName: "Subway",
            priority: 75
        ).with {
            $0.merchantContains = "SUBWAY"
            $0.amountSign = .negative
        })
        
        // Ride Sharing
        templates.append(CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "Uber",
            priority: 80
        ).with {
            $0.merchantContains = "UBER"
            $0.amountSign = .negative
        })
        
        templates.append(CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "Lyft",
            priority: 80
        ).with {
            $0.merchantContains = "LYFT"
            $0.amountSign = .negative
        })
        
        // Online Shopping
        templates.append(CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Amazon",
            priority: 80
        ).with {
            $0.regexPattern = "AMAZON|AMZN"
            $0.amountSign = .negative
        })
        
        templates.append(CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Target",
            priority: 75
        ).with {
            $0.merchantContains = "TARGET"
            $0.amountSign = .negative
        })
        
        templates.append(CategoryRule(
            categoryId: Category.systemCategoryIds.shopping,
            ruleName: "Walmart",
            priority: 75
        ).with {
            $0.regexPattern = "WAL-MART|WALMART"
            $0.amountSign = .negative
        })
        
        // Grocery Stores
        templates.append(CategoryRule(
            categoryId: UUID(uuidString: "00000000-0000-0000-0000-000000000046")!, // Groceries
            ruleName: "Whole Foods",
            priority: 80
        ).with {
            $0.merchantContains = "WHOLE FOODS"
            $0.amountSign = .negative
        })
        
        templates.append(CategoryRule(
            categoryId: UUID(uuidString: "00000000-0000-0000-0000-000000000046")!, // Groceries
            ruleName: "Kroger",
            priority: 75
        ).with {
            $0.merchantContains = "KROGER"
            $0.amountSign = .negative
        })
        
        // Gas Stations
        templates.append(CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "Shell Gas",
            priority: 80
        ).with {
            $0.merchantContains = "SHELL"
            $0.amountSign = .negative
        })
        
        templates.append(CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "Exxon Mobile",
            priority: 80
        ).with {
            $0.regexPattern = "EXXON|MOBIL"
            $0.amountSign = .negative
        })
        
        templates.append(CategoryRule(
            categoryId: Category.systemCategoryIds.transportation,
            ruleName: "BP Gas",
            priority: 80
        ).with {
            $0.merchantContains = "BP"
            $0.amountSign = .negative
        })
        
        // Streaming Services
        templates.append(CategoryRule(
            categoryId: UUID(uuidString: "00000000-0000-0000-0000-000000000047")!, // Subscriptions
            ruleName: "Netflix",
            priority: 85
        ).with {
            $0.merchantContains = "NETFLIX"
            $0.amountSign = .negative
        })
        
        templates.append(CategoryRule(
            categoryId: UUID(uuidString: "00000000-0000-0000-0000-000000000047")!, // Subscriptions
            ruleName: "Spotify",
            priority: 85
        ).with {
            $0.merchantContains = "SPOTIFY"
            $0.amountSign = .negative
        })
        
        templates.append(CategoryRule(
            categoryId: UUID(uuidString: "00000000-0000-0000-0000-000000000047")!, // Subscriptions
            ruleName: "Apple Subscriptions",
            priority: 85
        ).with {
            $0.regexPattern = "APPLE\\.COM|ITUNES"
            $0.amountSign = .negative
        })
        
        // Utilities
        templates.append(CategoryRule(
            categoryId: UUID(uuidString: "00000000-0000-0000-0000-000000000024")!, // Utilities
            ruleName: "Electric Company",
            priority: 90
        ).with {
            $0.regexPattern = "ELECTRIC|PG&E|CON ED|EDISON"
            $0.amountSign = .negative
        })
        
        templates.append(CategoryRule(
            categoryId: UUID(uuidString: "00000000-0000-0000-0000-000000000024")!, // Utilities
            ruleName: "Internet/Cable",
            priority: 90
        ).with {
            $0.regexPattern = "COMCAST|VERIZON|AT&T|SPECTRUM|XFINITY"
            $0.amountSign = .negative
        })
        
        // Banking/Finance
        templates.append(CategoryRule(
            categoryId: Category.systemCategoryIds.creditCardPayment,
            ruleName: "Credit Card Payments",
            priority: 95
        ).with {
            $0.regexPattern = "PAYMENT|AUTOPAY|ONLINE PMT"
            $0.amountSign = .positive
        })
        
        return templates
    }()
}

// MARK: - Helper Extension for Builder Pattern

private extension CategoryRule {
    func with(_ block: (inout CategoryRule) -> Void) -> CategoryRule {
        var copy = self
        block(&copy)
        return copy
    }
}

// MARK: - Rule Validation

extension CategoryRule {
    /// Validates that the rule is properly configured
    var isValid: Bool {
        // Rule must have at least one condition
        let hasCondition = merchantContains != nil ||
                          merchantExact != nil ||
                          descriptionContains != nil ||
                          amountMin != nil ||
                          amountMax != nil ||
                          accountType != nil ||
                          dayOfWeek != nil ||
                          amountSign != nil ||
                          regexPattern != nil
        
        // Rule name must not be empty
        let hasValidName = !ruleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        // Amount range must be valid if specified
        let hasValidAmountRange = {
            if let min = amountMin, let max = amountMax {
                return min <= max
            }
            return true
        }()
        
        // Day of week values must be valid (1-7)
        let hasValidDayOfWeek = {
            if let days = dayOfWeek {
                return days.allSatisfy { $0 >= 1 && $0 <= 7 }
            }
            return true
        }()
        
        return hasCondition && hasValidName && hasValidAmountRange && hasValidDayOfWeek
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if ruleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Rule name cannot be empty")
        }
        
        let hasCondition = merchantContains != nil ||
                          merchantExact != nil ||
                          descriptionContains != nil ||
                          amountMin != nil ||
                          amountMax != nil ||
                          accountType != nil ||
                          dayOfWeek != nil ||
                          amountSign != nil ||
                          regexPattern != nil
        
        if !hasCondition {
            errors.append("Rule must have at least one condition")
        }
        
        if let min = amountMin, let max = amountMax, min > max {
            errors.append("Minimum amount cannot be greater than maximum amount")
        }
        
        if let days = dayOfWeek {
            let invalidDays = days.filter { $0 < 1 || $0 > 7 }
            if !invalidDays.isEmpty {
                errors.append("Day of week values must be between 1-7")
            }
        }
        
        if let pattern = regexPattern, !pattern.isEmpty {
            do {
                _ = try NSRegularExpression(pattern: pattern, options: [])
            } catch {
                errors.append("Invalid regular expression pattern")
            }
        }
        
        return errors
    }
}