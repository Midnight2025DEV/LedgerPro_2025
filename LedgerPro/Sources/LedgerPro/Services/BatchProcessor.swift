import Foundation
import Combine

// MARK: - BatchProcessor Protocol

/// Protocol for batch processing operations with progress tracking
protocol BatchProcessor {
    associatedtype Item
    associatedtype Result
    
    /// Process a batch of items
    func processBatch(_ items: [Item]) async throws -> [Result]
    
    /// The optimal batch size for this processor
    var batchSize: Int { get }
}

// MARK: - Batch Progress Types

/// Progress information for batch operations
public struct BatchProgress {
    public let totalItems: Int
    public let processedItems: Int
    public let currentBatch: Int
    public let totalBatches: Int
    public let estimatedTimeRemaining: TimeInterval
    public let startTime: CFAbsoluteTime
    
    /// Percentage complete (0.0 to 1.0)
    public var percentComplete: Double {
        guard totalItems > 0 else { return 0 }
        return Double(processedItems) / Double(totalItems)
    }
    
    /// Items per second based on current progress
    public var itemsPerSecond: Double {
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        guard elapsedTime > 0, processedItems > 0 else { return 0 }
        return Double(processedItems) / elapsedTime
    }
    
    /// Current memory usage in MB
    public var currentMemoryMB: Int {
        return PerformanceMonitor.shared.getCurrentMemoryUsage()
    }
    
    public init(totalItems: Int, processedItems: Int, currentBatch: Int, totalBatches: Int, estimatedTimeRemaining: TimeInterval, startTime: CFAbsoluteTime) {
        self.totalItems = totalItems
        self.processedItems = processedItems
        self.currentBatch = currentBatch
        self.totalBatches = totalBatches
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.startTime = startTime
    }
}

// MARK: - TransactionBatchProcessor

/// Batch processor specifically for Transaction objects
class TransactionBatchProcessor: BatchProcessor {
    typealias Item = Transaction
    typealias Result = Transaction
    
    /// Optimal batch size for transaction processing
    let batchSize: Int
    
    private let categoryService: CategoryService
    
    init(batchSize: Int = 500, categoryService: CategoryService) {
        self.batchSize = batchSize
        self.categoryService = categoryService
    }
    
    /// Process a batch of transactions with auto-categorization
    func processBatch(_ items: [Transaction]) async throws -> [Transaction] {
        return await PerformanceMonitor.shared.trackFilterOperation(
            filterType: "batch_transaction_processing",
            itemCount: items.count
        ) {
            // Track memory before processing
            PerformanceMonitor.shared.recordMemoryUsage(
                context: "before_batch_\(items.count)",
                itemCount: items.count
            )
            
            // Process transactions with auto-categorization
            var processedTransactions: [Transaction] = []
            
            for transaction in items {
                // Apply categorization rules
                let (suggestedCategory, confidence) = await categoryService.suggestCategory(for: transaction)
                let categorizedTransaction = Transaction(
                    id: transaction.id,
                    date: transaction.date,
                    description: transaction.description,
                    amount: transaction.amount,
                    category: suggestedCategory?.name ?? transaction.category,
                    confidence: confidence ?? transaction.confidence ?? 0.0,
                    jobId: transaction.jobId,
                    accountId: transaction.accountId,
                    rawData: transaction.rawData,
                    originalAmount: transaction.originalAmount,
                    originalCurrency: transaction.originalCurrency,
                    exchangeRate: transaction.exchangeRate
                )
                processedTransactions.append(categorizedTransaction)
                
                // Yield control periodically to prevent blocking
                if processedTransactions.count % 50 == 0 {
                    await Task.yield()
                }
            }
            
            // Track memory after processing
            PerformanceMonitor.shared.recordMemoryUsage(
                context: "after_batch_\(items.count)",
                itemCount: processedTransactions.count
            )
            
            AppLogger.shared.info("🔄 Processed batch of \(items.count) transactions", category: "BatchProcessor")
            
            return processedTransactions
        }
    }
}


// MARK: - BatchProcessingError

enum BatchProcessingError: LocalizedError {
    case invalidBatchSize
    case processingFailed(String)
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidBatchSize:
            return "Invalid batch size specified"
        case .processingFailed(let message):
            return "Batch processing failed: \(message)"
        case .cancelled:
            return "Batch processing was cancelled"
        }
    }
}

// MARK: - Utility Extensions

extension PerformanceMonitor {
    /// Get current memory usage in MB
    func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Int(info.resident_size / 1024 / 1024)
        } else {
            return 0
        }
    }
}