import SwiftUI
import AppKit

/// Improved category picker popup with spacious design and better UX
struct CategoryPickerPopup: View {
    @Binding var selectedCategory: Category?
    @Binding var isPresented: Bool
    let transaction: Transaction
    
    @EnvironmentObject private var categoryService: CategoryService
    @State private var searchText = ""
    @State private var showingAddCategory = false
    @State private var iconRotation: Double = 0
    @StateObject private var statsProvider = CategoryStatsProvider()
    
    // MARK: - Computed Properties
    
    private var recentCategories: [Category] {
        // Returns commonly used categories for quick access
        // Future enhancement: Track user's recent category selections
        let commonIds = [
            Category.systemCategoryIds.foodDining,
            Category.systemCategoryIds.transportation,
            Category.systemCategoryIds.shopping
        ]
        return commonIds.compactMap { categoryService.category(by: $0) }
    }
    
    private var suggestedCategories: [Category] {
        let (suggested, confidence) = categoryService.suggestCategory(for: transaction)
        guard let suggestedCategory = suggested, confidence > 0.2 else { 
            return [] // Only show suggestions with reasonable confidence
        }
        
        // Return the suggested category plus related ones
        var suggestions = [suggestedCategory]
        
        // Add related categories from the same parent
        if let parentId = suggestedCategory.parentId {
            let siblings = categoryService.children(of: parentId)
                .filter { $0.id != suggestedCategory.id }
                .prefix(3)
            suggestions.append(contentsOf: siblings)
        }
        
        return suggestions
    }
    
    private var suggestionConfidence: Double {
        let (_, confidence) = categoryService.suggestCategory(for: transaction)
        return confidence
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
    
    // MARK: - Enhanced Helper Functions
    
    private func impact(_ style: NSHapticFeedbackManager.FeedbackPattern) {
        NSHapticFeedbackManager.defaultPerformer.perform(style, performanceTime: .now)
    }
    
    private func findHistoricalCategory() -> String? {
        let merchantTransactions = FinancialDataManager().transactions
            .filter { $0.displayMerchantName == transaction.displayMerchantName }
            .compactMap { $0.category }
        
        let counts = Dictionary(grouping: merchantTransactions, by: { $0 })
            .mapValues { $0.count }
        
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    private func getSuggestionReason(for category: Category) -> String {
        let merchant = transaction.displayMerchantName
        
        if merchant.contains("UBER") && !merchant.contains("EATS") && category.name == "Transportation" {
            return "Uber rides are usually transportation"
        } else if merchant.contains("UBER EATS") && category.name == "Food & Dining" {
            return "Food delivery service"
        } else if abs(transaction.amount) > 500 && category.name == "Housing" {
            return "Large recurring payment"
        }
        
        return "Based on similar transactions"
    }
    
    private func createSmartRule(from query: String) {
        print("Creating smart rule from: \(query)")
        // Implementation would create actual rule
    }
    
    private var merchantIcon: String {
        let merchant = transaction.displayMerchantName.lowercased()
        
        if merchant.contains("uber") && !merchant.contains("eats") {
            return "car.fill"
        } else if merchant.contains("uber eats") || merchant.contains("doordash") {
            return "bag.fill"
        } else if merchant.contains("amazon") {
            return "cart.fill"
        } else if merchant.contains("starbucks") || merchant.contains("coffee") {
            return "cup.and.saucer.fill"
        } else if merchant.contains("walmart") || merchant.contains("target") {
            return "basket.fill"
        }
        
        return "building.2.fill"
    }
    
    private var merchantColor: Color {
        let merchant = transaction.displayMerchantName.lowercased()
        
        if merchant.contains("uber") { return .black }
        else if merchant.contains("amazon") { return .orange }
        else if merchant.contains("starbucks") { return .green }
        else if merchant.contains("walmart") { return .blue }
        
        return .secondary
    }
    
    // MARK: - Main View
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay - tap to dismiss
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
                
                // The actual popup
                VStack(spacing: 0) {
                    // Enhanced transaction context header
                    transactionContextHeader
            
            Divider()
            
            // Main content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Recent categories (if any and not searching)
                    if !recentCategories.isEmpty && searchText.isEmpty {
                        EnhancedCategorySection(
                            title: "RECENT",
                            categories: recentCategories,
                            selectedCategory: selectedCategory,
                            statsProvider: statsProvider,
                            onSelect: selectCategory
                        )
                    }
                    
                    // Smart suggestions section (if not searching)
                    if !suggestedCategories.isEmpty && searchText.isEmpty {
                        smartSuggestionsSection
                    }
                    
                    // All categories by group
                    ForEach(categoryGroups, id: \.key) { groupName, categories in
                        EnhancedCategorySection(
                            title: groupName.uppercased(),
                            categories: categories.sorted { $0.sortOrder < $1.sortOrder },
                            selectedCategory: selectedCategory,
                            statsProvider: statsProvider,
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
                .frame(
                    width: min(720, max(600, geometry.size.width * 0.85)), 
                    height: min(580, max(450, geometry.size.height * 0.8))
                )
                .frame(maxWidth: 720, maxHeight: 580)
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
        }
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
    
    // MARK: - Enhanced Transaction Context
    
    private var transactionContextHeader: some View {
        VStack(spacing: 12) {
            // Close button in top right
            HStack {
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .background(Circle().fill(Color(NSColor.windowBackgroundColor)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Transaction details with merchant icon
            HStack(spacing: 16) {
                // Merchant icon with animation
                ZStack {
                    Circle()
                        .fill(merchantColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: merchantIcon)
                        .font(.title2)
                        .foregroundColor(merchantColor)
                        .rotationEffect(.degrees(iconRotation))
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: iconRotation)
                }
                .onAppear {
                    withAnimation {
                        iconRotation = 5
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.displayMerchantName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(transaction.amount, format: .currency(code: "USD"))
                            .font(.subheadline)
                            .foregroundColor(transaction.amount < 0 ? .primary : .green)
                            .fontWeight(.semibold)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(transaction.date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Show historical pattern if exists
                    if let historicalCategory = findHistoricalCategory() {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption2)
                            Text("Usually: \(historicalCategory)")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Enhanced search bar with natural language
            enhancedSearchBar
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .background(
            LinearGradient(
                colors: [Color(NSColor.windowBackgroundColor), Color(NSColor.windowBackgroundColor).opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Enhanced Search Bar
    
    private var enhancedSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: searchText.isEmpty ? "magnifyingglass" : "sparkles")
                .foregroundColor(.secondary)
                .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
            
            TextField("Search or describe (e.g., 'food over $50')...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { 
                    searchText = ""
                    impact(.generic)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                
                // Smart action button
                if searchText.contains("over") || searchText.contains("under") {
                    Button("Create Rule") {
                        createSmartRule(from: searchText)
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(searchText.isEmpty ? Color.clear : Color.accentColor, lineWidth: 2)
                )
        )
    }
    
    // MARK: - Smart Suggestions Section
    
    private var smartSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Smart Suggestions", systemImage: "sparkles")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Confidence indicator
                if suggestionConfidence > 0 {
                    ConfidenceIndicator(confidence: suggestionConfidence)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestedCategories.prefix(3)) { category in
                        SmartSuggestionCard(
                            category: category,
                            confidence: suggestionConfidence,
                            reason: getSuggestionReason(for: category),
                            onSelect: {
                                impact(.levelChange)
                                selectCategory(category)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}


// MARK: - Enhanced Category Section

struct EnhancedCategorySection: View {
    let title: String
    let categories: [Category]
    let selectedCategory: Category?
    let statsProvider: CategoryStatsProvider
    let onSelect: (Category) -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header with expand/collapse
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("(\(categories.count))")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
                
                Spacer()
                
                // Show section spending total for expense categories
                if title == "EXPENSES" || title.contains("EXPENSE") {
                    Text("$\(sectionTotal, specifier: "%.0f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Button(action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                }
            }
            
            if isExpanded {
                FlowLayout(spacing: 8) {
                    ForEach(categories) { category in
                        EnhancedCategoryChip(
                            category: category,
                            isSelected: selectedCategory?.id == category.id,
                            stats: statsProvider.stats(for: category),
                            action: { 
                                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                                onSelect(category)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    @MainActor
    private var sectionTotal: Double {
        categories.reduce(0) { total, category in
            total + (statsProvider.stats(for: category).spentThisMonth ?? 0)
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

// MARK: - Enhanced Category Chip

struct EnhancedCategoryChip: View {
    let category: Category
    let isSelected: Bool
    let stats: CategoryStats
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var showStats = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category.icon)
                    .font(.body)
                
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                // Show indicators
                if stats.frequency > 10 {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                
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


// MARK: - Smart Suggestion Card

struct SmartSuggestionCard: View {
    let category: Category
    let confidence: Double
    let reason: String
    let onSelect: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: confidence > 0.8 ? 
                                        [.green, .blue] : [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 36, height: 36)
                        
                        Text(category.icon)
                            .font(.title3)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(reason)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
                
                // Quick accept gesture hint
                Text("Tap to use • Swipe right to accept")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 50 {
                        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
                        onSelect()
                    }
                }
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