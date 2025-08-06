import SwiftUI
import Charts

struct BudgetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let budget: Budget
    let budgetManager: BudgetManager
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    overviewSection
                    progressSection
                    spendingBreakdownSection
                    recentTransactionsSection
                }
                .padding()
            }
            
            Divider()
            
            // Actions
            actionButtons
        }
        .frame(width: 700, height: 600)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: budget.color) ?? .blue)
                            .frame(width: 20, height: 20)
                        
                        Text(budget.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 4) {
                            Image(systemName: budget.status.systemImage)
                                .font(.caption)
                            Text(budget.status.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: budget.status.color)?.opacity(0.2))
                        .foregroundColor(Color(hex: budget.status.color))
                        .cornerRadius(8)
                    }
                    
                    Text(budget.category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    
                    Button("Close") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                }
            }
            
            if let description = budget.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                InfoCard(
                    title: "Budget",
                    value: budget.amount.formatted(.currency(code: "USD")),
                    icon: "target",
                    color: .blue
                )
                
                InfoCard(
                    title: "Spent",
                    value: budget.spentAmount.formatted(.currency(code: "USD")),
                    icon: "minus.circle.fill",
                    color: .orange
                )
                
                InfoCard(
                    title: "Remaining",
                    value: budget.remainingAmount.formatted(.currency(code: "USD")),
                    icon: budget.remainingAmount >= 0 ? "plus.circle.fill" : "exclamationmark.triangle.fill",
                    color: budget.remainingAmount >= 0 ? .green : .red
                )
                
                InfoCard(
                    title: "Progress",
                    value: "\(Int(budget.percentageUsed * 100))%",
                    icon: "chart.pie.fill",
                    color: budget.isOverBudget ? .red : .green
                )
            }
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("$\(budget.spentAmount, specifier: "%.2f") of $\(budget.amount, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(budget.percentageUsed * 100, specifier: "%.1f")%")
                        .font(.headline)
                        .foregroundColor(budget.isOverBudget ? .red : .primary)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 20)
                            .cornerRadius(10)
                        
                        Rectangle()
                            .fill(Color(hex: budget.status.color) ?? .blue)
                            .frame(
                                width: geometry.size.width * min(1.0, budget.percentageUsed), 
                                height: 20
                            )
                            .cornerRadius(10)
                        
                        // Alert threshold indicator
                        Rectangle()
                            .fill(Color.yellow.opacity(0.7))
                            .frame(width: 2, height: 24)
                            .offset(x: geometry.size.width * budget.alertThreshold - 1, y: -2)
                    }
                }
                .frame(height: 20)
                
                HStack {
                    Text("Period: \(budget.startDate.formatted(.dateTime.month().day())) - \(budget.endDate.formatted(.dateTime.month().day()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Alert at \(Int(budget.alertThreshold * 100))%")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }
    
    private var spendingBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Spending Trend")
                .font(.headline)
            
            // Simple chart placeholder - would use Charts framework in real implementation
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("Spending trend chart would go here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
        }
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to filtered transaction list
                }
                .font(.caption)
            }
            
            VStack(spacing: 8) {
                // Would show actual transactions in budget period/category
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sample Transaction")
                                .font(.body)
                            Text("Today")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("-$25.00")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }
    
    private var actionButtons: some View {
        HStack {
            Button("Delete Budget", role: .destructive) {
                showingDeleteAlert = true
            }
            .foregroundColor(.red)
            
            Spacer()
            
            Button("Toggle Active") {
                budgetManager.toggleBudgetActive(budget.id)
                dismiss()
            }
            
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding()
        .alert("Delete Budget", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                budgetManager.deleteBudget(budget.id)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this budget? This action cannot be undone.")
        }
        .sheet(isPresented: $showingEditSheet) {
            EditBudgetView(budget: budget, budgetManager: budgetManager)
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct EditBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var editableBudget: Budget
    let budgetManager: BudgetManager
    
    init(budget: Budget, budgetManager: BudgetManager) {
        self._editableBudget = State(initialValue: budget)
        self.budgetManager = budgetManager
    }
    
    var body: some View {
        VStack {
            Text("Edit Budget")
                .font(.title2)
                .padding()
            
            Text("Edit functionality would go here")
                .foregroundColor(.secondary)
                .padding()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Save") {
                    budgetManager.updateBudget(editableBudget)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 400, height: 300)
    }
}

#Preview {
    BudgetDetailView(
        budget: Budget(
            name: "Food Budget",
            category: "Food & Dining",
            amount: 500,
            period: .monthly
        ),
        budgetManager: BudgetManager(dataManager: FinancialDataManager())
    )
}