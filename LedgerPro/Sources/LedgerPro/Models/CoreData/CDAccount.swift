import Foundation
import CoreData

/// Core Data entity representing a bank account
@objc(CDAccount)
public class CDAccount: NSManagedObject {
    
    // MARK: - Core Data Properties
    
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var institution: String
    @NSManaged public var accountTypeRaw: String  // Store as string for Core Data
    @NSManaged public var lastFourDigits: String?
    @NSManaged public var currency: String
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    // MARK: - Relationships
    
    @NSManaged public var transactions: NSSet?
    @NSManaged public var statements: NSSet?
    
    // MARK: - Computed Properties
    
    /// Account type enum
    public var accountType: BankAccount.AccountType {
        get {
            return BankAccount.AccountType(rawValue: accountTypeRaw) ?? .checking
        }
        set {
            accountTypeRaw = newValue.rawValue
        }
    }
    
    /// Convert to domain model BankAccount
    public func toBankAccount() -> BankAccount {
        return BankAccount(
            id: id,
            name: name,
            institution: institution,
            accountType: accountType,
            lastFourDigits: lastFourDigits,
            currency: currency,
            isActive: isActive,
            createdAt: ISO8601DateFormatter().string(from: createdAt)
        )
    }
    
    /// Get transactions as an array
    public var transactionsArray: [CDTransaction] {
        let set = transactions as? Set<CDTransaction> ?? []
        return Array(set).sorted { $0.date > $1.date }
    }
    
    /// Get statements as an array
    public var statementsArray: [CDUploadedStatement] {
        let set = statements as? Set<CDUploadedStatement> ?? []
        return Array(set).sorted { $0.uploadDate > $1.uploadDate }
    }
    
    // MARK: - Factory Methods
    
    /// Create CDAccount from domain model BankAccount
    public static func create(
        from bankAccount: BankAccount,
        in context: NSManagedObjectContext
    ) -> CDAccount {
        let cdAccount = CDAccount(context: context)
        cdAccount.update(from: bankAccount)
        return cdAccount
    }
    
    /// Update CDAccount from domain model BankAccount
    public func update(from bankAccount: BankAccount) {
        self.id = bankAccount.id
        self.name = bankAccount.name
        self.institution = bankAccount.institution
        self.accountType = bankAccount.accountType
        self.lastFourDigits = bankAccount.lastFourDigits
        self.currency = bankAccount.currency
        self.isActive = bankAccount.isActive
        
        // Parse created date if possible, otherwise use current date
        if let createdDate = ISO8601DateFormatter().date(from: bankAccount.createdAt) {
            self.createdAt = createdDate
        }
        
        self.updatedAt = Date()
    }
    
    // MARK: - Core Data Lifecycle
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        let now = Date()
        createdAt = now
        updatedAt = now
        
        // Set default values
        currency = "USD"
        isActive = true
        accountTypeRaw = BankAccount.AccountType.checking.rawValue
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

extension CDAccount {
    
    /// Fetch request for all accounts
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAccount> {
        return NSFetchRequest<CDAccount>(entityName: "CDAccount")
    }
    
    /// Fetch active accounts
    public static func fetchActiveAccountsRequest() -> NSFetchRequest<CDAccount> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDAccount.institution, ascending: true),
            NSSortDescriptor(keyPath: \CDAccount.name, ascending: true)
        ]
        return request
    }
    
    /// Fetch accounts by institution
    public static func fetchRequest(institution: String) -> NSFetchRequest<CDAccount> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "institution ==[cd] %@", institution)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDAccount.name, ascending: true)]
        return request
    }
    
    /// Fetch accounts by type
    public static func fetchRequest(accountType: BankAccount.AccountType) -> NSFetchRequest<CDAccount> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "accountTypeRaw == %@", accountType.rawValue)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDAccount.institution, ascending: true),
            NSSortDescriptor(keyPath: \CDAccount.name, ascending: true)
        ]
        return request
    }
    
    /// Find account by ID
    public static func fetchRequest(id: String) -> NSFetchRequest<CDAccount> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return request
    }
}

// MARK: - Relationship Management

extension CDAccount {
    
    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: CDTransaction)
    
    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: CDTransaction)
    
    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)
    
    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)
    
    @objc(addStatementsObject:)
    @NSManaged public func addToStatements(_ value: CDUploadedStatement)
    
    @objc(removeStatementsObject:)
    @NSManaged public func removeFromStatements(_ value: CDUploadedStatement)
    
    @objc(addStatements:)
    @NSManaged public func addToStatements(_ values: NSSet)
    
    @objc(removeStatements:)
    @NSManaged public func removeFromStatements(_ values: NSSet)
}

// MARK: - Identifiable Conformance

extension CDAccount: Identifiable {
    // NSManagedObject already has an objectID, but we use our custom id
}