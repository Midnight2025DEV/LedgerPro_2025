import SwiftUI

/// Improved category picker popup with spacious design and better UX
struct CategoryPickerPopup: View {
    @Binding var selectedCategory: Category?
    @Binding var isPresented: Bool
    let transaction: Transaction
    
    @StateObject private var categoryService = CategoryService.shared
    @State private var searchText = ""
    @State private var showingAddCategory = false
    
    // MARK: - Computed Properties
    
    private var recentCategories: [Category] {
        // TODO: Implement recent category tracking
        // For now, return a few commonly used categories
        let commonIds = [
            Category.systemCategoryIds.foodDining,
            Category.systemCategoryIds.transportation,
            Category.systemCategoryIds.shopping
        ]
        return commonIds.compactMap { categoryService.category(by: $0) }
    }
    
    private var suggestedCategories: [Category] {
        guard let suggested = categoryService.suggestCategory(
            for: transaction.description,
            amount: transaction.amount
        ) else { return [] }
        
        // Return the suggested category plus related ones
        var suggestions = [suggested]
        
        // Add related categories from the same parent
        if let parentId = suggested.parentId {
            let siblings = categoryService.children(of: parentId)
                .filter { $0.id != suggested.id }
                .prefix(3)
            suggestions.append(contentsOf: siblings)
        }
        
        return suggestions
    }
    
    private var categoryGroups: [(key: String, value: [Category])] {
        let filtered = filteredCategories
        
        // Group by root category
        let grouped = Dictionary(grouping: filtered) { category in
            if let parentId = category.parentId,
               let parent = categoryService.category(by: parentId) {
                // If this is a subcategory, group by its root parent
                return findRootCategory(parent).name
            } else {
                // This is already a root category
                return category.name
            }
        }
        
        // Sort groups by a predefined order
        let groupOrder = ["Income", "Expenses", "Transfers", "Other"]
        return grouped.sorted { first, second in
            let firstIndex = groupOrder.firstIndex(of: first.key) ?? Int.max
            let secondIndex = groupOrder.firstIndex(of: second.key) ?? Int.max
            return firstIndex < secondIndex
        }
    }
    
    private var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categoryService.categories.filter { $0.isActive }
        } else {
            return categoryService.categories.filter { category in
                category.isActive &&
                category.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func findRootCategory(_ category: Category) -> Category {
        if let parentId = category.parentId,
           let parent = categoryService.category(by: parentId) {
            return findRootCategory(parent)
        }
        return category
    }
    
    // MARK: - Main View
    
    var body: some View {
        ZStack {
            // Background overlay - tap to dismiss
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // The actual popup
            VStack(spacing: 0) {
            // Header with search
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Select Category")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(transaction.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Compact search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .imageScale(.medium)
                    
                    TextField("Search categories...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.body)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .imageScale(.small)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal, 20)
            }
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Main content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Recent categories (if any and not searching)
                    if !recentCategories.isEmpty && searchText.isEmpty {
                        CategorySection(
                            title: "RECENT",
                            categories: recentCategories,
                            selectedCategory: selectedCategory,
                            onSelect: selectCategory
                        )
                    }
                    
                    // Suggested categories based on merchant (if not searching)
                    if !suggestedCategories.isEmpty && searchText.isEmpty {
                        CategorySection(
                            title: "SUGGESTED FOR THIS TRANSACTION",
                            categories: suggestedCategories,
                            selectedCategory: selectedCategory,
                            onSelect: selectCategory
                        )
                    }
                    
                    // All categories by group
                    ForEach(categoryGroups, id: \.key) { groupName, categories in
                        CategorySection(
                            title: groupName.uppercased(),
                            categories: categories.sorted { $0.sortOrder < $1.sortOrder },
                            selectedCategory: selectedCategory,
                            onSelect: selectCategory
                        )
                    }
                    
                    // Bottom padding for scroll
                    Color.clear.frame(height: 20)
                }
                .padding(.vertical, 16)
            }
            
            Divider()
            
            // Footer with create new category option
            HStack {
                Button(action: { showingAddCategory = true }) {
                    Label("Create New Category", systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if let selected = selectedCategory {
                    HStack(spacing: 8) {
                        Text("Selected:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Text(selected.icon)
                                .font(.caption)
                            Text(selected.name)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: selected.color)?.opacity(0.2) ?? Color.blue.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            }
            .frame(width: 850, height: 650)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 8)
            .onTapGesture {} // Prevent taps on popup from closing
            .sheet(isPresented: $showingAddCategory) {
                NavigationStack {
                    AddCategoryView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Load categories if needed
            if categoryService.categories.isEmpty {
                Task {
                    await categoryService.loadCategories()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func selectCategory(_ category: Category) {
        selectedCategory = category
        
        // Add a small delay for visual feedback, then close
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

// MARK: - Category Section

struct CategorySection: View {
    let title: String
    let categories: [Category]
    let selectedCategory: Category?
    let onSelect: (Category) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                Text("\(categories.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            
            FlowLayout(spacing: 8) {
                ForEach(categories) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory?.id == category.id,
                        action: { onSelect(category) }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Category Chip Component

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category.icon)
                    .font(.body)
                
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? 
                          (Color(hex: category.color) ?? .blue) : 
                          Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color(hex: category.color) ?? .blue, 
                        lineWidth: isSelected ? 0 : 1
                    )
                    .opacity(isSelected ? 0 : 0.5)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .help(category.name)
    }
}

// MARK: - Flow Layout Implementation

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions(by: CGSize(width: 10000, height: 10000)),
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions(by: bounds.size),
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }
}

// MARK: - Flow Layout Helper

struct FlowResult {
    let bounds: CGSize
    let positions: [CGPoint]
    let sizes: [CGSize]
    
    init(in bounds: CGSize, subviews: LayoutSubviews, spacing: CGFloat) {
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentPosition = CGPoint.zero
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            // Check if we need to wrap to next row
            if currentPosition.x + size.width > bounds.width && currentPosition.x > 0 {
                currentPosition.x = 0
                currentPosition.y += rowHeight + spacing
                rowHeight = 0
            }
            
            positions.append(currentPosition)
            sizes.append(size)
            
            currentPosition.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, currentPosition.x - spacing)
        }
        
        self.positions = positions
        self.sizes = sizes
        self.bounds = CGSize(
            width: min(maxX, bounds.width),
            height: currentPosition.y + rowHeight
        )
    }
}

// MARK: - Preview

#Preview {
    CategoryPickerPopup(
        selectedCategory: .constant(nil),
        isPresented: .constant(true),
        transaction: Transaction(
            date: "2025-06-30",
            description: "STARBUCKS COFFEE #123",
            amount: -5.50,
            category: "Food & Dining"
        )
    )
    .environmentObject(CategoryService.shared)
}