import SwiftUI
import Charts

struct AccountsView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @State private var selectedAccount: BankAccount?
    
    var body: some View {
        NavigationSplitView {
            accountsList
        } detail: {
            if let account = selectedAccount {
                AccountDetailView(account: account)
            } else {
                accountsOverview
            }
        }
        .navigationTitle("Accounts")
        .onAppear {
            if selectedAccount == nil && !dataManager.bankAccounts.isEmpty {
                selectedAccount = dataManager.bankAccounts.first
            }
        }
    }
    
    private var accountsList: some View {
        List(dataManager.bankAccounts, id: \.id, selection: $selectedAccount) { account in
            AccountRowView(account: account)
                .tag(account)
        }
        .listStyle(.sidebar)
        .navigationTitle("Accounts")
    }
    
    private var accountsOverview: some View {
        VStack(spacing: 24) {
            if dataManager.bankAccounts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "building.columns")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("No Accounts Found")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Upload a financial statement to see your accounts")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Account Overview")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Account Summary Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(dataManager.bankAccounts) { account in
                            AccountSummaryCard(account: account)
                                .onTapGesture {
                                    selectedAccount = account
                                }
                        }
                    }
                    
                    // Portfolio Balance Chart
                    if dataManager.bankAccounts.count > 1 {
                        if #available(macOS 14.0, *) {
                            PortfolioChartView()
                        } else {
                            Text("Portfolio chart requires macOS 14.0+")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AccountRowView: View {
    let account: BankAccount
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    private var accountSummary: FinancialSummary {
        dataManager.getSummary(for: account.id)
    }
    
    private var transactionCount: Int {
        dataManager.getTransactions(for: account.id).count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: account.accountType.systemImage)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(account.institution)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Balance")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(accountSummary.formattedBalance)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(transactionCount) transactions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Circle()
                        .fill(account.isActive ? .green : .gray)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AccountSummaryCard: View {
    let account: BankAccount
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    private var accountSummary: FinancialSummary {
        dataManager.getSummary(for: account.id)
    }
    
    private var transactionCount: Int {
        dataManager.getTransactions(for: account.id).count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: account.accountType.systemImage)
                            .foregroundColor(.blue)
                        Text(account.accountType.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(account.name)
                        .font(.headline)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Circle()
                    .fill(account.isActive ? .green : .gray)
                    .frame(width: 12, height: 12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(accountSummary.formattedBalance)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(transactionCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Net Savings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(accountSummary.formattedSavings)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(accountSummary.netSavings >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct AccountDetailView: View {
    let account: BankAccount
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    private var accountTransactions: [Transaction] {
        dataManager.getTransactions(for: account.id)
    }
    
    private var accountSummary: FinancialSummary {
        dataManager.getSummary(for: account.id)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Account Header
                accountHeader
                
                // Quick Stats
                accountStats
                
                // Spending Trend Chart
                if !accountTransactions.isEmpty {
                    accountSpendingChart
                }
                
                // Recent Transactions
                recentTransactionsSection
            }
            .padding()
        }
        .navigationTitle(account.name)
    }
    
    private var accountHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: account.accountType.systemImage)
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(account.institution)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let lastFour = account.lastFourDigits {
                        Text("•••• \(lastFour)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospaced()
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(account.isActive ? .green : .gray)
                            .frame(width: 8, height: 8)
                        Text(account.isActive ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(account.accountType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private var accountStats: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            StatCard(
                title: "Balance",
                value: accountSummary.formattedBalance,
                change: accountSummary.balanceChange ?? "",
                color: .blue,
                icon: "banknote.fill"
            )
            
            StatCard(
                title: "Income",
                value: accountSummary.formattedIncome,
                change: accountSummary.incomeChange ?? "",
                color: .green,
                icon: "arrow.up.circle.fill"
            )
            
            StatCard(
                title: "Expenses",
                value: accountSummary.formattedExpenses,
                change: accountSummary.expensesChange ?? "",
                color: .red,
                icon: "arrow.down.circle.fill"
            )
        }
    }
    
    private var accountSpendingChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trend")
                .font(.title2)
                .fontWeight(.bold)
            
            Chart(accountChartData) { data in
                LineMark(
                    x: .value("Date", data.date),
                    y: .value("Amount", data.expenses)
                )
                .foregroundStyle(.blue)
                .symbol(.circle)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("$\(Int(doubleValue))")
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private var accountChartData: [DailySpending] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let grouped = Dictionary(grouping: accountTransactions) { $0.date }
        
        return grouped.map { date, transactions in
            let total = transactions.reduce(0) { $0 + abs($1.amount) }
            return DailySpending(
                date: dateFormatter.date(from: date) ?? Date(),
                expenses: total,
                income: 0
            )
        }.sorted { $0.date < $1.date }
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink("View All") {
                    TransactionListView { _ in }
                }
            }
            
            if accountTransactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No transactions found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(accountTransactions.prefix(5))) { transaction in
                        TransactionRowView(transaction: transaction)
                        if transaction.id != accountTransactions.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                .shadow(radius: 1)
            }
        }
    }
}

@available(macOS 14.0, *)
struct PortfolioChartView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    private var portfolioData: [PortfolioBalance] {
        dataManager.bankAccounts.map { account in
            let summary = dataManager.getSummary(for: account.id)
            return PortfolioBalance(
                account: account.name,
                balance: summary.availableBalance
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Portfolio Distribution")
                .font(.title2)
                .fontWeight(.bold)
            
            Chart(portfolioData) { data in
                SectorMark(
                    angle: .value("Balance", data.balance),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Account", data.account))
            }
            .frame(height: 250)
            .chartLegend(position: .trailing, alignment: .center)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct PortfolioBalance: Identifiable {
    let id: UUID
    let account: String
    let balance: Double
    
    init(account: String, balance: Double) {
        self.id = UUID()
        self.account = account
        self.balance = balance
    }
}

#Preview {
    NavigationView {
        AccountsView()
            .environmentObject(FinancialDataManager())
    }
}