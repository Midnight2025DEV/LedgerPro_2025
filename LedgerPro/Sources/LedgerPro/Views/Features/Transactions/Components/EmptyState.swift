import SwiftUI

/// Transaction Empty State
///
/// Contextual empty states with helpful illustrations, messages,
/// and action buttons to guide users.
struct EmptyState: View {
    var context: EmptyStateContext = .noTransactions
    var onAction: (() -> Void)?
    
    @State private var hasAppeared = false
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    
    enum EmptyStateContext {
        case noTransactions
        case noSearchResults(query: String)
        case noFilterResults
        case loadingFailed
        case firstTimeUser
        
        var illustration: String {
            switch self {
            case .noTransactions, .firstTimeUser: return "doc.text.magnifyingglass"
            case .noSearchResults: return "magnifyingglass"
            case .noFilterResults: return "line.3.horizontal.decrease.circle"
            case .loadingFailed: return "exclamationmark.triangle"
            }
        }
        
        var title: String {
            switch self {
            case .noTransactions: return "No transactions yet"
            case .noSearchResults: return "No results found"
            case .noFilterResults: return "No matching transactions"
            case .loadingFailed: return "Couldn't load transactions"
            case .firstTimeUser: return "Welcome to LedgerPro!"
            }
        }
        
        var message: String {
            switch self {
            case .noTransactions:
                return "Your transactions will appear here once you upload your first bank statement or add manual entries."
            case .noSearchResults(let query):
                return "We couldn't find any transactions matching '\(query)'. Try adjusting your search terms."
            case .noFilterResults:
                return "Your current filters don't match any transactions. Try adjusting or clearing your filters."
            case .loadingFailed:
                return "Something went wrong while loading your transactions. Please try again."
            case .firstTimeUser:
                return "Start by uploading a bank statement or adding your first transaction to see your financial data come to life."
            }
        }
        
        var actionTitle: String? {
            switch self {
            case .noTransactions, .firstTimeUser: return "Upload Statement"
            case .noSearchResults: return "Clear Search"
            case .noFilterResults: return "Clear Filters"
            case .loadingFailed: return "Try Again"
            }
        }
        
        var secondaryActionTitle: String? {
            switch self {
            case .noTransactions, .firstTimeUser: return "Add Manually"
            case .noSearchResults: return "Browse All"
            case .noFilterResults: return "Browse All"
            case .loadingFailed: return "Contact Support"
            }
        }
        
        var illustrationColor: Color {
            switch self {
            case .noTransactions, .firstTimeUser: return DSColors.primary.main
            case .noSearchResults: return DSColors.warning.main
            case .noFilterResults: return DSColors.neutral.n400
            case .loadingFailed: return DSColors.error.main
            }
        }
    }
    
    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()
            
            // Illustration
            illustrationSection
            
            // Content
            contentSection
            
            // Actions
            if let actionTitle = context.actionTitle {
                actionsSection(primaryTitle: actionTitle)
            }
            
            Spacer()
        }
        .padding(.horizontal, DSSpacing.xl)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                hasAppeared = true
            }
            startAnimations()
        }
    }
    
    // MARK: - Illustration Section
    
    @ViewBuilder
    private var illustrationSection: some View {
        ZStack {
            // Background gradient circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            context.illustrationColor.opacity(0.1),
                            context.illustrationColor.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(pulseScale)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: pulseScale
                )
            
            // Glass morphism container
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(context.illustrationColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(
                    color: context.illustrationColor.opacity(0.1),
                    radius: 20,
                    x: 0,
                    y: 8
                )
            
            // Main illustration icon
            Image(systemName: context.illustration)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(context.illustrationColor)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // Floating decorative elements
            floatingElements
        }
        .scaleEffect(hasAppeared ? 1.0 : 0.8)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: hasAppeared)
    }
    
    @ViewBuilder
    private var floatingElements: some View {
        ForEach(0..<3, id: \.self) { index in
            Circle()
                .fill(context.illustrationColor.opacity(0.3))
                .frame(width: 8, height: 8)
                .offset(
                    x: cos(Double(index) * 2 * .pi / 3) * 70,
                    y: sin(Double(index) * 2 * .pi / 3) * 70
                )
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .opacity(isAnimating ? 0.8 : 0.4)
                .animation(
                    .easeInOut(duration: 1.0 + Double(index) * 0.2)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.3),
                    value: isAnimating
                )
        }
    }
    
    // MARK: - Content Section
    
    @ViewBuilder
    private var contentSection: some View {
        VStack(spacing: DSSpacing.md) {
            // Title
            Text(context.title)
                .font(DSTypography.title.title1)
                .foregroundColor(DSColors.neutral.text)
                .multilineTextAlignment(.center)
                .opacity(hasAppeared ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.6).delay(0.3), value: hasAppeared)
            
            // Message
            Text(context.message)
                .font(DSTypography.body.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .opacity(hasAppeared ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.6).delay(0.4), value: hasAppeared)
            
            // Context-specific help
            if case .noSearchResults(let query) = context {
                searchSuggestions(for: query)
            }
        }
        .padding(.horizontal, DSSpacing.lg)
    }
    
    @ViewBuilder
    private func searchSuggestions(for query: String) -> some View {
        VStack(spacing: DSSpacing.sm) {
            Text("Search suggestions:")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textTertiary)
                .padding(.top, DSSpacing.md)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DSSpacing.sm) {
                SuggestionChip(title: "Food", onTap: { applySuggestion("Food") })
                SuggestionChip(title: "Shopping", onTap: { applySuggestion("Shopping") })
                SuggestionChip(title: "Transportation", onTap: { applySuggestion("Transportation") })
                SuggestionChip(title: "Entertainment", onTap: { applySuggestion("Entertainment") })
            }
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.6).delay(0.6), value: hasAppeared)
    }
    
    // MARK: - Actions Section
    
    @ViewBuilder
    private func actionsSection(primaryTitle: String) -> some View {
        VStack(spacing: DSSpacing.md) {
            // Primary action button
            Button(action: { onAction?() }) {
                HStack(spacing: DSSpacing.sm) {
                    Image(systemName: primaryActionIcon)
                        .font(DSTypography.body.medium)
                    
                    Text(primaryTitle)
                        .font(DSTypography.body.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, DSSpacing.xl)
                .padding(.vertical, DSSpacing.md)
                .background(
                    LinearGradient(
                        colors: [
                            context.illustrationColor,
                            context.illustrationColor.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(DSSpacing.radius.xl)
                .shadow(
                    color: context.illustrationColor.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .buttonStyle(.plain)
            .scaleEffect(hasAppeared ? 1.0 : 0.9)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: hasAppeared)
            
            // Secondary action button
            if let secondaryTitle = context.secondaryActionTitle {
                Button(action: { secondaryAction() }) {
                    Text(secondaryTitle)
                        .font(DSTypography.body.medium)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .padding(.horizontal, DSSpacing.lg)
                        .padding(.vertical, DSSpacing.sm)
                }
                .buttonStyle(.plain)
                .opacity(hasAppeared ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.4).delay(0.7), value: hasAppeared)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var primaryActionIcon: String {
        switch context {
        case .noTransactions, .firstTimeUser: return "doc.badge.plus"
        case .noSearchResults: return "xmark.circle"
        case .noFilterResults: return "line.3.horizontal.decrease"
        case .loadingFailed: return "arrow.clockwise"
        }
    }
    
    // MARK: - Actions
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.0).delay(0.8)) {
            isAnimating = true
        }
        
        withAnimation(.easeInOut(duration: 2.0).delay(1.0)) {
            pulseScale = 1.05
        }
    }
    
    private func applySuggestion(_ suggestion: String) {
        // Apply search suggestion
        print("Apply suggestion: \(suggestion)")
    }
    
    private func secondaryAction() {
        // Handle secondary action based on context
        switch context {
        case .noTransactions, .firstTimeUser:
            print("Add manual transaction")
        case .noSearchResults, .noFilterResults:
            print("Browse all transactions")
        case .loadingFailed:
            print("Contact support")
        }
    }
}

// MARK: - Suggestion Chip

struct SuggestionChip: View {
    let title: String
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.primary.main)
                .padding(.horizontal, DSSpacing.md)
                .padding(.vertical, DSSpacing.xs)
                .background(
                    Capsule()
                        .fill(DSColors.primary.main.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(DSColors.primary.main.opacity(0.3), lineWidth: 0.5)
                        )
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
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
}

// MARK: - Contextual Empty States

extension EmptyState {
    /// Empty state for no transactions
    static func noTransactions(onUpload: @escaping () -> Void) -> EmptyState {
        EmptyState(context: .noTransactions, onAction: onUpload)
    }
    
    /// Empty state for search results
    static func noSearchResults(query: String, onClear: @escaping () -> Void) -> EmptyState {
        EmptyState(context: .noSearchResults(query: query), onAction: onClear)
    }
    
    /// Empty state for filter results
    static func noFilterResults(onClear: @escaping () -> Void) -> EmptyState {
        EmptyState(context: .noFilterResults, onAction: onClear)
    }
    
    /// Empty state for loading failures
    static func loadingFailed(onRetry: @escaping () -> Void) -> EmptyState {
        EmptyState(context: .loadingFailed, onAction: onRetry)
    }
    
    /// Empty state for first-time users
    static func firstTimeUser(onGetStarted: @escaping () -> Void) -> EmptyState {
        EmptyState(context: .firstTimeUser, onAction: onGetStarted)
    }
}

// MARK: - Interactive Empty State

struct InteractiveEmptyState: View {
    let context: EmptyState.EmptyStateContext
    let onPrimaryAction: () -> Void
    let onSecondaryAction: (() -> Void)?
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        EmptyState(context: context) {
            onPrimaryAction()
        }
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = CGSize(
                            width: value.translation.width * 0.1,
                            height: value.translation.height * 0.1
                        )
                        isDragging = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        dragOffset = .zero
                        isDragging = false
                    }
                }
        )
        .scaleEffect(isDragging ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
    }
}

// MARK: - Preview

#Preview("Empty States") {
    TabView {
        // No transactions
        EmptyState.noTransactions(onUpload: {})
            .tabItem { Label("No Transactions", systemImage: "doc") }
        
        // No search results
        EmptyState.noSearchResults(query: "Starbucks", onClear: {})
            .tabItem { Label("No Results", systemImage: "magnifyingglass") }
        
        // No filter results
        EmptyState.noFilterResults(onClear: {})
            .tabItem { Label("No Filters", systemImage: "line.3.horizontal.decrease") }
        
        // Loading failed
        EmptyState.loadingFailed(onRetry: {})
            .tabItem { Label("Error", systemImage: "exclamationmark.triangle") }
        
        // First time user
        EmptyState.firstTimeUser(onGetStarted: {})
            .tabItem { Label("Welcome", systemImage: "hand.wave") }
    }
    .background(
        LinearGradient(
            colors: [DSColors.neutral.background, DSColors.neutral.backgroundSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}