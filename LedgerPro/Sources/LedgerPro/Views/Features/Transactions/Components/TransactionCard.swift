import SwiftUI

/// Premium Transaction Card
///
/// A sophisticated transaction row with glass morphism, merchant logos,
/// animated amounts, and smooth swipe interactions.
struct TransactionCard: View {
    let transaction: Transaction
    let isSelected: Bool
    let isBulkSelectionMode: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onSwipeAction: (SwipeAction) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var isHovered = false
    @State private var hasAppeared = false
    @State private var revealedAction: SwipeAction?
    
    // Swipe action configuration
    private let swipeThreshold: CGFloat = 80
    private let maxSwipeDistance: CGFloat = 200
    
    var body: some View {
        ZStack {
            // Swipe actions background
            swipeActionsBackground
            
            // Main card content
            cardContent
                .offset(x: dragOffset.width)
                .scaleEffect(isSelected ? 0.98 : 1.0)
                .opacity(hasAppeared ? 1.0 : 0.0)
                .animation(DSAnimations.common.gentleBounce, value: isSelected)
                .animation(DSAnimations.common.standardTransition, value: hasAppeared)
                .gesture(swipeGesture)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { onTap() }
                )
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in onLongPress() }
                )
                .onHover { hovering in
                    withAnimation(DSAnimations.common.quickFeedback) {
                        isHovered = hovering
                    }
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.radius.lg))
        .padding(.horizontal, DSSpacing.xl)
        .padding(.vertical, DSSpacing.xs)
        .onAppear {
            withAnimation(
                DSAnimations.common.standardTransition.delay(Double.random(in: 0...0.2))
            ) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Card Content
    
    @ViewBuilder
    private var cardContent: some View {
        HStack(spacing: DSSpacing.md) {
            // Selection indicator (bulk mode)
            if isBulkSelectionMode {
                selectionIndicator
            }
            
            // Merchant icon/logo
            merchantIcon
            
            // Transaction details
            transactionDetails
            
            Spacer()
            
            // Amount and metadata
            amountSection
        }
        .padding(DSSpacing.lg)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(
            color: isSelected ? DSColors.primary.main.opacity(0.3) : DSColors.neutral.n200.opacity(0.3),
            radius: isSelected ? 8 : 2,
            x: 0,
            y: isSelected ? 4 : 1
        )
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                    .fill(
                        LinearGradient(
                            colors: [
                                isSelected ? DSColors.primary.p50.opacity(0.3) : Color.clear,
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
    }
    
    @ViewBuilder
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
            .stroke(
                isSelected ? DSColors.primary.main.opacity(0.5) : DSColors.neutral.border.opacity(0.3),
                lineWidth: isSelected ? 1.5 : 0.5
            )
    }
    
    // MARK: - Selection Indicator
    
    @ViewBuilder
    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .fill(isSelected ? DSColors.primary.main : DSColors.neutral.n300)
                .frame(width: 24, height: 24)
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(DSTypography.caption.small)
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(DSAnimations.common.quickFeedback, value: isSelected)
    }
    
    // MARK: - Merchant Icon
    
    @ViewBuilder
    private var merchantIcon: some View {
        ZStack {
            // Background circle with category color
            Circle()
                .fill(categoryColor.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Circle()
                        .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                )
            
            // Icon or merchant logo
            if let merchantLogo = getMerchantLogo() {
                merchantLogo
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Image(systemName: categoryIcon)
                    .font(DSTypography.body.medium)
                    .foregroundColor(categoryColor)
            }
        }
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .animation(DSAnimations.common.quickFeedback, value: isDragging)
    }
    
    // MARK: - Transaction Details
    
    @ViewBuilder
    private var transactionDetails: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            // Merchant/Description
            Text(cleanMerchantName)
                .font(DSTypography.body.medium)
                .foregroundColor(DSColors.neutral.text)
                .lineLimit(1)
            
            // Category pill
            categoryPill
            
            // Date and additional info
            HStack(spacing: DSSpacing.sm) {
                Text(formattedDate)
                    .font(DSTypography.caption.regular)
                    .foregroundColor(DSColors.neutral.textTertiary)
                
                if transaction.isRecurring {
                    Image(systemName: "repeat.circle.fill")
                        .font(DSTypography.caption.small)
                        .foregroundColor(DSColors.primary.main)
                }
                
                if transaction.isPending {
                    Text("PENDING")
                        .font(DSTypography.caption.small)
                        .foregroundColor(DSColors.warning.main)
                        .padding(.horizontal, DSSpacing.xs)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(DSColors.warning.main.opacity(0.1))
                        )
                }
            }
        }
    }
    
    @ViewBuilder
    private var categoryPill: some View {
        Text(transaction.category)
            .font(DSTypography.caption.small)
            .foregroundColor(categoryColor)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(categoryColor.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(categoryColor.opacity(0.3), lineWidth: 0.5)
                    )
            )
    }
    
    // MARK: - Amount Section
    
    @ViewBuilder
    private var amountSection: some View {
        VStack(alignment: .trailing, spacing: DSSpacing.xs) {
            // Animated amount
            AnimatedNumber(value: transaction.amount, format: .currency())
                .font(DSTypography.financial.currency)
                .foregroundColor(amountColor)
                .multilineTextAlignment(.trailing)
            
            // Balance impact indicator
            if transaction.isExpense {
                HStack(spacing: DSSpacing.xs) {
                    Image(systemName: "arrow.down.right")
                        .font(DSTypography.caption.small)
                        .foregroundColor(DSColors.error.main)
                    
                    Text("Expense")
                        .font(DSTypography.caption.small)
                        .foregroundColor(DSColors.error.main)
                }
            } else if transaction.amount > 0 {
                HStack(spacing: DSSpacing.xs) {
                    Image(systemName: "arrow.up.right")
                        .font(DSTypography.caption.small)
                        .foregroundColor(DSColors.success.main)
                    
                    Text("Income")
                        .font(DSTypography.caption.small)
                        .foregroundColor(DSColors.success.main)
                }
            }
        }
    }
    
    // MARK: - Swipe Actions Background
    
    @ViewBuilder
    private var swipeActionsBackground: some View {
        HStack(spacing: 0) {
            // Left swipe actions (positive swipe)
            if dragOffset.width > 0 {
                leftSwipeActions
            }
            
            Spacer()
            
            // Right swipe actions (negative swipe)
            if dragOffset.width < 0 {
                rightSwipeActions
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.radius.lg))
    }
    
    @ViewBuilder
    private var leftSwipeActions: some View {
        HStack(spacing: DSSpacing.sm) {
            SwipeActionButton(
                action: .categorize,
                icon: "tag.fill",
                color: DSColors.primary.main,
                isRevealed: dragOffset.width > swipeThreshold,
                onTrigger: { triggerSwipeAction(.categorize) }
            )
            
            SwipeActionButton(
                action: .flag,
                icon: "flag.fill",
                color: DSColors.warning.main,
                isRevealed: dragOffset.width > swipeThreshold * 2,
                onTrigger: { triggerSwipeAction(.flag) }
            )
        }
        .padding(.leading, DSSpacing.lg)
        .opacity(dragOffset.width > 20 ? 1.0 : 0.0)
        .scaleEffect(dragOffset.width > 20 ? 1.0 : 0.8)
        .animation(DSAnimations.common.quickFeedback, value: dragOffset.width)
    }
    
    @ViewBuilder
    private var rightSwipeActions: some View {
        HStack(spacing: DSSpacing.sm) {
            SwipeActionButton(
                action: .split,
                icon: "scissors",
                color: DSColors.neutral.n600,
                isRevealed: abs(dragOffset.width) > swipeThreshold,
                onTrigger: { triggerSwipeAction(.split) }
            )
            
            SwipeActionButton(
                action: .delete,
                icon: "trash.fill",
                color: DSColors.error.main,
                isRevealed: abs(dragOffset.width) > swipeThreshold * 2,
                onTrigger: { triggerSwipeAction(.delete) }
            )
        }
        .padding(.trailing, DSSpacing.lg)
        .opacity(abs(dragOffset.width) > 20 ? 1.0 : 0.0)
        .scaleEffect(abs(dragOffset.width) > 20 ? 1.0 : 0.8)
        .animation(DSAnimations.common.quickFeedback, value: dragOffset.width)
    }
    
    // MARK: - Computed Properties
    
    private var categoryColor: Color {
        DSColors.category.color(for: transaction.category)
    }
    
    private var categoryIcon: String {
        switch transaction.category.lowercased() {
        case "food & dining", "food", "dining": return "fork.knife"
        case "transportation", "transport": return "car.fill"
        case "shopping": return "bag.fill"
        case "entertainment": return "tv.fill"
        case "healthcare", "health": return "cross.fill"
        case "utilities": return "bolt.fill"
        case "groceries": return "cart.fill"
        case "gas": return "fuelpump.fill"
        case "coffee": return "cup.and.saucer.fill"
        default: return "circle.fill"
        }
    }
    
    private var amountColor: Color {
        transaction.isExpense ? DSColors.error.main : DSColors.success.main
    }
    
    private var cleanMerchantName: String {
        // Clean up merchant names (remove extra info, standardize)
        var name = transaction.description
        
        // Remove common suffixes
        let suffixesToRemove = ["LLC", "INC", "CORP", "LTD", "#"]
        for suffix in suffixesToRemove {
            name = name.replacingOccurrences(of: suffix, with: "")
        }
        
        // Capitalize properly
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.count > 30 {
            name = String(name.prefix(30)) + "..."
        }
        
        return name.isEmpty ? "Unknown Merchant" : name
    }
    
    private var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(transaction.formattedDate) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: transaction.formattedDate)
        } else if calendar.isDateInYesterday(transaction.formattedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: transaction.formattedDate)
        }
    }
    
    // MARK: - Gestures
    
    private var swipeGesture: some Gesture {
        DragGesture(coordinateSpace: .local)
            .onChanged { value in
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                    let clampedWidth = min(maxSwipeDistance, max(-maxSwipeDistance, value.translation.width))
                    dragOffset = CGSize(width: clampedWidth, height: 0)
                    isDragging = true
                }
                
                // Haptic feedback at thresholds
                let absWidth = abs(value.translation.width)
                if absWidth > swipeThreshold && revealedAction == nil {
                    #if canImport(UIKit)
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    #endif
                    revealedAction = absWidth > swipeThreshold * 2 ? .delete : .categorize
                }
            }
            .onEnded { value in
                let absWidth = abs(value.translation.width)
                
                if absWidth > swipeThreshold * 2 {
                    // Strong swipe - trigger action
                    let action: SwipeAction = value.translation.width > 0 ? .flag : .delete
                    triggerSwipeAction(action)
                } else if absWidth > swipeThreshold {
                    // Medium swipe - trigger primary action
                    let action: SwipeAction = value.translation.width > 0 ? .categorize : .split
                    triggerSwipeAction(action)
                } else {
                    // Weak swipe - return to center
                    snapBack()
                }
            }
    }
    
    // MARK: - Action Handlers
    
    private func triggerSwipeAction(_ action: SwipeAction) {
        // Haptic feedback
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
        
        // Animate action trigger
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = .zero
            isDragging = false
            revealedAction = nil
        }
        
        // Execute action
        onSwipeAction(action)
    }
    
    private func snapBack() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            dragOffset = .zero
            isDragging = false
            revealedAction = nil
        }
    }
    
    private func getMerchantLogo() -> Image? {
        // In a real app, this would fetch merchant logos from a service
        // For now, return nil to use category icons
        return nil
    }
}

// MARK: - Swipe Action Button

struct SwipeActionButton: View {
    let action: SwipeAction
    let icon: String
    let color: Color
    let isRevealed: Bool
    let onTrigger: () -> Void
    
    var body: some View {
        Button(action: onTrigger) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
                    .scaleEffect(isRevealed ? 1.2 : 1.0)
                
                Image(systemName: icon)
                    .font(DSTypography.body.medium)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRevealed)
    }
}

// MARK: - Transaction Extensions

extension Transaction {
    var isRecurring: Bool {
        // In a real app, this would check for recurring patterns
        false
    }
    
    var isPending: Bool {
        // In a real app, this would check transaction status
        false
    }
}

// MARK: - Preview

#Preview("Transaction Card") {
    VStack(spacing: DSSpacing.md) {
        // Expense transaction
        TransactionCard(
            transaction: Transaction(
                date: "2024-01-15",
                description: "Starbucks Coffee #1234",
                amount: -45.67,
                category: "Food & Dining",
                confidence: 0.95,
                accountId: "account1"
            ),
            isSelected: false,
            isBulkSelectionMode: false,
            onTap: {},
            onLongPress: {},
            onSwipeAction: { _ in }
        )
        
        // Income transaction
        TransactionCard(
            transaction: Transaction(
                date: "2024-01-15",
                description: "Salary Deposit",
                amount: 2500.00,
                category: "Income",
                confidence: 1.0,
                accountId: "account1"
            ),
            isSelected: true,
            isBulkSelectionMode: true,
            onTap: {},
            onLongPress: {},
            onSwipeAction: { _ in }
        )
        
        // Transfer transaction
        TransactionCard(
            transaction: Transaction(
                date: "2024-01-14",
                description: "Transfer to Savings",
                amount: -500.00,
                category: "Transfer",
                confidence: 1.0,
                accountId: "account1"
            ),
            isSelected: false,
            isBulkSelectionMode: false,
            onTap: {},
            onLongPress: {},
            onSwipeAction: { _ in }
        )
    }
    .padding(DSSpacing.xl)
    .background(
        LinearGradient(
            colors: [DSColors.neutral.n100, DSColors.neutral.n200],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}