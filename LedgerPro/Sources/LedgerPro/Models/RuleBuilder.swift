import Foundation

@MainActor
class RuleBuilder: ObservableObject {
    @Published var ruleName: String = ""
    @Published var categoryId: UUID?
    @Published var priority: Int = 50
    @Published var merchantContains: String = ""
    @Published var merchantExact: String = ""
    @Published var descriptionContains: String = ""
    @Published var amountMin: String = ""
    @Published var amountMax: String = ""
    @Published var accountType: BankAccount.AccountType?
    @Published var dayOfWeek: Set<Int> = []
    @Published var amountSign: CategoryRule.AmountSign? = nil
    @Published var regexPattern: String = ""
    @Published var isActive: Bool = true
    
    var isValid: Bool {
        !ruleName.isEmpty && hasAtLeastOneCondition && validationErrors.isEmpty
    }
    
    var hasAtLeastOneCondition: Bool {
        !merchantContains.isEmpty ||
        !merchantExact.isEmpty ||
        !descriptionContains.isEmpty ||
        !amountMin.isEmpty ||
        !amountMax.isEmpty ||
        accountType != nil ||
        !dayOfWeek.isEmpty ||
        amountSign != nil ||
        !regexPattern.isEmpty
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if ruleName.isEmpty {
            errors.append("Rule name is required")
        }
        
        if !hasAtLeastOneCondition {
            errors.append("At least one condition is required")
        }
        
        // Validate amount range
        if !amountMin.isEmpty && !amountMax.isEmpty {
            if let min = Decimal(string: amountMin),
               let max = Decimal(string: amountMax),
               min > max {
                errors.append("Minimum amount cannot be greater than maximum amount")
            }
        }
        
        // Validate regex pattern
        if !regexPattern.isEmpty {
            do {
                _ = try NSRegularExpression(pattern: regexPattern, options: [])
            } catch {
                errors.append("Invalid regular expression pattern")
            }
        }
        
        return errors
    }
    
    func buildRule() -> CategoryRule? {
        guard isValid, let categoryId = categoryId else { return nil }
        
        var rule = CategoryRule(
            categoryId: categoryId,
            ruleName: ruleName
        )
        rule.priority = priority
        
        if !merchantContains.isEmpty {
            rule.merchantContains = merchantContains
        }
        
        if !merchantExact.isEmpty {
            rule.merchantExact = merchantExact
        }
        
        if !descriptionContains.isEmpty {
            rule.descriptionContains = descriptionContains
        }
        
        if !amountMin.isEmpty, let min = Decimal(string: amountMin) {
            rule.amountMin = Double(truncating: min as NSDecimalNumber)
        }
        
        if !amountMax.isEmpty, let max = Decimal(string: amountMax) {
            rule.amountMax = Double(truncating: max as NSDecimalNumber)
        }
        
        rule.accountType = accountType?.rawValue
        
        if let firstDay = dayOfWeek.first {
            rule.dayOfWeek = firstDay
        }
        
        if let amountSign = amountSign {
            rule.amountSign = amountSign
        }
        
        if !regexPattern.isEmpty {
            rule.regexPattern = regexPattern
        }
        
        rule.isActive = isActive
        
        return rule
    }
    
    func testRule(against transactions: [Transaction]) -> [Transaction] {
        guard let rule = buildRule() else { return [] }
        
        return transactions.filter { transaction in
            rule.matches(transaction: transaction)
        }
    }
    
    func reset() {
        ruleName = ""
        categoryId = nil
        priority = 50
        merchantContains = ""
        merchantExact = ""
        descriptionContains = ""
        amountMin = ""
        amountMax = ""
        accountType = nil
        dayOfWeek = []
        amountSign = nil
        regexPattern = ""
        isActive = true
    }
}