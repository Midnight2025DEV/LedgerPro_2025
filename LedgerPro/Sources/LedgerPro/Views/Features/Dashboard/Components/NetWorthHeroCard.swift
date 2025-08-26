import SwiftUI
import Charts

struct NetWorthHeroCard: View {
    @EnvironmentObject var dataManager: FinancialDataManager
    @State private var animatedValue: Double = 0
    @State private var showBreakdown = false
    
    private var totalAssets: Double {
        dataManager.bankAccounts.filter { $0.accountType != .credit && $0.accountType != .loan }
            .reduce(0) { (total, account) in
                let accountTransactions = dataManager.transactions.filter { $0.accountId == account.id }
                let balance = accountTransactions.reduce(0) { $0 + $1.amount }
                return total + max(0, balance) // Only count positive balances as assets
            }
    }
    
    private var totalLiabilities: Double {
        dataManager.bankAccounts.filter { $0.accountType == .credit || $0.accountType == .loan }
            .reduce(0) { (total, account) in
                let accountTransactions = dataManager.transactions.filter { $0.accountId == account.id }
                let balance = accountTransactions.reduce(0) { $0 + $1.amount }
                return total + abs(min(0, balance)) // Only count negative balances as liabilities
            }
    }
    
    private var netWorth: Double {
        totalAssets - totalLiabilities
    }
    
    private var monthlyChange: Double {
        // Calculate change from transactions in last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let recentTransactions = dataManager.transactions.filter { transaction in
            guard let transactionDate = dateFormatter.date(from: transaction.date) else { return false }
            return transactionDate >= thirtyDaysAgo
        }
        
        let income = recentTransactions.filter { $0.amount > 0 }
            .reduce(0) { $0 + $1.amount }
        let expenses = recentTransactions.filter { $0.amount < 0 }
            .reduce(0) { $0 + abs($1.amount) }
        
        return income - expenses
    }
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Net Worth")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text(animatedValue.formatted(.currency(code: "USD")))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(netWorth >= 0 ? .income : .expense)
                            .contentTransition(.numericText())
                        
                        HStack(spacing: 8) {
                            Image(systemName: monthlyChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                                .foregroundColor(monthlyChange >= 0 ? .income : .expense)
                            
                            Text("\(abs(monthlyChange).formatted(.currency(code: "USD"))) this month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Visual representation
                    ZStack {
                        Circle()
                            .fill(Color.income.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: totalAssets / (totalAssets + totalLiabilities))
                            .stroke(Color.income, lineWidth: 8)
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Text("\(Int((totalAssets / (totalAssets + totalLiabilities)) * 100))%")
                                .font(.title3.bold())
                            Text("Assets")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                // Breakdown
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Assets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(totalAssets.formatted(.currency(code: "USD")))
                            .font(.title3.bold())
                            .foregroundColor(.income)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Liabilities")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(totalLiabilities.formatted(.currency(code: "USD")))
                            .font(.title3.bold())
                            .foregroundColor(.expense)
                    }
                    
                    Spacer()
                    
                    Button(action: { 
                        // TODO: Navigate to detailed breakdown view
                    }) {
                        Label("Details", systemImage: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .frame(height: 220)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animatedValue = netWorth
            }
        }
    }
}