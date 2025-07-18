import Foundation
import SwiftUI

struct Transaction: Codable, Identifiable, Hashable {
    let id: String
    let date: String
    let description: String
    let amount: Double
    let category: String
    let confidence: Double?
    let jobId: String?
    let accountId: String?
    let rawData: [String: String]?
    
    // Foreign currency fields
    let originalAmount: Double?     // Original foreign amount
    let originalCurrency: String?   // Currency code (EUR, GBP, MXN, etc.)
    let exchangeRate: Double?       // Exchange rate used
    let hasForex: Bool?            // Flag for foreign transactions
    
    // Auto-categorization tracking
    let wasAutoCategorized: Bool?   // Whether this was auto-categorized
    let categorizationMethod: String? // "merchant_rule", "smart_rule", "ai_suggestion"
    
    enum CodingKeys: String, CodingKey {
        case id, date, description, amount, category, confidence, jobId, accountId
        case rawData = "raw_data"
        case originalAmount = "original_amount"
        case originalCurrency = "original_currency"
        case exchangeRate = "exchange_rate"
        case hasForex = "has_forex"
        case wasAutoCategorized = "was_auto_categorized"
        case categorizationMethod = "categorization_method"
    }
    
    // Memberwise initializer for creating transactions manually
    init(id: String? = nil, date: String, description: String, amount: Double, category: String, confidence: Double? = nil, jobId: String? = nil, accountId: String? = nil, rawData: [String: String]? = nil, originalAmount: Double? = nil, originalCurrency: String? = nil, exchangeRate: Double? = nil, hasForex: Bool? = nil, wasAutoCategorized: Bool? = nil, categorizationMethod: String? = nil) {
        if let providedId = id {
            self.id = providedId
        } else {
            // FIXED: Safe description handling to prevent range errors
            let safeDescription = Self.safeTruncateDescription(description, maxLength: 20)
            self.id = "\(date)_\(safeDescription)_\(amount)_\(UUID().uuidString)".replacingOccurrences(of: " ", with: "_")
        }
        self.date = date
        self.description = description
        self.amount = amount
        self.category = category
        self.confidence = confidence
        self.jobId = jobId
        self.accountId = accountId
        self.rawData = rawData
        self.originalAmount = originalAmount
        self.originalCurrency = originalCurrency
        self.exchangeRate = exchangeRate
        self.hasForex = hasForex
        self.wasAutoCategorized = wasAutoCategorized
        self.categorizationMethod = categorizationMethod
    }
    
    // Decoder initializer for JSON parsing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // If id is missing, generate one from other fields
        if let providedId = try container.decodeIfPresent(String.self, forKey: .id) {
            self.id = providedId
        } else {
            // Generate ID from date + description + amount for uniqueness
            let date = try container.decode(String.self, forKey: .date)
            let description = try container.decode(String.self, forKey: .description)
            let amount = try container.decode(Double.self, forKey: .amount)
            // FIXED: Safe description handling to prevent range errors
            let safeDescription = Self.safeTruncateDescription(description, maxLength: 20)
            self.id = "\(date)_\(safeDescription)_\(amount)_\(UUID().uuidString)".replacingOccurrences(of: " ", with: "_")
        }
        
        self.date = try container.decode(String.self, forKey: .date)
        self.description = try container.decode(String.self, forKey: .description)
        self.amount = try container.decode(Double.self, forKey: .amount)
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? "Uncategorized"
        self.confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        self.jobId = try container.decodeIfPresent(String.self, forKey: .jobId)
        self.accountId = try container.decodeIfPresent(String.self, forKey: .accountId)
        self.rawData = try container.decodeIfPresent([String: String].self, forKey: .rawData)
        self.originalAmount = try container.decodeIfPresent(Double.self, forKey: .originalAmount)
        self.originalCurrency = try container.decodeIfPresent(String.self, forKey: .originalCurrency)
        self.exchangeRate = try container.decodeIfPresent(Double.self, forKey: .exchangeRate)
        self.hasForex = try container.decodeIfPresent(Bool.self, forKey: .hasForex)
        self.wasAutoCategorized = try container.decodeIfPresent(Bool.self, forKey: .wasAutoCategorized)
        self.categorizationMethod = try container.decodeIfPresent(String.self, forKey: .categorizationMethod)
    }
    
    // MARK: - Safe String Operations
    
    /// Safely truncate description to prevent range errors
    static func safeTruncateDescription(_ description: String, maxLength: Int) -> String {
        // Handle empty or invalid strings
        guard !description.isEmpty else { return "empty" }
        
        // Safe truncation that handles all edge cases
        if description.count <= maxLength {
            return description
        } else {
            // Use safe subscripting with String.Index
            let endIndex = description.index(description.startIndex, offsetBy: maxLength, limitedBy: description.endIndex) ?? description.endIndex
            return String(description[description.startIndex..<endIndex])
        }
    }
    
    /// Safely take first N components from description
    static func safePrefix<T>(_ collection: [T], count: Int) -> [T] {
        guard count > 0 else { return [] }
        guard !collection.isEmpty else { return [] }
        
        let actualCount = min(count, collection.count)
        return Array(collection[0..<actualCount])
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var formattedDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date) ?? Date()
    }
    
    var isExpense: Bool {
        return amount < 0
    }
    
    var isIncome: Bool {
        return amount > 0
    }
    
    var isPayment: Bool {
        return amount > 0 && (description.lowercased().contains("payment") || 
                             description.lowercased().contains("autopay") ||
                             description.lowercased().contains("online pmt") ||
                             description.lowercased().contains("transfer"))
    }
    
    var displayAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let absAmount = abs(amount)
        return formatter.string(from: NSNumber(value: absAmount)) ?? "$0.00"
    }
}

struct FinancialSummary: Codable {
    let totalIncome: Double
    let totalExpenses: Double
    let netSavings: Double
    let availableBalance: Double
    let transactionCount: Int
    let incomeChange: String?
    let expensesChange: String?
    let savingsChange: String?
    let balanceChange: String?
    
    var formattedIncome: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalIncome)) ?? "$0.00"
    }
    
    var formattedExpenses: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalExpenses)) ?? "$0.00"
    }
    
    var formattedSavings: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: netSavings)) ?? "$0.00"
    }
    
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: availableBalance)) ?? "$0.00"
    }
}

struct BankAccount: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let institution: String
    let accountType: AccountType
    let lastFourDigits: String?
    let currency: String
    let isActive: Bool
    let createdAt: String
    
    enum AccountType: String, Codable, CaseIterable {
        case checking = "checking"
        case savings = "savings"
        case credit = "credit"
        case investment = "investment"
        case loan = "loan"
        
        var displayName: String {
            switch self {
            case .checking: return "Checking"
            case .savings: return "Savings"
            case .credit: return "Credit Card"
            case .investment: return "Investment"
            case .loan: return "Loan"
            }
        }
        
        var systemImage: String {
            switch self {
            case .checking: return "banknote"
            case .savings: return "piggybank"
            case .credit: return "creditcard"
            case .investment: return "chart.line.uptrend.xyaxis"
            case .loan: return "house"
            }
        }
        
        var color: Color {
            switch self {
            case .checking: return .blue
            case .savings: return .green
            case .credit: return .orange
            case .investment: return .purple
            case .loan: return .red
            }
        }
    }
    
    var displayName: String {
        if let lastFour = lastFourDigits {
            return "\(name) •••• \(lastFour)"
        }
        return name
    }
}

struct UploadedStatement: Codable, Identifiable {
    let id: String
    let jobId: String
    let filename: String
    let uploadDate: String
    let transactionCount: Int
    let accountId: String
    let summary: StatementSummary
    
    struct StatementSummary: Codable {
        let totalIncome: Double
        let totalExpenses: Double
        let netAmount: Double
    }
    
    init(jobId: String, filename: String, uploadDate: String, transactionCount: Int, accountId: String, summary: StatementSummary) {
        self.id = jobId
        self.jobId = jobId
        self.filename = filename
        self.uploadDate = uploadDate
        self.transactionCount = transactionCount
        self.accountId = accountId
        self.summary = summary
    }
}

// MARK: - Category Analysis
extension Transaction {
    static let categoryColors: [String: String] = [
        "Groceries": "green",
        "Food & Dining": "orange", 
        "Transportation": "blue",
        "Shopping": "purple",
        "Entertainment": "pink",
        "Utilities": "red",        // Fixed: was "Bills & Utilities"
        "Healthcare": "mint",
        "Travel": "teal",
        "Income": "green",
        "Transfers": "blue",       // Added: for payment/transfer category
        "Business": "orange",      // Added: business expense category
        "Education": "purple",     // Added: education category
        "Insurance": "red",        // Added: insurance category
        "Subscriptions": "pink",   // Added: subscription category
        "Lodging": "teal",         // Added: lodging category
        "Other": "gray"
    ]
    
    var categoryColor: String {
        return Self.categoryColors[category] ?? "gray"
    }
    
    // Helper to identify payment/transfer transactions
    var isPaymentOrTransfer: Bool {
        // Check category - use correct system category name
        if category == "Transfers" || category == "Credit Card Payment" {
            return true
        }
        
        // Check description for payment patterns
        let paymentKeywords = ["payment", "pymt", "capital one mobile", "transfer", "xfer"]
        let descriptionLower = description.lowercased()
        
        return paymentKeywords.contains { keyword in
            descriptionLower.contains(keyword)
        }
    }
    
    // Helper to identify actual income (not payments/transfers)
    var isActualIncome: Bool {
        return amount > 0 && !isPaymentOrTransfer
    }
    
    // Pre-computed display values for better performance
    var displayMerchantName: String {
        if description.contains("Capital One") {
            return "Capital One Mobile Payment"
        } else if description.contains("UBER") {
            return "Uber Eats"
        } else if description.contains("WAL-MART") || description.contains("WALMART") {
            return "Walmart"
        } else if description.contains("CHEVRON") {
            return "Chevron"
        } else if description.contains("NETFLIX") {
            return "Netflix.com"
        } else if description.contains("FARM") {
            return "Farm Roma Hipodromo"
        }
        
        // FIXED: Safe component handling to prevent range errors
        let components = description.components(separatedBy: " ")
        let safeComponents = Self.safePrefix(components, count: 4)
        return safeComponents.joined(separator: " ")
    }
    
    var displayDetailAmount: String {
        let formatter = NumberFormatter.currencyFormatter
        
        if description.lowercased().contains("capital one") {
            return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
        }
        
        if isExpense {
            return "-" + (formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00")
        } else {
            return "+" + (formatter.string(from: NSNumber(value: amount)) ?? "$0.00")
        }
    }
    
    var displayDate: String {
        return DateFormatter.fullDateFormatter.string(from: formattedDate)
    }
}

// MARK: - Performance Optimizations
extension NumberFormatter {
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
}

extension DateFormatter {
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
}

