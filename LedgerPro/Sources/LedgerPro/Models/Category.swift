import Foundation
import SwiftUI

/// Core category model supporting hierarchical organization, budgeting, and rich metadata
struct Category: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String // SF Symbol name or emoji
    var color: String // Hex color string
    var parentId: UUID?
    var isSystem: Bool = false
    var isActive: Bool = true
    var sortOrder: Int = 0
    var budgetAmount: Decimal?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Computed property for children (will be populated by CategoryService)
    var children: [Category]? = nil
    
    // MARK: - Initializers
    
    init(id: UUID = UUID(), name: String, icon: String, color: String, parentId: UUID? = nil, isSystem: Bool = false, isActive: Bool = true, sortOrder: Int = 0, budgetAmount: Decimal? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.parentId = parentId
        self.isSystem = isSystem
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.budgetAmount = budgetAmount
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Helper Computed Properties
    
    /// Determines if this category represents income based on parent hierarchy or name
    var isIncome: Bool {
        // Check if this is a direct income category
        if name.lowercased().contains("income") || name.lowercased().contains("salary") || name.lowercased().contains("wages") {
            return true
        }
        
        // Check if parent is income (will need CategoryService to resolve)
        // For now, return false - this will be enhanced when CategoryService is implemented
        return false
    }
    
    /// Determines if this category represents an expense
    var isExpense: Bool {
        return !isIncome && !isTransfer
    }
    
    /// Determines if this category represents a transfer between accounts
    var isTransfer: Bool {
        return name.lowercased().contains("transfer") || name.lowercased().contains("payment")
    }
    
    /// Returns the SwiftUI Color from the hex string
    var swiftUIColor: Color {
        return Color(hex: color) ?? .gray
    }
    
    /// Returns display name with hierarchy level indication
    var displayName: String {
        return name
    }
    
    /// Returns the hierarchy level (0 for root categories)
    var hierarchyLevel: Int {
        // This will be calculated by CategoryService when loading the full hierarchy
        return parentId == nil ? 0 : 1
    }
    
    /// Returns a path string showing the full category hierarchy
    var hierarchyPath: String {
        // This will be enhanced when CategoryService can resolve parent chains
        return name
    }
    
    // MARK: - Validation
    
    /// Validates that the category data is consistent and valid
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
            errors.append("Category name cannot be empty")
        }
        
        if icon.isEmpty {
            errors.append("Category icon cannot be empty")
        }
        
        if color.isEmpty {
            errors.append("Category color cannot be empty")
        }
        
        if sortOrder < 0 {
            errors.append("Sort order must be non-negative")
        }
        
        if let budget = budgetAmount, budget < 0 {
            errors.append("Budget amount must be non-negative")
        }
        
        return errors
    }
}

// MARK: - Default System Categories

extension Category {
    /// Predefined system categories that are created by default
    static let systemCategories: [Category] = {
        // Generate consistent UUIDs for system categories
        let incomeId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let expenseId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let transferId = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        
        return [
            // Root Categories
            Category(id: incomeId, name: "Income", icon: "arrow.down.circle.fill", color: "#34C759", isSystem: true, sortOrder: 0),
            Category(id: expenseId, name: "Expenses", icon: "arrow.up.circle.fill", color: "#FF3B30", isSystem: true, sortOrder: 1),
            Category(id: transferId, name: "Transfers", icon: "arrow.left.arrow.right", color: "#007AFF", isSystem: true, sortOrder: 2),
            
            // Income Subcategories
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!, name: "Salary", icon: "briefcase.fill", color: "#34C759", parentId: incomeId, isSystem: true, sortOrder: 0),
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!, name: "Freelance", icon: "person.badge.shield.checkmark.fill", color: "#34C759", parentId: incomeId, isSystem: true, sortOrder: 1),
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!, name: "Investment Returns", icon: "chart.line.uptrend.xyaxis", color: "#34C759", parentId: incomeId, isSystem: true, sortOrder: 2),
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!, name: "Bonus", icon: "gift.fill", color: "#34C759", parentId: incomeId, isSystem: true, sortOrder: 3),
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000015")!, name: "Other Income", icon: "plus.circle.fill", color: "#34C759", parentId: incomeId, isSystem: true, sortOrder: 4),
            
            // Expense Subcategories - Essential (matching Overview's Color.forCategory)
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!, name: "Housing", icon: "house.fill", color: "#FF3B30", parentId: expenseId, isSystem: true, sortOrder: 0), // Red (bills/rent)
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000022")!, name: "Transportation", icon: "car.fill", color: "#007AFF", parentId: expenseId, isSystem: true, sortOrder: 1), // Blue
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000023")!, name: "Food & Dining", icon: "fork.knife", color: "#34C759", parentId: expenseId, isSystem: true, sortOrder: 2), // Green (dining)
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000024")!, name: "Utilities", icon: "bolt.fill", color: "#FF3B30", parentId: expenseId, isSystem: true, sortOrder: 3), // Red (bills)
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000025")!, name: "Healthcare", icon: "cross.fill", color: "#00C7BE", parentId: expenseId, isSystem: true, sortOrder: 4), // Mint
            
            // Expense Subcategories - Lifestyle (matching Overview's Color.forCategory)
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000031")!, name: "Shopping", icon: "bag.fill", color: "#AF52DE", parentId: expenseId, isSystem: true, sortOrder: 5), // Purple
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000032")!, name: "Entertainment", icon: "tv.fill", color: "#FF2D92", parentId: expenseId, isSystem: true, sortOrder: 6), // Pink
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000033")!, name: "Travel", icon: "airplane", color: "#30D5C8", parentId: expenseId, isSystem: true, sortOrder: 7), // Teal
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000034")!, name: "Education", icon: "graduationcap.fill", color: "#FFCC00", parentId: expenseId, isSystem: true, sortOrder: 8), // Yellow
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000035")!, name: "Personal Care", icon: "person.circle.fill", color: "#8E8E93", parentId: expenseId, isSystem: true, sortOrder: 9), // Gray (default)
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000036")!, name: "Business", icon: "briefcase.fill", color: "#007AFF", parentId: expenseId, isSystem: true, sortOrder: 10), // Blue
            
            // Expense Subcategories - Financial (matching Overview's Color.forCategory)
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000041")!, name: "Insurance", icon: "shield.fill", color: "#FF9500", parentId: expenseId, isSystem: true, sortOrder: 11), // Orange
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000042")!, name: "Taxes", icon: "doc.text.fill", color: "#5856D6", parentId: expenseId, isSystem: true, sortOrder: 12), // Indigo
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000043")!, name: "Investments", icon: "chart.pie.fill", color: "#AF52DE", parentId: expenseId, isSystem: true, sortOrder: 13), // Purple
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000044")!, name: "Savings", icon: "banknote.fill", color: "#34C759", parentId: expenseId, isSystem: true, sortOrder: 14),
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000045")!, name: "Debt Payments", icon: "creditcard.fill", color: "#FF3B30", parentId: expenseId, isSystem: true, sortOrder: 15),
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000046")!, name: "Groceries", icon: "cart.fill", color: "#FFCC00", parentId: expenseId, isSystem: true, sortOrder: 16), // Yellow
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000047")!, name: "Subscriptions", icon: "repeat.circle.fill", color: "#BF5AF2", parentId: expenseId, isSystem: true, sortOrder: 17), // Light Purple  
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000048")!, name: "Lodging", icon: "bed.double.fill", color: "#30D5C8", parentId: expenseId, isSystem: true, sortOrder: 18), // Teal
            
            // Transfer Subcategories
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000051")!, name: "Account Transfer", icon: "arrow.left.arrow.right.square.fill", color: "#007AFF", parentId: transferId, isSystem: true, sortOrder: 0),
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000052")!, name: "Credit Card Payment", icon: "creditcard.trianglebadge.exclamationmark", color: "#007AFF", parentId: transferId, isSystem: true, sortOrder: 1),
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000053")!, name: "Loan Payment", icon: "building.columns.fill", color: "#007AFF", parentId: transferId, isSystem: true, sortOrder: 2),
            
            // Catch-all
            Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000999")!, name: "Other", icon: "questionmark.circle.fill", color: "#FF6B35", isSystem: true, sortOrder: 999)
        ]
    }()
    
    /// System category IDs for quick reference
    static let systemCategoryIds = SystemCategoryIds()
    
    struct SystemCategoryIds {
        let income = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let expenses = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let transfers = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let other = UUID(uuidString: "00000000-0000-0000-0000-000000000999")!
        
        // Quick access to common subcategories
        let salary = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
        let housing = UUID(uuidString: "00000000-0000-0000-0000-000000000021")!
        let transportation = UUID(uuidString: "00000000-0000-0000-0000-000000000022")!
        let foodDining = UUID(uuidString: "00000000-0000-0000-0000-000000000023")!
        let utilities = UUID(uuidString: "00000000-0000-0000-0000-000000000024")!
        let healthcare = UUID(uuidString: "00000000-0000-0000-0000-000000000025")!
        let shopping = UUID(uuidString: "00000000-0000-0000-0000-000000000031")!
        let entertainment = UUID(uuidString: "00000000-0000-0000-0000-000000000032")!
        let travel = UUID(uuidString: "00000000-0000-0000-0000-000000000033")!
        let education = UUID(uuidString: "00000000-0000-0000-0000-000000000034")!
        let personalCare = UUID(uuidString: "00000000-0000-0000-0000-000000000035")!
        let business = UUID(uuidString: "00000000-0000-0000-0000-000000000036")!
        let groceries = UUID(uuidString: "00000000-0000-0000-0000-000000000046")!
        let subscriptions = UUID(uuidString: "00000000-0000-0000-0000-000000000047")!
        let lodging = UUID(uuidString: "00000000-0000-0000-0000-000000000048")!
        let creditCardPayment = UUID(uuidString: "00000000-0000-0000-0000-000000000052")!
    }
    
    /// Returns a category by its system ID if it exists in the system categories
    static func systemCategory(id: UUID) -> Category? {
        return systemCategories.first { $0.id == id }
    }
    
    /// Returns all root system categories (those without parents)
    static var rootSystemCategories: [Category] {
        return systemCategories.filter { $0.parentId == nil }
    }
    
    /// Returns all system subcategories for a given parent ID
    static func systemSubcategories(parentId: UUID) -> [Category] {
        return systemCategories.filter { $0.parentId == parentId }.sorted { $0.sortOrder < $1.sortOrder }
    }
}

// MARK: - Color Extension

extension Color {
    /// Initializes a Color from a hex string
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Converts a Color to a hex string
    var hexString: String {
        let uiColor = NSColor(self)
        guard let components = uiColor.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}

// MARK: - Category Extensions for Migration

extension Category {
    /// Creates a Category from a legacy string category name
    static func fromLegacyString(_ categoryString: String) -> Category {
        // Map common legacy categories to system categories
        let legacyMapping: [String: UUID] = [
            "Groceries": systemCategoryIds.foodDining,
            "Food & Dining": systemCategoryIds.foodDining,
            "Transportation": systemCategoryIds.transportation,
            "Shopping": systemCategoryIds.shopping,
            "Housing": systemCategoryIds.housing,
            "Income": systemCategoryIds.income,
            "Salary": systemCategoryIds.salary,
            "Transfer": systemCategoryIds.transfers,
            "Payment": systemCategoryIds.creditCardPayment,
            "Other": systemCategoryIds.other
        ]
        
        // Try to find a matching system category
        if let systemId = legacyMapping[categoryString],
           let systemCategory = systemCategory(id: systemId) {
            return systemCategory
        }
        
        // Create a new category if no match found
        return Category(
            name: categoryString,
            icon: "circle.fill",
            color: "#8E8E93",
            isSystem: false
        )
    }
    
    /// Returns the legacy string representation for backwards compatibility
    var legacyString: String {
        return name
    }
}