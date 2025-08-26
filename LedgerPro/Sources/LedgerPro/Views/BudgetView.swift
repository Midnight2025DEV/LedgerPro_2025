import SwiftUI

struct BudgetView: View {
    @StateObject private var budgetManager: BudgetManager
    @EnvironmentObject private var dataManager: FinancialDataManager
    
    @State private var showingCreateBudget = false
    @State private var selectedBudget: Budget?
    @State private var showingBudgetDetail = false
    
    init(dataManager: FinancialDataManager) {
        self._budgetManager = StateObject(wrappedValue: BudgetManager(dataManager: dataManager))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            Divider()
            
            if budgetManager.budgets.isEmpty {
                emptyStateView
            } else {
                budgetListView
            }
        }
        .navigationTitle("Budgets")
        .sheet(isPresented: $showingCreateBudget) {
            CreateBudgetView()
        }
        .sheet(item: $selectedBudget) { budget in
            BudgetDetailView(budget: budget, spending: 0.0)
        }
        .onAppear {
            budgetManager.checkAndAdvancePeriods()
            budgetManager.updateAllBudgetSpending()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Budget Overview")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if !budgetManager.budgets.isEmpty {
                        Text("\(budgetManager.budgets.filter { $0.isActive }.count) active budgets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showingCreateBudget = true
                }) {
                    Label("Create Budget", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            
            if !budgetManager.budgets.isEmpty {
                budgetSummaryCards
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var budgetSummaryCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
            SummaryCard(
                title: "Total Budget",
                value: budgetManager.totalBudgetedAmount.formatted(.currency(code: "USD")),
                icon: "dollarsign.circle.fill",
                color: .blue
            )
            
            SummaryCard(
                title: "Total Spent",
                value: budgetManager.totalSpentAmount.formatted(.currency(code: "USD")),
                icon: "minus.circle.fill",
                color: .orange
            )
            
            SummaryCard(
                title: "Remaining",
                value: budgetManager.totalRemainingAmount.formatted(.currency(code: "USD")),
                icon: "plus.circle.fill",
                color: budgetManager.totalRemainingAmount >= 0 ? .green : .red
            )
            
            SummaryCard(
                title: "Over Budget",
                value: "\(budgetManager.overBudgetCount)",
                icon: "exclamationmark.triangle.fill",
                color: budgetManager.overBudgetCount > 0 ? .red : .green
            )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.pie")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Budgets Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create budgets to track your spending and stay on target")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    showingCreateBudget = true
                }) {
                    Label("Create Your First Budget", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                if !budgetManager.generateBudgetRecommendations().isEmpty {
                    Button(action: {
                        // Show recommendations
                    }) {
                        Label("See Recommendations", systemImage: "lightbulb")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var budgetListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(budgetManager.budgets.filter { $0.isActive }) { budget in
                    BudgetRowView(budget: budget) {
                        selectedBudget = budget
                        showingBudgetDetail = true
                    }
                }
                
                if !budgetManager.budgets.filter({ !$0.isActive }).isEmpty {
                    Section {
                        ForEach(budgetManager.budgets.filter { !$0.isActive }) { budget in
                            BudgetRowView(budget: budget) {
                                selectedBudget = budget
                                showingBudgetDetail = true
                            }
                        }
                    } header: {
                        HStack {
                            Text("Inactive Budgets")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                }
            }
            .padding()
        }
    }
}

struct BudgetRowView: View {
    let budget: Budget
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: budget.color) ?? .blue)
                            .frame(width: 12, height: 12)
                        
                        Text(budget.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("• \(budget.category)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: budget.status.systemImage)
                                .font(.caption)
                            Text(budget.status.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Color(hex: budget.status.color))
                        
                        Text(budget.period.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("$\(budget.spentAmount, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("of $\(budget.amount, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(budget.percentageUsed * 100, specifier: "%.0f")%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(budget.isOverBudget ? .red : .primary)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(Color(hex: budget.status.color) ?? .blue)
                                .frame(width: geometry.size.width * min(1.0, budget.percentageUsed), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
                
                HStack {
                    Text("Remaining: $\(budget.remainingAmount, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(budget.remainingAmount >= 0 ? .green : .red)
                    
                    Spacer()
                    
                    Text("\(budget.startDate.formatted(.dateTime.month().day())) - \(budget.endDate.formatted(.dateTime.month().day()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .buttonStyle(.plain)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .opacity(budget.isActive ? 1.0 : 0.6)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

