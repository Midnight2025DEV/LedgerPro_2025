import SwiftUI

/// Modern Transaction List
///
/// A premium transaction experience that rivals the best financial apps with
/// sophisticated animations, gestures, and interactions.
struct ModernTransactionList: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @State private var searchText = ""
    @State private var selectedTransactions = Set<String>()
    @State private var isRefreshing = false
    @State private var isBulkSelectionMode = false
    @State private var groupingMode: GroupingMode = .day
    @State private var showFilters = false
    @State private var activeFilters = TransactionFilters()
    @State private var lastShakeTime: Date?
    @State private var scrollOffset: CGFloat = 0
    @State private var headerOffsets: [String: CGFloat] = [:]
    
    // Performance optimizations
    @State private var visibleTransactions: [Transaction] = []
    @State private var groupedTransactions: [TransactionGroup] = []
    @State private var isLoading = false
    
    enum GroupingMode: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        
        var icon: String {
            switch self {
            case .day: return "calendar"
            case .week: return "calendar.circle"
            case .month: return "calendar.badge.plus"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
            
            // Main content
            VStack(spacing: 0) {
                // Search and filters
                searchSection
                
                // Transaction list
                transactionListContent
            }
            
            // Bulk actions overlay
            if isBulkSelectionMode {
                bulkActionsOverlay
            }
            
            // Loading overlay
            if isLoading {
                loadingOverlay
            }
        }
        .navigationTitle("Transactions")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            toolbarContent
        }
        .onAppear {
            loadTransactions()
        }
        .onShake {
            handleShakeGesture()
        }
        .refreshable {
            await refreshTransactions()
        }
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                DSColors.neutral.background,
                DSColors.neutral.backgroundSecondary,
                DSColors.primary.p50.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Search Section
    
    @ViewBuilder
    private var searchSection: some View {
        VStack(spacing: DSSpacing.md) {
            TransactionSearch(
                searchText: $searchText,
                showFilters: $showFilters,
                activeFilters: $activeFilters
            )
            
            // Filter chips
            if activeFilters.hasActiveFilters {
                filterChipsSection
            }
            
            // Grouping mode selector
            groupingModeSelector
        }
        .padding(.horizontal, DSSpacing.xl)
        .padding(.top, DSSpacing.lg)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(DSColors.neutral.border.opacity(0.3))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    @ViewBuilder
    private var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DSSpacing.sm) {
                ForEach(activeFilters.activeChips, id: \.id) { chip in
                    FilterChip(
                        title: chip.title,
                        color: chip.color,
                        onRemove: {
                            activeFilters.removeFilter(chip.type)
                            updateTransactions()
                        }
                    )
                }
                
                Button("Clear All") {
                    withAnimation(DSAnimations.common.quickFeedback) {
                        activeFilters.clear()
                        updateTransactions()
                    }
                }
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.error.main)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xs)
                .background(
                    Capsule()
                        .fill(DSColors.error.main.opacity(0.1))
                )
            }
            .padding(.horizontal, DSSpacing.xl)
        }
    }
    
    @ViewBuilder
    private var groupingModeSelector: some View {
        HStack {
            Text("Group by")
                .font(DSTypography.caption.regular)
                .foregroundColor(DSColors.neutral.textSecondary)
            
            Spacer()
            
            HStack(spacing: DSSpacing.xs) {
                ForEach(GroupingMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(DSAnimations.common.quickFeedback) {
                            groupingMode = mode
                            regroupTransactions()
                        }
                    }) {
                        HStack(spacing: DSSpacing.xs) {
                            Image(systemName: mode.icon)
                                .font(DSTypography.caption.small)
                            Text(mode.rawValue)
                                .font(DSTypography.caption.regular)
                        }
                        .foregroundColor(groupingMode == mode ? .white : DSColors.neutral.textSecondary)
                        .padding(.horizontal, DSSpacing.sm)
                        .padding(.vertical, DSSpacing.xs)
                        .background(
                            Capsule()
                                .fill(groupingMode == mode ? DSColors.primary.main : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, DSSpacing.xl)
    }
    
    // MARK: - Transaction List Content
    
    @ViewBuilder
    private var transactionListContent: some View {
        if groupedTransactions.isEmpty && !isLoading {
            emptyStateView
        } else {
            transactionScrollView
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        EmptyState()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var transactionScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                transactionListStack
            }
            .coordinateSpace(name: "transactionList")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                scrollOffset = offset
            }
            .simultaneousGesture(magnificationGesture)
        }
    }
    
    @ViewBuilder
    private var transactionListStack: some View {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            ForEach(groupedTransactions, id: \.id) { group in
                transactionSection(for: group)
            }
            
            // Bottom padding for floating elements
            Color.clear.frame(height: 100)
        }
    }
    
    @ViewBuilder
    private func transactionSection(for group: TransactionGroup) -> some View {
        Section {
            ForEach(group.transactions, id: \.id) { transaction in
                transactionCard(for: transaction)
            }
        } header: {
            TransactionGroupHeader(
                group: group,
                groupingMode: groupingMode,
                scrollOffset: scrollOffset
            )
        }
    }
    
    @ViewBuilder
    private func transactionCard(for transaction: Transaction) -> some View {
        TransactionCard(
            transaction: transaction,
            isSelected: selectedTransactions.contains(transaction.id),
            isBulkSelectionMode: isBulkSelectionMode,
            onTap: { handleTransactionTap(transaction) },
            onLongPress: { handleTransactionLongPress(transaction) },
            onSwipeAction: { action in
                handleSwipeAction(action, for: transaction)
            }
        )
        .id(transaction.id)
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onEnded { value in
                handlePinchGesture(value)
            }
    }
    
    // MARK: - Bulk Actions Overlay
    
    @ViewBuilder
    private var bulkActionsOverlay: some View {
        BulkActions(
            selectedCount: selectedTransactions.count,
            onCategorize: { handleBulkCategorize() },
            onDelete: { handleBulkDelete() },
            onExport: { handleBulkExport() },
            onCancel: { exitBulkSelectionMode() }
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Loading Overlay
    
    @ViewBuilder
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: DSSpacing.lg) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
                
                Text("Loading transactions...")
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.neutral.text)
            }
            .padding(DSSpacing.xl)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.lg)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            HStack(spacing: DSSpacing.sm) {
                // Selection mode toggle
                Button(action: toggleBulkSelectionMode) {
                    Image(systemName: isBulkSelectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                        .foregroundColor(isBulkSelectionMode ? DSColors.primary.main : DSColors.neutral.textSecondary)
                }
                
                // Filter button
                Button(action: { showFilters.toggle() }) {
                    Image(systemName: activeFilters.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundColor(activeFilters.hasActiveFilters ? DSColors.primary.main : DSColors.neutral.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Data Loading & Updates
    
    private func loadTransactions() {
        isLoading = true
        
        Task {
            // Simulate loading delay for smooth UX
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            await MainActor.run {
                updateTransactions()
                isLoading = false
            }
        }
    }
    
    private func updateTransactions() {
        let allTransactions = dataManager.transactions
        
        // Apply search filter
        var filtered = allTransactions
        if !searchText.isEmpty {
            filtered = filtered.filter { transaction in
                transaction.description.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText) ||
                transaction.displayAmount.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply active filters
        filtered = activeFilters.apply(to: filtered)
        
        visibleTransactions = filtered
        regroupTransactions()
    }
    
    private func regroupTransactions() {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: visibleTransactions) { transaction in
            switch groupingMode {
            case .day:
                return calendar.startOfDay(for: transaction.formattedDate)
            case .week:
                return calendar.dateInterval(of: .weekOfYear, for: transaction.formattedDate)?.start ?? transaction.formattedDate
            case .month:
                return calendar.dateInterval(of: .month, for: transaction.formattedDate)?.start ?? transaction.formattedDate
            }
        }
        
        groupedTransactions = grouped.map { date, transactions in
            TransactionGroup(
                date: date,
                transactions: transactions.sorted { $0.formattedDate > $1.formattedDate },
                groupingMode: groupingMode
            )
        }.sorted { $0.date > $1.date }
    }
    
    @MainActor
    private func refreshTransactions() async {
        isRefreshing = true
        
        // Haptic feedback
        #if canImport(UIKit)
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
        #endif
        
        // Simulate network refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        dataManager.loadStoredData()
        updateTransactions()
        
        isRefreshing = false
    }
    
    // MARK: - Gesture Handlers
    
    private func handleTransactionTap(_ transaction: Transaction) {
        if isBulkSelectionMode {
            toggleTransactionSelection(transaction)
        } else {
            // Navigate to transaction detail
            print("Navigate to transaction detail: \(transaction.id)")
        }
    }
    
    private func handleTransactionLongPress(_ transaction: Transaction) {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
        
        if !isBulkSelectionMode {
            enterBulkSelectionMode()
        }
        toggleTransactionSelection(transaction)
    }
    
    private func handleSwipeAction(_ action: SwipeAction, for transaction: Transaction) {
        switch action {
        case .categorize:
            showCategoryPicker(for: transaction)
        case .delete:
            deleteTransaction(transaction)
        case .split:
            showSplitTransaction(transaction)
        case .flag:
            flagTransaction(transaction)
        }
    }
    
    private func handlePinchGesture(_ value: CGFloat) {
        if value > 1.2 {
            // Pinch out - expand grouping
            let modes = GroupingMode.allCases
            if let currentIndex = modes.firstIndex(of: groupingMode),
               currentIndex > 0 {
                withAnimation(DSAnimations.common.quickFeedback) {
                    groupingMode = modes[currentIndex - 1]
                    regroupTransactions()
                }
            }
        } else if value < 0.8 {
            // Pinch in - compress grouping
            let modes = GroupingMode.allCases
            if let currentIndex = modes.firstIndex(of: groupingMode),
               currentIndex < modes.count - 1 {
                withAnimation(DSAnimations.common.quickFeedback) {
                    groupingMode = modes[currentIndex + 1]
                    regroupTransactions()
                }
            }
        }
    }
    
    private func handleShakeGesture() {
        let now = Date()
        if let lastShake = lastShakeTime,
           now.timeIntervalSince(lastShake) < 2.0 {
            return // Prevent rapid shake actions
        }
        lastShakeTime = now
        
        // Undo last action (if any)
        undoLastAction()
    }
    
    // MARK: - Selection Management
    
    private func toggleBulkSelectionMode() {
        withAnimation(DSAnimations.common.standardTransition) {
            if isBulkSelectionMode {
                exitBulkSelectionMode()
            } else {
                enterBulkSelectionMode()
            }
        }
    }
    
    private func enterBulkSelectionMode() {
        isBulkSelectionMode = true
        selectedTransactions.removeAll()
    }
    
    private func exitBulkSelectionMode() {
        isBulkSelectionMode = false
        selectedTransactions.removeAll()
    }
    
    private func toggleTransactionSelection(_ transaction: Transaction) {
        let id = transaction.id
        if selectedTransactions.contains(id) {
            selectedTransactions.remove(id)
        } else {
            selectedTransactions.insert(id)
        }
        
        // Auto-exit if no items selected
        if selectedTransactions.isEmpty && isBulkSelectionMode {
            exitBulkSelectionMode()
        }
    }
    
    // MARK: - Action Handlers
    
    private func showCategoryPicker(for transaction: Transaction) {
        // Show category picker modal
        print("Show category picker for: \(transaction.id)")
    }
    
    private func deleteTransaction(_ transaction: Transaction) {
        // Show delete confirmation
        print("Delete transaction: \(transaction.id)")
    }
    
    private func showSplitTransaction(_ transaction: Transaction) {
        // Show split transaction modal
        print("Split transaction: \(transaction.id)")
    }
    
    private func flagTransaction(_ transaction: Transaction) {
        // Flag transaction for review
        print("Flag transaction: \(transaction.id)")
    }
    
    private func handleBulkCategorize() {
        print("Bulk categorize \(selectedTransactions.count) transactions")
        exitBulkSelectionMode()
    }
    
    private func handleBulkDelete() {
        print("Bulk delete \(selectedTransactions.count) transactions")
        exitBulkSelectionMode()
    }
    
    private func handleBulkExport() {
        print("Bulk export \(selectedTransactions.count) transactions")
        exitBulkSelectionMode()
    }
    
    private func undoLastAction() {
        // Implement undo functionality
        print("Undo last action")
        
        #if canImport(UIKit)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        #endif
    }
}

// MARK: - Supporting Types

struct TransactionGroup: Identifiable {
    let id = UUID()
    let date: Date
    let transactions: [Transaction]
    let groupingMode: ModernTransactionList.GroupingMode
    
    var displayTitle: String {
        let calendar = Calendar.current
        let now = Date()
        
        switch groupingMode {
        case .day:
            if calendar.isDateInToday(date) {
                return "Today"
            } else if calendar.isDateInYesterday(date) {
                return "Yesterday"
            } else if calendar.dateComponents([.day], from: date, to: now).day! < 7 {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                return formatter.string(from: date)
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: date)
            }
        case .week:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let endDate = calendar.date(byAdding: .day, value: 6, to: date) ?? date
            return "\(formatter.string(from: date)) - \(formatter.string(from: endDate))"
        case .month:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
    }
    
    var totalAmount: Double {
        transactions.reduce(0) { $0 + $1.amount }
    }
}

// TransactionFilters moved to Models/TransactionFilters.swift

enum SwipeAction {
    case categorize, delete, split, flag
}

// MARK: - Extensions

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        #if canImport(UIKit)
        self.onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
            action()
        }
        #else
        // Shake gesture not supported on macOS
        self
        #endif
    }
}

#if canImport(UIKit)
import UIKit

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}
#endif

// MARK: - Preview

#Preview("Modern Transaction List") {
    NavigationView {
        ModernTransactionList()
            .environmentObject(FinancialDataManager())
    }
}