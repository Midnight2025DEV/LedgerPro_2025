import Foundation

/// Represents a portion of a transaction allocated to a specific category
struct TransactionSplit: Identifiable, Codable {
    let id: UUID
    let transactionId: UUID
    var categoryId: UUID
    var amount: Decimal
    var note: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - Initializers
    
    init(id: UUID = UUID(), transactionId: UUID, categoryId: UUID, amount: Decimal, note: String? = nil) {
        self.id = id
        self.transactionId = transactionId
        self.categoryId = categoryId
        self.amount = amount
        self.note = note
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Returns the formatted amount as currency
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
    
    /// Returns the absolute value of the amount
    var absoluteAmount: Decimal {
        return abs(amount)
    }
    
    /// Determines if this is an income split (positive amount)
    var isIncome: Bool {
        return amount > 0
    }
    
    /// Determines if this is an expense split (negative amount)
    var isExpense: Bool {
        return amount < 0
    }
    
    // MARK: - Validation
    
    /// Validates that the split data is consistent and valid
    var isValid: Bool {
        return amount != 0 // Split must have a non-zero amount
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if amount == 0 {
            errors.append("Split amount cannot be zero")
        }
        
        return errors
    }
    
    // MARK: - Split Management
    
    /// Updates the amount and timestamp
    mutating func updateAmount(_ newAmount: Decimal) {
        amount = newAmount
        updatedAt = Date()
    }
    
    /// Updates the category and timestamp
    mutating func updateCategory(_ newCategoryId: UUID) {
        categoryId = newCategoryId
        updatedAt = Date()
    }
    
    /// Updates the note and timestamp
    mutating func updateNote(_ newNote: String?) {
        note = newNote
        updatedAt = Date()
    }
}

// MARK: - Transaction Extensions for Split Support

extension Transaction {
    /// Returns the splits for this transaction (loaded separately from Core Data)
    var splits: [TransactionSplit]? {
        // This will be populated by the CategoryService when loading transaction details
        return nil
    }
    
    /// Determines if this transaction has multiple category splits
    var isSplit: Bool {
        return (splits?.count ?? 0) > 1
    }
    
    /// Returns the total amount of all splits (should equal transaction amount)
    var totalSplitAmount: Decimal {
        guard let splits = splits else { return Decimal(amount) }
        return splits.reduce(Decimal(0)) { sum, split in
            sum + split.amount
        }
    }
    
    /// Returns the primary category ID (largest split or first split)
    var primaryCategoryId: UUID? {
        guard let splits = splits, !splits.isEmpty else { return nil }
        
        // Return the category with the largest absolute amount
        return splits.max { abs($0.amount) < abs($1.amount) }?.categoryId
    }
    
    /// Returns the split for a specific category, if any
    func split(for categoryId: UUID) -> TransactionSplit? {
        return splits?.first { $0.categoryId == categoryId }
    }
    
    /// Returns all categories involved in this transaction
    var involvedCategories: Set<UUID> {
        guard let splits = splits else { return Set() }
        return Set(splits.map { $0.categoryId })
    }
}

// MARK: - Split Collection Management

/// A collection of splits for a transaction with validation and management utilities
struct TransactionSplitCollection {
    let transactionId: UUID
    private(set) var splits: [TransactionSplit]
    let originalAmount: Decimal
    
    // MARK: - Initializers
    
    init(transactionId: UUID, originalAmount: Decimal, splits: [TransactionSplit] = []) {
        self.transactionId = transactionId
        self.originalAmount = originalAmount
        self.splits = splits.filter { $0.transactionId == transactionId }
    }
    
    // MARK: - Computed Properties
    
    /// Returns the total amount of all splits
    var totalSplitAmount: Decimal {
        return splits.reduce(Decimal(0)) { sum, split in
            sum + split.amount
        }
    }
    
    /// Returns the remaining amount not yet allocated to splits
    var remainingAmount: Decimal {
        return originalAmount - totalSplitAmount
    }
    
    /// Determines if the splits are balanced (total equals original amount)
    var isBalanced: Bool {
        return totalSplitAmount == originalAmount
    }
    
    /// Returns the percentage of the original amount that has been allocated
    var allocationPercentage: Double {
        guard originalAmount != 0 else { return 0 }
        return Double(truncating: (totalSplitAmount / originalAmount * 100) as NSDecimalNumber)
    }
    
    /// Returns validation errors for the entire split collection
    var validationErrors: [String] {
        var errors: [String] = []
        
        // Check individual split validity
        for (index, split) in splits.enumerated() {
            let splitErrors = split.validationErrors.map { "Split \(index + 1): \($0)" }
            errors.append(contentsOf: splitErrors)
        }
        
        // Check for duplicate categories
        let categoryIds = splits.map { $0.categoryId }
        let duplicates = Dictionary(grouping: categoryIds, by: { $0 }).filter { $1.count > 1 }
        if !duplicates.isEmpty {
            errors.append("Cannot have multiple splits for the same category")
        }
        
        // Check if splits exceed original amount (with small tolerance for rounding)
        let tolerance = Decimal(0.01)
        if abs(totalSplitAmount - originalAmount) > tolerance {
            errors.append("Split total (\(totalSplitAmount)) does not match transaction amount (\(originalAmount))")
        }
        
        return errors
    }
    
    // MARK: - Split Management
    
    /// Adds a new split to the collection
    mutating func addSplit(_ split: TransactionSplit) throws {
        guard split.transactionId == transactionId else {
            throw SplitError.transactionIdMismatch
        }
        
        guard !splits.contains(where: { $0.categoryId == split.categoryId }) else {
            throw SplitError.duplicateCategory
        }
        
        splits.append(split)
    }
    
    /// Removes a split by ID
    mutating func removeSplit(id: UUID) {
        splits.removeAll { $0.id == id }
    }
    
    /// Removes a split for a specific category
    mutating func removeSplit(for categoryId: UUID) {
        splits.removeAll { $0.categoryId == categoryId }
    }
    
    /// Updates an existing split
    mutating func updateSplit(id: UUID, amount: Decimal? = nil, categoryId: UUID? = nil, note: String? = nil) throws {
        guard let index = splits.firstIndex(where: { $0.id == id }) else {
            throw SplitError.splitNotFound
        }
        
        var split = splits[index]
        
        if let newAmount = amount {
            split.updateAmount(newAmount)
        }
        
        if let newCategoryId = categoryId {
            // Check for duplicate category
            if splits.contains(where: { $0.categoryId == newCategoryId && $0.id != id }) {
                throw SplitError.duplicateCategory
            }
            split.updateCategory(newCategoryId)
        }
        
        if let newNote = note {
            split.updateNote(newNote)
        }
        
        splits[index] = split
    }
    
    /// Clears all splits
    mutating func clearSplits() {
        splits.removeAll()
    }
    
    /// Auto-balances splits by adjusting the largest split to match the remaining amount
    mutating func autoBalance() throws {
        guard !splits.isEmpty else { return }
        
        // Find the split with the largest absolute amount
        guard let largestSplitIndex = splits.indices.max(by: { abs(splits[$0].amount) < abs(splits[$1].amount) }) else {
            return
        }
        
        let adjustment = remainingAmount
        splits[largestSplitIndex].amount += adjustment
        splits[largestSplitIndex].updatedAt = Date()
    }
    
    /// Creates an even split across the specified categories
    static func evenSplit(transactionId: UUID, originalAmount: Decimal, categoryIds: [UUID]) -> TransactionSplitCollection {
        let splitAmount = originalAmount / Decimal(categoryIds.count)
        var splits: [TransactionSplit] = []
        
        for (index, categoryId) in categoryIds.enumerated() {
            let amount = (index == categoryIds.count - 1) ? 
                originalAmount - (splitAmount * Decimal(categoryIds.count - 1)) : // Adjust last split for rounding
                splitAmount
            
            splits.append(TransactionSplit(
                transactionId: transactionId,
                categoryId: categoryId,
                amount: amount
            ))
        }
        
        return TransactionSplitCollection(transactionId: transactionId, originalAmount: originalAmount, splits: splits)
    }
    
    /// Creates a percentage-based split
    static func percentageSplit(transactionId: UUID, originalAmount: Decimal, categoryPercentages: [(UUID, Double)]) throws -> TransactionSplitCollection {
        let totalPercentage = categoryPercentages.reduce(0.0) { sum, pair in sum + pair.1 }
        
        guard abs(totalPercentage - 100.0) < 0.01 else {
            throw SplitError.invalidPercentageTotal
        }
        
        var splits: [TransactionSplit] = []
        var remainingAmount = originalAmount
        
        for (index, (categoryId, percentage)) in categoryPercentages.enumerated() {
            let amount = (index == categoryPercentages.count - 1) ?
                remainingAmount : // Use remaining amount for last split to handle rounding
                originalAmount * Decimal(percentage / 100.0)
            
            splits.append(TransactionSplit(
                transactionId: transactionId,
                categoryId: categoryId,
                amount: amount
            ))
            
            remainingAmount -= amount
        }
        
        return TransactionSplitCollection(transactionId: transactionId, originalAmount: originalAmount, splits: splits)
    }
}

// MARK: - Split Errors

enum SplitError: LocalizedError {
    case transactionIdMismatch
    case duplicateCategory
    case splitNotFound
    case invalidPercentageTotal
    case amountExceedsTransaction
    
    var errorDescription: String? {
        switch self {
        case .transactionIdMismatch:
            return "Split transaction ID does not match collection transaction ID"
        case .duplicateCategory:
            return "Cannot have multiple splits for the same category"
        case .splitNotFound:
            return "Split not found in collection"
        case .invalidPercentageTotal:
            return "Split percentages must total 100%"
        case .amountExceedsTransaction:
            return "Split amounts exceed transaction total"
        }
    }
}

// MARK: - Split Templates

extension TransactionSplitCollection {
    /// Common split templates for different scenarios
    enum SplitTemplate {
        case groceriesAndHousehold(groceriesPercentage: Double = 70.0)
        case businessMeal(businessPercentage: Double = 80.0)
        case mixedShopping(categories: [UUID], percentages: [Double])
        case billSplit(numberOfPeople: Int)
        
        func createSplits(transactionId: UUID, originalAmount: Decimal, categoryMapping: [String: UUID]) throws -> TransactionSplitCollection {
            switch self {
            case .groceriesAndHousehold(let groceriesPercentage):
                guard let groceriesId = categoryMapping["groceries"],
                      let householdId = categoryMapping["household"] else {
                    throw SplitError.splitNotFound
                }
                
                return try TransactionSplitCollection.percentageSplit(
                    transactionId: transactionId,
                    originalAmount: originalAmount,
                    categoryPercentages: [
                        (groceriesId, groceriesPercentage),
                        (householdId, 100.0 - groceriesPercentage)
                    ]
                )
                
            case .businessMeal(let businessPercentage):
                guard let businessId = categoryMapping["business"],
                      let personalId = categoryMapping["personal"] else {
                    throw SplitError.splitNotFound
                }
                
                return try TransactionSplitCollection.percentageSplit(
                    transactionId: transactionId,
                    originalAmount: originalAmount,
                    categoryPercentages: [
                        (businessId, businessPercentage),
                        (personalId, 100.0 - businessPercentage)
                    ]
                )
                
            case .mixedShopping(let categories, let percentages):
                guard categories.count == percentages.count else {
                    throw SplitError.invalidPercentageTotal
                }
                
                let categoryPercentages = zip(categories, percentages).map { ($0, $1) }
                return try TransactionSplitCollection.percentageSplit(
                    transactionId: transactionId,
                    originalAmount: originalAmount,
                    categoryPercentages: categoryPercentages
                )
                
            case .billSplit(let numberOfPeople):
                guard numberOfPeople > 0 else {
                    throw SplitError.invalidPercentageTotal
                }
                
                guard let personalId = categoryMapping["personal"] else {
                    throw SplitError.splitNotFound
                }
                
                // For bill splits, typically split evenly with personal category
                let personalAmount = originalAmount / Decimal(numberOfPeople)
                return TransactionSplitCollection(
                    transactionId: transactionId,
                    originalAmount: originalAmount,
                    splits: [TransactionSplit(
                        transactionId: transactionId,
                        categoryId: personalId,
                        amount: personalAmount
                    )]
                )
            }
        }
    }
}