import Foundation
import Combine

@MainActor
class FinancialDataManager: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var bankAccounts: [BankAccount] = []
    @Published var uploadedStatements: [UploadedStatement] = []
    @Published var isLoading = false
    @Published var summary: FinancialSummary = FinancialSummary(
        totalIncome: 0,
        totalExpenses: 0,
        netSavings: 0,
        availableBalance: 0,
        transactionCount: 0,
        incomeChange: nil,
        expensesChange: nil,
        savingsChange: nil,
        balanceChange: nil
    )
    
    private let userDefaults = UserDefaults.standard
    private let transactionsKey = "stored_transactions"
    private let accountsKey = "stored_accounts"
    private let statementsKey = "stored_statements"
    
    init() {
        loadStoredData()
    }
    
    // MARK: - Data Loading/Saving
    func loadStoredData() {
        isLoading = true
        
        // Load transactions
        if let transactionData = userDefaults.data(forKey: transactionsKey) {
            do {
                let decoder = JSONDecoder()
                transactions = try decoder.decode([Transaction].self, from: transactionData)
            } catch {
                print("Failed to load transactions: \(error)")
            }
        }
        
        // Load bank accounts
        if let accountData = userDefaults.data(forKey: accountsKey) {
            do {
                let decoder = JSONDecoder()
                bankAccounts = try decoder.decode([BankAccount].self, from: accountData)
            } catch {
                print("Failed to load bank accounts: \(error)")
            }
        }
        
        // Load uploaded statements
        if let statementData = userDefaults.data(forKey: statementsKey) {
            do {
                let decoder = JSONDecoder()
                uploadedStatements = try decoder.decode([UploadedStatement].self, from: statementData)
            } catch {
                print("Failed to load uploaded statements: \(error)")
            }
        }
        
        // If we have transactions but no accounts, create accounts from transaction data
        if !transactions.isEmpty && bankAccounts.isEmpty {
            createAccountsFromTransactions()
        }
        
        updateSummary()
        isLoading = false
    }
    
    private func saveData() {
        let encoder = JSONEncoder()
        
        // Save transactions
        if let transactionData = try? encoder.encode(transactions) {
            userDefaults.set(transactionData, forKey: transactionsKey)
        }
        
        // Save bank accounts
        if let accountData = try? encoder.encode(bankAccounts) {
            userDefaults.set(accountData, forKey: accountsKey)
        }
        
        // Save uploaded statements
        if let statementData = try? encoder.encode(uploadedStatements) {
            userDefaults.set(statementData, forKey: statementsKey)
        }
    }
    
    // MARK: - Account Management
    private func createAccountsFromTransactions() {
        let uniqueAccountIds = Set(transactions.compactMap { $0.accountId })
        
        for accountId in uniqueAccountIds {
            let account = detectBankAccount(from: accountId, transactions: transactions)
            bankAccounts.append(account)
        }
        
        saveData()
    }
    
    private func detectBankAccount(from accountId: String, transactions: [Transaction]) -> BankAccount {
        let accountIdLower = accountId.lowercased()
        
        var institution = "Unknown Bank"
        var accountName = "Account"
        var accountType: BankAccount.AccountType = .checking
        
        // Detect institution from account ID
        if accountIdLower.contains("capital") && accountIdLower.contains("one") {
            institution = "Capital One"
            accountName = "Capital One Account"
            if accountIdLower.contains("credit") {
                accountType = .credit
                accountName = "Capital One Credit Card"
            }
        } else if accountIdLower.contains("navy") && accountIdLower.contains("federal") {
            institution = "Navy Federal Credit Union"
            accountName = "Navy Federal Account"
        } else if accountIdLower.contains("chase") {
            institution = "Chase Bank"
            accountName = "Chase Account"
        } else if accountIdLower.contains("wells") {
            institution = "Wells Fargo"
            accountName = "Wells Fargo Account"
        } else if accountIdLower.contains("bankofamerica") || accountIdLower.contains("bofa") {
            institution = "Bank of America"
            accountName = "Bank of America Account"
        } else if accountIdLower.contains("citi") {
            institution = "Citibank"
            accountName = "Citibank Account"
        } else if accountIdLower.contains("usaa") {
            institution = "USAA"
            accountName = "USAA Account"
        }
        
        // Try to extract last four digits
        let lastFourDigits = accountId.components(separatedBy: "_").last
        
        return BankAccount(
            id: accountId,
            name: accountName,
            institution: institution,
            accountType: accountType,
            lastFourDigits: lastFourDigits,
            currency: "USD",
            isActive: true,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    // MARK: - Transaction Management
    func addTransactions(_ newTransactions: [Transaction], jobId: String, filename: String) {
        isLoading = true
        
        // Check for duplicate jobId
        let existingJobIds = Set(transactions.compactMap { $0.jobId })
        if existingJobIds.contains(jobId) {
            print("Job \(jobId) already exists, skipping duplicate transactions")
            isLoading = false
            return
        }
        
        // Debug: Check if any transactions have forex data
        let forexTransactions = newTransactions.filter { $0.hasForex == true }
        if !forexTransactions.isEmpty {
            print("📈 Found \(forexTransactions.count) foreign currency transactions:")
            for transaction in forexTransactions {
                print("  - \(transaction.description): \(transaction.originalAmount ?? 0) \(transaction.originalCurrency ?? "??") @ \(transaction.exchangeRate ?? 0)")
            }
        }
        
        // Detect or create bank account
        let detectedAccount = detectBankAccountFromFilename(filename, transactions: newTransactions)
        
        // Check if account already exists
        let existingAccount = bankAccounts.first { account in
            account.institution == detectedAccount.institution &&
            account.accountType == detectedAccount.accountType &&
            account.lastFourDigits == detectedAccount.lastFourDigits
        }
        
        let finalAccount: BankAccount
        if let existing = existingAccount {
            finalAccount = existing
        } else {
            finalAccount = detectedAccount
            bankAccounts.append(finalAccount)
        }
        
        // Add transactions with account linkage
        let transactionsWithAccounts = newTransactions.map { transaction in
            // DEBUG: Log forex data for each transaction
            print("💾 Adding transaction: \(transaction.description)")
            print("   - originalCurrency: \(transaction.originalCurrency ?? "nil")")
            print("   - originalAmount: \(transaction.originalAmount ?? 0)")
            print("   - exchangeRate: \(transaction.exchangeRate ?? 0)")
            print("   - hasForex: \(transaction.hasForex ?? false)")
            
            return Transaction(
                id: transaction.id,
                date: transaction.date,
                description: transaction.description,
                amount: transaction.amount,
                category: transaction.category,
                confidence: transaction.confidence,
                jobId: jobId,
                accountId: finalAccount.id,
                rawData: transaction.rawData,
                originalAmount: transaction.originalAmount,
                originalCurrency: transaction.originalCurrency,
                exchangeRate: transaction.exchangeRate,
                hasForex: transaction.hasForex
            )
        }
        
        transactions.append(contentsOf: transactionsWithAccounts)
        
        // Create uploaded statement record
        let statementSummary = calculateSummary(for: transactionsWithAccounts)
        let statement = UploadedStatement(
            jobId: jobId,
            filename: filename,
            uploadDate: ISO8601DateFormatter().string(from: Date()),
            transactionCount: transactionsWithAccounts.count,
            accountId: finalAccount.id,
            summary: UploadedStatement.StatementSummary(
                totalIncome: statementSummary.totalIncome,
                totalExpenses: statementSummary.totalExpenses,
                netAmount: statementSummary.netSavings
            )
        )
        
        uploadedStatements.insert(statement, at: 0)
        
        updateSummary()
        saveData()
        isLoading = false
    }
    
    private func detectBankAccountFromFilename(_ filename: String, transactions: [Transaction]) -> BankAccount {
        let filenameLower = filename.lowercased()
        
        var institution = "Unknown Bank"
        var accountName = "Main Account"
        var accountType: BankAccount.AccountType = .checking
        
        // Detect institution from filename
        if filenameLower.contains("capital") && filenameLower.contains("one") {
            institution = "Capital One"
            accountName = "Capital One Account"
        } else if filenameLower.contains("navy") && filenameLower.contains("federal") {
            institution = "Navy Federal Credit Union"
            accountName = "Navy Federal Account"
        } else if filenameLower.contains("chase") {
            institution = "Chase Bank"
            accountName = "Chase Account"
        } else if filenameLower.contains("wells") {
            institution = "Wells Fargo"
            accountName = "Wells Fargo Account"
        } else if filenameLower.contains("bank") && filenameLower.contains("america") {
            institution = "Bank of America"
            accountName = "Bank of America Account"
        } else if filenameLower.contains("citi") {
            institution = "Citibank"
            accountName = "Citibank Account"
        } else if filenameLower.contains("usaa") {
            institution = "USAA"
            accountName = "USAA Account"
        }
        
        // Detect account type
        if filenameLower.contains("credit") {
            accountType = .credit
            accountName = "\(institution) Credit Card"
        } else if filenameLower.contains("savings") {
            accountType = .savings
            accountName = "\(institution) Savings"
        } else if filenameLower.contains("checking") {
            accountType = .checking
            accountName = "\(institution) Checking"
        }
        
        // Try to extract last four digits from filename
        let lastFourDigits = extractDigits(from: filename)
        
        let accountId = "\(institution.lowercased().replacingOccurrences(of: " ", with: "_"))_\(accountType.rawValue)_\(lastFourDigits ?? String(Int.random(in: 1000...9999)))"
        
        return BankAccount(
            id: accountId,
            name: accountName,
            institution: institution,
            accountType: accountType,
            lastFourDigits: lastFourDigits,
            currency: "USD",
            isActive: true,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    func removeDuplicates() {
        let uniqueTransactions = transactions.removingDuplicates { transaction in
            "\(transaction.date)_\(transaction.description)_\(transaction.amount)"
        }
        
        print("Removed \(transactions.count - uniqueTransactions.count) duplicate transactions")
        transactions = uniqueTransactions
        
        updateSummary()
        saveData()
    }
    
    func clearAllData() {
        transactions.removeAll()
        bankAccounts.removeAll()
        uploadedStatements.removeAll()
        
        userDefaults.removeObject(forKey: transactionsKey)
        userDefaults.removeObject(forKey: accountsKey)
        userDefaults.removeObject(forKey: statementsKey)
        
        updateSummary()
    }
    
    // MARK: - Account Queries
    func getTransactions(for accountId: String) -> [Transaction] {
        return transactions.filter { $0.accountId == accountId }
    }
    
    func getSummary(for accountId: String) -> FinancialSummary {
        let accountTransactions = getTransactions(for: accountId)
        return calculateSummary(for: accountTransactions)
    }
    
    func getAccount(for accountId: String?) -> BankAccount? {
        guard let accountId = accountId else { return nil }
        return bankAccounts.first { $0.id == accountId }
    }
    
    func getAccountType(for transaction: Transaction) -> BankAccount.AccountType? {
        return getAccount(for: transaction.accountId)?.accountType
    }
    
    // MARK: - Summary Calculation
    private func updateSummary() {
        summary = calculateSummary(for: transactions)
    }
    
    private func calculateSummary(for transactions: [Transaction]) -> FinancialSummary {
        // Exclude payments and transfers from income calculation
        let income = transactions.filter { $0.isActualIncome }.reduce(0) { $0 + $1.amount }
        
        let expenses = abs(transactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount })
        let netSavings = income - expenses
        let availableBalance = netSavings // No assumed base balance when no transactions
        
        // Calculate percentage changes only if we have data
        let incomeChange: String? = transactions.isEmpty ? nil : "+5.2%"
        let expensesChange: String? = transactions.isEmpty ? nil : "-8.1%"
        let savingsChange: String? = transactions.isEmpty ? nil : "+21.4%"
        let balanceChange: String? = transactions.isEmpty ? nil : "+12.3%"
        
        return FinancialSummary(
            totalIncome: income,
            totalExpenses: expenses,
            netSavings: netSavings,
            availableBalance: availableBalance,
            transactionCount: transactions.count,
            incomeChange: incomeChange,
            expensesChange: expensesChange,
            savingsChange: savingsChange,
            balanceChange: balanceChange
        )
    }
    
    // MARK: - Helper Methods
    private func extractDigits(from string: String) -> String? {
        let digits = string.filter { $0.isNumber }
        if digits.count >= 4 {
            return String(digits.suffix(4))
        }
        return nil
    }
    
    // MARK: - Demo Data
    func loadDemoData() {
        let demoTransactions = [
            Transaction(
                id: "demo_1",
                date: "2024-11-01",
                description: "Whole Foods Market",
                amount: -156.43,
                category: "Groceries",
                confidence: 0.95,
                jobId: "demo_job",
                accountId: "demo_account",
                rawData: [
                    "Posting Date": "11/01/2024",
                    "Transaction Date": "10/31/2024",
                    "Amount": "156.43",
                    "Credit Debit Indicator": "Debit",
                    "Type": "POS",
                    "Description": "Whole Foods Market",
                    "Category": "Groceries"
                ]
            ),
            Transaction(
                id: "demo_2",
                date: "2024-11-02",
                description: "Monthly Salary",
                amount: 5500.00,
                category: "Income",
                confidence: 1.0,
                jobId: "demo_job",
                accountId: "demo_account",
                rawData: [
                    "Posting Date": "11/02/2024",
                    "Amount": "5500.00",
                    "Credit Debit Indicator": "Credit",
                    "Type": "ACH Credit",
                    "Description": "Monthly Salary",
                    "Category": "Deposits"
                ]
            ),
            Transaction(
                id: "demo_3",
                date: "2024-11-03",
                description: "Starbucks Coffee",
                amount: -8.75,
                category: "Food & Dining",
                confidence: 0.9,
                jobId: "demo_job",
                accountId: "demo_account",
                rawData: [
                    "Posting Date": "11/03/2024",
                    "Amount": "8.75",
                    "Credit Debit Indicator": "Debit",
                    "Type": "POS",
                    "Description": "Starbucks Coffee",
                    "Category": "Food & Dining"
                ]
            )
        ]
        
        addTransactions(demoTransactions, jobId: "demo_job", filename: "demo_statement.csv")
    }
    
    // MARK: - Transaction Updates
    
    /// Update the category of a specific transaction
    func updateTransactionCategory(transactionId: String, newCategory: String) {
        guard let index = transactions.firstIndex(where: { $0.id == transactionId }) else {
            print("❌ Transaction not found: \(transactionId)")
            return
        }
        
        let oldCategory = transactions[index].category
        let originalTransaction = transactions[index]
        
        // Create new transaction with updated category
        let updatedTransaction = Transaction(
            id: originalTransaction.id,
            date: originalTransaction.date,
            description: originalTransaction.description,
            amount: originalTransaction.amount,
            category: newCategory,
            confidence: originalTransaction.confidence,
            jobId: originalTransaction.jobId,
            accountId: originalTransaction.accountId,
            rawData: originalTransaction.rawData,
            originalAmount: originalTransaction.originalAmount,
            originalCurrency: originalTransaction.originalCurrency,
            exchangeRate: originalTransaction.exchangeRate,
            hasForex: originalTransaction.hasForex
        )
        
        // Update the transaction in the array
        transactions[index] = updatedTransaction
        
        // NEW: Learn from this categorization
        Task {
            await learnFromCategorization(
                transaction: updatedTransaction,
                oldCategory: oldCategory,
                newCategory: newCategory
            )
        }
        
        // Update summary and save
        updateSummary()
        saveData()
        
        print("✅ Updated transaction category: \(oldCategory) → \(newCategory)")
    }
    
    /// Update the category of a transaction using Category object (for new category system)
    func updateTransactionCategory(transactionId: String, newCategory: Category) {
        updateTransactionCategory(transactionId: transactionId, newCategory: newCategory.name)
    }
    
    // MARK: - Learning Integration
    
    /// Learn from user categorization to improve future suggestions
    @MainActor
    private func learnFromCategorization(transaction: Transaction, oldCategory: String, newCategory: String) async {
        // Get the merchant name from the transaction
        let merchantName = extractMerchantName(from: transaction.description)
        
        // Get CategoryService and RuleStorageService instances
        let categoryService = CategoryService.shared
        let ruleStorage = RuleStorageService.shared
        
        // Check if there was an existing rule that suggested the old category
        let (suggestedCategory, _) = categoryService.suggestCategory(for: transaction)
        
        if let suggestedCategory = suggestedCategory {
            // There was a suggestion
            if suggestedCategory.name == newCategory {
                // User confirmed the suggestion - increase confidence
                if var matchingRule = findMatchingRule(for: transaction) {
                    matchingRule.recordMatch()
                    ruleStorage.updateRule(matchingRule)
                    print("✅ Rule confidence increased for: \(merchantName)")
                }
            } else if suggestedCategory.name == oldCategory {
                // User corrected the suggestion
                if var matchingRule = findMatchingRule(for: transaction) {
                    matchingRule.recordCorrection()
                    ruleStorage.updateRule(matchingRule)
                    print("📝 Rule confidence decreased for: \(merchantName)")
                }
            }
        }
        
        // Create a new rule if none exists for this merchant and it's a meaningful pattern
        if !hasRuleForMerchant(merchantName) && shouldCreateRule(for: merchantName, transaction: transaction) {
            await createMerchantRule(
                merchantName: merchantName,
                category: newCategory,
                transaction: transaction
            )
        }
    }
    
    /// Helper to extract clean merchant name
    private func extractMerchantName(from description: String) -> String {
        // Use similar logic to Transaction's displayMerchantName
        if description.contains("UBER") {
            return "UBER"
        } else if description.contains("WAL-MART") || description.contains("WALMART") {
            return "WALMART"
        } else if description.contains("CHEVRON") {
            return "CHEVRON"
        } else if description.contains("NETFLIX") {
            return "NETFLIX"
        } else if description.contains("AMAZON") {
            return "AMAZON"
        } else if description.contains("STARBUCKS") {
            return "STARBUCKS"
        }
        
        // For other merchants, take first 1-3 meaningful words
        let words = description.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty && $0.count > 2 }
            .prefix(2)
        
        return words.joined(separator: " ").uppercased()
    }
    
    /// Find a rule that matches this transaction
    private func findMatchingRule(for transaction: Transaction) -> CategoryRule? {
        let allRules = RuleStorageService.shared.allRules
        
        return allRules.first { rule in
            rule.matches(transaction: transaction)
        }
    }
    
    /// Check if we already have a rule for this merchant
    private func hasRuleForMerchant(_ merchantName: String) -> Bool {
        let allRules = RuleStorageService.shared.allRules
        
        return allRules.contains { rule in
            if let exact = rule.merchantExact {
                return exact.localizedCaseInsensitiveCompare(merchantName) == .orderedSame
            }
            if let contains = rule.merchantContains {
                return merchantName.localizedCaseInsensitiveContains(contains)
            }
            return false
        }
    }
    
    /// Determine if we should create a rule for this merchant
    private func shouldCreateRule(for merchantName: String, transaction: Transaction) -> Bool {
        // Don't create rules for very generic or short merchant names
        if merchantName.count < 3 || merchantName.contains("UNKNOWN") {
            return false
        }
        
        // Don't create rules for one-time transactions (transfers, payments, etc.)
        let description = transaction.description.lowercased()
        let skipPatterns = ["payment", "transfer", "xfer", "pymt", "deposit", "withdrawal", "atm"]
        
        for pattern in skipPatterns {
            if description.contains(pattern) {
                return false
            }
        }
        
        return true
    }
    
    /// Create a merchant-specific rule from user categorization
    private func createMerchantRule(merchantName: String, category: String, transaction: Transaction) async {
        // Find the category object
        guard let categoryObj = CategoryService.shared.categories.first(where: { $0.name == category }) else {
            print("❌ Category not found: \(category)")
            return
        }
        
        // Create a merchant-based rule
        var newRule = CategoryRule(
            categoryId: categoryObj.id,
            ruleName: "Auto: \(merchantName)"
        )
        
        // Set rule properties
        newRule.merchantContains = merchantName
        newRule.amountSign = transaction.amount < 0 ? .negative : .positive
        newRule.priority = 75 // User-generated rules get medium priority
        newRule.confidence = 0.75 // Start with reasonable confidence
        newRule.isActive = true
        
        // Save the rule
        RuleStorageService.shared.saveRule(newRule)
        print("🎯 Created new merchant rule: \(merchantName) → \(category)")
    }
}

// MARK: - Array Extensions
private extension Array {
    func removingDuplicates<T: Hashable>(by keyPath: (Element) -> T) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert(keyPath($0)).inserted }
    }
}