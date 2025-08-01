import SwiftUI

struct TransactionStateInspector: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    let filteredCount: Int
    let searchText: String
    let selectedCategory: String
    let showUncategorizedOnly: Bool
    let sortOrder: TransactionListView.SortOrder
    
    @State private var isExpanded = false
    @State private var showDetailedDebug = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            
            if isExpanded {
                Divider()
                countsView
                Divider()
                filtersView
                Divider()
                actionsView
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "eye.circle")
                .foregroundColor(.blue)
            Text("Transaction State Inspector")
                .font(.headline)
            Spacer()
            Button(action: { isExpanded.toggle() }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            }
        }
        .onTapGesture {
            isExpanded.toggle()
        }
    }
    
    private var countsView: some View {
        Group {
            HStack {
                Label("\(dataManager.transactions.count)", systemImage: "doc.text")
                Text("Total Transactions")
                Spacer()
            }
            
            HStack {
                Label("\(filteredCount)", systemImage: "eye")
                Text("Visible Transactions")
                Spacer()
                if filteredCount != dataManager.transactions.count {
                    Text("(\(dataManager.transactions.count - filteredCount) hidden)")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
    }
    
    private var filtersView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Active Filters:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty {
                Label("Search: '\(searchText)'", systemImage: "magnifyingglass")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            if selectedCategory != "All" {
                Label("Category: \(selectedCategory)", systemImage: "folder")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            if showUncategorizedOnly {
                Label("Showing Uncategorized Only", systemImage: "questionmark.folder")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Label("Sort: \(sortOrder.description)", systemImage: "arrow.up.arrow.down")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if searchText.isEmpty && selectedCategory == "All" && !showUncategorizedOnly {
                Text("No filters active")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    private var actionsView: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Reset All Filters") {
                    NotificationCenter.default.post(name: NSNotification.Name("ResetAllFilters"), object: nil)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Detailed Debug") {
                    showDetailedDebug.toggle()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            if showDetailedDebug {
                debugDetailsView
            }
        }
    }
    
    private var debugDetailsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Debug Info:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            debugStatsView
            
            Button("Export Debug Data") {
                exportDebugData()
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(4)
    }
    
    private var debugStatsView: some View {
        Group {
            if dataManager.transactions.count > 0 {
                Text("Date range: \(uniqueDateCount) unique dates")
                    .font(.caption)
                
                Text("Categories: \(uniqueCategoryCount) unique")
                    .font(.caption)
                
                Text("Auto-categorized: \(autoCategorizedCount)")
                    .font(.caption)
            }
        }
    }
    
    private var uniqueDateCount: Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dates = Set(dataManager.transactions.map { dateFormatter.string(from: $0.formattedDate) })
        return dates.count
    }
    
    private var uniqueCategoryCount: Int {
        let categories = Set(dataManager.transactions.map { $0.category })
        return categories.count
    }
    
    private var autoCategorizedCount: Int {
        return dataManager.transactions.filter { $0.wasAutoCategorized == true }.count
    }
    
    private func exportDebugData() {
        let debugInfo = generateDebugReport()
        
        // Save to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(debugInfo, forType: .string)
        
        AppLogger.shared.info("📋 Debug data exported to clipboard", category: "Debug")
    }
    
    private func generateDebugReport() -> String {
        var report = "# LedgerPro Transaction Debug Report\n\n"
        report += "Generated: \(Date())\n\n"
        
        report += "## Transaction Counts\n"
        report += "- Total: \(dataManager.transactions.count)\n"
        report += "- Visible: \(filteredCount)\n"
        report += "- Hidden: \(dataManager.transactions.count - filteredCount)\n\n"
        
        report += "## Active Filters\n"
        report += "- Search: '\(searchText)'\n"
        report += "- Category: '\(selectedCategory)'\n"
        report += "- Uncategorized Only: \(showUncategorizedOnly)\n"
        report += "- Sort Order: \(sortOrder.description)\n\n"
        
        if dataManager.transactions.count > 0 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dates = Set(dataManager.transactions.map { dateFormatter.string(from: $0.formattedDate) })
            
            report += "## Data Analysis\n"
            report += "- Date Range: \(dates.count) unique dates\n"
            report += "- Categories: \(Set(dataManager.transactions.map { $0.category }).count) unique\n"
            report += "- Auto-categorized: \(dataManager.transactions.filter { $0.wasAutoCategorized == true }.count)\n\n"
            
            report += "## Sample Transactions (First 5)\n"
            for (index, transaction) in dataManager.transactions.prefix(5).enumerated() {
                report += "\(index + 1). \(transaction.description) | \(dateFormatter.string(from: transaction.formattedDate)) | \(transaction.category) | $\(String(format: "%.2f", transaction.amount))\n"
            }
        }
        
        return report
    }
}

// Extension for SortOrder description
extension TransactionListView.SortOrder {
    var description: String {
        switch self {
        case .dateDescending:
            return "Date (Newest First)"
        case .dateAscending:
            return "Date (Oldest First)"
        case .amountDescending:
            return "Amount (Highest First)"
        case .amountAscending:
            return "Amount (Lowest First)"
        case .description:
            return "Description (A-Z)"
        }
    }
}

// Preview for SwiftUI Canvas
struct TransactionStateInspector_Previews: PreviewProvider {
    static var previews: some View {
        TransactionStateInspector(
            filteredCount: 150,
            searchText: "amazon",
            selectedCategory: "Shopping",
            showUncategorizedOnly: false,
            sortOrder: .dateDescending
        )
        .environmentObject(FinancialDataManager())
        .frame(width: 400)
    }
}