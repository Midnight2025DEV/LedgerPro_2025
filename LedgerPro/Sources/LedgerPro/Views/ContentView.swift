import SwiftUI

// Modern UI imports
struct ContentViewModernDashboard: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DSSpacing.xl) {
                // Premium hero section with glass morphism
                modernHeroSection
                
                // Enhanced stats cards
                modernStatsSection
                
                // Budget cards grid
                modernBudgetsSection
                
                // Quick insights
                modernInsightsSection
            }
            .padding(.horizontal, DSSpacing.xl)
            .padding(.vertical, DSSpacing.lg)
        }
        .background(modernBackground)
        .navigationTitle("Dashboard")
    }
    
    @ViewBuilder
    private var modernHeroSection: some View {
        GlassCard {
            VStack(spacing: DSSpacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("Total Balance")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                        
                        AnimatedNumber(value: dataManager.summary.availableBalance, format: .currency())
                            .font(DSTypography.title.title1)
                            .foregroundColor(DSColors.neutral.text)
                    }
                    
                    Spacer()
                    
                    AnimatedStatCard.balance(
                        title: "This Month",
                        amount: dataManager.summary.netSavings,
                        change: dataManager.summary.netSavings >= 0 ? "+5.2%" : "-2.1%"
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var modernStatsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.lg), count: 2), spacing: DSSpacing.lg) {
            AnimatedStatCard.balance(
                title: "Income",
                amount: dataManager.summary.totalIncome,
                change: "+12.5%",
                icon: "arrow.up.circle.fill"
            )
            
            AnimatedStatCard.balance(
                title: "Expenses",
                amount: abs(dataManager.summary.totalExpenses),
                change: "+8.3%",
                icon: "arrow.down.circle.fill"
            )
        }
    }
    
    @ViewBuilder
    private var modernBudgetsSection: some View {
        if !dataManager.activeBudgets.isEmpty {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Active Budgets")
                    .font(DSTypography.title.title3)
                    .foregroundColor(DSColors.neutral.text)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DSSpacing.lg), count: 2), spacing: DSSpacing.lg) {
                    ForEach(dataManager.activeBudgets.prefix(4)) { budget in
                        BudgetCard(budget: budget, spending: budget.calculateSpending(transactions: dataManager.transactions))
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var modernInsightsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            Text("Financial Insights")
                .font(DSTypography.title.title3)
                .foregroundColor(DSColors.neutral.text)
            
            if let firstBudget = dataManager.activeBudgets.first {
                BudgetInsights(
                    budget: firstBudget,
                    currentSpending: firstBudget.calculateSpending(transactions: dataManager.transactions),
                    insights: []
                )
            }
        }
    }
    
    @ViewBuilder
    private var modernBackground: some View {
        LinearGradient(
            colors: [
                DSColors.neutral.background,
                DSColors.primary.main.opacity(0.02),
                DSColors.neutral.backgroundSecondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct ContentViewModernTransactionList: View {
    let onTransactionSelect: (Transaction) -> Void
    let initialShowUncategorizedOnly: Bool
    let triggerUncategorizedFilter: Bool
    
    @EnvironmentObject private var dataManager: FinancialDataManager
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var showingFilters = false
    
    var filteredTransactions: [Transaction] {
        var transactions = dataManager.transactions
        
        if initialShowUncategorizedOnly {
            transactions = transactions.filter { $0.category.isEmpty || $0.category == "Uncategorized" }
        }
        
        if !searchText.isEmpty {
            transactions = transactions.filter { 
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            transactions = transactions.filter { $0.category == category }
        }
        
        return transactions.sorted { $0.formattedDate > $1.formattedDate }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern search and filter header
            modernHeaderSection
            
            // Enhanced transaction list
            ScrollView {
                LazyVStack(spacing: DSSpacing.sm) {
                    ForEach(filteredTransactions) { transaction in
                        ModernTransactionRow(transaction: transaction) {
                            onTransactionSelect(transaction)
                        }
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
                .padding(.vertical, DSSpacing.md)
            }
            .background(modernListBackground)
        }
        .navigationTitle("Transactions")
    }
    
    @ViewBuilder
    private var modernHeaderSection: some View {
        VStack(spacing: DSSpacing.md) {
            // Search bar with glass morphism
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DSColors.neutral.textSecondary)
                
                TextField("Search transactions...", text: $searchText)
                    .font(DSTypography.body.regular)
                    .foregroundColor(DSColors.neutral.text)
                
                if showingFilters {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(DSColors.primary.main)
                    }
                } else {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(DSColors.neutral.textSecondary)
                    }
                }
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.vertical, DSSpacing.md)
            .background(.ultraThinMaterial)
            .cornerRadius(DSSpacing.radius.lg)
            
            // Filter chips (if showing filters)
            if showingFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DSSpacing.sm) {
                        ContentViewFilterChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        
                        ForEach(Array(Set(dataManager.transactions.map(\.category))).sorted(), id: \.self) { category in
                            if !category.isEmpty {
                                ContentViewFilterChip(title: category, isSelected: selectedCategory == category) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DSSpacing.lg)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.vertical, DSSpacing.md)
        .background(DSColors.neutral.background)
    }
    
    @ViewBuilder
    private var modernListBackground: some View {
        LinearGradient(
            colors: [
                DSColors.neutral.background,
                DSColors.neutral.backgroundSecondary
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct ModernTransactionRow: View {
    let transaction: Transaction
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: DSSpacing.md) {
                    // Category icon with modern styling
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: categoryIcon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(categoryColor)
                        )
                    
                    // Transaction details
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text(transaction.description)
                            .font(DSTypography.body.semibold)
                            .foregroundColor(DSColors.neutral.text)
                            .lineLimit(1)
                        
                        HStack(spacing: DSSpacing.xs) {
                            Text(transaction.category.isEmpty ? "Uncategorized" : transaction.category)
                                .font(DSTypography.caption.regular)
                                .foregroundColor(DSColors.neutral.textSecondary)
                            
                            Text("•")
                                .font(DSTypography.caption.regular)
                                .foregroundColor(DSColors.neutral.textTertiary)
                            
                            Text(transaction.formattedDate.formatted(date: .abbreviated, time: .omitted))
                                .font(DSTypography.caption.regular)
                                .foregroundColor(DSColors.neutral.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    // Amount with animated number
                    AnimatedNumber(value: transaction.amount, format: .currency())
                        .font(DSTypography.body.semibold)
                        .foregroundColor(transaction.amount < 0 ? DSColors.error.main : DSColors.success.main)
                }
                .padding(DSSpacing.lg)
            }
            .buttonStyle(.plain)
            
            // AI Helper for uncategorized transactions
            if transaction.category.isEmpty || transaction.category == "Uncategorized" {
                AITransactionHelper(transaction: transaction)
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.bottom, DSSpacing.md)
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(DSSpacing.radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                .stroke(DSColors.neutral.border.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var categoryColor: Color {
        switch transaction.category.lowercased() {
        case "food", "groceries": return DSColors.success.main
        case "entertainment": return DSColors.primary.main
        case "transportation": return DSColors.info.main
        case "shopping": return DSColors.warning.main
        default: return DSColors.neutral.n600
        }
    }
    
    private var categoryIcon: String {
        switch transaction.category.lowercased() {
        case "food", "groceries": return "cart.fill"
        case "entertainment": return "tv.fill"
        case "transportation": return "car.fill"
        case "shopping": return "bag.fill"
        default: return "creditcard.fill"
        }
    }
}

struct ContentViewFilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(DSTypography.caption.regular)
                .foregroundColor(isSelected ? .white : DSColors.neutral.textSecondary)
                .padding(.horizontal, DSSpacing.md)
                .padding(.vertical, DSSpacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? DSColors.primary.main : .clear)
                        .overlay(
                            Capsule()
                                .stroke(DSColors.neutral.border.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct ContentView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @EnvironmentObject private var apiService: APIService
    @EnvironmentObject private var mcpBridge: MCPBridge
    @State private var selectedTab: DashboardTab = .overview
    @State private var previousTab: DashboardTab = .overview
    @State private var showingUploadSheet = false
    @State private var showingTransactionDetail = false
    @State private var selectedTransaction: Transaction?
    @State private var showingHealthAlert = false
    @State private var healthCheckMessage = ""
    @State private var selectedTransactionFilter: TransactionFilter = .all
    @State private var shouldNavigateToTransactions = false
    @State private var triggerUncategorizedFilter = false
    
    enum TransactionFilter: Equatable {
        case all
        case uncategorized
        case category(String)
    }
    
    enum DashboardTab: String, CaseIterable {
        case overview = "Overview"
        case transactions = "Transactions"
        case accounts = "Accounts"
        case insights = "Insights"
        case tools = "Tools"
        case settings = "Settings"
        
        var systemImage: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .transactions: return "list.bullet"
            case .accounts: return "building.columns"
            case .insights: return "brain"
            case .tools: return "wrench.and.screwdriver"
            case .settings: return "gear"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            detailView
        }
        .navigationTitle("LedgerPro")
        .toolbar {
            CleanToolbar(
                onRefresh: {
                    dataManager.loadStoredData()
                },
                onSettings: {
                    selectedTab = .settings
                }
            )
        }
        .sheet(isPresented: $showingUploadSheet) {
            NavigationStack {
                FileUploadView()
            }
        }
        .sheet(item: $selectedTransaction) { transaction in
            NavigationStack {
                TransactionDetailView(transaction: transaction)
            }
        }
        .alert("Backend Health", isPresented: $showingHealthAlert) {
            Button("OK") { }
        } message: {
            Text(healthCheckMessage)
        }
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("NavigateToUncategorized"),
                object: nil,
                queue: .main
            ) { notification in
                // Switch to transactions tab and enable uncategorized filter
                selectedTab = .transactions
                selectedTransactionFilter = .uncategorized
                
                // Trigger the filter with a slight delay to ensure view is loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    triggerUncategorizedFilter.toggle()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenTools"))) { _ in
            selectedTab = .tools
        }
        .task {
            checkHealth()
            
            // Monitor MCP connection status
            AppLogger.shared.info("Starting MCP connection monitoring...", category: "UI")
            
            // Log initial status
            AppLogger.shared.info("Initial MCP Status:", category: "UI")
            AppLogger.shared.info("Connected: \(mcpBridge.isConnected)", category: "UI")
            AppLogger.shared.info("Available Servers: \(mcpBridge.servers.count)", category: "UI")
            for server in mcpBridge.servers.values {
                AppLogger.shared.info("\(server.info.name): \(server.isConnected ? "Active" : "Inactive")", category: "UI")
            }
            
            // Log path resolution for debugging
            AppLogger.shared.debug("MCP Path Resolution Debug:", category: "UI")
            AppLogger.shared.debug("Current directory: \(FileManager.default.currentDirectoryPath)", category: "UI")
            let mcpPath = "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/mcp-servers"
            AppLogger.shared.debug("MCP servers path exists: \(FileManager.default.fileExists(atPath: mcpPath))", category: "UI")
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .overview:
            ContentViewModernDashboard()
        case .transactions:
            ContentViewModernTransactionList(
                onTransactionSelect: { transaction in
                    selectedTransaction = transaction
                    showingTransactionDetail = true
                },
                initialShowUncategorizedOnly: selectedTransactionFilter == .uncategorized,
                triggerUncategorizedFilter: triggerUncategorizedFilter
            )
            .onAppear {
                // DEBUG: Log current data state when switching to transactions tab
                AppLogger.shared.info("📱 ContentView: Transactions tab appeared")
                AppLogger.shared.info("📊 Total transactions in dataManager: \(dataManager.transactions.count)")
                AppLogger.shared.info("🏦 Total accounts in dataManager: \(dataManager.bankAccounts.count)")
                for account in dataManager.bankAccounts {
                    let accountTransactions = dataManager.transactions.filter { $0.accountId == account.id }
                    AppLogger.shared.info("   Account: \(account.institution) - \(account.name) (\(account.id)): \(accountTransactions.count) transactions")
                }
            }
        case .accounts:
            AccountsView()
        case .insights:
            InsightsView()
        case .tools:
            ToolsHubView()
        case .settings:
            SettingsView()
        }
    }
    
    private func checkHealth() {
        Task {
            do {
                let health = try await apiService.healthCheck()
                await MainActor.run {
                    healthCheckMessage = health.message
                    showingHealthAlert = true
                }
            } catch {
                await MainActor.run {
                    healthCheckMessage = "Backend unavailable: \(error.localizedDescription)"
                    showingHealthAlert = true
                }
            }
        }
    }
}

struct SidebarView: View {
    @Binding var selectedTab: ContentView.DashboardTab
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Modern sidebar navigation
            VStack(spacing: DSSpacing.sm) {
                ForEach(ContentView.DashboardTab.allCases, id: \.self) { tab in
                    ModernSidebarItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        onTap: {
                            selectedTab = tab
                            Analytics.shared.trackTabNavigation(
                                from: selectedTab.rawValue,
                                to: tab.rawValue
                            )
                        }
                    )
                }
            }
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.lg)
            
            Spacer()
            
            // Modern financial score card
            if dataManager.transactions.isEmpty {
                ModernEmptyStateView()
                    .padding(DSSpacing.lg)
            } else {
                ModernFinancialScoreCard()
                    .padding(DSSpacing.lg)
            }
        }
        .background(modernSidebarBackground)
        .navigationTitle("Dashboard")
    }
    
    @ViewBuilder
    private var modernSidebarBackground: some View {
        LinearGradient(
            colors: [
                DSColors.neutral.background,
                DSColors.neutral.backgroundSecondary
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct ModernSidebarItem: View {
    let tab: ContentView.DashboardTab
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DSSpacing.md) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : DSColors.neutral.textSecondary)
                    .frame(width: 20)
                
                Text(tab.rawValue)
                    .font(DSTypography.body.medium)
                    .foregroundColor(isSelected ? .white : DSColors.neutral.text)
                
                Spacer()
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.vertical, DSSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                    .fill(isSelected ? DSColors.primary.main : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: DSSpacing.radius.lg)
                            .stroke(DSColors.neutral.border.opacity(0.1), lineWidth: isSelected ? 0 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct ModernEmptyStateView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    var body: some View {
        GlassCard {
            VStack(spacing: DSSpacing.lg) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(DSColors.primary.main.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(DSColors.primary.main)
                }
                
                VStack(spacing: DSSpacing.sm) {
                    Text("No Financial Data")
                        .font(DSTypography.title.title3)
                        .foregroundColor(DSColors.neutral.text)
                    
                    Text("Upload a statement or try demo data to get started")
                        .font(DSTypography.body.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: DSSpacing.md) {
                    Button("Load Demo Data") {
                        dataManager.loadDemoData()
                    }
                    .font(DSTypography.body.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.vertical, DSSpacing.md)
                    .background(DSColors.primary.main)
                    .cornerRadius(DSSpacing.radius.lg)
                    
                    Button("Clear All Data") {
                        dataManager.clearAllData()
                    }
                    .font(DSTypography.body.medium)
                    .foregroundColor(DSColors.neutral.textSecondary)
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.vertical, DSSpacing.sm)
                    .background(.ultraThinMaterial)
                    .cornerRadius(DSSpacing.radius.lg)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    var body: some View {
        ModernEmptyStateView()
    }
}

struct ModernFinancialScoreCard: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @State private var hasAppeared = false
    @State private var animatedScore = 0
    
    var body: some View {
        GlassCard {
            VStack(spacing: DSSpacing.lg) {
                // Header
                HStack {
                    Text("Financial Score")
                        .font(DSTypography.title.title3)
                        .foregroundColor(DSColors.neutral.text)
                    
                    Spacer()
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DSColors.primary.main)
                }
                
                // Score display with animated ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(DSColors.neutral.n200.opacity(0.3), lineWidth: 6)
                        .frame(width: 80, height: 80)
                    
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: hasAppeared ? CGFloat(financialScore) / 100 : 0)
                        .stroke(
                            AngularGradient(
                                colors: [scoreColor, scoreColor.opacity(0.5)],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: hasAppeared)
                    
                    // Score number
                    VStack(spacing: 2) {
                        Text("\(animatedScore)")
                            .font(DSTypography.title.title2)
                            .foregroundColor(DSColors.neutral.text)
                        
                        Text(scoreLabel)
                            .font(DSTypography.caption.small)
                            .foregroundColor(scoreColor)
                    }
                }
                
                // Stats grid
                VStack(spacing: DSSpacing.sm) {
                    HStack {
                        Text("Balance")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                        
                        Spacer()
                        
                        AnimatedNumber(value: dataManager.summary.availableBalance, format: .currency())
                            .font(DSTypography.caption.regular)
                            .fontWeight(.semibold)
                            .foregroundColor(DSColors.neutral.text)
                    }
                    
                    HStack {
                        Text("Savings")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                        
                        Spacer()
                        
                        AnimatedNumber(value: dataManager.summary.netSavings, format: .currency())
                            .font(DSTypography.caption.regular)
                            .fontWeight(.semibold)
                            .foregroundColor(dataManager.summary.netSavings >= 0 ? DSColors.success.main : DSColors.error.main)
                    }
                    
                    HStack {
                        Text("Transactions")
                            .font(DSTypography.caption.regular)
                            .foregroundColor(DSColors.neutral.textSecondary)
                        
                        Spacer()
                        
                        Text("\(dataManager.transactions.count)")
                            .font(DSTypography.caption.regular)
                            .fontWeight(.semibold)
                            .foregroundColor(DSColors.neutral.textTertiary)
                    }
                }
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.md)
                .background(.ultraThinMaterial)
                .cornerRadius(DSSpacing.radius.md)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
                hasAppeared = true
            }
            
            // Animate score counter
            withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
                animatedScore = financialScore
            }
        }
    }
    
    private var financialScore: Int {
        let balance = dataManager.summary.availableBalance
        let savings = dataManager.summary.netSavings
        
        var score = 50 // Base score
        
        if balance > 1000 { score += 20 }
        if savings > 0 { score += 20 }
        if dataManager.transactions.count > 10 { score += 10 }
        
        return min(100, max(0, score))
    }
    
    private var scoreColor: Color {
        switch financialScore {
        case 80...100: return DSColors.success.main
        case 60...79: return DSColors.warning.main
        case 40...59: return DSColors.info.main
        default: return DSColors.error.main
        }
    }
    
    private var scoreLabel: String {
        switch financialScore {
        case 80...100: return "Excellent"
        case 60...79: return "Good"
        case 40...59: return "Fair"
        default: return "Needs Work"
        }
    }
}

struct FinancialScoreCard: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    var body: some View {
        ModernFinancialScoreCard()
    }
}

#Preview {
    ContentView()
        .environmentObject(FinancialDataManager())
        .environmentObject(APIService())
}