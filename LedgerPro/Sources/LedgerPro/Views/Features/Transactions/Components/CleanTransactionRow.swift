import SwiftUI

struct CleanTransactionRow: View {
    let transaction: Transaction
    let showAccount: Bool
    @State private var isHovered = false
    
    private var merchantIcon: String {
        // Simple icon mapping based on category
        switch transaction.category.lowercased() {
        case "food & dining", "restaurants": return "fork.knife"
        case "shopping": return "bag"
        case "transport", "transportation": return "car"
        case "utilities": return "bolt"
        case "entertainment": return "tv"
        case "healthcare": return "heart"
        case "salary", "income": return "dollarsign.circle"
        default: return "circle.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: merchantIcon)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())
                
                // Main content
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text(transaction.category.isEmpty ? "Uncategorized" : transaction.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if showAccount {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Account")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Amount
                VStack(alignment: .trailing, spacing: 2) {
                    Text(transaction.amount.formatted(.currency(code: "USD")))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(transaction.amount >= 0 ? .green : .red)
                    
                    Text(transaction.date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // AI Helper for uncategorized transactions
            if transaction.category.isEmpty || transaction.category == "Uncategorized" {
                AITransactionHelper(transaction: transaction)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .background(isHovered ? Color.gray.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// Simplified list wrapper
struct CleanTransactionList: View {
    let transactions: [Transaction]
    @State private var selectedTransaction: Transaction?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(transactions) { transaction in
                    CleanTransactionRow(
                        transaction: transaction,
                        showAccount: true
                    )
                    .onTapGesture {
                        selectedTransaction = transaction
                    }
                    
                    Divider()
                        .padding(.leading, 60)
                }
            }
        }
        .sheet(item: $selectedTransaction) { transaction in
            NavigationStack {
                VStack {
                    Text("Transaction Details")
                        .font(.title)
                    Text(transaction.description)
                        .font(.headline)
                    Text(transaction.amount.formatted(.currency(code: "USD")))
                        .font(.title2)
                    Spacer()
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done") {
                            selectedTransaction = nil
                        }
                    }
                }
            }
        }
    }
}