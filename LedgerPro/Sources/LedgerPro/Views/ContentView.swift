import SwiftUI

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
    @State private var showingCategoryTest = false
    @State private var showingRulesWindow = false
    @State private var showingLearningWindow = false
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
        case settings = "Settings"
        
        var systemImage: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .transactions: return "list.bullet"
            case .accounts: return "building.columns"
            case .insights: return "brain"
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
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showingRulesWindow = true }) {
                    Image(systemName: "gearshape.2")
                        .foregroundColor(.purple)
                }
                .help("Manage Rules")
                
                Button(action: { showingLearningWindow = true }) {
                    Image(systemName: "brain")
                        .foregroundColor(.blue)
                }
                .help("Learning Analytics")
                
                Button(action: { showingCategoryTest = true }) {
                    Image(systemName: "folder.badge.gearshape")
                        .foregroundColor(.blue)
                }
                .help("Test Category System")
                
                Button(action: checkHealth) {
                    Image(systemName: apiService.isHealthy ? "heart.fill" : "heart")
                        .foregroundColor(apiService.isHealthy ? .green : .red)
                }
                .help("Check Backend Health")
                
                // MCP Status Indicator
                MCPStatusIndicator(mcpBridge: mcpBridge)
                
                Button(action: { 
                    AppLogger.shared.debug("Upload button clicked in ContentView")
                    showingUploadSheet = true 
                }) {
                    Image(systemName: "plus")
                }
                .help("Upload Statement")
            }
        }
        .sheet(isPresented: $showingUploadSheet) {
            NavigationStack {
                FileUploadView()
            }
        }
        .sheet(isPresented: $showingRulesWindow) {
            RulesManagementView()
        }
        .sheet(isPresented: $showingLearningWindow) {
            LearningAnalyticsView()
        }
        .sheet(isPresented: $showingCategoryTest) {
            NavigationStack {
                CategoryTestView()
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
            OverviewView()
        case .transactions:
            TransactionListView(
                onTransactionSelect: { transaction in
                    selectedTransaction = transaction
                    showingTransactionDetail = true
                },
                initialShowUncategorizedOnly: selectedTransactionFilter == .uncategorized,
                triggerUncategorizedFilter: triggerUncategorizedFilter
            )
        case .accounts:
            AccountsView()
        case .insights:
            InsightsView()
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
        List(ContentView.DashboardTab.allCases, id: \.self, selection: $selectedTab) { tab in
            Label(tab.rawValue, systemImage: tab.systemImage)
                .tag(tab)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Track tab navigation
            Analytics.shared.trackTabNavigation(
                from: oldValue.rawValue,
                to: newValue.rawValue
            )
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Dashboard")
        
        if dataManager.transactions.isEmpty {
            EmptyStateView()
                .padding()
        } else {
            FinancialScoreCard()
                .padding()
        }
    }
}

struct EmptyStateView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Financial Data")
                .font(.headline)
            
            Text("Upload a statement or try demo data")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("Load Demo Data") {
                    dataManager.loadDemoData()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Clear All Data") {
                    dataManager.clearAllData()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct FinancialScoreCard: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Financial Score")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Circle()
                    .fill(scoreColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("\(financialScore)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(scoreLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(dataManager.transactions.count) transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(dataManager.summary.formattedBalance)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Savings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(dataManager.summary.formattedSavings)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(dataManager.summary.netSavings >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
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
        case 80...100: return .green
        case 60...79: return .yellow
        case 40...59: return .orange
        default: return .red
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

#Preview {
    ContentView()
        .environmentObject(FinancialDataManager())
        .environmentObject(APIService())
}