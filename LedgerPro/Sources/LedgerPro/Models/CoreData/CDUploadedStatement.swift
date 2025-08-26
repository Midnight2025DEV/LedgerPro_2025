import Foundation
import CoreData

/// Core Data entity representing an uploaded statement
@objc(CDUploadedStatement)
public class CDUploadedStatement: NSManagedObject {
    
    // MARK: - Core Data Properties
    
    @NSManaged public var id: String
    @NSManaged public var jobId: String
    @NSManaged public var filename: String
    @NSManaged public var uploadDate: Date
    @NSManaged public var transactionCount: Int32
    
    // Summary fields
    @NSManaged public var totalIncome: Double
    @NSManaged public var totalExpenses: Double
    @NSManaged public var netAmount: Double
    
    // Metadata
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    // MARK: - Relationships
    
    @NSManaged public var account: CDAccount?
    @NSManaged public var transactions: NSSet?
    
    // MARK: - Computed Properties
    
    /// Convert to domain model UploadedStatement
    public func toUploadedStatement() -> UploadedStatement {
        let summary = UploadedStatement.StatementSummary(
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netAmount: netAmount
        )
        
        return UploadedStatement(
            jobId: jobId,
            filename: filename,
            uploadDate: ISO8601DateFormatter().string(from: uploadDate),
            transactionCount: Int(transactionCount),
            accountId: account?.id ?? "",
            summary: summary
        )
    }
    
    /// Get transactions as an array
    public var transactionsArray: [CDTransaction] {
        let set = transactions as? Set<CDTransaction> ?? []
        return Array(set).sorted { $0.date > $1.date }
    }
    
    // MARK: - Factory Methods
    
    /// Create CDUploadedStatement from domain model UploadedStatement
    public static func create(
        from statement: UploadedStatement,
        in context: NSManagedObjectContext,
        account: CDAccount? = nil
    ) -> CDUploadedStatement {
        let cdStatement = CDUploadedStatement(context: context)
        cdStatement.update(from: statement, account: account)
        return cdStatement
    }
    
    /// Update CDUploadedStatement from domain model UploadedStatement
    public func update(from statement: UploadedStatement, account: CDAccount? = nil) {
        self.id = statement.id
        self.jobId = statement.jobId
        self.filename = statement.filename
        self.transactionCount = Int32(statement.transactionCount)
        
        // Parse upload date
        if let uploadDate = ISO8601DateFormatter().date(from: statement.uploadDate) {
            self.uploadDate = uploadDate
        } else {
            self.uploadDate = Date()
        }
        
        // Summary data
        self.totalIncome = statement.summary.totalIncome
        self.totalExpenses = statement.summary.totalExpenses
        self.netAmount = statement.summary.netAmount
        
        // Set account relationship
        if let account = account {
            self.account = account
        }
        
        self.updatedAt = Date()
    }
    
    // MARK: - Core Data Lifecycle
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        let now = Date()
        createdAt = now
        updatedAt = now
        uploadDate = now
        
        // Set default values
        transactionCount = 0
        totalIncome = 0.0
        totalExpenses = 0.0
        netAmount = 0.0
    }
    
    public override func willSave() {
        super.willSave()
        
        // Update timestamp on every save
        if !isDeleted {
            updatedAt = Date()
        }
    }
}

// MARK: - Fetch Request Extensions

extension CDUploadedStatement {
    
    /// Fetch request for all statements
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUploadedStatement> {
        return NSFetchRequest<CDUploadedStatement>(entityName: "CDUploadedStatement")
    }
    
    /// Fetch statements for a specific account
    public static func fetchRequest(for accountId: String) -> NSFetchRequest<CDUploadedStatement> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "account.id == %@", accountId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDUploadedStatement.uploadDate, ascending: false)]
        return request
    }
    
    /// Fetch statements by date range
    public static func fetchRequest(from startDate: Date, to endDate: Date) -> NSFetchRequest<CDUploadedStatement> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "uploadDate >= %@ AND uploadDate <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDUploadedStatement.uploadDate, ascending: false)]
        return request
    }
    
    /// Fetch recent statements (last 30 days)
    public static func fetchRecentStatementsRequest() -> NSFetchRequest<CDUploadedStatement> {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return fetchRequest(from: thirtyDaysAgo, to: Date())
    }
    
    /// Find statement by job ID
    public static func fetchRequest(jobId: String) -> NSFetchRequest<CDUploadedStatement> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "jobId == %@", jobId)
        request.fetchLimit = 1
        return request
    }
}

// MARK: - Relationship Management

extension CDUploadedStatement {
    
    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: CDTransaction)
    
    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: CDTransaction)
    
    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)
    
    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)
}

// MARK: - Identifiable Conformance

extension CDUploadedStatement: Identifiable {
    // NSManagedObject already has an objectID, but we use our custom id
}