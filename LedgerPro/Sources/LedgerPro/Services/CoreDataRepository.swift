import Foundation
import CoreData
import Combine

/// Repository layer providing clean interface for Core Data operations
@MainActor
public class CoreDataRepository: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var isLoading = false
    @Published public private(set) var lastError: Error?
    
    // MARK: - Dependencies
    
    private let coreDataManager: CoreDataManager
    private let performanceMonitor = PerformanceMonitor.shared
    
    // MARK: - Initialization
    
    public init(coreDataManager: CoreDataManager? = nil) {
        self.coreDataManager = coreDataManager ?? CoreDataManager.shared
    }
    
    // MARK: - Transaction Operations
    
    /// Fetch all transactions
    public func fetchTransactions() async throws -> [Transaction] {
        isLoading = true
        defer { isLoading = false }
        
        return try await performanceMonitor.trackFilterOperation(
            filterType: "fetch_all_transactions",
            itemCount: 0
        ) {
            let cdTransactions = try await coreDataManager.fetch(
                CDTransaction.self,
                sortDescriptors: [NSSortDescriptor(keyPath: \CDTransaction.date, ascending: false)]
            )
            
            return cdTransactions.map { $0.toTransaction() }
        }
    }
    
    /// Fetch transactions for a specific account
    public func fetchTransactions(for accountId: String) async throws -> [Transaction] {
        isLoading = true
        defer { isLoading = false }
        
        return try await performanceMonitor.trackFilterOperation(
            filterType: "fetch_account_transactions",
            itemCount: 0
        ) {
            let predicate = NSPredicate(format: "account.id == %@", accountId)
            let cdTransactions = try await coreDataManager.fetch(
                CDTransaction.self,
                predicate: predicate,
                sortDescriptors: [NSSortDescriptor(keyPath: \CDTransaction.date, ascending: false)]
            )
            
            return cdTransactions.map { $0.toTransaction() }
        }
    }
    
    /// Fetch transactions by category
    public func fetchTransactions(category: String) async throws -> [Transaction] {
        isLoading = true
        defer { isLoading = false }
        
        return try await performanceMonitor.trackFilterOperation(
            filterType: "fetch_category_transactions",
            itemCount: 0
        ) {
            let predicate = NSPredicate(format: "category == %@", category)
            let cdTransactions = try await coreDataManager.fetch(
                CDTransaction.self,
                predicate: predicate,
                sortDescriptors: [NSSortDescriptor(keyPath: \CDTransaction.date, ascending: false)]
            )
            
            return cdTransactions.map { $0.toTransaction() }
        }
    }
    
    /// Fetch transactions in date range
    public func fetchTransactions(from startDate: String, to endDate: String) async throws -> [Transaction] {
        isLoading = true
        defer { isLoading = false }
        
        return try await performanceMonitor.trackFilterOperation(
            filterType: "fetch_date_range_transactions",
            itemCount: 0
        ) {
            let predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate, endDate)
            let cdTransactions = try await coreDataManager.fetch(
                CDTransaction.self,
                predicate: predicate,
                sortDescriptors: [NSSortDescriptor(keyPath: \CDTransaction.date, ascending: false)]
            )
            
            return cdTransactions.map { $0.toTransaction() }
        }
    }
    
    /// Fetch uncategorized transactions
    public func fetchUncategorizedTransactions() async throws -> [Transaction] {
        isLoading = true
        defer { isLoading = false }
        
        return try await performanceMonitor.trackFilterOperation(
            filterType: "fetch_uncategorized_transactions",
            itemCount: 0
        ) {
            let predicate = NSPredicate(format: "category == %@ OR category == %@", "Other", "Uncategorized")
            let cdTransactions = try await coreDataManager.fetch(
                CDTransaction.self,
                predicate: predicate,
                sortDescriptors: [NSSortDescriptor(keyPath: \CDTransaction.date, ascending: false)]
            )
            
            return cdTransactions.map { $0.toTransaction() }
        }
    }
    
    /// Add transactions using batch processing
    public func addTransactions(_ transactions: [Transaction], jobId: String, filename: String) async throws {
        let context = coreDataManager.newBackgroundContext()
        
        // Get or create accounts
        let accountMapping = try await getOrCreateAccounts(for: transactions, in: context)
        
        // Use batch processing for large datasets
        if transactions.count > 500 {
            try await batchInsertTransactions(transactions, jobId: jobId, filename: filename, accountMapping: accountMapping, context: context)
        } else {
            try await insertTransactions(transactions, jobId: jobId, filename: filename, accountMapping: accountMapping, context: context)
        }
        
        try await coreDataManager.saveContext(context)
        
        AppLogger.shared.info("✅ Added \(transactions.count) transactions to Core Data", category: "CoreDataRepository")
        
        // Track operation
        Analytics.shared.track("transactions_added", properties: [
            "count": transactions.count,
            "job_id": jobId,
            "filename": filename,
            "method": transactions.count > 500 ? "batch" : "regular"
        ])
    }
    
    /// Update transaction category
    public func updateTransactionCategory(transactionId: String, newCategory: String) async throws {
        let context = coreDataManager.newBackgroundContext()
        
        try await context.perform {
            let predicate = NSPredicate(format: "id == %@", transactionId)
            let request = CDTransaction.fetchRequest()
            request.predicate = predicate
            request.fetchLimit = 1
            
            do {
                let results = try context.fetch(request)
                if let cdTransaction = results.first {
                    cdTransaction.category = newCategory
                    cdTransaction.updatedAt = Date()
                    
                    AppLogger.shared.info("🏷️ Updated transaction category: \(transactionId) -> \(newCategory)", category: "CoreDataRepository")
                } else {
                    throw RepositoryError.transactionNotFound(transactionId)
                }
            } catch {
                throw RepositoryError.updateFailed(error)
            }
        }
        
        try await coreDataManager.saveContext(context)
    }
    
    // MARK: - Account Operations
    
    /// Fetch all accounts
    public func fetchAccounts() async throws -> [BankAccount] {
        isLoading = true
        defer { isLoading = false }
        
        let cdAccounts = try await coreDataManager.fetch(
            CDAccount.self,
            sortDescriptors: [
                NSSortDescriptor(keyPath: \CDAccount.institution, ascending: true),
                NSSortDescriptor(keyPath: \CDAccount.name, ascending: true)
            ]
        )
        
        return cdAccounts.map { $0.toBankAccount() }
    }
    
    /// Fetch active accounts
    public func fetchActiveAccounts() async throws -> [BankAccount] {
        isLoading = true
        defer { isLoading = false }
        
        let predicate = NSPredicate(format: "isActive == YES")
        let cdAccounts = try await coreDataManager.fetch(
            CDAccount.self,
            predicate: predicate,
            sortDescriptors: [
                NSSortDescriptor(keyPath: \CDAccount.institution, ascending: true),
                NSSortDescriptor(keyPath: \CDAccount.name, ascending: true)
            ]
        )
        
        return cdAccounts.map { $0.toBankAccount() }
    }
    
    /// Find account by ID
    public func findAccount(id: String) async throws -> BankAccount? {
        let predicate = NSPredicate(format: "id == %@", id)
        let cdAccounts = try await coreDataManager.fetch(
            CDAccount.self,
            predicate: predicate,
            limit: 1
        )
        
        return cdAccounts.first?.toBankAccount()
    }
    
    // MARK: - Statement Operations
    
    /// Fetch all statements
    public func fetchStatements() async throws -> [UploadedStatement] {
        isLoading = true
        defer { isLoading = false }
        
        let cdStatements = try await coreDataManager.fetch(
            CDUploadedStatement.self,
            sortDescriptors: [NSSortDescriptor(keyPath: \CDUploadedStatement.uploadDate, ascending: false)]
        )
        
        return cdStatements.map { $0.toUploadedStatement() }
    }
    
    /// Fetch statements for account
    public func fetchStatements(for accountId: String) async throws -> [UploadedStatement] {
        isLoading = true
        defer { isLoading = false }
        
        let predicate = NSPredicate(format: "account.id == %@", accountId)
        let cdStatements = try await coreDataManager.fetch(
            CDUploadedStatement.self,
            predicate: predicate,
            sortDescriptors: [NSSortDescriptor(keyPath: \CDUploadedStatement.uploadDate, ascending: false)]
        )
        
        return cdStatements.map { $0.toUploadedStatement() }
    }
    
    // MARK: - Analytics and Aggregation
    
    /// Get transaction count
    public func getTransactionCount() async throws -> Int {
        return try await coreDataManager.count(CDTransaction.self)
    }
    
    /// Get transaction count for account
    public func getTransactionCount(for accountId: String) async throws -> Int {
        let predicate = NSPredicate(format: "account.id == %@", accountId)
        return try await coreDataManager.count(CDTransaction.self, predicate: predicate)
    }
    
    /// Get transaction count by category
    public func getTransactionCount(category: String) async throws -> Int {
        let predicate = NSPredicate(format: "category == %@", category)
        return try await coreDataManager.count(CDTransaction.self, predicate: predicate)
    }
    
    // MARK: - Cleanup Operations
    
    /// Remove duplicate transactions
    public func removeDuplicateTransactions() async throws -> Int {
        let context = coreDataManager.newBackgroundContext()
        
        return try await context.perform {
            // Fetch all transactions grouped by potential duplicate keys
            let request = CDTransaction.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTransaction.date, ascending: true)]
            
            do {
                let allTransactions = try context.fetch(request)
                var seen = Set<String>()
                var duplicates: [CDTransaction] = []
                
                for transaction in allTransactions {
                    let key = "\(transaction.date)_\(transaction.transactionDescription)_\(transaction.amount)"
                    if seen.contains(key) {
                        duplicates.append(transaction)
                    } else {
                        seen.insert(key)
                    }
                }
                
                // Delete duplicates
                for duplicate in duplicates {
                    context.delete(duplicate)
                }
                
                if duplicates.count > 0 {
                    try context.save()
                    AppLogger.shared.info("🗑️ Removed \(duplicates.count) duplicate transactions", category: "CoreDataRepository")
                }
                
                return duplicates.count
            } catch {
                throw RepositoryError.cleanupFailed(error)
            }
        }
    }
    
    /// Clear all data
    public func clearAllData() async throws {
        let context = coreDataManager.newBackgroundContext()
        
        try await context.perform {
            // Delete all transactions
            let transactionDeleteCount = try self.coreDataManager.batchDelete(entity: CDTransaction.self)
            
            // Delete all statements
            let statementDeleteCount = try self.coreDataManager.batchDelete(entity: CDUploadedStatement.self)
            
            // Delete all accounts
            let accountDeleteCount = try self.coreDataManager.batchDelete(entity: CDAccount.self)
            
            AppLogger.shared.info("🗑️ Cleared all data: \(transactionDeleteCount) transactions, \(statementDeleteCount) statements, \(accountDeleteCount) accounts", category: "CoreDataRepository")
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func getOrCreateAccounts(for transactions: [Transaction], in context: NSManagedObjectContext) async throws -> [String: CDAccount] {
        var accountMapping: [String: CDAccount] = [:]
        
        // Get unique account IDs
        let accountIds = Set(transactions.compactMap { $0.accountId })
        
        try await context.perform {
            for accountId in accountIds {
                // Try to find existing account
                let predicate = NSPredicate(format: "id == %@", accountId)
                let request = CDAccount.fetchRequest()
                request.predicate = predicate
                request.fetchLimit = 1
                
                if let existingAccount = try context.fetch(request).first {
                    accountMapping[accountId] = existingAccount
                } else {
                    // Create new account (would need account creation logic)
                    let newAccount = CDAccount(context: context)
                    newAccount.id = accountId
                    newAccount.name = "Account \(accountId.suffix(4))"
                    newAccount.institution = "Unknown"
                    newAccount.accountType = .checking
                    newAccount.currency = "USD"
                    newAccount.isActive = true
                    
                    accountMapping[accountId] = newAccount
                }
            }
        }
        
        return accountMapping
    }
    
    private func insertTransactions(
        _ transactions: [Transaction],
        jobId: String,
        filename: String,
        accountMapping: [String: CDAccount],
        context: NSManagedObjectContext
    ) async throws {
        try await context.perform {
            for transaction in transactions {
                let account = transaction.accountId.flatMap { accountMapping[$0] }
                let cdTransaction = CDTransaction.create(from: transaction, in: context, account: account)
                
                if let account = account {
                    account.addToTransactions(cdTransaction)
                }
            }
        }
    }
    
    private func batchInsertTransactions(
        _ transactions: [Transaction],
        jobId: String,
        filename: String,
        accountMapping: [String: CDAccount],
        context: NSManagedObjectContext
    ) async throws {
        let batchSize = 500
        let batches = transactions.chunked(into: batchSize)
        
        for batch in batches {
            try await context.perform {
                for transaction in batch {
                    let account = transaction.accountId.flatMap { accountMapping[$0] }
                    let cdTransaction = CDTransaction.create(from: transaction, in: context, account: account)
                    
                    if let account = account {
                        account.addToTransactions(cdTransaction)
                    }
                }
            }
            
            // Save periodically to avoid memory pressure
            try await coreDataManager.saveContext(context)
        }
    }
}

// MARK: - Repository Errors

public enum RepositoryError: LocalizedError {
    case transactionNotFound(String)
    case accountNotFound(String)
    case updateFailed(Error)
    case cleanupFailed(Error)
    case invalidData(String)
    
    public var errorDescription: String? {
        switch self {
        case .transactionNotFound(let id):
            return "Transaction not found: \(id)"
        case .accountNotFound(let id):
            return "Account not found: \(id)"
        case .updateFailed(let error):
            return "Update failed: \(error.localizedDescription)"
        case .cleanupFailed(let error):
            return "Cleanup failed: \(error.localizedDescription)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}

