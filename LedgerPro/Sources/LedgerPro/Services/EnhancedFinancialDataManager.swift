import Foundation
import SwiftUI
import Combine
import CoreData

/// Enhanced Financial Data Manager with Core Data support and migration capabilities
@MainActor
public class EnhancedFinancialDataManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var transactions: [Transaction] = []
    @Published var bankAccounts: [BankAccount] = []
    @Published var uploadedStatements: [UploadedStatement] = []
    @Published var isLoading = false
    @Published var lastImportTime: Date? = nil
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
    
    // MARK: - Migration Properties
    
    @Published var isMigrating = false
    @Published var migrationProgress: Double = 0.0
    @Published var migrationCompleted = false
    @Published var useCoreData = false
    
    // MARK: - Batch Processing Support
    @Published var batchProgress: BatchProgress? = nil
    
    // MARK: - Dependencies
    
    private let coreDataRepository: CoreDataRepository
    private let migrationService: CoreDataMigrationService
    private let legacyDataManager: FinancialDataManager // Fallback to original implementation
    
    // MARK: - Initialization
    
    init() {
        let coreDataManager = CoreDataManager.shared
        self.coreDataRepository = CoreDataRepository(coreDataManager: coreDataManager)
        self.migrationService = CoreDataMigrationService(coreDataManager: coreDataManager)
        self.legacyDataManager = FinancialDataManager()
        
        // Check migration status
        Task {
            await checkMigrationStatus()
        }
    }
    
    // MARK: - Migration Management
    
    /// Check if migration has been completed and set the appropriate data source
    private func checkMigrationStatus() async {
        migrationCompleted = migrationService.hasMigrationCompleted
        useCoreData = migrationCompleted
        
        if migrationCompleted {
            AppLogger.shared.info("📊 Using Core Data for data operations", category: "FinancialDataManager")
            await loadDataFromCoreData()
        } else {
            AppLogger.shared.info("📊 Using UserDefaults for data operations", category: "FinancialDataManager")
            await loadDataFromUserDefaults()
            
            // Check if migration is needed
            if await migrationService.needsMigration() {
                await performMigration()
            }
        }
    }
    
    /// Perform migration from UserDefaults to Core Data
    private func performMigration() async {
        isMigrating = true
        
        do {
            // Subscribe to migration progress
            migrationService.$migrationProgress
                .receive(on: DispatchQueue.main)
                .assign(to: &$migrationProgress)
            
            try await migrationService.performMigration()
            
            // Migration completed successfully
            migrationCompleted = true
            useCoreData = true
            
            // Load data from Core Data
            await loadDataFromCoreData()
            
            // Clean up UserDefaults
            migrationService.cleanupUserDefaults()
            
            AppLogger.shared.info("🎉 Migration completed successfully. Now using Core Data.", category: "FinancialDataManager")
            
        } catch {
            AppLogger.shared.error("❌ Migration failed: \(error)", category: "FinancialDataManager")
            // Fall back to UserDefaults
            useCoreData = false
        }
        
        isMigrating = false
    }
    
    // MARK: - Data Loading
    
    /// Load data from Core Data
    private func loadDataFromCoreData() async {
        isLoading = true
        
        do {
            async let transactionsTask = coreDataRepository.fetchTransactions()
            async let accountsTask = coreDataRepository.fetchAccounts()
            async let statementsTask = coreDataRepository.fetchStatements()
            
            let (loadedTransactions, loadedAccounts, loadedStatements) = try await (
                transactionsTask,
                accountsTask,
                statementsTask
            )
            
            transactions = loadedTransactions
            bankAccounts = loadedAccounts
            uploadedStatements = loadedStatements
            
            updateSummary()
            
            AppLogger.shared.info("📊 Loaded from Core Data: \(transactions.count) transactions, \(bankAccounts.count) accounts", category: "FinancialDataManager")
            
        } catch {
            AppLogger.shared.error("Failed to load data from Core Data: \(error)", category: "FinancialDataManager")
            // Fall back to UserDefaults
            await loadDataFromUserDefaults()
        }
        
        isLoading = false
    }
    
    /// Load data from UserDefaults (legacy)
    private func loadDataFromUserDefaults() async {
        // Delegate to legacy data manager
        await legacyDataManager.loadStoredData()
        
        // Copy data to our published properties
        transactions = legacyDataManager.transactions
        bankAccounts = legacyDataManager.bankAccounts
        uploadedStatements = legacyDataManager.uploadedStatements
        summary = legacyDataManager.summary
    }
    
    // MARK: - Transaction Operations
    
    /// Add transactions with automatic Core Data vs UserDefaults routing
    func addTransactions(_ newTransactions: [Transaction], jobId: String, filename: String) {
        if useCoreData {
            addTransactionsToCoreData(newTransactions, jobId: jobId, filename: filename)
        } else {
            legacyDataManager.addTransactions(newTransactions, jobId: jobId, filename: filename)
            // Sync the published properties
            syncFromLegacyManager()
        }
    }
    
    /// Add transactions with batch processing (Core Data optimized)
    func addTransactionsBatched(
        _ newTransactions: [Transaction],
        jobId: String,
        filename: String,
        batchSize: Int = 500
    ) {
        if useCoreData {
            Task.detached { [weak self] in
                guard let self = self else { return }
                
                do {
                    try await self.performBatchProcessing(newTransactions, jobId: jobId, filename: filename, batchSize: batchSize)
                } catch {
                    AppLogger.shared.error("Batch processing failed: \(error)", category: "FinancialDataManager")
                }
            }
        } else {
            // Delegate to legacy batch processing
            legacyDataManager.addTransactionsBatched(newTransactions, jobId: jobId, filename: filename, batchSize: batchSize)
        }
    }
    
    /// Core Data batch processing implementation
    private func performBatchProcessing(
        _ transactions: [Transaction],
        jobId: String,
        filename: String,
        batchSize: Int = 500
    ) async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        AppLogger.shared.info("🔄 Starting Core Data batch processing of \(transactions.count) transactions", category: "FinancialDataManager")
        
        // Create batches
        let batches = transactions.chunked(into: batchSize)
        
        // Track batch processing start
        Analytics.shared.track("core_data_batch_processing_started", properties: [
            "total_items": transactions.count,
            "batch_size": batchSize,
            "estimated_batches": batches.count,
            "job_id": jobId,
            "filename": filename
        ])
        
        // Process each batch
        for (index, batch) in batches.enumerated() {
            // Update progress
            let processedCount = index * batchSize
            let progress = BatchProgress(
                totalItems: transactions.count,
                processedItems: processedCount,
                currentBatch: index + 1,
                totalBatches: batches.count,
                estimatedTimeRemaining: estimateTimeRemaining(
                    startTime: startTime,
                    currentProgress: Double(processedCount) / Double(transactions.count)
                ),
                startTime: startTime
            )
            
            await MainActor.run {
                self.batchProgress = progress
            }
            
            // Process batch using Core Data repository
            try await coreDataRepository.addTransactions(batch, jobId: jobId, filename: filename)
            
            AppLogger.shared.debug("✅ Core Data batch \(index + 1)/\(batches.count) completed", category: "FinancialDataManager")
            
            // Allow UI to breathe between batches
            if index < batches.count - 1 {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
        
        // Final update
        let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        await MainActor.run {
            self.batchProgress = nil
            self.lastImportTime = Date()
        }
        
        // Reload data from Core Data
        await loadDataFromCoreData()
        
        // Track completion
        Analytics.shared.track("core_data_batch_processing_completed", properties: [
            "total_items": transactions.count,
            "total_duration": totalDuration,
            "throughput_per_second": Int(Double(transactions.count) / totalDuration),
            "success": true
        ])
        
        AppLogger.shared.info("🎉 Core Data batch processing completed: \(transactions.count) transactions in \(String(format: "%.2f", totalDuration))s", category: "FinancialDataManager")
    }
    
    /// Add transactions to Core Data
    private func addTransactionsToCoreData(_ newTransactions: [Transaction], jobId: String, filename: String) {
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            do {
                try await self.coreDataRepository.addTransactions(newTransactions, jobId: jobId, filename: filename)
                
                // Reload data on main thread
                await self.loadDataFromCoreData()
                
            } catch {
                AppLogger.shared.error("Failed to add transactions to Core Data: \(error)", category: "FinancialDataManager")
            }
        }
    }
    
    /// Update transaction category
    func updateTransactionCategory(transactionId: String, newCategory: String) {
        if useCoreData {
            Task {
                do {
                    try await coreDataRepository.updateTransactionCategory(transactionId: transactionId, newCategory: newCategory)
                    await loadDataFromCoreData()
                } catch {
                    AppLogger.shared.error("Failed to update transaction category: \(error)", category: "FinancialDataManager")
                }
            }
        } else {
            legacyDataManager.updateTransactionCategory(transactionId: transactionId, newCategory: newCategory)
            syncFromLegacyManager()
        }
    }
    
    // MARK: - Query Operations
    
    /// Get transactions for account
    func getTransactions(for accountId: String) -> [Transaction] {
        if useCoreData {
            // For Core Data, we need to filter from loaded transactions
            // In a real implementation, you might want to create async versions
            return transactions.filter { $0.accountId == accountId }
        } else {
            return legacyDataManager.getTransactions(for: accountId)
        }
    }
    
    /// Get summary for account
    func getSummary(for accountId: String) -> FinancialSummary {
        let accountTransactions = getTransactions(for: accountId)
        return calculateSummary(for: accountTransactions)
    }
    
    /// Get account by ID
    func getAccount(for accountId: String?) -> BankAccount? {
        guard let accountId = accountId else { return nil }
        return bankAccounts.first { $0.id == accountId }
    }
    
    // MARK: - Cleanup Operations
    
    /// Remove duplicate transactions
    func removeDuplicates() {
        if useCoreData {
            Task {
                do {
                    let removedCount = try await coreDataRepository.removeDuplicateTransactions()
                    AppLogger.shared.info("Removed \(removedCount) duplicate transactions from Core Data", category: "FinancialDataManager")
                    await loadDataFromCoreData()
                } catch {
                    AppLogger.shared.error("Failed to remove duplicates: \(error)", category: "FinancialDataManager")
                }
            }
        } else {
            legacyDataManager.removeDuplicates()
            syncFromLegacyManager()
        }
    }
    
    /// Clear all data
    func clearAllData() {
        if useCoreData {
            Task {
                do {
                    try await coreDataRepository.clearAllData()
                    await loadDataFromCoreData()
                } catch {
                    AppLogger.shared.error("Failed to clear Core Data: \(error)", category: "FinancialDataManager")
                }
            }
        } else {
            legacyDataManager.clearAllData()
            syncFromLegacyManager()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Sync data from legacy manager (when using UserDefaults)
    private func syncFromLegacyManager() {
        transactions = legacyDataManager.transactions
        bankAccounts = legacyDataManager.bankAccounts
        uploadedStatements = legacyDataManager.uploadedStatements
        summary = legacyDataManager.summary
    }
    
    /// Update summary based on current transactions
    private func updateSummary() {
        summary = calculateSummary(for: transactions)
    }
    
    /// Calculate summary for given transactions
    private func calculateSummary(for transactions: [Transaction]) -> FinancialSummary {
        let income = transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
        let expenses = transactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
        let netSavings = income - expenses
        
        return FinancialSummary(
            totalIncome: income,
            totalExpenses: expenses,
            netSavings: netSavings,
            availableBalance: netSavings,
            transactionCount: transactions.count,
            incomeChange: nil,
            expensesChange: nil,
            savingsChange: nil,
            balanceChange: nil
        )
    }
    
    /// Estimate time remaining for batch processing
    private func estimateTimeRemaining(startTime: CFAbsoluteTime, currentProgress: Double) -> TimeInterval {
        guard currentProgress > 0 else { return 0 }
        
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        let estimatedTotalTime = elapsedTime / currentProgress
        return max(0, estimatedTotalTime - elapsedTime)
    }
}

