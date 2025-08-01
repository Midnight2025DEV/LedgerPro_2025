import SwiftUI

struct SplitTransactionView: View {
    let transaction: Transaction
    @State private var splits: [SplitUIModel] = []
    @State private var splitMethod: SplitMethod = .percentage
    @State private var autoSplitEnabled = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: FinancialDataManager
    
    enum SplitMethod: String, CaseIterable {
        case percentage = "Percentage"
        case fixedAmount = "Fixed Amount"
        case equal = "Equal Split"
    }
    
    private var isValidSplit: Bool {
        guard !splits.isEmpty else { return false }
        
        switch splitMethod {
        case .percentage:
            let totalPercentage = splits.reduce(0) { $0 + $1.percentage }
            return abs(totalPercentage - 100) < 0.01
        case .fixedAmount:
            let totalAmount = splits.reduce(0) { $0 + $1.amount }
            return abs(totalAmount - abs(transaction.amount)) < 0.01
        case .equal:
            return splits.count > 1
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Split Transaction")
                    .font(.title2.bold())
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Original Transaction
            VStack(alignment: .leading, spacing: 8) {
                Text("Original Transaction")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text(transaction.merchantName)
                            .font(.title3.bold())
                        Text(transaction.displayDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(formatCurrency(transaction.amount))
                        .font(.title3.bold())
                        .foregroundColor(transaction.amount < 0 ? .red : .green)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Split Controls
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Split Method")
                        .font(.headline)
                    
                    Spacer()
                    
                    Picker("Method", selection: $splitMethod) {
                        ForEach(SplitMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                    .onChange(of: splitMethod) { _ in
                        updateSplitsForMethod()
                    }
                }
                
                Toggle("Create rule for future transactions from \(transaction.merchantName)", isOn: $autoSplitEnabled)
                    .font(.subheadline)
            }
            .padding(.horizontal)
            
            // Split Builder
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(splits.indices, id: \.self) { index in
                        SplitRow(
                            split: $splits[index],
                            method: splitMethod,
                            totalAmount: transaction.amount,
                            onDelete: splits.count > 2 ? { splits.remove(at: index) } : nil
                        )
                    }
                    
                    Button(action: addSplit) {
                        Label("Add Split", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 300)
            
            // Validation
            if !splits.isEmpty {
                SplitValidationView(
                    splits: splits,
                    totalAmount: transaction.amount,
                    method: splitMethod,
                    isValid: isValidSplit
                )
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Apply Split") {
                    applySplit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidSplit)
            }
            .padding()
        }
        .frame(width: 600, height: 700)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            initializeDefaultSplits()
        }
    }
    
    private func initializeDefaultSplits() {
        splits = [
            SplitUIModel(category: transaction.category, percentage: 50, amount: abs(transaction.amount) / 2),
            SplitUIModel(category: "", percentage: 50, amount: abs(transaction.amount) / 2)
        ]
    }
    
    private func updateSplitsForMethod() {
        switch splitMethod {
        case .equal:
            let equalAmount = abs(transaction.amount) / Double(splits.count)
            let equalPercentage = 100.0 / Double(splits.count)
            for index in splits.indices {
                splits[index].amount = equalAmount
                splits[index].percentage = equalPercentage
            }
        case .percentage:
            for index in splits.indices {
                splits[index].amount = abs(transaction.amount) * splits[index].percentage / 100
            }
        case .fixedAmount:
            for index in splits.indices {
                splits[index].percentage = splits[index].amount / abs(transaction.amount) * 100
            }
        }
    }
    
    private func addSplit() {
        let newSplit = SplitUIModel(
            category: "",
            percentage: 0,
            amount: 0
        )
        splits.append(newSplit)
        
        if splitMethod == .equal {
            updateSplitsForMethod()
        }
    }
    
    private func applySplit() {
        // Create new transactions from splits
        for (index, split) in splits.enumerated() {
            let splitAmount = transaction.amount < 0 ? -split.amount : split.amount
            
            // Create raw data for the split transaction
            var rawData = transaction.rawData ?? [:]
            rawData["notes"] = "Split \(index + 1)/\(splits.count) from original transaction"
            rawData["original_transaction_id"] = transaction.id
            
            let newTransaction = Transaction(
                date: transaction.date,
                description: transaction.description,
                amount: splitAmount,
                category: split.category,
                confidence: transaction.confidence,
                jobId: transaction.jobId,
                accountId: transaction.accountId,
                rawData: rawData,
                wasAutoCategorized: true,
                categorizationMethod: "split"
            )
            
            dataManager.addTransaction(newTransaction)
        }
        
        // Note: markTransactionAsSplit method doesn't exist in FinancialDataManager
        // We'll mark the transaction category or add metadata to indicate it's been split
        
        // Create rule if enabled
        if autoSplitEnabled {
            createSplitRule()
        }
        
        dismiss()
    }
    
    private func createSplitRule() {
        let conditions = [
            RuleCondition(type: .merchant, value: transaction.merchantName, comparison: .equals)
        ]
        
        let actions = [
            RuleAction(type: .split, value: "\(splits.count)")
        ]
        
        let rule = TransactionRule(
            id: UUID(),
            name: "Auto-split \(transaction.merchantName)",
            conditions: conditions,
            actions: actions,
            isEnabled: true
        )
        
        dataManager.addRule(rule)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct SplitUIModel: Identifiable {
    let id = UUID()
    var category: String
    var percentage: Double
    var amount: Double
    var description: String = ""
}

struct SplitRow: View {
    @Binding var split: SplitUIModel
    let method: SplitTransactionView.SplitMethod
    let totalAmount: Double
    let onDelete: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Category picker
            Menu {
                ForEach(["Food & Dining", "Shopping", "Transportation", "Entertainment", "Bills", "Other"], id: \.self) { category in
                    Button(category) {
                        split.category = category
                    }
                }
            } label: {
                HStack {
                    Image(systemName: categoryIcon(for: split.category))
                        .foregroundColor(.accentColor)
                    Text(split.category.isEmpty ? "Select Category" : split.category)
                        .foregroundColor(split.category.isEmpty ? .secondary : .primary)
                }
                .frame(width: 150, alignment: .leading)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .menuStyle(.borderlessButton)
            
            // Value input
            switch method {
            case .percentage:
                HStack {
                    TextField("0", value: $split.percentage, format: .number.precision(.fractionLength(1)))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onChange(of: split.percentage) { newValue in
                            split.amount = abs(totalAmount) * newValue / 100
                        }
                    Text("%")
                        .foregroundColor(.secondary)
                }
                
            case .fixedAmount:
                HStack {
                    Text("$")
                        .foregroundColor(.secondary)
                    TextField("0.00", value: $split.amount, format: .number.precision(.fractionLength(2)))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onChange(of: split.amount) { newValue in
                            split.percentage = newValue / abs(totalAmount) * 100
                        }
                }
                
            case .equal:
                Text(formatCurrency(split.amount))
                    .foregroundColor(.secondary)
                    .frame(width: 100)
            }
            
            // Description
            TextField("Description (optional)", text: $split.description)
                .textFieldStyle(.roundedBorder)
            
            // Delete button
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Food & Dining": return "fork.knife"
        case "Shopping": return "cart"
        case "Transportation": return "car"
        case "Entertainment": return "tv"
        case "Bills": return "doc.text"
        default: return "tag"
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct SplitValidationView: View {
    let splits: [SplitUIModel]
    let totalAmount: Double
    let method: SplitTransactionView.SplitMethod
    let isValid: Bool
    
    private var validationMessage: String {
        switch method {
        case .percentage:
            let totalPercentage = splits.reduce(0) { $0 + $1.percentage }
            if abs(totalPercentage - 100) < 0.01 {
                return "✓ Total equals 100%"
            } else {
                return "⚠️ Total: \(String(format: "%.1f", totalPercentage))% (must equal 100%)"
            }
            
        case .fixedAmount:
            let totalSplit = splits.reduce(0) { $0 + $1.amount }
            let difference = abs(totalAmount) - totalSplit
            if abs(difference) < 0.01 {
                return "✓ Total matches original amount"
            } else {
                return "⚠️ Difference: \(formatCurrency(difference))"
            }
            
        case .equal:
            return "✓ Amount split equally"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isValid ? .green : .orange)
            
            Text(validationMessage)
                .font(.subheadline)
                .foregroundColor(isValid ? .secondary : .orange)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Original: \(formatCurrency(totalAmount))")
                    .font(.caption)
                Text("Split Total: \(formatCurrency(splits.reduce(0) { $0 + $1.amount }))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(isValid ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
    }
}