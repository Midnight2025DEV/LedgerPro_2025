import Foundation
import CoreData
import Combine

/// Service responsible for migrating data from UserDefaults to Core Data
@MainActor
public class CoreDataMigrationService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var isMigrating = false
    @Published public private(set) var migrationProgress: Double = 0.0
    @Published public private(set) var migrationStep: String = ""
    @Published public private(set) var migrationCompleted = false
    @Published public private(set) var migrationError: Error?
    
    // MARK: - Dependencies
    
    private let coreDataManager: CoreDataManager
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults keys
    private let transactionsKey = "stored_transactions"
    private let accountsKey = "stored_accounts"
    private let statementsKey = "stored_statements"
    private let migrationCompletedKey = "core_data_migration_completed"
    
    // MARK: - Initialization
    
    public init(coreDataManager: CoreDataManager? = nil) {
        self.coreDataManager = coreDataManager ?? CoreDataManager.shared
    }
    
    // MARK: - Migration Status
    
    /// Check if migration has been completed
    public var hasMigrationCompleted: Bool {
        return userDefaults.bool(forKey: migrationCompletedKey)
    }
    
    /// Check if migration is needed
    public func needsMigration() async -> Bool {
        // If migration already completed, no need to migrate
        if hasMigrationCompleted {
            return false
        }
        
        // Check if there's any data in UserDefaults to migrate
        let hasTransactions = userDefaults.data(forKey: transactionsKey) != nil
        let hasAccounts = userDefaults.data(forKey: accountsKey) != nil
        let hasStatements = userDefaults.data(forKey: statementsKey) != nil
        
        return hasTransactions || hasAccounts || hasStatements
    }
    
    // MARK: - Migration Process
    
    /// Perform complete migration from UserDefaults to Core Data
    public func performMigration() async throws {
        guard await needsMigration() else {
            AppLogger.shared.info("🔄 No migration needed - already completed or no data to migrate", category: "Migration")
            return
        }
        
        guard !isMigrating else {
            AppLogger.shared.warning("🔄 Migration already in progress", category: "Migration")
            return
        }
        
        isMigrating = true
        migrationProgress = 0.0
        migrationError = nil
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        AppLogger.shared.info("🚀 Starting Core Data migration from UserDefaults", category: "Migration")
        
        do {
            // Step 1: Load data from UserDefaults
            migrationStep = "Loading data from UserDefaults..."
            let (transactions, accounts, statements) = try await loadDataFromUserDefaults()
            migrationProgress = 0.2
            
            // Step 2: Create Core Data context
            migrationStep = "Preparing Core Data..."
            let context = coreDataManager.newBackgroundContext()
            migrationProgress = 0.3
            
            // Step 3: Migrate accounts first (they're referenced by transactions)
            migrationStep = "Migrating \(accounts.count) accounts..."
            let accountMapping = try await migrateAccounts(accounts, to: context)
            migrationProgress = 0.5
            
            // Step 4: Migrate transactions
            migrationStep = "Migrating \(transactions.count) transactions..."
            try await migrateTransactions(transactions, to: context, accountMapping: accountMapping)
            migrationProgress = 0.8
            
            // Step 5: Migrate statements
            migrationStep = "Migrating \(statements.count) statements..."
            try await migrateStatements(statements, to: context, accountMapping: accountMapping)
            migrationProgress = 0.9
            
            // Step 6: Save and finalize
            migrationStep = "Finalizing migration..."
            try await coreDataManager.saveContext(context)
            
            // Mark migration as completed
            userDefaults.set(true, forKey: migrationCompletedKey)
            
            migrationProgress = 1.0
            migrationCompleted = true
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            AppLogger.shared.info("🎉 Core Data migration completed successfully in \(String(format: "%.2f", duration))s", category: "Migration")
            
            // Track migration success
            Analytics.shared.track("core_data_migration_completed", properties: [
                "transaction_count": transactions.count,
                "account_count": accounts.count,
                "statement_count": statements.count,
                "duration_seconds": duration,
                "success": true
            ])
            
            migrationStep = "Migration completed successfully!"
            
        } catch {
            migrationError = error
            AppLogger.shared.error("❌ Core Data migration failed: \(error)", category: "Migration")
            
            // Track migration failure
            Analytics.shared.track("core_data_migration_failed", properties: [
                "error": error.localizedDescription,
                "step": migrationStep
            ])
            
            migrationStep = "Migration failed: \(error.localizedDescription)"
            throw CoreDataMigrationError.migrationFailed(error)
        }
        
        isMigrating = false
    }
    
    // MARK: - Data Loading
    
    private func loadDataFromUserDefaults() async throws -> ([Transaction], [BankAccount], [UploadedStatement]) {
        return try await withThrowingTaskGroup(of: (String, Any).self) { group in
            
            // Load transactions
            group.addTask {
                let transactions: [Transaction]
                if let data = self.userDefaults.data(forKey: self.transactionsKey) {
                    transactions = try JSONDecoder().decode([Transaction].self, from: data)
                } else {
                    transactions = []
                }
                return ("transactions", transactions)
            }
            
            // Load accounts
            group.addTask {
                let accounts: [BankAccount]
                if let data = self.userDefaults.data(forKey: self.accountsKey) {
                    accounts = try JSONDecoder().decode([BankAccount].self, from: data)
                } else {
                    accounts = []
                }
                return ("accounts", accounts)
            }
            
            // Load statements
            group.addTask {
                let statements: [UploadedStatement]
                if let data = self.userDefaults.data(forKey: self.statementsKey) {
                    statements = try JSONDecoder().decode([UploadedStatement].self, from: data)
                } else {
                    statements = []
                }
                return ("statements", statements)
            }
            
            var transactions: [Transaction] = []
            var accounts: [BankAccount] = []
            var statements: [UploadedStatement] = []
            
            for try await result in group {
                switch result.0 {
                case "transactions":
                    transactions = result.1 as! [Transaction]
                case "accounts":
                    accounts = result.1 as! [BankAccount]
                case "statements":
                    statements = result.1 as! [UploadedStatement]
                default:
                    break
                }
            }
            
            AppLogger.shared.info("📄 Loaded from UserDefaults: \(transactions.count) transactions, \(accounts.count) accounts, \(statements.count) statements", category: "Migration")
            
            return (transactions, accounts, statements)
        }
    }
    
    // MARK: - Account Migration
    
    private func migrateAccounts(_ accounts: [BankAccount], to context: NSManagedObjectContext) async throws -> [String: CDAccount] {
        var accountMapping: [String: CDAccount] = [:]
        
        try await context.perform {
            for account in accounts {
                let cdAccount = CDAccount.create(from: account, in: context)
                accountMapping[account.id] = cdAccount
                
                AppLogger.shared.debug("✅ Migrated account: \(account.name) (\(account.institution))", category: "Migration")
            }
        }
        
        AppLogger.shared.info("🏦 Migrated \(accounts.count) accounts to Core Data", category: "Migration")
        return accountMapping
    }
    
    // MARK: - Transaction Migration
    
    private func migrateTransactions(
        _ transactions: [Transaction],
        to context: NSManagedObjectContext,
        accountMapping: [String: CDAccount]
    ) async throws {
        
        // Process transactions in batches for better performance
        let batchSize = 500
        let batches = transactions.chunked(into: batchSize)
        
        for (batchIndex, batch) in batches.enumerated() {
            try await context.perform {
                for transaction in batch {
                    let account = transaction.accountId.flatMap { accountMapping[$0] }
                    let cdTransaction = CDTransaction.create(from: transaction, in: context, account: account)
                    
                    // Link to statement if account exists
                    if let account = account {
                        account.addToTransactions(cdTransaction)
                    }
                }
            }
            
            // Update progress
            let progress = 0.5 + (Double(batchIndex + 1) / Double(batches.count)) * 0.3
            await MainActor.run {
                self.migrationProgress = progress
            }
            
            AppLogger.shared.debug("✅ Migrated transaction batch \(batchIndex + 1)/\(batches.count)", category: "Migration")
        }
        
        AppLogger.shared.info("💰 Migrated \(transactions.count) transactions to Core Data", category: "Migration")
    }
    
    // MARK: - Statement Migration
    
    private func migrateStatements(
        _ statements: [UploadedStatement],
        to context: NSManagedObjectContext,
        accountMapping: [String: CDAccount]
    ) async throws {
        
        try await context.perform {
            for statement in statements {
                let account = accountMapping[statement.accountId]
                let cdStatement = CDUploadedStatement.create(from: statement, in: context, account: account)
                
                // Link to account if exists
                if let account = account {
                    account.addToStatements(cdStatement)
                }
                
                AppLogger.shared.debug("✅ Migrated statement: \(statement.filename)", category: "Migration")
            }
        }
        
        AppLogger.shared.info("📋 Migrated \(statements.count) statements to Core Data", category: "Migration")
    }
    
    // MARK: - Cleanup
    
    /// Remove data from UserDefaults after successful migration
    public func cleanupUserDefaults() {
        userDefaults.removeObject(forKey: transactionsKey)
        userDefaults.removeObject(forKey: accountsKey)
        userDefaults.removeObject(forKey: statementsKey)
        
        AppLogger.shared.info("🧹 Cleaned up UserDefaults data after migration", category: "Migration")
    }
    
    /// Reset migration status (for testing purposes)
    public func resetMigrationStatus() {
        userDefaults.removeObject(forKey: migrationCompletedKey)
        migrationCompleted = false
    }
}

// MARK: - Migration Errors

public enum CoreDataMigrationError: LocalizedError {
    case migrationFailed(Error)
    case dataLoadingFailed(String)
    case accountMigrationFailed(Error)
    case transactionMigrationFailed(Error)
    case statementMigrationFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .migrationFailed(let error):
            return "Core Data migration failed: \(error.localizedDescription)"
        case .dataLoadingFailed(let message):
            return "Failed to load data from UserDefaults: \(message)"
        case .accountMigrationFailed(let error):
            return "Account migration failed: \(error.localizedDescription)"
        case .transactionMigrationFailed(let error):
            return "Transaction migration failed: \(error.localizedDescription)"
        case .statementMigrationFailed(let error):
            return "Statement migration failed: \(error.localizedDescription)"
        }
    }
}

