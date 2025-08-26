import Foundation
import CoreData

/// Core Data entity representing a financial transaction
@objc(CDTransaction)
public class CDTransaction: NSManagedObject {
    
    // MARK: - Core Data Properties
    
    @NSManaged public var id: String
    @NSManaged public var date: String
    @NSManaged public var transactionDescription: String  // 'description' is reserved in NSManagedObject
    @NSManaged public var amount: Double
    @NSManaged public var category: String
    @NSManaged public var confidence: Double
    @NSManaged public var jobId: String?
    @NSManaged public var rawDataJSON: String?  // JSON string representation of rawData
    
    // Foreign currency fields
    @NSManaged public var originalAmount: Double
    @NSManaged public var originalCurrency: String?
    @NSManaged public var exchangeRate: Double
    
    // Auto-categorization tracking
    @NSManaged public var wasAutoCategorized: Bool
    @NSManaged public var categorizationMethod: String?
    
    // Timestamps
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    // MARK: - Relationships
    
    @NSManaged public var account: CDAccount?
    @NSManaged public var statement: CDUploadedStatement?
    
    // MARK: - Computed Properties
    
    /// Raw data dictionary parsed from JSON
    public var rawData: [String: String]? {
        get {
            guard let json = rawDataJSON,
                  let data = json.data(using: .utf8) else { return nil }
            return try? JSONSerialization.jsonObject(with: data) as? [String: String]
        }
        set {
            if let data = newValue {
                rawDataJSON = try? String(data: JSONSerialization.data(withJSONObject: data), encoding: .utf8)
            } else {
                rawDataJSON = nil
            }
        }
    }
    
    /// Check if transaction has valid foreign currency data
    public var hasForex: Bool {
        let hasValidCurrency = originalCurrency != nil && !originalCurrency!.isEmpty
        let hasAmount = originalAmount != 0
        let hasRate = exchangeRate > 0
        return hasValidCurrency && (hasAmount || hasRate)
    }
    
    /// Convert to domain model Transaction
    public func toTransaction() -> Transaction {
        return Transaction(
            id: id,
            date: date,
            description: transactionDescription,
            amount: amount,
            category: category,
            confidence: confidence == 0 ? nil : confidence,
            jobId: jobId,
            accountId: account?.id,
            rawData: rawData,
            originalAmount: originalAmount == 0 ? nil : originalAmount,
            originalCurrency: originalCurrency,
            exchangeRate: exchangeRate == 0 ? nil : exchangeRate,
            wasAutoCategorized: wasAutoCategorized,
            categorizationMethod: categorizationMethod
        )
    }
    
    // MARK: - Factory Methods
    
    /// Create CDTransaction from domain model Transaction
    public static func create(
        from transaction: Transaction,
        in context: NSManagedObjectContext,
        account: CDAccount? = nil
    ) -> CDTransaction {
        let cdTransaction = CDTransaction(context: context)
        cdTransaction.update(from: transaction, account: account)
        return cdTransaction
    }
    
    /// Update CDTransaction from domain model Transaction
    public func update(from transaction: Transaction, account: CDAccount? = nil) {
        self.id = transaction.id
        self.date = transaction.date
        self.transactionDescription = transaction.description
        self.amount = transaction.amount
        self.category = transaction.category
        self.confidence = transaction.confidence ?? 0.0
        self.jobId = transaction.jobId
        self.rawData = transaction.rawData
        
        // Foreign currency fields
        self.originalAmount = transaction.originalAmount ?? 0.0
        self.originalCurrency = transaction.originalCurrency
        self.exchangeRate = transaction.exchangeRate ?? 0.0
        
        // Auto-categorization tracking
        self.wasAutoCategorized = transaction.wasAutoCategorized ?? false
        self.categorizationMethod = transaction.categorizationMethod
        
        // Set account relationship
        if let account = account {
            self.account = account
        }
        
        // Update timestamps
        let now = Date()
        if self.createdAt == Date(timeIntervalSince1970: 0) {
            self.createdAt = now
        }
        self.updatedAt = now
    }
    
    // MARK: - Core Data Lifecycle
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        let now = Date()
        createdAt = now
        updatedAt = now
        
        // Set default values
        confidence = 0.0
        originalAmount = 0.0
        exchangeRate = 0.0
        wasAutoCategorized = false
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

extension CDTransaction {
    
    /// Fetch request for all transactions
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTransaction> {
        return NSFetchRequest<CDTransaction>(entityName: "CDTransaction")
    }
    
    /// Fetch transactions for a specific account
    public static func fetchRequest(for accountId: String) -> NSFetchRequest<CDTransaction> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "account.id == %@", accountId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTransaction.date, ascending: false)]
        return request
    }
    
    /// Fetch transactions by category
    public static func fetchRequest(category: String) -> NSFetchRequest<CDTransaction> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTransaction.date, ascending: false)]
        return request
    }
    
    /// Fetch transactions in date range
    public static func fetchRequest(from startDate: String, to endDate: String) -> NSFetchRequest<CDTransaction> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate, endDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTransaction.date, ascending: false)]
        return request
    }
    
    /// Fetch uncategorized transactions
    public static func fetchUncategorizedRequest() -> NSFetchRequest<CDTransaction> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "category == %@ OR category == %@", "Other", "Uncategorized")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTransaction.date, ascending: false)]
        return request
    }
    
    /// Fetch foreign currency transactions
    public static func fetchForexTransactionsRequest() -> NSFetchRequest<CDTransaction> {
        let request = fetchRequest()
        request.predicate = NSPredicate(
            format: "originalCurrency != nil AND originalCurrency != '' AND (originalAmount != 0 OR exchangeRate > 0)"
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTransaction.date, ascending: false)]
        return request
    }
}

// MARK: - Identifiable Conformance

extension CDTransaction: Identifiable {
    // NSManagedObject already has an objectID, but we use our custom id
}