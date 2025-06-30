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
            Transaction(
                id: transaction.id,
                date: transaction.date,
                description: transaction.description,
                amount: transaction.amount,
                category: transaction.category,
                confidence: transaction.confidence,
                jobId: jobId,
                accountId: finalAccount.id,
                rawData: transaction.rawData
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
    
    // MARK: - Summary Calculation
    private func updateSummary() {
        summary = calculateSummary(for: transactions)
    }
    
    private func calculateSummary(for transactions: [Transaction]) -> FinancialSummary {
        let income = transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
        let expenses = abs(transactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount })
        let netSavings = income - expenses
        let availableBalance = netSavings + 1000 // Assume base balance
        
        return FinancialSummary(
            totalIncome: income,
            totalExpenses: expenses,
            netSavings: netSavings,
            availableBalance: availableBalance,
            transactionCount: transactions.count,
            incomeChange: "+5.2%",
            expensesChange: "-8.1%",
            savingsChange: "+21.4%",
            balanceChange: "+12.3%"
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
}

// MARK: - Array Extensions
private extension Array {
    func removingDuplicates<T: Hashable>(by keyPath: (Element) -> T) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert(keyPath($0)).inserted }
    }
}