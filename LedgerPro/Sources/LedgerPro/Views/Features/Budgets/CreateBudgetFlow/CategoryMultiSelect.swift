import SwiftUI

/// CategoryMultiSelect - Visual category selection interface
///
/// Beautiful multi-select category picker with search, historical spending data,
/// and visual previews to help users make informed budget category choices.
struct CategoryMultiSelect: View {
    @Binding var selectedCategories: Set<String>
    let availableCategories: [BudgetCategory]
    
    @State private var searchText = ""
    @State private var hasAppeared = false
    @State private var showingPreview = false
    @State private var previewTransactions: [Transaction] = []
    
    private var filteredCategories: [BudgetCategory] {
        if searchText.isEmpty {
            return availableCategories
        } else {
            return availableCategories.filter { category in
                category.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var selectedCount: Int {
        selectedCategories.count
    }
    
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            // Search and controls
            searchAndControlsSection
            
            // Selected categories preview
            if !selectedCategories.isEmpty {
                selectedCategoriesPreview
            }
            
            // Category grid
            categoryGrid
            
            // Transaction preview toggle
            if !selectedCategories.isEmpty {
                transactionPreviewToggle
            }
            
            // Transaction preview
            if showingPreview {
                transactionPreview
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
            }
            generatePreviewTransactions()
        }
        .onChange(of: selectedCategories) { _, _ in
            generatePreviewTransactions()
        }
    }
    
    // MARK: - Search and Controls Section
    
    @ViewBuilder
    private var searchAndControlsSection: some View {
        VStack(spacing: DSSpacing.md) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.neutral.textSecondary)
                
                TextField("Search categories...", text: $searchText)
                    .font(DSTypography.body.regular)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(DSTypography.body.medium)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                    .stroke(DSColors.neutral.border.opacity(0.3), lineWidth: 1)
            )
            
            // Quick actions
            HStack {
                // Select all button
                Button(action: selectAll) {
                    HStack(spacing: DSSpacing.xs) {
                        Image(systemName: "checkmark.square.fill")
                            .font(DSTypography.caption.regular)
                        Text("Select All")
                            .font(DSTypography.caption.regular)
                    }
                    .foregroundColor(DSColors.primary.main)
                }
                .buttonStyle(.plain)
                .disabled(selectedCategories.count == filteredCategories.count)
                .opacity(selectedCategories.count == filteredCategories.count ? 0.5 : 1.0)
                
                Spacer()
                
                // Clear selection button
                if !selectedCategories.isEmpty {
                    Button(action: clearSelection) {
                        HStack(spacing: DSSpacing.xs) {
                            Image(systemName: "xmark.square")
                                .font(DSTypography.caption.regular)
                            Text("Clear All")
                                .font(DSTypography.caption.regular)
                        }
                        .foregroundColor(DSColors.error.main)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                Spacer()
                
                // Selection count
                if selectedCount > 0 {
                    Text("\(selectedCount) selected")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .transition(.opacity.combined(with: .slide))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedCategories.count)
        }
    }
    
    // MARK: - Selected Categories Preview
    
    @ViewBuilder
    private var selectedCategoriesPreview: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("Selected Categories")
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DSSpacing.sm) {
                    ForEach(Array(selectedCategories), id: \.self) { categoryId in
                        if let category = availableCategories.first(where: { $0.id == categoryId }) {
                            SelectedCategoryChip(
                                category: category,
                                onRemove: {
                                    removeCategory(categoryId)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, DSSpacing.sm)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedCategories)
    }
    
    // MARK: - Category Grid
    
    @ViewBuilder
    private var categoryGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.md), count: 2),
            spacing: DSSpacing.md
        ) {
            ForEach(Array(filteredCategories.enumerated()), id: \.element.id) { index, category in
                CategorySelectionCard(
                    category: category,
                    isSelected: selectedCategories.contains(category.id),
                    onToggle: {
                        toggleCategory(category.id)
                    }
                )
                .scaleEffect(hasAppeared ? 1.0 : 0.8)
                .opacity(hasAppeared ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8)
                    .delay(Double(index) * 0.05),
                    value: hasAppeared
                )
            }
        }
    }
    
    // MARK: - Transaction Preview Toggle
    
    @ViewBuilder
    private var transactionPreviewToggle: some View {
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showingPreview.toggle()
            }
        }) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(DSTypography.body.medium)
                
                Text(showingPreview ? "Hide Preview" : "Preview Transactions")
                    .font(DSTypography.body.medium)
                
                Spacer()
                
                Text("\(previewTransactions.count) transactions")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                
                Image(systemName: showingPreview ? "chevron.up" : "chevron.down")
                    .font(DSTypography.caption.regular)
            }
            .foregroundColor(DSColors.primary.main)
            .padding(DSSpacing.md)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.lg)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Transaction Preview
    
    @ViewBuilder
    private var transactionPreview: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("Included Transactions")
                .font(DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
            
            if previewTransactions.isEmpty {
                EmptyTransactionPreview()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: DSSpacing.sm) {
                        ForEach(previewTransactions.prefix(10)) { transaction in
                            TransactionPreviewRow(transaction: transaction)
                        }
                        
                        if previewTransactions.count > 10 {
                            Text("... and \(previewTransactions.count - 10) more")
                                .font(DSTypography.caption.regular)
                                .foregroundColor(DSColors.neutral.textSecondary)
                                .padding(.vertical, DSSpacing.sm)
                        }
                    }
                    .padding(.vertical, DSSpacing.sm)
                }
                .frame(maxHeight: 200)
                .background(.ultraThinMaterial)
                .cornerRadius(DSSpacing.radius.lg)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    // MARK: - Actions
    
    private func toggleCategory(_ categoryId: String) {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if selectedCategories.contains(categoryId) {
                selectedCategories.remove(categoryId)
            } else {
                selectedCategories.insert(categoryId)
            }
        }
    }
    
    private func removeCategory(_ categoryId: String) {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedCategories.remove(categoryId)
        }
    }
    
    private func selectAll() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            selectedCategories = Set(filteredCategories.map(\.id))
        }
    }
    
    private func clearSelection() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            selectedCategories.removeAll()
        }
    }
    
    private func generatePreviewTransactions() {
        // In a real app, this would query your transaction data
        // For now, we'll generate sample transactions
        let sampleTransactions = selectedCategories.flatMap { categoryId -> [Transaction] in
            guard let category = availableCategories.first(where: { $0.id == categoryId }) else { return [] }
            
            return (0..<Int.random(in: 2...5)).map { i in
                Transaction(
                    id: "\(categoryId)-\(i)",
                    date: Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...30), to: Date())?.ISO8601Format() ?? "",
                    description: generateSampleDescription(for: category),
                    amount: Double.random(in: -200...(-10)),
                    category: category.name,
                    confidence: 0.9,
                    jobId: "sample",
                    accountId: "sample"
                )
            }
        }
        
        previewTransactions = Array(sampleTransactions.prefix(50))
    }
    
    private func generateSampleDescription(for category: BudgetCategory) -> String {
        switch category.id {
        case "groceries":
            return ["Whole Foods", "Safeway", "Trader Joe's", "Costco"].randomElement() ?? "Grocery Store"
        case "dining":
            return ["Starbucks", "McDonald's", "Chipotle", "Local Restaurant"].randomElement() ?? "Restaurant"
        case "entertainment":
            return ["Netflix", "Spotify", "Movie Theater", "Concert"].randomElement() ?? "Entertainment"
        case "transportation":
            return ["Uber", "Lyft", "Gas Station", "Public Transit"].randomElement() ?? "Transportation"
        case "shopping":
            return ["Amazon", "Target", "Best Buy", "Mall"].randomElement() ?? "Shopping"
        case "utilities":
            return ["Electric Bill", "Water Bill", "Internet", "Phone"].randomElement() ?? "Utility"
        default:
            return "Sample Transaction"
        }
    }
}

// MARK: - Category Selection Card

struct CategorySelectionCard: View {
    let category: BudgetCategory
    let isSelected: Bool
    let onToggle: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: DSSpacing.md) {
                // Icon and selection indicator
                ZStack {
                    // Category icon background
                    Circle()
                        .fill(category.color.opacity(isSelected ? 0.8 : 0.15))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(category.color.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? .white : category.color)
                    
                    // Selection checkmark
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(DSColors.success.main)
                                    .background(Circle().fill(.white))
                                    .transition(.scale.combined(with: .opacity))
                            }
                            Spacer()
                        }
                        .frame(width: 60, height: 60)
                    }
                }
                
                // Category info
                VStack(spacing: DSSpacing.xs) {
                    Text(category.name)
                        .font(DSTypography.body.semibold)
                        .foregroundColor(DSColors.neutral.text)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // Historical spending
                    if let monthlyAverage = category.monthlyAverage {
                        Text("Avg: \(monthlyAverage.formatAsCurrency())/mo")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                }
            }
            .padding(DSSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(cardBackground)
            .cornerRadius(DSSpacing.radius.xl)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: 50,
            pressing: { pressing in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                    .fill(
                        LinearGradient(
                            colors: [
                                category.color.opacity(isSelected ? 0.1 : 0.03),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.xl)
                    .stroke(
                        isSelected ? category.color.opacity(0.5) : DSColors.neutral.border.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
    }
}

// MARK: - Selected Category Chip

struct SelectedCategoryChip: View {
    let category: BudgetCategory
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: category.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(category.color)
            
            Text(category.name)
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.text)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(category.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Transaction Preview Row

struct TransactionPreviewRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: DSSpacing.md) {
            // Transaction icon
            Circle()
                .fill(DSColors.neutral.n200.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 14))
                        .foregroundColor(DSColors.neutral.textSecondary)
                )
            
            // Transaction details
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.neutral.text)
                    .lineLimit(1)
                
                Text(transaction.category)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
            }
            
            Spacer()
            
            // Amount
            Text(transaction.amount.formatAsCurrency())
                .font(DSTypography.body.semibold)
                .foregroundColor(transaction.amount < 0 ? DSColors.error.main : DSColors.success.main)
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
    }
}

// MARK: - Empty Transaction Preview

struct EmptyTransactionPreview: View {
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 32))
                .foregroundColor(DSColors.neutral.textTertiary)
            
            Text("No transactions found")
                .font(DSTypography.body.medium)
                .foregroundColor(DSColors.neutral.textSecondary)
            
            Text("Your budget will include transactions from the selected categories once you start spending.")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .padding(DSSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
    }
}

// MARK: - Preview

#Preview("Category Multi Select") {
    ScrollView {
        CategoryMultiSelect(
            selectedCategories: .constant(["groceries", "dining"]),
            availableCategories: [
                BudgetCategory(id: "groceries", name: "Groceries", icon: "cart.fill", color: DSColors.success.main, monthlyAverage: 450),
                BudgetCategory(id: "dining", name: "Dining Out", icon: "fork.knife", color: DSColors.warning.main, monthlyAverage: 300),
                BudgetCategory(id: "entertainment", name: "Entertainment", icon: "tv.fill", color: DSColors.primary.main, monthlyAverage: 150),
                BudgetCategory(id: "transportation", name: "Transportation", icon: "car.fill", color: DSColors.primary.main, monthlyAverage: 200),
                BudgetCategory(id: "shopping", name: "Shopping", icon: "bag.fill", color: DSColors.error.main, monthlyAverage: 250),
                BudgetCategory(id: "utilities", name: "Utilities", icon: "bolt.fill", color: DSColors.neutral.n600, monthlyAverage: 180)
            ]
        )
    }
    .padding()
    .background(
        LinearGradient(
            colors: [DSColors.neutral.background, DSColors.neutral.backgroundSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}