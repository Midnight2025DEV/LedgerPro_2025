// STEP 1: Add this enhanced transaction header to CategoryPickerPopup (after line 95)

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
                    .background(Circle().fill(Color(.systemBackground)))
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
                    
                    Text(transaction.date, style: .date)
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
            colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.95)],
            startPoint: .top,
            endPoint: .bottom
        )
    )
}

// STEP 2: Replace the search bar (around line 120) with enhanced version
private var enhancedSearchBar: some View {
    HStack(spacing: 12) {
        Image(systemName: searchText.isEmpty ? "magnifyingglass" : "sparkles")
            .foregroundColor(.secondary)
            .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
        
        TextField("Search or describe (e.g., 'food over $50')...", text: $searchText)
            .textFieldStyle(.plain)
        
        if \!searchText.isEmpty {
            Button(action: { 
                searchText = ""
                impact(.light)
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
            .fill(Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(searchText.isEmpty ? Color.clear : Color.accentColor, lineWidth: 2)
            )
    )
}

// STEP 3: Enhance CategorySection with live data (replace struct at line 281)
struct CategorySection: View {
    let title: String
    let categories: [Category]
    let selectedCategory: Category?
    let onSelect: (Category) -> Void
    
    @StateObject private var statsProvider = CategoryStatsProvider()
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
                        impact(.light)
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
                    impact(.light)
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
                                impact(.light)
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
    
    private var sectionTotal: Double {
        categories.reduce(0) { total, category in
            total + (statsProvider.stats(for: category).spentThisMonth ?? 0)
        }
    }
}

// STEP 4: Create enhanced category chip (new component)
struct EnhancedCategoryChip: View {
    let category: Category
    let isSelected: Bool
    let stats: CategoryStats
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var showStats = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
                action()
            }
        }) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(category.icon)
                        .font(.body)
                    
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    // Show indicators
                    if stats.isOverBudget {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                    } else if stats.frequency > 10 {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // Show spending info on hover/tap
                if showStats && stats.spentThisMonth \!= nil {
                    HStack(spacing: 4) {
                        Text("$\(Int(stats.spentThisMonth ?? 0))")
                            .font(.caption2)
                            .fontWeight(.medium)
                        
                        if let remaining = stats.budgetRemaining {
                            Text("•")
                            Text("$\(Int(abs(remaining))) \(remaining < 0 ? "over" : "left")")
                                .foregroundColor(remaining < 0 ? .red : .green)
                        }
                    }
                    .font(.caption2)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, showStats ? 10 : 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? 
                        Color(hex: category.color) : 
                        Color(hex: category.color).opacity(0.15)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Color.clear : Color(hex: category.color).opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                showStats = hovering && \!isSelected
            }
        }
        .onLongPressGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showStats.toggle()
                impact(.medium)
            }
        }
    }
}

// STEP 5: Add smart suggestions section (enhanced version)
private var smartSuggestionsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Label("Smart Suggestions", systemImage: "sparkles")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Confidence indicator
            if let confidence = suggestionConfidence, confidence > 0 {
                ConfidenceIndicator(confidence: confidence)
            }
        }
        .padding(.horizontal, 20)
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(suggestedCategories.prefix(3)) { category in
                    SmartSuggestionCard(
                        category: category,
                        confidence: suggestionConfidence ?? 0.5,
                        reason: getSuggestionReason(for: category),
                        onSelect: {
                            impact(.success)
                            selectCategory(category)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// STEP 6: Add confidence indicator component
struct ConfidenceIndicator: View {
    let confidence: Double
    @State private var animatedConfidence: Double = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(
                        index < Int(animatedConfidence * 5) ? 
                        Color.green : Color.gray.opacity(0.3)
                    )
                    .frame(width: 4, height: 4)
            }
            
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                animatedConfidence = confidence
            }
        }
    }
}

// STEP 7: Add smart suggestion card
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
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 50 {
                        impact(.success)
                        onSelect()
                    }
                }
        )
    }
}

// STEP 8: Add helper functions
private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

private func findHistoricalCategory() -> String? {
    // Find most common category for this merchant
    let merchantTransactions = FinancialDataManager.shared.transactions
        .filter { $0.displayMerchantName == transaction.displayMerchantName }
        .compactMap { $0.category }
    
    let counts = Dictionary(grouping: merchantTransactions, by: { $0 })
        .mapValues { $0.count }
    
    return counts.max(by: { $0.value < $1.value })?.key
}

private func getSuggestionReason(for category: Category) -> String {
    let merchant = transaction.displayMerchantName
    
    if merchant.contains("UBER") && category.name == "Transportation" {
        return "Uber rides are usually transportation"
    } else if merchant.contains("UBER EATS") && category.name == "Food & Dining" {
        return "Food delivery service"
    } else if abs(transaction.amount) > 500 && category.name == "Housing" {
        return "Large recurring payment"
    }
    
    return "Based on similar transactions"
}

private func createSmartRule(from query: String) {
    // Parse natural language query and create rule
    // "food over $50" -> Create rule for Food & Dining with amount > 50
    print("Creating smart rule from: \(query)")
    // Implementation would create actual rule
}

// STEP 9: Add merchant icon and color helpers
private var merchantIcon: String {
    let merchant = transaction.displayMerchantName.lowercased()
    
    if merchant.contains("uber") && \!merchant.contains("eats") {
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
EOF < /dev/null