import Foundation
import CoreData
import Combine

/// Core Data manager providing thread-safe database operations with performance monitoring
@MainActor
public class CoreDataManager: ObservableObject {
    public static let shared = CoreDataManager()
    
    // MARK: - Published Properties
    
    @Published public private(set) var isInitialized = false
    @Published public private(set) var isPerformingMigration = false
    @Published public private(set) var migrationProgress: Double = 0.0
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LedgerPro")
        
        // Enable persistent history tracking for multi-context synchronization
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        // Configure persistent store for performance
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Enable WAL mode for better concurrency
        description.setOption("WAL" as NSString, forKey: NSSQLitePragmasOption)
        
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error {
                AppLogger.shared.error("Core Data failed to load: \(error)", category: "CoreData")
                fatalError("Core Data failed to load: \(error)")
            }
            
            DispatchQueue.main.async {
                self?.isInitialized = true
                AppLogger.shared.info("🗄️ Core Data stack initialized successfully", category: "CoreData")
            }
        }
        
        // Configure view context for UI operations
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.name = "ViewContext"
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    // MARK: - Context Management
    
    /// Main context for UI operations - always use on main thread
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    /// Create a new background context for data processing operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.name = "BackgroundContext-\(UUID().uuidString.prefix(8))"
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Save Operations
    
    /// Save the view context with error handling and performance tracking
    func saveViewContext() throws {
        guard viewContext.hasChanges else { return }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            try viewContext.save()
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            AppLogger.shared.debug("💾 View context saved in \(String(format: "%.3f", duration))s", category: "CoreData")
            
            // Track save performance
            Analytics.shared.trackPerformanceMetric(
                metricName: "core_data_save_duration",
                value: duration,
                metadata: ["context": "view", "changes": "\(viewContext.insertedObjects.count + viewContext.updatedObjects.count + viewContext.deletedObjects.count)"]
            )
        } catch {
            AppLogger.shared.error("Failed to save view context: \(error)", category: "CoreData")
            throw CoreDataError.saveFailed(error)
        }
    }
    
    /// Save a background context with error handling
    func saveContext(_ context: NSManagedObjectContext) async throws {
        guard context.hasChanges else { return }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await context.perform {
            do {
                try context.save()
                
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                AppLogger.shared.debug("💾 Background context saved in \(String(format: "%.3f", duration))s", category: "CoreData")
                
                // Track save performance
                Analytics.shared.trackPerformanceMetric(
                    metricName: "core_data_save_duration",
                    value: duration,
                    metadata: ["context": "background", "changes": "\(context.insertedObjects.count + context.updatedObjects.count + context.deletedObjects.count)"]
                )
            } catch {
                AppLogger.shared.error("Failed to save background context: \(error)", category: "CoreData")
                throw CoreDataError.saveFailed(error)
            }
        }
    }
    
    // MARK: - Batch Operations
    
    /// Perform batch insert with progress tracking
    func batchInsert<T: NSManagedObject>(
        entity: T.Type,
        objects: [[String: Any]],
        batchSize: Int = 500
    ) async throws {
        let context = newBackgroundContext()
        let entityName = String(describing: entity)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let batches = objects.chunked(into: batchSize)
        
        AppLogger.shared.info("🔄 Starting batch insert: \(objects.count) \(entityName) objects in \(batches.count) batches", category: "CoreData")
        
        for (index, batch) in batches.enumerated() {
            try await context.perform {
                // Create batch insert request
                let request = NSBatchInsertRequest(entityName: entityName, objects: batch)
                request.resultType = .count
                
                do {
                    let result = try context.execute(request) as? NSBatchInsertResult
                    let insertCount = result?.result as? Int ?? 0
                    
                    AppLogger.shared.debug("✅ Batch \(index + 1)/\(batches.count): inserted \(insertCount) \(entityName) objects", category: "CoreData")
                } catch {
                    AppLogger.shared.error("Batch insert failed for batch \(index + 1): \(error)", category: "CoreData")
                    throw CoreDataError.batchOperationFailed(error)
                }
            }
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        AppLogger.shared.info("🎉 Batch insert completed: \(objects.count) objects in \(String(format: "%.3f", duration))s", category: "CoreData")
        
        // Track batch insert performance
        Analytics.shared.trackBatchOperation(
            operation: "batch_insert_\(entityName)",
            batchSize: batchSize,
            itemsProcessed: objects.count,
            duration: duration,
            memoryUsageMB: PerformanceMonitor.shared.getCurrentMemoryUsage()
        )
    }
    
    /// Perform batch delete with predicate
    func batchDelete<T: NSManagedObject>(
        entity: T.Type,
        predicate: NSPredicate? = nil
    ) async throws -> Int {
        let context = newBackgroundContext()
        let entityName = String(describing: entity)
        
        return try await context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            fetchRequest.predicate = predicate
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeCount
            
            do {
                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                let deleteCount = result?.result as? Int ?? 0
                
                AppLogger.shared.info("🗑️ Batch deleted \(deleteCount) \(entityName) objects", category: "CoreData")
                return deleteCount
            } catch {
                AppLogger.shared.error("Batch delete failed: \(error)", category: "CoreData")
                throw CoreDataError.batchOperationFailed(error)
            }
        }
    }
    
    // MARK: - Query Operations
    
    /// Fetch objects with performance tracking
    func fetch<T: NSManagedObject>(
        _ type: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor] = [],
        limit: Int? = nil,
        context: NSManagedObjectContext? = nil
    ) async throws -> [T] {
        let targetContext = context ?? viewContext
        let entityName = String(describing: type)
        
        return try await targetContext.perform {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let request = NSFetchRequest<T>(entityName: entityName)
            request.predicate = predicate
            request.sortDescriptors = sortDescriptors
            
            if let limit = limit {
                request.fetchLimit = limit
            }
            
            do {
                let results = try targetContext.fetch(request)
                
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                AppLogger.shared.debug("🔍 Fetched \(results.count) \(entityName) objects in \(String(format: "%.3f", duration))s", category: "CoreData")
                
                return results
            } catch {
                AppLogger.shared.error("Fetch failed for \(entityName): \(error)", category: "CoreData")
                throw CoreDataError.fetchFailed(error)
            }
        }
    }
    
    /// Count objects matching predicate
    func count<T: NSManagedObject>(
        _ type: T.Type,
        predicate: NSPredicate? = nil,
        context: NSManagedObjectContext? = nil
    ) async throws -> Int {
        let targetContext = context ?? viewContext
        let entityName = String(describing: type)
        
        return try await targetContext.perform {
            let request = NSFetchRequest<T>(entityName: entityName)
            request.predicate = predicate
            
            do {
                return try targetContext.count(for: request)
            } catch {
                AppLogger.shared.error("Count failed for \(entityName): \(error)", category: "CoreData")
                throw CoreDataError.fetchFailed(error)
            }
        }
    }
    
    // MARK: - Migration Support
    
    /// Check if migration is needed
    func requiresMigration() -> Bool {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            return false
        }
        
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL,
                options: nil
            )
            
            let model = persistentContainer.managedObjectModel
            return !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        } catch {
            AppLogger.shared.error("Failed to check migration requirement: \(error)", category: "CoreData")
            return false
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Initialize Core Data stack
        _ = persistentContainer
    }
    
    deinit {
        // Deinit happens on any queue, skip cleanup that requires main actor
        // Core Data will handle cleanup automatically
    }
}

// MARK: - Core Data Errors

enum CoreDataError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case batchOperationFailed(Error)
    case migrationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save Core Data context: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch from Core Data: \(error.localizedDescription)"
        case .batchOperationFailed(let error):
            return "Batch operation failed: \(error.localizedDescription)"
        case .migrationFailed(let message):
            return "Core Data migration failed: \(message)"
        }
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}