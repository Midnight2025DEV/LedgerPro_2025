import SwiftUI

struct VisualRuleBuilder: View {
    @State private var ruleName = ""
    @State private var selectedConditions: [RuleCondition] = []
    @State private var selectedActions: [RuleAction] = []
    @State private var showingPreview = false
    @State private var affectedTransactions: [Transaction] = []
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: FinancialDataManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Create New Rule")
                        .font(.title2.bold())
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                TextField("Rule Name", text: $ruleName)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // IF Section
                    ConditionBuilderSection(conditions: $selectedConditions)
                    
                    // THEN Section
                    ActionBuilderSection(actions: $selectedActions)
                    
                    // Preview Section
                    if !selectedConditions.isEmpty && !selectedActions.isEmpty {
                        PreviewSection(
                            conditions: selectedConditions,
                            actions: selectedActions,
                            affectedCount: affectedTransactions.count
                        )
                    }
                }
                .padding()
            }
            
            // Bottom Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if showingPreview {
                    Button("Test Rule") {
                        testRule()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Save Rule") {
                    saveRule()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedConditions.isEmpty || selectedActions.isEmpty || ruleName.isEmpty)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
        }
        .frame(width: 800, height: 600)
    }
    
    private func testRule() {
        // Test rule on sample transactions
        affectedTransactions = dataManager.transactions.filter { transaction in
            matchesAllConditions(transaction, conditions: selectedConditions)
        }
        showingPreview = true
    }
    
    private func saveRule() {
        let rule = TransactionRule(
            id: UUID(),
            name: ruleName,
            conditions: selectedConditions,
            actions: selectedActions,
            isEnabled: true
        )
        dataManager.addRule(rule)
        dismiss()
    }
    
    private func matchesAllConditions(_ transaction: Transaction, conditions: [RuleCondition]) -> Bool {
        conditions.allSatisfy { condition in
            condition.matches(transaction)
        }
    }
}

struct ConditionBuilderSection: View {
    @Binding var conditions: [RuleCondition]
    @State private var showingAddMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("IF transaction matches", systemImage: "line.horizontal.3.decrease.circle")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Menu {
                    Button("Merchant name") { addCondition(.merchant) }
                    Button("Amount") { addCondition(.amount) }
                    Button("Category") { addCondition(.category) }
                    Button("Account") { addCondition(.account) }
                    Button("Date range") { addCondition(.dateRange) }
                } label: {
                    Label("Add Condition", systemImage: "plus.circle.fill")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
            }
            
            ForEach(conditions) { condition in
                ConditionRow(condition: condition, onDelete: {
                    conditions.removeAll { $0.id == condition.id }
                })
            }
            
            if conditions.isEmpty {
                Text("Add conditions to match transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func addCondition(_ type: RuleConditionType) {
        conditions.append(RuleCondition(type: type))
    }
}

struct ActionBuilderSection: View {
    @Binding var actions: [RuleAction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("THEN apply these actions", systemImage: "bolt.circle")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Spacer()
                
                Menu {
                    Button("Set category") { addAction(.setCategory) }
                    Button("Add tag") { addAction(.addTag) }
                    Button("Mark as reviewed") { addAction(.markReviewed) }
                    Button("Split transaction") { addAction(.split) }
                } label: {
                    Label("Add Action", systemImage: "plus.circle.fill")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
            }
            
            ForEach(actions) { action in
                ActionRow(action: action, onDelete: {
                    actions.removeAll { $0.id == action.id }
                })
            }
            
            if actions.isEmpty {
                Text("Add actions to apply to matching transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func addAction(_ type: RuleActionType) {
        actions.append(RuleAction(type: type))
    }
}

struct PreviewSection: View {
    let conditions: [RuleCondition]
    let actions: [RuleAction]
    let affectedCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Preview", systemImage: "eye")
                .font(.headline)
            
            Text("This rule will affect \(affectedCount) transaction\(affectedCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if affectedCount > 0 {
                Text("Click 'Test Rule' to see which transactions match")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Models

enum RuleConditionType: Codable {
    case merchant
    case amount
    case category
    case account
    case dateRange
}

struct RuleCondition: Identifiable, Codable {
    let id = UUID()
    let type: RuleConditionType
    var value: String = ""
    var comparison: ComparisonType = .contains
    
    enum ComparisonType: String, CaseIterable, Codable {
        case contains = "contains"
        case equals = "equals"
        case startsWith = "starts with"
        case endsWith = "ends with"
        case greaterThan = "greater than"
        case lessThan = "less than"
    }
    
    func matches(_ transaction: Transaction) -> Bool {
        switch type {
        case .merchant:
            return matchesString(transaction.merchantName, value: value, comparison: comparison)
        case .amount:
            return matchesAmount(transaction.amount, value: value, comparison: comparison)
        case .category:
            return transaction.category == value
        case .account:
            return transaction.accountName == value
        case .dateRange:
            // Implement date range matching
            return true
        }
    }
    
    private func matchesString(_ string: String, value: String, comparison: ComparisonType) -> Bool {
        let lowercasedString = string.lowercased()
        let lowercasedValue = value.lowercased()
        
        switch comparison {
        case .contains:
            return lowercasedString.contains(lowercasedValue)
        case .equals:
            return lowercasedString == lowercasedValue
        case .startsWith:
            return lowercasedString.hasPrefix(lowercasedValue)
        case .endsWith:
            return lowercasedString.hasSuffix(lowercasedValue)
        default:
            return false
        }
    }
    
    private func matchesAmount(_ amount: Double, value: String, comparison: ComparisonType) -> Bool {
        guard let valueAmount = Double(value) else { return false }
        
        switch comparison {
        case .equals:
            return abs(amount - valueAmount) < 0.01
        case .greaterThan:
            return amount > valueAmount
        case .lessThan:
            return amount < valueAmount
        default:
            return false
        }
    }
}

enum RuleActionType: Codable {
    case setCategory
    case addTag
    case markReviewed
    case split
}

struct RuleAction: Identifiable, Codable {
    let id = UUID()
    let type: RuleActionType
    var value: String = ""
}

struct TransactionRule: Identifiable, Codable {
    let id: UUID
    let name: String
    let conditions: [RuleCondition]
    let actions: [RuleAction]
    var isEnabled: Bool
}

// MARK: - Components

struct ConditionRow: View {
    let condition: RuleCondition
    let onDelete: () -> Void
    @State private var localValue = ""
    @State private var localComparison: RuleCondition.ComparisonType = .contains
    
    var body: some View {
        HStack {
            Text(conditionTypeLabel)
                .font(.subheadline)
                .frame(width: 100, alignment: .leading)
            
            Picker("", selection: $localComparison) {
                ForEach(availableComparisons, id: \.self) { comparison in
                    Text(comparison.rawValue).tag(comparison)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            
            TextField(placeholderText, text: $localValue)
                .textFieldStyle(.roundedBorder)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var conditionTypeLabel: String {
        switch condition.type {
        case .merchant: return "Merchant"
        case .amount: return "Amount"
        case .category: return "Category"
        case .account: return "Account"
        case .dateRange: return "Date"
        }
    }
    
    private var availableComparisons: [RuleCondition.ComparisonType] {
        switch condition.type {
        case .merchant:
            return [.contains, .equals, .startsWith, .endsWith]
        case .amount:
            return [.equals, .greaterThan, .lessThan]
        case .category, .account:
            return [.equals]
        case .dateRange:
            return [.equals]
        }
    }
    
    private var placeholderText: String {
        switch condition.type {
        case .merchant: return "e.g., Starbucks"
        case .amount: return "e.g., 50.00"
        case .category: return "Select category"
        case .account: return "Select account"
        case .dateRange: return "Select date range"
        }
    }
}

struct ActionRow: View {
    let action: RuleAction
    let onDelete: () -> Void
    @State private var localValue = ""
    
    var body: some View {
        HStack {
            Text(actionTypeLabel)
                .font(.subheadline)
                .frame(width: 120, alignment: .leading)
            
            TextField(placeholderText, text: $localValue)
                .textFieldStyle(.roundedBorder)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var actionTypeLabel: String {
        switch action.type {
        case .setCategory: return "Set category to"
        case .addTag: return "Add tag"
        case .markReviewed: return "Mark as"
        case .split: return "Split into"
        }
    }
    
    private var placeholderText: String {
        switch action.type {
        case .setCategory: return "Select category"
        case .addTag: return "Tag name"
        case .markReviewed: return "Reviewed"
        case .split: return "Number of parts"
        }
    }
}