import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var sortOrder: SortOrder = .dateDescending
    @State private var showingFilters = false
    
    let onTransactionSelect: (Transaction) -> Void
    
    enum SortOrder: String, CaseIterable {
        case dateDescending = "Date (Newest)"
        case dateAscending = "Date (Oldest)"
        case amountDescending = "Amount (Highest)"
        case amountAscending = "Amount (Lowest)"
        case description = "Description"
    }
    
    private var categories: [String] {
        let allCategories = Set(dataManager.transactions.map { $0.category })
        return ["All"] + allCategories.sorted()
    }
    
    private var filteredTransactions: [Transaction] {
        var filtered = dataManager.transactions
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { transaction in
                transaction.description.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Sort
        switch sortOrder {
        case .dateDescending:
            filtered = filtered.sorted { $0.formattedDate > $1.formattedDate }
        case .dateAscending:
            filtered = filtered.sorted { $0.formattedDate < $1.formattedDate }
        case .amountDescending:
            filtered = filtered.sorted { $0.amount > $1.amount }
        case .amountAscending:
            filtered = filtered.sorted { $0.amount < $1.amount }
        case .description:
            filtered = filtered.sorted { $0.description < $1.description }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search and filters
            VStack(spacing: 12) {
                HStack {
                    TextField("Search transactions...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                    }
                    .help("Filters")
                }
                
                if showingFilters {
                    HStack {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                        
                        Picker("Sort", selection: $sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                        
                        Spacer()
                        
                        Button("Clear Filters") {
                            searchText = ""
                            selectedCategory = "All"
                            sortOrder = .dateDescending
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Transaction List
            if filteredTransactions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No transactions found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if !searchText.isEmpty || selectedCategory != "All" {
                        Button("Clear Filters") {
                            searchText = ""
                            selectedCategory = "All"
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredTransactions) { transaction in
                        TransactionRowView(transaction: transaction)
                            .onTapGesture {
                                onTransactionSelect(transaction)
                            }
                            .listRowInsets(EdgeInsets())
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Transactions (\(filteredTransactions.count))")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { dataManager.removeDuplicates() }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .help("Remove Duplicates")
            }
        }
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundColor(categoryColor)
                .frame(width: 24, height: 24)
            
            // Transaction Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(transaction.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.2))
                        .foregroundColor(categoryColor)
                        .cornerRadius(4)
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let confidence = transaction.confidence {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text("\(Int(confidence * 100))%")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.displayAmount)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.isExpense ? .red : .green)
                
                Text(transaction.isExpense ? "Expense" : "Income")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private var categoryIcon: String {
        switch transaction.category {
        case "Groceries": return "cart.fill"
        case "Food & Dining": return "fork.knife"
        case "Transportation": return "car.fill"
        case "Shopping": return "bag.fill"
        case "Entertainment": return "tv.fill"
        case "Bills & Utilities": return "bolt.fill"
        case "Healthcare": return "cross.fill"
        case "Travel": return "airplane"
        case "Income", "Deposits": return "plus.circle.fill"
        default: return "circle.fill"
        }
    }
    
    private var categoryColor: Color {
        switch transaction.category {
        case "Groceries": return .green
        case "Food & Dining": return .orange
        case "Transportation": return .blue
        case "Shopping": return .purple
        case "Entertainment": return .pink
        case "Bills & Utilities": return .red
        case "Healthcare": return .mint
        case "Travel": return .teal
        case "Income", "Deposits": return .green
        default: return .gray
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: transaction.formattedDate)
    }
}

struct TransactionDetailView: View {
    let transaction: Transaction
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(transaction.description)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(transaction.formattedAmount)
                        .font(.title)
                        .foregroundColor(transaction.isExpense ? .red : .green)
                }
                
                // Details Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 2), spacing: 16) {
                    DetailField(label: "Date", value: formattedDate)
                    DetailField(label: "Category", value: transaction.category)
                    DetailField(label: "Amount", value: transaction.formattedAmount)
                    DetailField(label: "Type", value: transaction.isExpense ? "Expense" : "Income")
                    
                    if let confidence = transaction.confidence {
                        DetailField(label: "Confidence", value: "\(Int(confidence * 100))%")
                    }
                    
                    if let jobId = transaction.jobId {
                        DetailField(label: "Job ID", value: jobId)
                    }
                }
                
                // Raw Data
                if let rawData = transaction.rawData, !rawData.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Raw Data")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(rawData.keys.sorted()), id: \.self) { key in
                                HStack {
                                    Text(key)
                                        .fontWeight(.medium)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(rawData[key] ?? "")
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                                .padding(.vertical, 4)
                                Divider()
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Transaction Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: transaction.formattedDate)
    }
}

struct DetailField: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}

#Preview {
    NavigationView {
        TransactionListView { _ in }
            .environmentObject(FinancialDataManager())
    }
}