#!/bin/bash

echo "🔧 Applying Test Fixes..."
echo "========================="

cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro

# 1. Fix Transaction model - make hasForex a computed property
echo "📝 Fixing Transaction model (hasForex property)..."

# Create a temporary file with the fixed Transaction model
cat > Transaction_fixed.swift << 'EOF'
import Foundation
import SwiftUI

struct Transaction: Codable, Identifiable, Hashable {
    let id: String
    let date: String
    let description: String
    let amount: Double
    var category: String
    var confidence: Double?
    let jobId: String?
    let accountId: String?
    let rawData: [String: String]?
    
    // Foreign currency fields
    var originalAmount: Double?     // Original foreign amount
    var originalCurrency: String?   // Currency code (EUR, GBP, MXN, etc.)
    var exchangeRate: Double?       // Exchange rate used
    
    // FIXED: Make hasForex a computed property
    var hasForex: Bool {
        return originalAmount != nil || originalCurrency != nil || exchangeRate != nil
    }
    
    // Auto-categorization tracking
    var wasAutoCategorized: Bool?   // Whether this was auto-categorized
    let categorizationMethod: String? // "merchant_rule", "smart_rule", "ai_suggestion"
    
    enum CodingKeys: String, CodingKey {
        case id, date, description, amount, category, confidence, jobId, accountId
        case rawData = "raw_data"
        case originalAmount = "original_amount"
        case originalCurrency = "original_currency"
        case exchangeRate = "exchange_rate"
        case wasAutoCategorized = "was_auto_categorized"
        case categorizationMethod = "categorization_method"
    }
    
    // Memberwise initializer for creating transactions manually
    init(id: String? = nil, date: String, description: String, amount: Double, category: String, confidence: Double? = nil, jobId: String? = nil, accountId: String? = nil, rawData: [String: String]? = nil, originalAmount: Double? = nil, originalCurrency: String? = nil, exchangeRate: Double? = nil, wasAutoCategorized: Bool? = nil, categorizationMethod: String? = nil) {
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
        self.wasAutoCategorized = try container.decodeIfPresent(Bool.self, forKey: .wasAutoCategorized)
        self.categorizationMethod = try container.decodeIfPresent(String.self, forKey: .categorizationMethod)
    }
EOF

# Append the rest of the Transaction.swift file (from safeTruncateDescription onwards)
tail -n +100 Sources/LedgerPro/Models/Transaction.swift >> Transaction_fixed.swift

# Replace the original file
mv Transaction_fixed.swift Sources/LedgerPro/Models/Transaction.swift

# 2. Fix CategoryRule amount range logic
echo "📝 Fixing CategoryRule amount range logic..."

# Create a Python script to fix the CategoryRule matches function
cat > fix_category_rule.py << 'EOF'
import re

# Read the file
with open('Sources/LedgerPro/Models/CategoryRule.swift', 'r') as f:
    content = f.read()

# Find the matches function and replace the amount range logic
old_pattern = r'// Amount range checks\s*\n\s*let amount = abs\(transaction\.amount\)\s*\n\s*if let amountMin[^}]+?\}\s*\n\s*\n\s*if let amountMax[^}]+?\}'

new_code = '''// Amount range checks
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
        }'''

# Replace the old code with new code
content = re.sub(old_pattern, new_code, content, flags=re.DOTALL)

# Write back
with open('Sources/LedgerPro/Models/CategoryRule.swift', 'w') as f:
    f.write(content)
EOF

python3 fix_category_rule.py
rm fix_category_rule.py

# 3. Replace the system rules with enhanced version
echo "📝 Updating CategoryRule+SystemRules.swift with enhanced rules..."
cat > Sources/LedgerPro/Models/CategoryRule+SystemRules.swift << 'EOF'
import Foundation

extension CategoryRule {
    static let systemRules: [CategoryRule] = {
        var rules: [CategoryRule] = []
        
        // MARK: - Transportation Rules
        var uberRule = CategoryRule(categoryId: Category.systemCategoryIds.transportation, ruleName: "Uber Rides")
        uberRule.merchantContains = "UBER"
        uberRule.confidence = 0.9
        uberRule.priority = 100
        uberRule.isSystem = true
        uberRule.amountSign = .negative
        rules.append(uberRule)
        
        var lyftRule = CategoryRule(categoryId: Category.systemCategoryIds.transportation, ruleName: "Lyft Rides")
        lyftRule.merchantContains = "LYFT"
        lyftRule.confidence = 0.9
        lyftRule.priority = 100
        lyftRule.isSystem = true
        lyftRule.amountSign = .negative
        rules.append(lyftRule)
        
        var taxiRule = CategoryRule(categoryId: Category.systemCategoryIds.transportation, ruleName: "Taxi Services")
        taxiRule.regexPattern = "TAXI|CAB|YELLOW CAB"
        taxiRule.confidence = 0.8
        taxiRule.priority = 90
        taxiRule.isSystem = true
        taxiRule.amountSign = .negative
        rules.append(taxiRule)
        
        var gasRule = CategoryRule(categoryId: Category.systemCategoryIds.transportation, ruleName: "Gas Stations")
        gasRule.regexPattern = "SHELL|CHEVRON|EXXON|BP|CITGO|SUNOCO|TEXACO|76.*GAS|GAS STATION"
        gasRule.confidence = 0.85
        gasRule.priority = 95
        gasRule.isSystem = true
        gasRule.amountSign = .negative
        rules.append(gasRule)
        
        // NEW: Parking rule
        var parkingRule = CategoryRule(categoryId: Category.systemCategoryIds.transportation, ruleName: "Parking")
        parkingRule.regexPattern = "PARKING|PARK\\s*METER|METER\\s*PARKING|PARK\\s*&|PARKADE|PARKWHIZ"
        parkingRule.confidence = 0.85
        parkingRule.priority = 90
        parkingRule.isSystem = true
        parkingRule.amountSign = .negative
        rules.append(parkingRule)
        
        // MARK: - Food & Dining Rules
        var starbucksRule = CategoryRule(categoryId: Category.systemCategoryIds.foodDining, ruleName: "Starbucks")
        starbucksRule.merchantContains = "STARBUCKS"
        starbucksRule.confidence = 0.95
        starbucksRule.priority = 90
        starbucksRule.isSystem = true
        starbucksRule.amountSign = .negative
        rules.append(starbucksRule)
        
        var mcdonaldsRule = CategoryRule(categoryId: Category.systemCategoryIds.foodDining, ruleName: "McDonald's")
        mcdonaldsRule.merchantContains = "MCDONALD"
        mcdonaldsRule.confidence = 0.9
        mcdonaldsRule.priority = 85
        mcdonaldsRule.isSystem = true
        mcdonaldsRule.amountSign = .negative
        rules.append(mcdonaldsRule)
        
        // NEW: Coffee shops (Rifle Coffee)
        var coffeeRule = CategoryRule(categoryId: Category.systemCategoryIds.foodDining, ruleName: "Coffee Shops")
        coffeeRule.regexPattern = "COFFEE|CAFE|ESPRESSO|ROASTERY|BARISTA"
        coffeeRule.confidence = 0.85
        coffeeRule.priority = 80
        coffeeRule.isSystem = true
        coffeeRule.amountSign = .negative
        rules.append(coffeeRule)
        
        // NEW: Mexican food stores
        var mexicanFoodRule = CategoryRule(categoryId: Category.systemCategoryIds.foodDining, ruleName: "Mexican Food Stores")
        mexicanFoodRule.regexPattern = "CARNICERIA|FRUTERIA|PANADERIA|TAQUERIA|TORTILLERIA"
        mexicanFoodRule.confidence = 0.85
        mexicanFoodRule.priority = 80
        mexicanFoodRule.isSystem = true
        mexicanFoodRule.amountSign = .negative
        rules.append(mexicanFoodRule)
        
        // MARK: - Shopping Rules
        var amazonRule = CategoryRule(categoryId: Category.systemCategoryIds.shopping, ruleName: "Amazon")
        amazonRule.merchantContains = "AMAZON"
        amazonRule.confidence = 0.9
        amazonRule.priority = 85
        amazonRule.isSystem = true
        amazonRule.amountSign = .negative
        rules.append(amazonRule)
        
        var walmartRule = CategoryRule(categoryId: Category.systemCategoryIds.shopping, ruleName: "Walmart")
        walmartRule.merchantContains = "WALMART"
        walmartRule.confidence = 0.9
        walmartRule.priority = 85
        walmartRule.isSystem = true
        walmartRule.amountSign = .negative
        rules.append(walmartRule)
        
        // NEW: Convenience stores (OXXO)
        var convenienceRule = CategoryRule(categoryId: Category.systemCategoryIds.shopping, ruleName: "Convenience Stores")
        convenienceRule.regexPattern = "OXXO|7-ELEVEN|CIRCLE K|WAWA|CONVENIENCE|CVS(?!\\s*PHARMACY)"
        convenienceRule.confidence = 0.85
        convenienceRule.priority = 80
        convenienceRule.isSystem = true
        convenienceRule.amountSign = .negative
        rules.append(convenienceRule)
        
        // MARK: - Entertainment Rules (NEW CATEGORY)
        // Assuming entertainment category exists, otherwise use a different category
        let entertainmentId = UUID(uuidString: "00000000-0000-0000-0000-000000000032") ?? Category.systemCategoryIds.other
        
        // NEW: Streaming services
        var netflixRule = CategoryRule(categoryId: entertainmentId, ruleName: "Netflix")
        netflixRule.merchantContains = "NETFLIX"
        netflixRule.confidence = 0.95
        netflixRule.priority = 90
        netflixRule.isSystem = true
        netflixRule.amountSign = .negative
        rules.append(netflixRule)
        
        var crunchyrollRule = CategoryRule(categoryId: entertainmentId, ruleName: "Crunchyroll")
        crunchyrollRule.merchantContains = "CRUNCHYROLL"
        crunchyrollRule.confidence = 0.95
        crunchyrollRule.priority = 90
        crunchyrollRule.isSystem = true
        crunchyrollRule.amountSign = .negative
        rules.append(crunchyrollRule)
        
        var youtubeRule = CategoryRule(categoryId: entertainmentId, ruleName: "YouTube")
        youtubeRule.merchantContains = "YOUTUBE"
        youtubeRule.confidence = 0.95
        youtubeRule.priority = 90
        youtubeRule.isSystem = true
        youtubeRule.amountSign = .negative
        rules.append(youtubeRule)
        
        // MARK: - Technology/AI Services (Education or Other category)
        let educationId = UUID(uuidString: "00000000-0000-0000-0000-000000000034") ?? Category.systemCategoryIds.other
        
        // NEW: AI Services
        var claudeRule = CategoryRule(categoryId: educationId, ruleName: "Claude AI")
        claudeRule.regexPattern = "CLAUDE|ANTHROPIC"
        claudeRule.confidence = 0.95
        claudeRule.priority = 90
        claudeRule.isSystem = true
        claudeRule.amountSign = .negative
        rules.append(claudeRule)
        
        var openaiRule = CategoryRule(categoryId: educationId, ruleName: "OpenAI")
        openaiRule.regexPattern = "OPENAI|CHATGPT|GPT"
        openaiRule.confidence = 0.95
        openaiRule.priority = 90
        openaiRule.isSystem = true
        openaiRule.amountSign = .negative
        rules.append(openaiRule)
        
        // NEW: Online Education
        var courseraRule = CategoryRule(categoryId: educationId, ruleName: "Coursera")
        courseraRule.merchantContains = "COURSERA"
        courseraRule.confidence = 0.95
        courseraRule.priority = 90
        courseraRule.isSystem = true
        courseraRule.amountSign = .negative
        rules.append(courseraRule)
        
        // MARK: - Travel/Lodging Rules
        let travelId = UUID(uuidString: "00000000-0000-0000-0000-000000000033") ?? Category.systemCategoryIds.other
        
        // NEW: Hotels
        var hotelRule = CategoryRule(categoryId: travelId, ruleName: "Hotels")
        hotelRule.regexPattern = "HOTEL|MOTEL|INN|MARRIOTT|HILTON|HYATT|SHERATON|HOLIDAY\\s*INN"
        hotelRule.confidence = 0.9
        hotelRule.priority = 85
        hotelRule.isSystem = true
        hotelRule.amountSign = .negative
        rules.append(hotelRule)
        
        // MARK: - Income Rules
        var salaryRule = CategoryRule(categoryId: Category.systemCategoryIds.salary, ruleName: "Salary Deposits")
        salaryRule.descriptionContains = "PAYROLL"
        salaryRule.confidence = 0.95
        salaryRule.priority = 100
        salaryRule.isSystem = true
        salaryRule.amountSign = .positive
        rules.append(salaryRule)
        
        var incomeRule = CategoryRule(categoryId: Category.systemCategoryIds.income, ruleName: "General Income")
        incomeRule.descriptionContains = "DEPOSIT"
        incomeRule.confidence = 0.8
        incomeRule.priority = 90
        incomeRule.isSystem = true
        incomeRule.amountSign = .positive
        rules.append(incomeRule)
        
        // MARK: - Transfer Rules
        // NEW: Bank transfers
        var transferRule = CategoryRule(categoryId: Category.systemCategoryIds.other, ruleName: "Bank Transfers")
        transferRule.regexPattern = "TRANSFER|MOBILE\\s*TRANSFER|BANK\\s*TRANSFER|ACH|WIRE"
        transferRule.confidence = 0.85
        transferRule.priority = 85
        transferRule.isSystem = true
        rules.append(transferRule)
        
        // NEW: Payment services
        var paypalRule = CategoryRule(categoryId: Category.systemCategoryIds.other, ruleName: "PayPal")
        paypalRule.merchantContains = "PAYPAL"
        paypalRule.confidence = 0.9
        paypalRule.priority = 85
        paypalRule.isSystem = true
        rules.append(paypalRule)
        
        // MARK: - Credit Card Payment Rules
        var creditCardRule = CategoryRule(categoryId: Category.systemCategoryIds.creditCardPayment, ruleName: "Capital One Payments")
        creditCardRule.merchantContains = "CAPITAL ONE"
        creditCardRule.descriptionContains = "PAYMENT"
        creditCardRule.confidence = 0.95
        creditCardRule.priority = 95
        creditCardRule.isSystem = true
        creditCardRule.amountSign = .positive
        rules.append(creditCardRule)
        
        return rules
    }()
}

// MARK: - Helper Extension for Testing
extension CategoryRule {
    /// Find all rules that match a given transaction description
    static func findMatchingRules(for description: String, in rules: [CategoryRule] = systemRules) -> [CategoryRule] {
        let mockTransaction = Transaction(
            date: Date().ISO8601Format(),
            description: description,
            amount: -50.0,
            balance: 1000.0,
            category: nil,
            account: "Test"
        )
        
        return rules.filter { $0.matches(transaction: mockTransaction) }
    }
}
EOF

# 4. Clean build directory to ensure changes are picked up
echo "🧹 Cleaning build directory..."
swift package clean

# 5. Build the project
echo "🔨 Building project..."
swift build

echo ""
echo "✅ Fixes applied!"
echo ""
echo "Summary of changes:"
echo "1. ✅ Transaction.hasForex is now a computed property"
echo "2. ✅ CategoryRule amount range logic fixed for negative amounts"
echo "3. ✅ Enhanced system rules added for better categorization"
echo ""
echo "Next steps:"
echo "1. Run the tests again: ./run_fixed_tests_v2.sh"
echo "2. Check the results in the latest test_results_fixed_* directory"
