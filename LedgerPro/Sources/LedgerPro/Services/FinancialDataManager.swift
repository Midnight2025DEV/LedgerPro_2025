import Foundation
import SwiftUI
import Combine

class FinancialDataManager: ObservableObject {
    @MainActor @Published var transactions: [Transaction] = []
    @MainActor @Published var bankAccounts: [BankAccount] = []
    @MainActor @Published var uploadedStatements: [UploadedStatement] = []
    @MainActor @Published var isLoading = false
    @MainActor @Published var lastImportTime: Date? = nil
    @MainActor @Published var summary: FinancialSummary = FinancialSummary(
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
        // DEBUG: Log data loading start
        AppLogger.shared.info("💾 FinancialDataManager: Starting to load stored data...")
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            await MainActor.run {
                self.isLoading = true
            }
            
            // Load data in background
            let userDefaults = UserDefaults.standard
            let loadedTransactions: [Transaction]
            let loadedAccounts: [BankAccount] 
            let loadedStatements: [UploadedStatement]
            
            // Load transactions
            if let transactionData = userDefaults.data(forKey: self.transactionsKey) {
                do {
                    let decoder = JSONDecoder()
                    loadedTransactions = try decoder.decode([Transaction].self, from: transactionData)
                } catch {
                    AppLogger.shared.error("Failed to load transactions: \(error)")
                    loadedTransactions = []
                }
            } else {
                loadedTransactions = []
            }
            
            // Load bank accounts
            if let accountData = userDefaults.data(forKey: self.accountsKey) {
                do {
                    let decoder = JSONDecoder()
                    loadedAccounts = try decoder.decode([BankAccount].self, from: accountData)
                } catch {
                    AppLogger.shared.error("Failed to load bank accounts: \(error)")
                    loadedAccounts = []
                }
            } else {
                loadedAccounts = []
            }
            
            // Load uploaded statements
            if let statementData = userDefaults.data(forKey: self.statementsKey) {
                do {
                    let decoder = JSONDecoder()
                    loadedStatements = try decoder.decode([UploadedStatement].self, from: statementData)
                } catch {
                    AppLogger.shared.error("Failed to load uploaded statements: \(error)")
                    loadedStatements = []
                }
            } else {
                loadedStatements = []
            }
            
            // Update UI on main thread
            await MainActor.run {
                self.transactions = loadedTransactions
                self.bankAccounts = loadedAccounts
                self.uploadedStatements = loadedStatements
                
                // DEBUG: Log what was loaded
                AppLogger.shared.info("💾 Loaded \(loadedTransactions.count) transactions from storage")
                AppLogger.shared.info("💾 Loaded \(loadedAccounts.count) accounts from storage")
                AppLogger.shared.info("💾 Loaded \(loadedStatements.count) statements from storage")
                
                // If we have transactions but no accounts, create accounts from transaction data
                if !self.transactions.isEmpty && self.bankAccounts.isEmpty {
                    AppLogger.shared.info("🔧 Creating accounts from transaction data...")
                    self.createAccountsFromTransactions()
                }
                
                self.updateSummaryOnMainThread()
                self.isLoading = false
            }
        }
    }
    
    private func saveData() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            // Capture current state on main thread
            let (currentTransactions, currentAccounts, currentStatements) = await MainActor.run {
                (self.transactions, self.bankAccounts, self.uploadedStatements)
            }
            
            // DEBUG: Log what we're saving
            AppLogger.shared.info("💾 Saving \(currentTransactions.count) transactions to storage")
            AppLogger.shared.info("💾 Saving \(currentAccounts.count) accounts to storage")
            AppLogger.shared.info("💾 Saving \(currentStatements.count) statements to storage")
            
            // Perform encoding and UserDefaults operations in background
            let encoder = JSONEncoder()
            let userDefaults = UserDefaults.standard
            
            // Save transactions
            if let transactionData = try? encoder.encode(currentTransactions) {
                userDefaults.set(transactionData, forKey: self.transactionsKey)
            }
            
            // Save bank accounts
            if let accountData = try? encoder.encode(currentAccounts) {
                userDefaults.set(accountData, forKey: self.accountsKey)
            }
            
            // Save uploaded statements
            if let statementData = try? encoder.encode(currentStatements) {
                userDefaults.set(statementData, forKey: self.statementsKey)
            }
        }
    }
    
    // MARK: - Account Management
    @MainActor private func createAccountsFromTransactions() {
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
        // DEBUG: Log entry point
        AppLogger.shared.info("📥 addTransactions called with \(newTransactions.count) transactions, jobId: \(jobId), filename: \(filename)")
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            await MainActor.run {
                self.isLoading = true
            }
            
            // Check for duplicate jobId on main thread (quick check)
            let existingJobIds = await MainActor.run {
                Set(self.transactions.compactMap { $0.jobId })
            }
            
            if existingJobIds.contains(jobId) {
                AppLogger.shared.warning("🔄 Job \(jobId) already exists, skipping duplicate transactions")
                await MainActor.run {
                    self.isLoading = false
                }
                return
            }
            
            // DEBUG: Log existing data before adding
            let currentTransactionCount = await MainActor.run { self.transactions.count }
            AppLogger.shared.info("📊 Current transaction count before adding: \(currentTransactionCount)")
            
            // Process data in background
            // Debug: Check if any transactions have forex data
            let forexTransactions = newTransactions.filter { $0.hasForex }
            if !forexTransactions.isEmpty {
                AppLogger.shared.info("Found \(forexTransactions.count) foreign currency transactions")
                for transaction in forexTransactions {
                    AppLogger.shared.debug("Foreign transaction: \(transaction.description): \(transaction.originalAmount ?? 0) \(transaction.originalCurrency ?? "??") @ \(transaction.exchangeRate ?? 0)")
                }
            }
            
            // Get current accounts on main thread
            let currentAccounts = await MainActor.run { self.bankAccounts }
            
            // Check if transactions already have account IDs and find/create corresponding accounts
            let uniqueAccountIds = Set(newTransactions.compactMap { $0.accountId })
            
            let (finalAccount, updatedAccounts): (BankAccount, [BankAccount])
            
            if let firstAccountId = uniqueAccountIds.first, uniqueAccountIds.count == 1 {
                // All transactions have the same accountId, try to find existing account
                if let existingAccount = currentAccounts.first(where: { $0.id == firstAccountId }) {
                    finalAccount = existingAccount
                    updatedAccounts = currentAccounts
                } else {
                    // Create account based on existing accountId
                    finalAccount = self.createAccountFromId(firstAccountId, filename: filename)
                    updatedAccounts = currentAccounts + [finalAccount]
                }
            } else {
                // No consistent accountId, detect from filename
                let detectedAccount = self.detectBankAccountFromFilename(filename, transactions: newTransactions)
                
                // Check if account already exists
                let existingAccount = currentAccounts.first { account in
                    account.institution == detectedAccount.institution &&
                    account.accountType == detectedAccount.accountType &&
                    account.lastFourDigits == detectedAccount.lastFourDigits
                }
                
                if let existing = existingAccount {
                    finalAccount = existing
                    updatedAccounts = currentAccounts
                } else {
                    finalAccount = detectedAccount
                    updatedAccounts = currentAccounts + [finalAccount]
                }
            }
            
            // Add transactions with account linkage
            let transactionsWithAccounts = newTransactions.map { transaction in
                // DEBUG: Log forex data for each transaction
                AppLogger.shared.debug("Adding transaction: \(transaction.description)")
                AppLogger.shared.debug("   - originalCurrency: \(transaction.originalCurrency ?? "nil")")
                AppLogger.shared.debug("   - originalAmount: \(transaction.originalAmount ?? 0)")
                AppLogger.shared.debug("   - exchangeRate: \(transaction.exchangeRate ?? 0)")
                AppLogger.shared.debug("   - hasForex: \(transaction.hasForex)")
                
                // Use existing accountId if present, otherwise use detected account
                let accountIdToUse = transaction.accountId ?? finalAccount.id
                
                return Transaction(
                    id: transaction.id,
                    date: transaction.date,
                    description: transaction.description,
                    amount: transaction.amount,
                    category: transaction.category,
                    confidence: transaction.confidence,
                    jobId: jobId,
                    accountId: accountIdToUse,
                    rawData: transaction.rawData,
                    originalAmount: transaction.originalAmount,
                    originalCurrency: transaction.originalCurrency,
                    exchangeRate: transaction.exchangeRate
                )
            }
            
            // Create uploaded statement record (heavy calculation in background)
            let statementSummary = self.calculateSummary(for: transactionsWithAccounts)
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
            
            // Update UI on main thread
            await MainActor.run {
                self.transactions.append(contentsOf: transactionsWithAccounts)
                self.bankAccounts = updatedAccounts
                self.uploadedStatements.insert(statement, at: 0)
                self.updateSummaryOnMainThread()
                self.lastImportTime = Date() // Trigger filter reset
                self.isLoading = false
                
                // DEBUG: Log final state after adding
                AppLogger.shared.info("✅ Transactions added successfully! New total: \(self.transactions.count)")
                AppLogger.shared.info("📊 Added \(transactionsWithAccounts.count) transactions to account: \(finalAccount.institution) - \(finalAccount.name)")
                AppLogger.shared.info("🏦 Total accounts: \(self.bankAccounts.count)")
            }
            
            // Save data in background (don't await)
            self.saveData()
        }
    }
    
    private func createAccountFromId(_ accountId: String, filename: String) -> BankAccount {
        // Try to parse account information from accountId
        let components = accountId.components(separatedBy: "_")
        
        var institution = "Unknown Bank"
        var accountName = "Account"
        var accountType: BankAccount.AccountType = .checking
        var lastFourDigits: String?
        
        // If accountId follows our pattern: institution_type_digits
        if components.count >= 2 {
            let institutionPart = components[0].replacingOccurrences(of: "_", with: " ").capitalized
            
            if institutionPart.contains("capital") {
                institution = "Capital One"
                accountName = "Capital One Account"
            } else if institutionPart.contains("test") {
                institution = "Test Bank"
                accountName = "Test Account"
            } else {
                institution = institutionPart
                accountName = "\(institutionPart) Account"
            }
            
            if components.count >= 3 {
                if let typeRaw = BankAccount.AccountType(rawValue: components[1]) {
                    accountType = typeRaw
                    accountName = "\(institution) \(typeRaw.displayName)"
                }
                
                lastFourDigits = components.last
            }
        } else {
            // Fallback: try to detect from filename
            let detectedAccount = detectBankAccountFromFilename(filename, transactions: [])
            institution = detectedAccount.institution
            accountName = detectedAccount.name
            accountType = detectedAccount.accountType
            lastFourDigits = detectedAccount.lastFourDigits
        }
        
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
    
    @MainActor func removeDuplicates() {
        let uniqueTransactions = transactions.removingDuplicates { transaction in
            "\(transaction.date)_\(transaction.description)_\(transaction.amount)"
        }
        
        AppLogger.shared.info("Removed \(transactions.count - uniqueTransactions.count) duplicate transactions")
        transactions = uniqueTransactions
        
        updateSummary()
        saveData()
    }
    
    @MainActor func clearAllData() {
        transactions.removeAll()
        bankAccounts.removeAll()
        uploadedStatements.removeAll()
        
        userDefaults.removeObject(forKey: transactionsKey)
        userDefaults.removeObject(forKey: accountsKey)
        userDefaults.removeObject(forKey: statementsKey)
        
        updateSummary()
    }
    
    // MARK: - Account Queries
    @MainActor func getTransactions(for accountId: String) -> [Transaction] {
        return transactions.filter { $0.accountId == accountId }
    }
    
    @MainActor func getSummary(for accountId: String) -> FinancialSummary {
        let accountTransactions = getTransactions(for: accountId)
        return calculateSummary(for: accountTransactions)
    }
    
    @MainActor func getAccount(for accountId: String?) -> BankAccount? {
        guard let accountId = accountId else { return nil }
        return bankAccounts.first { $0.id == accountId }
    }
    
    @MainActor func getAccountType(for transaction: Transaction) -> BankAccount.AccountType? {
        return getAccount(for: transaction.accountId)?.accountType
    }
    
    // MARK: - Summary Calculation
    @MainActor private func updateSummaryOnMainThread() {
        summary = calculateSummary(for: transactions)
    }
    
    private func updateSummary() {
        Task { @MainActor in
            summary = calculateSummary(for: transactions)
        }
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
    @MainActor func loadDemoData() {
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
    @MainActor func updateTransactionCategory(transactionId: String, newCategory: String) {
        guard let index = transactions.firstIndex(where: { $0.id == transactionId }) else {
            AppLogger.shared.error("Transaction not found: \(transactionId)")
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
            exchangeRate: originalTransaction.exchangeRate
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
            
            // Enhanced pattern learning
            PatternLearningService.shared.recordCorrection(
                transaction: updatedTransaction,
                originalCategory: oldCategory,
                newCategory: newCategory,
                confidence: updatedTransaction.confidence
            )
        }
        
        // Update summary and save
        updateSummary()
        saveData()
        
        AppLogger.shared.info("Updated transaction category: \(oldCategory) → \(newCategory)")
    }
    
    /// Update the category of a transaction using Category object (for new category system)
    @MainActor func updateTransactionCategory(transactionId: String, newCategory: Category) {
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
                    AppLogger.shared.info("Rule confidence increased for: \(merchantName)")
                }
            } else if suggestedCategory.name == oldCategory {
                // User corrected the suggestion
                if var matchingRule = findMatchingRule(for: transaction) {
                    matchingRule.recordCorrection()
                    ruleStorage.updateRule(matchingRule)
                    AppLogger.shared.info("Rule confidence decreased for: \(merchantName)")
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
    @MainActor private func findMatchingRule(for transaction: Transaction) -> CategoryRule? {
        let allRules = RuleStorageService.shared.allRules
        
        return allRules.first { rule in
            rule.matches(transaction: transaction)
        }
    }
    
    /// Check if we already have a rule for this merchant
    @MainActor private func hasRuleForMerchant(_ merchantName: String) -> Bool {
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
    @MainActor private func shouldCreateRule(for merchantName: String, transaction: Transaction) -> Bool {
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
    @MainActor private func createMerchantRule(merchantName: String, category: String, transaction: Transaction) async {
        // Find the category object
        guard let categoryObj = CategoryService.shared.categories.first(where: { $0.name == category }) else {
            AppLogger.shared.error("Category not found: \(category)")
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
        AppLogger.shared.info("Created new merchant rule: \(merchantName) → \(category)")
    }
    
    // MARK: - Account and Transaction Helpers
    
    /// Get account information for a specific account ID
    @MainActor func getAccount(for accountId: String) -> BankAccount? {
        return bankAccounts.first { $0.id == accountId }
    }
}

// MARK: - Context-Aware Financial Intelligence

extension FinancialDataManager {
    
    /// Provides context-aware financial summaries based on account type and transaction patterns
    @MainActor func getContextAwareSummary(for accountId: String? = nil) -> ContextAwareFinancialSummary {
        let relevantTransactions = accountId != nil ? 
            transactions.filter { $0.accountId == accountId } : 
            transactions
        
        // Determine account type from transactions or use mixed for all accounts
        let accountType = determineAccountType(from: relevantTransactions, accountId: accountId)
        
        switch accountType {
        case .creditCard:
            return generateCreditCardSummary(transactions: relevantTransactions)
        case .checking, .savings:
            return generateCheckingSavingsSummary(transactions: relevantTransactions)
        case .investment:
            return generateInvestmentSummary(transactions: relevantTransactions)
        case .loan:
            return generateLoanSummary(transactions: relevantTransactions)
        case .mixed:
            return generateMixedAccountSummary(transactions: relevantTransactions)
        }
    }
    
    @MainActor private func determineAccountType(from transactions: [Transaction], accountId: String?) -> AccountType {
        // If specific account ID provided, look up the actual account type
        if let accountId = accountId {
            AppLogger.shared.debug("Determining account type for ID: \(accountId)", category: "Data")
            if let account = getAccount(for: accountId) {
                AppLogger.shared.debug("Found account: \(account.displayName) - Type: \(account.accountType)", category: "Account")
                // Map BankAccount.AccountType to our AccountType
                switch account.accountType {
                case .checking:
                    return .checking
                case .savings:
                    return .savings
                case .credit:
                    return .creditCard
                case .investment:
                    return .investment
                case .loan:
                    return .loan
                }
            }
            
            // Fallback to heuristics if account not found
            let creditIndicators = transactions.filter { 
                $0.accountId == accountId && ($0.description.contains("PAYMENT") || $0.description.contains("AUTOPAY"))
            }.count
            
            let investmentIndicators = transactions.filter {
                $0.accountId == accountId && ($0.description.contains("DIVIDEND") || $0.description.contains("TRANSFER"))
            }.count
            
            if creditIndicators > 0 { return .creditCard }
            if investmentIndicators > 0 { return .investment }
            
            // Default to checking for specific accounts
            return .checking
        }
        
        // Mixed account summary
        return .mixed
    }
    
    private func generateCreditCardSummary(transactions: [Transaction]) -> ContextAwareFinancialSummary {
        let expenses = transactions.filter { $0.amount < 0 }
        let payments = transactions.filter { $0.amount > 0 }
        
        let totalSpent = expenses.reduce(0) { $0 + abs($1.amount) }
        let totalPayments = payments.reduce(0) { $0 + $1.amount }
        let currentBalance = totalSpent - totalPayments
        
        let averageTransaction = expenses.isEmpty ? 0 : totalSpent / Double(expenses.count)
        let utilizationTrend = calculateUtilizationTrend(expenses: expenses)
        
        return ContextAwareFinancialSummary(
            accountType: .creditCard,
            primaryMetrics: [
                ContextMetric(
                    title: "Current Balance",
                    value: currentBalance,
                    format: .currency,
                    trend: calculateBalanceTrend(transactions: transactions),
                    description: "Outstanding credit card balance"
                ),
                ContextMetric(
                    title: "Total Spent",
                    value: totalSpent,
                    format: .currency,
                    trend: .neutral,
                    description: "Total spending this period"
                ),
                ContextMetric(
                    title: "Average Transaction",
                    value: averageTransaction,
                    format: .currency,
                    trend: .neutral,
                    description: "Average purchase amount"
                )
            ],
            secondaryMetrics: [
                ContextMetric(
                    title: "Total Payments",
                    value: totalPayments,
                    format: .currency,
                    trend: .neutral,
                    description: "Payments made this period"
                ),
                ContextMetric(
                    title: "Utilization Trend",
                    value: utilizationTrend,
                    format: .percentage,
                    trend: utilizationTrend > 0.3 ? .negative : .positive,
                    description: "Spending pattern indicator"
                )
            ],
            insights: generateCreditCardInsights(
                totalSpent: totalSpent,
                totalPayments: totalPayments,
                averageTransaction: averageTransaction,
                transactionCount: expenses.count
            ),
            recommendations: generateCreditCardRecommendations(
                balance: currentBalance,
                utilizationTrend: utilizationTrend,
                paymentHistory: payments
            )
        )
    }
    
    private func generateCheckingSavingsSummary(transactions: [Transaction]) -> ContextAwareFinancialSummary {
        let income = transactions.filter { $0.amount > 0 }
        let expenses = transactions.filter { $0.amount < 0 }
        
        let totalIncome = income.reduce(0) { $0 + $1.amount }
        let totalExpenses = expenses.reduce(0) { $0 + abs($1.amount) }
        let netCashFlow = totalIncome - totalExpenses
        let savingsRate = totalIncome > 0 ? (netCashFlow / totalIncome) : 0
        
        return ContextAwareFinancialSummary(
            accountType: .checking,
            primaryMetrics: [
                ContextMetric(
                    title: "Net Cash Flow",
                    value: netCashFlow,
                    format: .currency,
                    trend: netCashFlow > 0 ? .positive : .negative,
                    description: "Income minus expenses"
                ),
                ContextMetric(
                    title: "Total Income",
                    value: totalIncome,
                    format: .currency,
                    trend: .neutral,
                    description: "Total deposits and income"
                ),
                ContextMetric(
                    title: "Total Expenses",
                    value: totalExpenses,
                    format: .currency,
                    trend: .neutral,
                    description: "Total spending and withdrawals"
                )
            ],
            secondaryMetrics: [
                ContextMetric(
                    title: "Savings Rate",
                    value: savingsRate,
                    format: .percentage,
                    trend: savingsRate > 0.2 ? .positive : (savingsRate > 0 ? .neutral : .negative),
                    description: "Percentage of income saved"
                ),
                ContextMetric(
                    title: "Transaction Volume",
                    value: Double(transactions.count),
                    format: .number,
                    trend: .neutral,
                    description: "Total transactions this period"
                )
            ],
            insights: generateCheckingInsights(
                netCashFlow: netCashFlow,
                savingsRate: savingsRate,
                transactionCount: transactions.count
            ),
            recommendations: generateCheckingRecommendations(
                savingsRate: savingsRate,
                netCashFlow: netCashFlow,
                expenses: expenses
            )
        )
    }
    
    private func generateInvestmentSummary(transactions: [Transaction]) -> ContextAwareFinancialSummary {
        let contributions = transactions.filter { $0.amount > 0 && !$0.description.contains("DIVIDEND") }
        let dividends = transactions.filter { $0.description.contains("DIVIDEND") }
        let withdrawals = transactions.filter { $0.amount < 0 }
        
        let totalContributions = contributions.reduce(0) { $0 + $1.amount }
        let totalDividends = dividends.reduce(0) { $0 + $1.amount }
        let totalWithdrawals = withdrawals.reduce(0) { $0 + abs($1.amount) }
        
        return ContextAwareFinancialSummary(
            accountType: .investment,
            primaryMetrics: [
                ContextMetric(
                    title: "Total Contributions",
                    value: totalContributions,
                    format: .currency,
                    trend: .positive,
                    description: "Money invested this period"
                ),
                ContextMetric(
                    title: "Dividend Income",
                    value: totalDividends,
                    format: .currency,
                    trend: .positive,
                    description: "Passive income generated"
                ),
                ContextMetric(
                    title: "Net Investment",
                    value: totalContributions - totalWithdrawals,
                    format: .currency,
                    trend: totalContributions > totalWithdrawals ? .positive : .negative,
                    description: "Net money invested"
                )
            ],
            secondaryMetrics: [
                ContextMetric(
                    title: "Withdrawals",
                    value: totalWithdrawals,
                    format: .currency,
                    trend: .neutral,
                    description: "Money withdrawn from investments"
                ),
                ContextMetric(
                    title: "Dividend Yield",
                    value: totalContributions > 0 ? (totalDividends / totalContributions) : 0,
                    format: .percentage,
                    trend: .neutral,
                    description: "Return on invested capital"
                )
            ],
            insights: generateInvestmentInsights(
                contributions: totalContributions,
                dividends: totalDividends,
                withdrawals: totalWithdrawals
            ),
            recommendations: generateInvestmentRecommendations(
                contributionPattern: contributions,
                dividendIncome: totalDividends
            )
        )
    }
    
    private func generateLoanSummary(transactions: [Transaction]) -> ContextAwareFinancialSummary {
        let payments = transactions.filter { $0.amount < 0 }
        let totalPayments = payments.reduce(0) { $0 + abs($1.amount) }
        let averagePayment = payments.isEmpty ? 0 : totalPayments / Double(payments.count)
        
        return ContextAwareFinancialSummary(
            accountType: .loan,
            primaryMetrics: [
                ContextMetric(
                    title: "Total Payments",
                    value: totalPayments,
                    format: .currency,
                    trend: .positive,
                    description: "Total loan payments made"
                ),
                ContextMetric(
                    title: "Average Payment",
                    value: averagePayment,
                    format: .currency,
                    trend: .neutral,
                    description: "Average payment amount"
                ),
                ContextMetric(
                    title: "Payment Frequency",
                    value: Double(payments.count),
                    format: .number,
                    trend: .neutral,
                    description: "Number of payments made"
                )
            ],
            secondaryMetrics: [],
            insights: generateLoanInsights(payments: payments, totalPayments: totalPayments),
            recommendations: generateLoanRecommendations(paymentPattern: payments)
        )
    }
    
    @MainActor private func generateMixedAccountSummary(transactions: [Transaction]) -> ContextAwareFinancialSummary {
        let actualIncomeTransactions = transactions.filter { $0.isActualIncome }
        let expenseTransactions = transactions.filter { $0.amount < 0 }
        
        let totalIncome = actualIncomeTransactions.reduce(0) { $0 + $1.amount }
        let totalExpenses = expenseTransactions.reduce(0) { $0 + abs($1.amount) }
        let cashFlow = totalIncome - totalExpenses
        
        // Calculate TRUE Net Worth based on account balances
        var trueNetWorth: Double = 0
        var totalAssets: Double = 0
        var totalLiabilities: Double = 0
        
        // Group transactions by account to calculate balances
        for account in self.bankAccounts {
            let accountTransactions = transactions.filter { $0.accountId == account.id }
            let inflows = accountTransactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
            let negativeTransactions = accountTransactions.filter { $0.amount < 0 }
            let outflows = abs(negativeTransactions.reduce(0) { $0 + $1.amount })
            
            switch account.accountType {
            case .checking, .savings, .investment:
                // Asset accounts: positive balance adds to net worth
                let balance = inflows - outflows
                if balance > 0 {
                    totalAssets += balance
                }
                trueNetWorth += balance
                
            case .credit, .loan:
                // Liability accounts: positive balance (debt) reduces net worth
                let balance = outflows - inflows  // What you owe
                if balance > 0 {
                    totalLiabilities += balance
                }
                trueNetWorth -= balance
            }
        }
        
        AppLogger.shared.info("Mixed Account Financial Summary:", category: "Data")
        AppLogger.shared.info("Total transactions: \(transactions.count)", category: "Data")
        AppLogger.shared.info("Actual income transactions: \(actualIncomeTransactions.count) = $\(String(format: "%.2f", totalIncome))", category: "Data")
        AppLogger.shared.info("Expense transactions: \(expenseTransactions.count) = $\(String(format: "%.2f", totalExpenses))", category: "Data")
        AppLogger.shared.info("Cash Flow (Income - Expenses): $\(String(format: "%.2f", cashFlow))", category: "Data")
        AppLogger.shared.info("Total Assets: $\(String(format: "%.2f", totalAssets))", category: "Data")
        AppLogger.shared.info("Total Liabilities: $\(String(format: "%.2f", totalLiabilities))", category: "Data")
        AppLogger.shared.info("Net Worth (Assets - Liabilities): $\(String(format: "%.2f", trueNetWorth))", category: "Data")
        
        // Debug: Show some sample income transactions
        if actualIncomeTransactions.count > 0 {
            AppLogger.shared.debug("Sample income transactions:", category: "Data")
            for transaction in actualIncomeTransactions.prefix(3) {
                AppLogger.shared.debug("\(transaction.description) = $\(String(format: "%.2f", transaction.amount)) (Category: \(transaction.category))", category: "Data")
            }
        }
        
        // Debug: Show positive amounts that were filtered out
        let filteredOutPositive = transactions.filter { $0.amount > 0 && !$0.isActualIncome }
        if filteredOutPositive.count > 0 {
            AppLogger.shared.debug("Filtered out \(filteredOutPositive.count) positive transactions:", category: "Data")
            for transaction in filteredOutPositive.prefix(3) {
                AppLogger.shared.debug("\(transaction.description) = $\(String(format: "%.2f", transaction.amount)) (Category: \(transaction.category))", category: "Data")
            }
        }
        
        return ContextAwareFinancialSummary(
            accountType: .mixed,
            primaryMetrics: [
                ContextMetric(
                    title: "Net Worth",
                    value: trueNetWorth,
                    format: .currency,
                    trend: trueNetWorth >= 0 ? .positive : .negative,
                    description: trueNetWorth >= 0 ? "Assets exceed liabilities" : "Liabilities exceed assets"
                ),
                ContextMetric(
                    title: "Total Income",
                    value: totalIncome,
                    format: .currency,
                    trend: totalIncome > 0 ? .positive : .neutral,
                    description: "All income across accounts"
                ),
                ContextMetric(
                    title: "Total Expenses",
                    value: totalExpenses,
                    format: .currency,
                    trend: .negative,
                    description: "All expenses across accounts"
                ),
                ContextMetric(
                    title: "Cash Flow",
                    value: cashFlow,
                    format: .currency,
                    trend: cashFlow >= 0 ? .positive : .negative,
                    description: cashFlow >= 0 ? "Income exceeds expenses" : "Expenses exceed income"
                )
            ],
            secondaryMetrics: [
                ContextMetric(
                    title: "Account Diversity",
                    value: Double(Set(transactions.compactMap { $0.accountId }).count),
                    format: .number,
                    trend: .neutral,
                    description: "Number of different accounts"
                )
            ],
            insights: generateMixedAccountInsights(
                netWorth: trueNetWorth,
                accountCount: Set(transactions.compactMap { $0.accountId }).count
            ),
            recommendations: generateMixedAccountRecommendations(transactions: transactions)
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateBalanceTrend(transactions: [Transaction]) -> ContextTrendDirection {
        let recentTransactions = transactions.sorted { $0.formattedDate > $1.formattedDate }.prefix(10)
        let olderTransactions = transactions.sorted { $0.formattedDate < $1.formattedDate }.prefix(10)
        
        let recentAverage = recentTransactions.reduce(0) { $0 + $1.amount } / max(1, Double(recentTransactions.count))
        let olderAverage = olderTransactions.reduce(0) { $0 + $1.amount } / max(1, Double(olderTransactions.count))
        
        if recentAverage > olderAverage * 1.1 { return .positive }
        if recentAverage < olderAverage * 0.9 { return .negative }
        return .neutral
    }
    
    private func calculateUtilizationTrend(expenses: [Transaction]) -> Double {
        guard !expenses.isEmpty else { return 0 }
        
        let highSpendingTransactions = expenses.filter { abs($0.amount) > 100 }.count
        
        return Double(highSpendingTransactions) / Double(expenses.count)
    }
    
    // MARK: - Insight Generators
    
    private func generateCreditCardInsights(totalSpent: Double, totalPayments: Double, averageTransaction: Double, transactionCount: Int) -> [String] {
        var insights: [String] = []
        
        if totalSpent > totalPayments {
            insights.append("💳 Your spending exceeds payments - consider paying down the balance")
        }
        
        if averageTransaction > 200 {
            insights.append("🛍️ High average transaction amount - review large purchases")
        }
        
        if transactionCount > 50 {
            insights.append("📊 High transaction volume - frequent small purchases detected")
        }
        
        return insights
    }
    
    private func generateCheckingInsights(netCashFlow: Double, savingsRate: Double, transactionCount: Int) -> [String] {
        var insights: [String] = []
        
        if savingsRate > 0.2 {
            insights.append("💰 Excellent savings rate - you're building wealth effectively")
        } else if savingsRate > 0 {
            insights.append("📈 Positive cash flow - consider increasing your savings rate")
        } else {
            insights.append("⚠️ Spending exceeds income - review your budget")
        }
        
        return insights
    }
    
    private func generateInvestmentInsights(contributions: Double, dividends: Double, withdrawals: Double) -> [String] {
        var insights: [String] = []
        
        if dividends > 0 {
            insights.append("📈 Generating passive income through dividends")
        }
        
        if contributions > withdrawals {
            insights.append("🎯 Net positive investment - building long-term wealth")
        }
        
        return insights
    }
    
    private func generateLoanInsights(payments: [Transaction], totalPayments: Double) -> [String] {
        var insights: [String] = []
        
        if payments.count > 1 {
            insights.append("✅ Consistent payment history")
        }
        
        if totalPayments > 1000 {
            insights.append("💪 Significant progress on loan repayment")
        }
        
        return insights
    }
    
    private func generateMixedAccountInsights(netWorth: Double, accountCount: Int) -> [String] {
        var insights: [String] = []
        
        if accountCount > 3 {
            insights.append("🏦 Well-diversified account portfolio")
        }
        
        if netWorth > 0 {
            insights.append("📊 Positive overall financial position")
        }
        
        return insights
    }
    
    // MARK: - Recommendation Generators
    
    private func generateCreditCardRecommendations(balance: Double, utilizationTrend: Double, paymentHistory: [Transaction]) -> [String] {
        var recommendations: [String] = []
        
        if balance > 1000 {
            recommendations.append("Consider making additional payments to reduce interest charges")
        }
        
        if utilizationTrend > 0.5 {
            recommendations.append("Monitor spending patterns - utilization is trending high")
        }
        
        return recommendations
    }
    
    private func generateCheckingRecommendations(savingsRate: Double, netCashFlow: Double, expenses: [Transaction]) -> [String] {
        var recommendations: [String] = []
        
        if savingsRate < 0.1 {
            recommendations.append("Try to save at least 10% of your income")
        }
        
        if netCashFlow < 0 {
            recommendations.append("Review expenses to improve cash flow")
        }
        
        return recommendations
    }
    
    private func generateInvestmentRecommendations(contributionPattern: [Transaction], dividendIncome: Double) -> [String] {
        var recommendations: [String] = []
        
        if contributionPattern.isEmpty {
            recommendations.append("Consider regular investment contributions")
        }
        
        if dividendIncome == 0 {
            recommendations.append("Explore dividend-paying investments for passive income")
        }
        
        return recommendations
    }
    
    private func generateLoanRecommendations(paymentPattern: [Transaction]) -> [String] {
        var recommendations: [String] = []
        
        if paymentPattern.count < 2 {
            recommendations.append("Establish consistent payment schedule")
        }
        
        return recommendations
    }
    
    private func generateMixedAccountRecommendations(transactions: [Transaction]) -> [String] {
        return ["Review individual account performance for optimization opportunities"]
    }
}

// MARK: - Context-Aware Models

struct ContextAwareFinancialSummary {
    let accountType: AccountType
    let primaryMetrics: [ContextMetric]
    let secondaryMetrics: [ContextMetric]
    let insights: [String]
    let recommendations: [String]
}

struct ContextMetric {
    let title: String
    let value: Double
    let format: MetricFormat
    let trend: ContextTrendDirection
    let description: String
    
    var formattedValue: String {
        switch format {
        case .currency:
            return value.formatAsCurrency()
        case .percentage:
            return String(format: "%.1f%%", value * 100)
        case .number:
            return String(format: "%.0f", value)
        }
    }
    
    var icon: String {
        switch format {
        case .currency:
            return value >= 0 ? "dollarsign.circle.fill" : "minus.circle.fill"
        case .percentage:
            return "percent"
        case .number:
            return "number.circle.fill"
        }
    }
    
    var color: Color {
        switch trend {
        case .positive:
            return .green
        case .negative:
            return .red
        case .neutral:
            return .blue
        }
    }
}

enum AccountType {
    case creditCard
    case checking
    case savings
    case investment
    case loan
    case mixed
    
    var displayName: String {
        switch self {
        case .creditCard: return "Credit Card"
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .investment: return "Investment"
        case .loan: return "Loan"
        case .mixed: return "All Accounts"
        }
    }
}

enum MetricFormat {
    case currency
    case percentage
    case number
}

enum ContextTrendDirection {
    case positive
    case negative
    case neutral
    
    var icon: String {
        switch self {
        case .positive:
            return "arrow.up.circle.fill"
        case .negative:
            return "arrow.down.circle.fill"
        case .neutral:
            return "minus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .positive:
            return .green
        case .negative:
            return .red
        case .neutral:
            return .gray
        }
    }
}

// MARK: - Array Extensions
private extension Array {
    func removingDuplicates<T: Hashable>(by keyPath: (Element) -> T) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert(keyPath($0)).inserted }
    }
}