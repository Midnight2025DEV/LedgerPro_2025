import Foundation
import SwiftUI

/// Service for managing categories with persistence and hierarchy support
@MainActor
class CategoryService: ObservableObject {
    static let shared = CategoryService()
    
    @Published var categories: [Category] = []
    @Published var rootCategories: [Category] = [] // Top-level only
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let userDefaults = UserDefaults.standard
    private let categoriesKey = "stored_categories"
    private let hasInitializedKey = "categories_initialized"
    
    // MARK: - Initialization
    
    init() {
        Task {
            await loadCategories()
        }
    }
    
    // MARK: - Data Loading
    
    /// Load all categories and organize hierarchy
    func loadCategories() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Check if this is first run - initialize system categories
            if !userDefaults.bool(forKey: hasInitializedKey) {
                try await initializeSystemCategories()
                userDefaults.set(true, forKey: hasInitializedKey)
            }
            
            // Load from UserDefaults
            let loadedCategories = loadCategoriesFromStorage()
            
            // Organize hierarchy
            await organizeCategories(loadedCategories)
            
            print("✅ Loaded \(categories.count) categories (\(rootCategories.count) root categories)")
            
        } catch {
            lastError = error.localizedDescription
            print("❌ Failed to load categories: \(error)")
        }
    }
    
    private func loadCategoriesFromStorage() -> [Category] {
        guard let data = userDefaults.data(forKey: categoriesKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Category].self, from: data)
        } catch {
            print("❌ Failed to decode categories: \(error)")
            return []
        }
    }
    
    private func organizeCategories(_ loadedCategories: [Category]) async {
        // Set main categories array
        self.categories = loadedCategories.sorted { $0.sortOrder < $1.sortOrder }
        
        // Filter root categories (no parent)
        self.rootCategories = loadedCategories
            .filter { $0.parentId == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
        
        // Populate children for each category
        for index in categories.indices {
            let categoryId = categories[index].id
            let children = loadedCategories
                .filter { $0.parentId == categoryId }
                .sorted { $0.sortOrder < $1.sortOrder }
            
            // Create a new category with children populated
            var updatedCategory = categories[index]
            updatedCategory.children = children.isEmpty ? nil : children
            categories[index] = updatedCategory
        }
        
        print("📊 Category hierarchy organized: \(rootCategories.count) root, \(categories.count) total")
    }
    
    // MARK: - System Categories Initialization
    
    /// Initialize default system categories on first run
    func initializeSystemCategories() async throws {
        print("🚀 Initializing system categories...")
        
        let systemCategories = Category.systemCategories
        
        // Save system categories
        try saveCategoriesToStorage(systemCategories)
        
        print("✅ Initialized \(systemCategories.count) system categories")
    }
    
    // MARK: - CRUD Operations
    
    /// Create a new category
    func createCategory(_ category: Category) async throws {
        var newCategory = category
        newCategory.createdAt = Date()
        newCategory.updatedAt = Date()
        
        // Add to current categories
        var updatedCategories = categories
        updatedCategories.append(newCategory)
        
        // Save to storage
        try saveCategoriesToStorage(updatedCategories)
        
        // Reload and reorganize
        await loadCategories()
        
        print("✅ Created category: \(newCategory.name)")
    }
    
    /// Update an existing category
    func updateCategory(_ category: Category) async throws {
        var updatedCategory = category
        updatedCategory.updatedAt = Date()
        
        // Find and update in current categories
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else {
            throw CategoryServiceError.categoryNotFound
        }
        
        var updatedCategories = categories
        updatedCategories[index] = updatedCategory
        
        // Save to storage
        try saveCategoriesToStorage(updatedCategories)
        
        // Reload and reorganize
        await loadCategories()
        
        print("✅ Updated category: \(updatedCategory.name)")
    }
    
    /// Delete a category (if not system category)
    func deleteCategory(_ categoryId: UUID) async throws {
        guard let category = categories.first(where: { $0.id == categoryId }) else {
            throw CategoryServiceError.categoryNotFound
        }
        
        if category.isSystem {
            throw CategoryServiceError.cannotDeleteSystemCategory
        }
        
        // Remove category and any children
        let updatedCategories = categories.filter { 
            $0.id != categoryId && $0.parentId != categoryId 
        }
        
        // Save to storage
        try saveCategoriesToStorage(updatedCategories)
        
        // Reload and reorganize
        await loadCategories()
        
        print("✅ Deleted category: \(category.name)")
    }
    
    // MARK: - Storage Operations
    
    private func saveCategoriesToStorage(_ categories: [Category]) throws {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(categories)
            userDefaults.set(data, forKey: categoriesKey)
            print("💾 Saved \(categories.count) categories to storage")
        } catch {
            print("❌ Failed to save categories: \(error)")
            throw CategoryServiceError.saveFailed(error)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get category by ID
    func category(by id: UUID) -> Category? {
        return categories.first { $0.id == id }
    }
    
    /// Get children of a category
    func children(of categoryId: UUID) -> [Category] {
        return categories.filter { $0.parentId == categoryId }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
    
    /// Get all subcategories recursively
    func allSubcategories(of categoryId: UUID) -> [Category] {
        let directChildren = children(of: categoryId)
        var allChildren = directChildren
        
        for child in directChildren {
            allChildren.append(contentsOf: allSubcategories(of: child.id))
        }
        
        return allChildren
    }
    
    /// Check if category has children
    func hasChildren(_ categoryId: UUID) -> Bool {
        return categories.contains { $0.parentId == categoryId }
    }
    
    /// Get category hierarchy path
    func hierarchyPath(for categoryId: UUID) -> String {
        guard let category = category(by: categoryId) else {
            return "Unknown"
        }
        
        var path = [category.name]
        var currentCategory = category
        
        // Walk up the hierarchy
        while let parentId = currentCategory.parentId,
              let parent = self.category(by: parentId) {
            path.insert(parent.name, at: 0)
            currentCategory = parent
        }
        
        return path.joined(separator: " → ")
    }
    
    /// Reload categories from system definitions (useful after updating systemCategories)
    func reloadCategories() async throws {
        print("🔄 Reloading categories from system definitions...")
        
        // Clear existing categories
        await MainActor.run {
            self.categories.removeAll()
            self.rootCategories.removeAll()
        }
        
        // Force reinitialize system categories
        userDefaults.set(false, forKey: hasInitializedKey)
        try await initializeSystemCategories()
        userDefaults.set(true, forKey: hasInitializedKey)
        
        // Reload from storage
        await loadCategories()
        
        print("✅ Categories reloaded successfully")
    }
    
    /// Reset all categories (for testing)
    func resetCategories() async {
        userDefaults.removeObject(forKey: categoriesKey)
        userDefaults.set(false, forKey: hasInitializedKey)
        
        categories = []
        rootCategories = []
        
        await loadCategories()
        
        print("🔄 Categories reset and reinitialized")
    }
}

// MARK: - Error Types

enum CategoryServiceError: LocalizedError {
    case categoryNotFound
    case cannotDeleteSystemCategory
    case saveFailed(Error)
    case invalidParentCategory
    
    var errorDescription: String? {
        switch self {
        case .categoryNotFound:
            return "Category not found"
        case .cannotDeleteSystemCategory:
            return "Cannot delete system category"
        case .saveFailed(let error):
            return "Failed to save categories: \(error.localizedDescription)"
        case .invalidParentCategory:
            return "Invalid parent category"
        }
    }
}

// MARK: - Extensions for Transaction Integration

extension CategoryService {
    /// Find the best matching category for a transaction description
    func suggestCategory(for transactionDescription: String, amount: Double) -> Category? {
        let description = transactionDescription.lowercased()
        
        // Simple rule-based matching (this would be enhanced with CategoryRule engine later)
        if amount > 0 {
            // Positive amount - likely income
            return category(by: Category.systemCategoryIds.salary) ?? category(by: Category.systemCategoryIds.income)
        } else {
            // Negative amount - expense
            if description.contains("uber") || description.contains("lyft") {
                return category(by: Category.systemCategoryIds.transportation)
            } else if description.contains("walmart") || description.contains("grocery") {
                return category(by: Category.systemCategoryIds.foodDining)
            } else if description.contains("amazon") {
                return category(by: Category.systemCategoryIds.shopping)
            } else if description.contains("capital one") && description.contains("payment") {
                return category(by: Category.systemCategoryIds.creditCardPayment)
            }
        }
        
        // Default fallback
        return category(by: Category.systemCategoryIds.other)
    }
    
    /// Get transactions for a specific category (placeholder for future integration)
    func transactionCount(for categoryId: UUID) -> Int {
        // This would be implemented when integrating with actual transaction data
        return 0
    }
    
    /// Get spending amount for a category (placeholder for future integration)
    func totalSpent(for categoryId: UUID) -> Decimal {
        // This would be implemented when integrating with actual transaction data
        return 0
    }
}