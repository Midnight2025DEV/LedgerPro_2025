import SwiftUI
import Combine

/// Enhanced Transaction Search
///
/// Sophisticated search experience with glass morphism, live filtering,
/// suggestions, and advanced filter options.
struct TransactionSearch: View {
    @Binding var searchText: String
    @Binding var showFilters: Bool
    @Binding var activeFilters: TransactionFilters
    
    @State private var isSearchFocused = false
    @State private var searchSuggestions: [SearchSuggestion] = []
    @State private var showSuggestions = false
    @State private var hasSearchResults = true
    @State private var resultCount = 0
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            // Search bar
            searchBar
            
            // Search suggestions
            if showSuggestions && !searchSuggestions.isEmpty {
                searchSuggestionsView
            }
            
            // Results indicator
            if !searchText.isEmpty {
                resultsIndicator
            }
            
            // Filter sheet
            if showFilters {
                filterOptionsView
            }
        }
    }
    
    // MARK: - Search Bar
    
    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: DSSpacing.md) {
            // Search input with glass morphism
            searchInput
            
            // Filter toggle button
            filterButton
        }
    }
    
    @ViewBuilder
    private var searchInput: some View {
        HStack(spacing: DSSpacing.sm) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(DSTypography.body.medium)
                .foregroundColor(isSearchFocused ? DSColors.primary.main : DSColors.neutral.textSecondary)
                .animation(DSAnimations.common.quickFeedback, value: isSearchFocused)
            
            // Text field
            TextField("Search transactions...", text: $searchText)
                .font(DSTypography.body.regular)
                .foregroundColor(DSColors.neutral.text)
                .focused($isTextFieldFocused)
                .onReceive(searchText.publisher.debounce(for: 0.3, scheduler: DispatchQueue.main)) { _ in
                    updateSearchSuggestions()
                    performSearch()
                }
                .onChange(of: isTextFieldFocused) { _, focused in
                    withAnimation(DSAnimations.common.quickFeedback) {
                        isSearchFocused = focused
                        showSuggestions = focused && !searchText.isEmpty
                    }
                }
            
            // Clear button
            if !searchText.isEmpty {
                Button(action: clearSearch) {
                    Image(systemName: "xmark.circle.fill")
                        .font(DSTypography.body.medium)
                        .foregroundColor(DSColors.neutral.textSecondary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
                .animation(DSAnimations.common.quickFeedback, value: searchText.isEmpty)
            }
        }
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.sm)
        .background(searchBarBackground)
        .overlay(searchBarBorder)
        .cornerRadius(DSSpacing.radius.lg)
    }
    
    @ViewBuilder
    private var searchBarBackground: some View {
        RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                    .fill(
                        LinearGradient(
                            colors: [
                                isSearchFocused ? DSColors.primary.p50.opacity(0.1) : Color.clear,
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(isSearchFocused ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSearchFocused)
    }
    
    @ViewBuilder
    private var searchBarBorder: some View {
        RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
            .stroke(
                isSearchFocused ? DSColors.primary.main.opacity(0.5) : DSColors.neutral.border.opacity(0.3),
                lineWidth: isSearchFocused ? 1.5 : 0.5
            )
            .animation(DSAnimations.common.quickFeedback, value: isSearchFocused)
    }
    
    // MARK: - Filter Button
    
    @ViewBuilder
    private var filterButton: some View {
        Button(action: toggleFilters) {
            ZStack {
                Circle()
                    .fill(showFilters ? DSColors.primary.main : DSColors.neutral.backgroundCard)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(
                                showFilters ? DSColors.primary.main.opacity(0.3) : DSColors.neutral.border.opacity(0.3),
                                lineWidth: 0.5
                            )
                    )
                
                Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(DSTypography.body.medium)
                    .foregroundColor(showFilters ? .white : DSColors.neutral.textSecondary)
                
                // Active filter indicator
                if activeFilters.hasActiveFilters {
                    Circle()
                        .fill(DSColors.error.main)
                        .frame(width: 12, height: 12)
                        .offset(x: 14, y: -14)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(showFilters ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showFilters)
    }
    
    // MARK: - Search Suggestions
    
    @ViewBuilder
    private var searchSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(searchSuggestions.prefix(5), id: \.id) { suggestion in
                SearchSuggestionRow(suggestion: suggestion) {
                    applySuggestion(suggestion)
                }
                
                if suggestion.id != searchSuggestions.prefix(5).last?.id {
                    Divider()
                        .overlay(DSColors.neutral.border.opacity(0.3))
                }
            }
        }
        .padding(.vertical, DSSpacing.sm)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
        .shadow(
            color: .black.opacity(0.1),
            radius: 10,
            x: 0,
            y: 4
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(DSAnimations.common.standardTransition, value: showSuggestions)
    }
    
    // MARK: - Results Indicator
    
    @ViewBuilder
    private var resultsIndicator: some View {
        HStack {
            // Results count
            if hasSearchResults {
                HStack(spacing: DSSpacing.xs) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.success.main)
                    
                    Text("\(resultCount) result\(resultCount == 1 ? "" : "s")")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                }
            } else {
                HStack(spacing: DSSpacing.xs) {
                    Image(systemName: "exclamationmark.circle")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.warning.main)
                    
                    Text("No results found")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                }
            }
            
            Spacer()
            
            // Search suggestions toggle
            if !searchSuggestions.isEmpty {
                Button(showSuggestions ? "Hide suggestions" : "Show suggestions") {
                    withAnimation(DSAnimations.common.quickFeedback) {
                        showSuggestions.toggle()
                    }
                }
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.primary.main)
            }
        }
        .padding(.horizontal, DSSpacing.sm)
        .transition(.opacity.combined(with: .slide))
    }
    
    // MARK: - Filter Options
    
    @ViewBuilder
    private var filterOptionsView: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            // Filter header
            HStack {
                Text("Filter Options")
                    .font(DSTypography.body.semibold)
                    .foregroundColor(DSColors.neutral.text)
                
                Spacer()
                
                Button("Clear All") {
                    clearAllFilters()
                }
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.error.main)
                .opacity(activeFilters.hasActiveFilters ? 1.0 : 0.5)
                .disabled(!activeFilters.hasActiveFilters)
            }
            
            // Date range filter
            dateRangeFilter
            
            // Amount range filter
            amountRangeFilter
            
            // Category filter
            categoryFilter
        }
        .padding(DSSpacing.lg)
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
        .shadow(
            color: .black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 2
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    @ViewBuilder
    private var dateRangeFilter: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Date Range")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DSSpacing.sm) {
                    ForEach([
                        TransactionFilters.DateRange.thisWeek,
                        .thisMonth,
                        .thisYear
                    ], id: \.title) { range in
                        SelectableFilterChip(
                            title: range.title,
                            color: DSColors.primary.main,
                            isSelected: activeFilters.dateRange?.title == range.title,
                            onTap: {
                                toggleDateFilter(range)
                            }
                        )
                    }
                }
                .padding(.horizontal, DSSpacing.sm)
            }
        }
    }
    
    @ViewBuilder
    private var amountRangeFilter: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Amount Range")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            // TODO: Add range slider for amount filtering
            Text("Coming soon...")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textTertiary)
        }
    }
    
    @ViewBuilder
    private var categoryFilter: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Categories")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DSSpacing.sm) {
                    ForEach(commonCategories, id: \.self) { category in
                        SelectableFilterChip(
                            title: category,
                            color: DSColors.category.color(for: category),
                            isSelected: activeFilters.categories.contains(category),
                            onTap: {
                                toggleCategoryFilter(category)
                            }
                        )
                    }
                }
                .padding(.horizontal, DSSpacing.sm)
            }
        }
    }
    
    // MARK: - Data & Logic
    
    private var commonCategories: [String] {
        ["Food & Dining", "Transportation", "Shopping", "Entertainment", "Utilities", "Healthcare"]
    }
    
    private func clearSearch() {
        withAnimation(DSAnimations.common.quickFeedback) {
            searchText = ""
            showSuggestions = false
            isTextFieldFocused = false
        }
    }
    
    private func toggleFilters() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        withAnimation(DSAnimations.common.standardTransition) {
            showFilters.toggle()
        }
    }
    
    private func updateSearchSuggestions() {
        guard !searchText.isEmpty else {
            searchSuggestions = []
            return
        }
        
        // Generate contextual search suggestions
        var suggestions: [SearchSuggestion] = []
        
        // Merchant suggestions
        if searchText.count >= 2 {
            suggestions.append(SearchSuggestion(
                id: "merchant-\(searchText)",
                type: .merchant,
                text: searchText.capitalized,
                description: "Search merchants"
            ))
        }
        
        // Category suggestions
        for category in commonCategories {
            if category.localizedCaseInsensitiveContains(searchText) {
                suggestions.append(SearchSuggestion(
                    id: "category-\(category)",
                    type: .category,
                    text: category,
                    description: "Filter by category"
                ))
            }
        }
        
        // Amount suggestions (if search text looks like a number)
        if let amount = Double(searchText.replacingOccurrences(of: "$", with: "")) {
            suggestions.append(SearchSuggestion(
                id: "amount-\(amount)",
                type: .amount,
                text: amount.formatAsCurrency(),
                description: "Find exact amount"
            ))
        }
        
        searchSuggestions = Array(suggestions.prefix(5))
    }
    
    private func applySuggestion(_ suggestion: SearchSuggestion) {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        switch suggestion.type {
        case .merchant:
            searchText = suggestion.text
        case .category:
            searchText = ""
            activeFilters.categories.insert(suggestion.text)
        case .amount:
            searchText = suggestion.text
        }
        
        showSuggestions = false
        isTextFieldFocused = false
        performSearch()
    }
    
    private func performSearch() {
        // Simulate search with delay for real-time feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Update result count based on search
            if searchText.isEmpty && !activeFilters.hasActiveFilters {
                resultCount = 0
                hasSearchResults = true
            } else {
                resultCount = Int.random(in: 0...50) // Simulate results
                hasSearchResults = resultCount > 0
            }
        }
    }
    
    private func toggleDateFilter(_ range: TransactionFilters.DateRange) {
        if activeFilters.dateRange?.title == range.title {
            activeFilters.dateRange = nil
        } else {
            activeFilters.dateRange = range
        }
        performSearch()
    }
    
    private func toggleCategoryFilter(_ category: String) {
        if activeFilters.categories.contains(category) {
            activeFilters.categories.remove(category)
        } else {
            activeFilters.categories.insert(category)
        }
        performSearch()
    }
    
    private func clearAllFilters() {
        withAnimation(DSAnimations.common.quickFeedback) {
            activeFilters.clear()
            performSearch()
        }
    }
}

// MARK: - Search Suggestion Row

struct SearchSuggestionRow: View {
    let suggestion: SearchSuggestion
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DSSpacing.md) {
                // Suggestion icon
                Image(systemName: suggestion.type.icon)
                    .font(DSTypography.body.medium)
                    .foregroundColor(suggestion.type.color)
                    .frame(width: 24)
                
                // Suggestion content
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.text)
                        .font(DSTypography.body.medium)
                        .foregroundColor(DSColors.neutral.text)
                    
                    Text(suggestion.description)
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                }
                
                Spacer()
                
                // Insert icon
                Image(systemName: "arrow.up.backward")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textTertiary)
                    .opacity(isPressed ? 1.0 : 0.6)
            }
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .background(
                Rectangle()
                    .fill(isPressed ? DSColors.neutral.n100.opacity(0.5) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: 50,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}

// MARK: - Filter Chip

// FilterChip moved to Models/TransactionFilters.swift
// This is a local version for selection state
struct SelectableFilterChip: View {
    let title: String
    let color: Color
    var isSelected: Bool = false
    let onTap: (() -> Void)?
    
    var body: some View {
        Button(action: { onTap?() }) {
            Text(title)
                .font(DSTypography.caption.regular)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(color.opacity(isSelected ? 0.3 : 0.5), lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Supporting Types

struct SearchSuggestion: Identifiable {
    let id: String
    let type: SuggestionType
    let text: String
    let description: String
    
    enum SuggestionType {
        case merchant, category, amount
        
        var icon: String {
            switch self {
            case .merchant: return "building.2"
            case .category: return "tag"
            case .amount: return "dollarsign.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .merchant: return DSColors.primary.main
            case .category: return DSColors.warning.main
            case .amount: return DSColors.success.main
            }
        }
    }
}

// ChipData moved to Models/TransactionFilters.swift

// MARK: - String Publisher Extension

extension String {
    var publisher: AnyPublisher<String, Never> {
        Just(self).eraseToAnyPublisher()
    }
}

// MARK: - Preview

#Preview("Transaction Search") {
    @State var searchText = ""
    @State var showFilters = false
    @State var activeFilters = TransactionFilters()
    
    VStack(spacing: DSSpacing.xl) {
        TransactionSearch(
            searchText: $searchText,
            showFilters: $showFilters,
            activeFilters: $activeFilters
        )
        
        Spacer()
    }
    .padding(DSSpacing.xl)
    .background(
        LinearGradient(
            colors: [DSColors.neutral.background, DSColors.neutral.backgroundSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}