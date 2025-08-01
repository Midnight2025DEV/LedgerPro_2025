import SwiftUI

/// Transaction Group Header
///
/// Sticky date headers with blur effects, collapse/expand animations,
/// and sophisticated visual treatments.
struct TransactionGroupHeader: View {
    let group: TransactionGroup
    let groupingMode: ModernTransactionList.GroupingMode
    let scrollOffset: CGFloat
    
    @State private var isExpanded = true
    @State private var hasAppeared = false
    @State private var isStuck = false
    
    var body: some View {
        ZStack {
            // Background blur effect
            headerBackground
            
            // Header content
            headerContent
        }
        .frame(height: 56)
        .onAppear {
            withAnimation(DSAnimations.common.standardTransition.delay(0.1)) {
                hasAppeared = true
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onChange(of: geometry.frame(in: .named("transactionList")).minY) { _, newValue in
                        updateStickiness(offset: newValue)
                    }
            }
        )
    }
    
    // MARK: - Header Background
    
    @ViewBuilder
    private var headerBackground: some View {
        ZStack {
            // Base background with adaptive blur
            RoundedRectangle(cornerRadius: isStuck ? 0 : DSSpacing.radius.sm)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: isStuck ? 0 : DSSpacing.radius.sm)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DSColors.neutral.backgroundCard.opacity(isStuck ? 0.8 : 0.5),
                                    DSColors.neutral.backgroundCard.opacity(isStuck ? 0.6 : 0.2)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
            
            // Sticky enhancement
            if isStuck {
                Rectangle()
                    .fill(.regularMaterial)
                    .opacity(0.3)
                    .transition(.opacity)
            }
            
            // Gradient edge effect when stuck
            if isStuck {
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [
                            DSColors.neutral.background.opacity(0.8),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 2)
                    
                    Spacer()
                    
                    LinearGradient(
                        colors: [
                            Color.clear,
                            DSColors.neutral.border.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 1)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isStuck)
    }
    
    // MARK: - Header Content
    
    @ViewBuilder
    private var headerContent: some View {
        HStack(spacing: DSSpacing.md) {
            // Expand/collapse button
            expandCollapseButton
            
            // Date and period info
            dateSection
            
            Spacer()
            
            // Transaction count and total
            summarySection
        }
        .padding(.horizontal, DSSpacing.xl)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(x: hasAppeared ? 0 : -20)
    }
    
    // MARK: - Expand/Collapse Button
    
    @ViewBuilder
    private var expandCollapseButton: some View {
        Button(action: toggleExpansion) {
            ZStack {
                Circle()
                    .fill(DSColors.neutral.n200.opacity(0.3))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "chevron.down")
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isStuck ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isStuck)
    }
    
    // MARK: - Date Section
    
    @ViewBuilder
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Primary date display
            Text(group.displayTitle)
                .font(isStuck ? DSTypography.title.title3 : DSTypography.body.semibold)
                .foregroundColor(DSColors.neutral.text)
                .animation(.easeInOut(duration: 0.2), value: isStuck)
            
            // Secondary date info (for weekly/monthly views)
            if let secondaryInfo = secondaryDateInfo {
                Text(secondaryInfo)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .opacity(isStuck ? 0.8 : 1.0)
            }
        }
    }
    
    // MARK: - Summary Section
    
    @ViewBuilder
    private var summarySection: some View {
        VStack(alignment: .trailing, spacing: 2) {
            // Total amount for the group
            HStack(spacing: DSSpacing.xs) {
                if group.totalAmount >= 0 {
                    Image(systemName: "arrow.up.right")
                        .font(DSTypography.caption.small)
                        .foregroundColor(DSColors.success.main)
                } else {
                    Image(systemName: "arrow.down.right")
                        .font(DSTypography.caption.small)
                        .foregroundColor(DSColors.error.main)
                }
                
                AnimatedNumber(value: group.totalAmount, format: .currency())
                    .font(DSTypography.body.semibold)
                    .foregroundColor(group.totalAmount >= 0 ? DSColors.success.main : DSColors.error.main)
            }
            
            // Transaction count
            Text("\(group.transactions.count) transaction\(group.transactions.count == 1 ? "" : "s")")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
        }
        .scaleEffect(isStuck ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isStuck)
    }
    
    // MARK: - Computed Properties
    
    private var secondaryDateInfo: String? {
        let calendar = Calendar.current
        
        switch groupingMode {
        case .day:
            // Show relative date for recent days
            if calendar.isDateInToday(group.date) || calendar.isDateInYesterday(group.date) {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: group.date)
            }
            return nil
            
        case .week:
            // Show week number and year
            let weekOfYear = calendar.component(.weekOfYear, from: group.date)
            let year = calendar.component(.year, from: group.date)
            return "Week \(weekOfYear), \(year)"
            
        case .month:
            // Show transaction count breakdown
            let expenses = group.transactions.filter { $0.amount < 0 }.count
            let income = group.transactions.filter { $0.amount > 0 }.count
            return "\(income) income, \(expenses) expenses"
        }
    }
    
    // MARK: - Actions
    
    private func toggleExpansion() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isExpanded.toggle()
        }
        
        // TODO: Implement actual expand/collapse of transaction list
        // This would require coordination with the parent view
    }
    
    private func updateStickiness(offset: CGFloat) {
        let threshold: CGFloat = 100 // Distance from top when considered "stuck"
        let newIsStuck = offset <= threshold
        
        if newIsStuck != isStuck {
            withAnimation(.easeInOut(duration: 0.2)) {
                isStuck = newIsStuck
            }
            
            // Subtle haptic feedback when becoming stuck
            if newIsStuck {
                #if canImport(UIKit)
                let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
                impactFeedback.impactOccurred()
                #endif
            }
        }
    }
}

// MARK: - Enhanced Group Header with Performance Metrics

extension TransactionGroupHeader {
    /// Create header with performance optimizations for large lists
    static func optimized(
        group: TransactionGroup,
        groupingMode: ModernTransactionList.GroupingMode,
        scrollOffset: CGFloat,
        isVisible: Bool = true
    ) -> some View {
        Group {
            if isVisible {
                TransactionGroupHeader(
                    group: group,
                    groupingMode: groupingMode,
                    scrollOffset: scrollOffset
                )
            } else {
                // Placeholder for off-screen headers
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 56)
            }
        }
    }
}

// MARK: - Accessibility Enhancements

extension TransactionGroupHeader {
    private var accessibilityLabel: String {
        let transactionCount = group.transactions.count
        let totalAmount = group.totalAmount.formatAsCurrency()
        let period = group.displayTitle
        
        return "\(period), \(transactionCount) transactions, total \(totalAmount)"
    }
    
    private var accessibilityHint: String {
        return isExpanded ? "Double tap to collapse transactions" : "Double tap to expand transactions"
    }
}

// MARK: - Interactive Enhancements

struct InteractiveGroupHeader: View {
    let group: TransactionGroup
    let groupingMode: ModernTransactionList.GroupingMode
    let scrollOffset: CGFloat
    let onToggleExpansion: (Bool) -> Void
    let onTap: () -> Void
    
    @State private var isExpanded = true
    @State private var isPressed = false
    
    var body: some View {
        TransactionGroupHeader(
            group: group,
            groupingMode: groupingMode,
            scrollOffset: scrollOffset
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(
            minimumDuration: 0.1,
            maximumDistance: 50,
            pressing: { pressing in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = pressing
                }
            },
            perform: {
                #if canImport(UIKit)
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                #endif
                
                isExpanded.toggle()
                onToggleExpansion(isExpanded)
            }
        )
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAction(.default) {
            isExpanded.toggle()
            onToggleExpansion(isExpanded)
        }
    }
    
    private var accessibilityLabel: String {
        let transactionCount = group.transactions.count
        let totalAmount = group.totalAmount.formatAsCurrency()
        let period = group.displayTitle
        
        return "\(period), \(transactionCount) transactions, total \(totalAmount)"
    }
    
    private var accessibilityHint: String {
        return isExpanded ? "Double tap to collapse transactions" : "Double tap to expand transactions"
    }
}

// MARK: - Preview

#Preview("Transaction Group Headers") {
    ScrollView {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            // Today's transactions
            Section {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(DSColors.neutral.n100)
                        .frame(height: 80)
                        .padding(.horizontal, DSSpacing.xl)
                        .padding(.vertical, DSSpacing.xs)
                }
            } header: {
                TransactionGroupHeader(
                    group: TransactionGroup(
                        date: Date(),
                        transactions: Array(repeating: Transaction(
                            date: "2024-01-15",
                            description: "Sample Transaction",
                            amount: -45.67,
                            category: "Food & Dining",
                            confidence: 0.95,
                            accountId: "account1"
                        ), count: 3),
                        groupingMode: .day
                    ),
                    groupingMode: .day,
                    scrollOffset: 0
                )
            }
            
            // Yesterday's transactions
            Section {
                ForEach(0..<5, id: \.self) { _ in
                    Rectangle()
                        .fill(DSColors.neutral.n100)
                        .frame(height: 80)
                        .padding(.horizontal, DSSpacing.xl)
                        .padding(.vertical, DSSpacing.xs)
                }
            } header: {
                TransactionGroupHeader(
                    group: TransactionGroup(
                        date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                        transactions: Array(repeating: Transaction(
                            date: "2024-01-14",
                            description: "Sample Transaction",
                            amount: -25.00,
                            category: "Transportation",
                            confidence: 0.9,
                            accountId: "account1"
                        ), count: 5),
                        groupingMode: .day
                    ),
                    groupingMode: .day,
                    scrollOffset: 0
                )
            }
        }
    }
    .coordinateSpace(name: "transactionList")
    .background(
        LinearGradient(
            colors: [DSColors.neutral.background, DSColors.neutral.backgroundSecondary],
            startPoint: .top,
            endPoint: .bottom
        )
    )
}