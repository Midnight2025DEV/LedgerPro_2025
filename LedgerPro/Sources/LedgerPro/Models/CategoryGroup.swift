import Foundation
import SwiftUI

/// Visual grouping system for organizing categories in the UI
struct CategoryGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var categoryIds: Set<UUID>
    var color: String // Hex color string
    var icon: String // SF Symbol name or emoji
    var sortOrder: Int = 0
    var isCollapsed: Bool = false
    var isSystem: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - Initializers
    
    init(id: UUID = UUID(), name: String, categoryIds: Set<UUID> = [], color: String, icon: String, sortOrder: Int = 0, isCollapsed: Bool = false, isSystem: Bool = false) {
        self.id = id
        self.name = name
        self.categoryIds = categoryIds
        self.color = color
        self.icon = icon
        self.sortOrder = sortOrder
        self.isCollapsed = isCollapsed
        self.isSystem = isSystem
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Returns the SwiftUI Color from the hex string
    var swiftUIColor: Color {
        return Color(hex: color) ?? .gray
    }
    
    /// Returns the number of categories in this group
    var categoryCount: Int {
        return categoryIds.count
    }
    
    /// Checks if this group contains the specified category
    func containsCategory(_ categoryId: UUID) -> Bool {
        return categoryIds.contains(categoryId)
    }
    
    // MARK: - Group Management
    
    /// Adds a category to this group
    mutating func addCategory(_ categoryId: UUID) {
        categoryIds.insert(categoryId)
        updatedAt = Date()
    }
    
    /// Removes a category from this group
    mutating func removeCategory(_ categoryId: UUID) {
        categoryIds.remove(categoryId)
        updatedAt = Date()
    }
    
    /// Adds multiple categories to this group
    mutating func addCategories(_ categoryIds: [UUID]) {
        for categoryId in categoryIds {
            self.categoryIds.insert(categoryId)
        }
        updatedAt = Date()
    }
    
    /// Removes multiple categories from this group
    mutating func removeCategories(_ categoryIds: [UUID]) {
        for categoryId in categoryIds {
            self.categoryIds.remove(categoryId)
        }
        updatedAt = Date()
    }
    
    /// Clears all categories from this group
    mutating func clearCategories() {
        categoryIds.removeAll()
        updatedAt = Date()
    }
    
    // MARK: - Validation
    
    /// Validates that the group data is consistent and valid
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !icon.isEmpty &&
               !color.isEmpty &&
               sortOrder >= 0
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Group name cannot be empty")
        }
        
        if icon.isEmpty {
            errors.append("Group icon cannot be empty")
        }
        
        if color.isEmpty {
            errors.append("Group color cannot be empty")
        }
        
        if sortOrder < 0 {
            errors.append("Sort order must be non-negative")
        }
        
        return errors
    }
}

// MARK: - Default System Groups

extension CategoryGroup {
    /// Predefined system groups for organizing categories
    static let defaultGroups: [CategoryGroup] = {
        // Generate consistent UUIDs for system groups
        let essentialExpensesId = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        let lifestyleExpensesId = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
        let financialExpensesId = UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
        let incomeSourcesId = UUID(uuidString: "10000000-0000-0000-0000-000000000004")!
        let transfersId = UUID(uuidString: "10000000-0000-0000-0000-000000000005")!
        
        return [
            // Essential Expenses Group
            CategoryGroup(
                id: essentialExpensesId,
                name: "Essential Expenses",
                categoryIds: Set([
                    Category.systemCategoryIds.housing,
                    Category.systemCategoryIds.transportation,
                    Category.systemCategoryIds.foodDining,
                    UUID(uuidString: "00000000-0000-0000-0000-000000000024")!, // Utilities
                    UUID(uuidString: "00000000-0000-0000-0000-000000000025")!  // Healthcare
                ]),
                color: "#FF3B30",
                icon: "house.fill",
                sortOrder: 0,
                isSystem: true
            ),
            
            // Lifestyle Expenses Group
            CategoryGroup(
                id: lifestyleExpensesId,
                name: "Lifestyle & Entertainment",
                categoryIds: Set([
                    Category.systemCategoryIds.shopping,
                    UUID(uuidString: "00000000-0000-0000-0000-000000000032")!, // Entertainment
                    UUID(uuidString: "00000000-0000-0000-0000-000000000033")!, // Travel
                    UUID(uuidString: "00000000-0000-0000-0000-000000000034")!, // Education
                    UUID(uuidString: "00000000-0000-0000-0000-000000000035")!  // Personal Care
                ]),
                color: "#AF52DE",
                icon: "sparkles",
                sortOrder: 1,
                isSystem: true
            ),
            
            // Financial Expenses Group
            CategoryGroup(
                id: financialExpensesId,
                name: "Financial & Planning",
                categoryIds: Set([
                    UUID(uuidString: "00000000-0000-0000-0000-000000000041")!, // Insurance
                    UUID(uuidString: "00000000-0000-0000-0000-000000000042")!, // Taxes
                    UUID(uuidString: "00000000-0000-0000-0000-000000000043")!, // Investments
                    UUID(uuidString: "00000000-0000-0000-0000-000000000044")!, // Savings
                    UUID(uuidString: "00000000-0000-0000-0000-000000000045")!  // Debt Payments
                ]),
                color: "#007AFF",
                icon: "chart.pie.fill",
                sortOrder: 2,
                isSystem: true
            ),
            
            // Income Sources Group
            CategoryGroup(
                id: incomeSourcesId,
                name: "Income Sources",
                categoryIds: Set([
                    Category.systemCategoryIds.salary,
                    UUID(uuidString: "00000000-0000-0000-0000-000000000012")!, // Freelance
                    UUID(uuidString: "00000000-0000-0000-0000-000000000013")!, // Investment Returns
                    UUID(uuidString: "00000000-0000-0000-0000-000000000014")!, // Bonus
                    UUID(uuidString: "00000000-0000-0000-0000-000000000015")!  // Other Income
                ]),
                color: "#34C759",
                icon: "arrow.down.circle.fill",
                sortOrder: 3,
                isSystem: true
            ),
            
            // Transfers Group
            CategoryGroup(
                id: transfersId,
                name: "Transfers & Payments",
                categoryIds: Set([
                    UUID(uuidString: "00000000-0000-0000-0000-000000000051")!, // Account Transfer
                    Category.systemCategoryIds.creditCardPayment,
                    UUID(uuidString: "00000000-0000-0000-0000-000000000053")!  // Loan Payment
                ]),
                color: "#007AFF",
                icon: "arrow.left.arrow.right",
                sortOrder: 4,
                isSystem: true
            )
        ]
    }()
    
    /// System group IDs for quick reference
    static let systemGroupIds = SystemGroupIds()
    
    struct SystemGroupIds {
        let essentialExpenses = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        let lifestyleExpenses = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
        let financialExpenses = UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
        let incomeSources = UUID(uuidString: "10000000-0000-0000-0000-000000000004")!
        let transfers = UUID(uuidString: "10000000-0000-0000-0000-000000000005")!
    }
    
    /// Returns a group by its system ID if it exists in the default groups
    static func systemGroup(id: UUID) -> CategoryGroup? {
        return defaultGroups.first { $0.id == id }
    }
    
    /// Returns the group that contains the specified category, if any
    static func groupContaining(categoryId: UUID) -> CategoryGroup? {
        return defaultGroups.first { $0.containsCategory(categoryId) }
    }
    
    /// Returns all groups sorted by sort order
    static var sortedGroups: [CategoryGroup] {
        return defaultGroups.sorted { $0.sortOrder < $1.sortOrder }
    }
}

// MARK: - Group Statistics

extension CategoryGroup {
    /// Statistics for a category group based on transactions
    struct GroupStatistics {
        let groupId: UUID
        let period: DateInterval
        let totalAmount: Decimal
        let transactionCount: Int
        let categoryBreakdown: [UUID: Decimal] // categoryId -> amount
        let averageTransactionAmount: Decimal
        let percentOfTotalSpending: Double
        
        var formattedTotalAmount: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            return formatter.string(from: totalAmount as NSDecimalNumber) ?? "$0.00"
        }
    }
    
    /// Calculates statistics for this group based on provided transactions
    func calculateStatistics(transactions: [Transaction], period: DateInterval) -> GroupStatistics {
        // Filter transactions that belong to categories in this group
        let groupTransactions = transactions.filter { transaction in
            // This would need to be enhanced with actual category lookup
            // For now, return empty statistics
            return false
        }
        
        let totalAmount = groupTransactions.reduce(Decimal(0)) { sum, transaction in
            sum + Decimal(abs(transaction.amount))
        }
        
        let categoryBreakdown = Dictionary(grouping: groupTransactions) { transaction in
            // This would map transaction to category ID
            UUID() // Placeholder
        }.mapValues { transactions in
            transactions.reduce(Decimal(0)) { sum, transaction in
                sum + Decimal(abs(transaction.amount))
            }
        }
        
        let averageAmount = groupTransactions.isEmpty ? Decimal(0) : totalAmount / Decimal(groupTransactions.count)
        
        return GroupStatistics(
            groupId: id,
            period: period,
            totalAmount: totalAmount,
            transactionCount: groupTransactions.count,
            categoryBreakdown: categoryBreakdown,
            averageTransactionAmount: averageAmount,
            percentOfTotalSpending: 0.0 // Would be calculated based on total spending
        )
    }
}

// MARK: - Group Display Options

extension CategoryGroup {
    /// Display options for how groups are shown in the UI
    enum DisplayStyle: String, Codable, CaseIterable {
        case expanded = "expanded"
        case collapsed = "collapsed"
        case summary = "summary"
        case hidden = "hidden"
        
        var displayName: String {
            switch self {
            case .expanded: return "Expanded"
            case .collapsed: return "Collapsed"
            case .summary: return "Summary Only"
            case .hidden: return "Hidden"
            }
        }
    }
    
    /// Sort options for categories within groups
    enum CategorySortOrder: String, Codable, CaseIterable {
        case alphabetical = "alphabetical"
        case amount = "amount"
        case frequency = "frequency"
        case recent = "recent"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .alphabetical: return "Alphabetical"
            case .amount: return "By Amount"
            case .frequency: return "By Frequency"
            case .recent: return "Most Recent"
            case .custom: return "Custom Order"
            }
        }
    }
}

// MARK: - Group Templates

extension CategoryGroup {
    /// Template groups for different use cases
    static let templateGroups: [CategoryGroup] = [
        // Family Budget Template
        CategoryGroup(
            id: UUID(),
            name: "Family Essentials",
            color: "#FF6B6B",
            icon: "heart.fill",
            isSystem: false
        ),
        
        // Student Budget Template
        CategoryGroup(
            id: UUID(),
            name: "Student Life",
            color: "#4ECDC4",
            icon: "graduationcap.fill",
            isSystem: false
        ),
        
        // Business Expenses Template
        CategoryGroup(
            id: UUID(),
            name: "Business Expenses",
            color: "#45B7D1",
            icon: "briefcase.fill",
            isSystem: false
        ),
        
        // Travel Budget Template
        CategoryGroup(
            id: UUID(),
            name: "Travel & Vacation",
            color: "#96CEB4",
            icon: "airplane",
            isSystem: false
        ),
        
        // Health & Wellness Template
        CategoryGroup(
            id: UUID(),
            name: "Health & Wellness",
            color: "#FFEAA7",
            icon: "heart.text.square.fill",
            isSystem: false
        )
    ]
    
    /// Creates a group from a template with specified categories
    static func fromTemplate(_ template: CategoryGroup, withCategories categoryIds: Set<UUID>) -> CategoryGroup {
        return CategoryGroup(
            id: UUID(),
            name: template.name,
            categoryIds: categoryIds,
            color: template.color,
            icon: template.icon,
            sortOrder: template.sortOrder,
            isCollapsed: template.isCollapsed,
            isSystem: false
        )
    }
}