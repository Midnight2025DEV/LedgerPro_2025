import SwiftUI

// MARK: - Transaction Header View
struct TransactionHeaderView: View {
    let showCheckbox: Bool
    
    init(showCheckbox: Bool = false) {
        self.showCheckbox = showCheckbox
    }
    
    var body: some View {
        HStack(spacing: 24) {
            // Checkbox column header
            if showCheckbox {
                Text("")
                    .frame(width: 24)
            }
            
            Text("Date")
                .frame(width: 100, alignment: .leading)
            
            Text("Merchant")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Category")
                .frame(width: 180, alignment: .leading)
            
            Text("Payment Method")
                .frame(width: 150, alignment: .leading)
            
            Text("Amount")
                .frame(width: 140, alignment: .trailing)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
        .textCase(.uppercase)
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Date Separator View
struct DateSeparatorView: View {
    let date: String
    let transactionCount: Int
    let dailyTotal: Double
    
    var body: some View {
        HStack {
            HStack(spacing: 16) {
                Text(formattedDate)
                    .fontWeight(.semibold)
                
                Text("\(transactionCount) transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formattedTotal)
                .fontWeight(.semibold)
                .foregroundColor(dailyTotal >= 0 ? .green : .primary)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(Color(NSColor.unemphasizedSelectedContentBackgroundColor))
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: date) else { return date }
        
        if Calendar.current.isDateInToday(date) {
            return "Today - " + DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday - " + DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        } else {
            return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        }
    }
    
    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let prefix = dailyTotal >= 0 ? "+" : ""
        return prefix + (formatter.string(from: NSNumber(value: dailyTotal)) ?? "$0.00")
    }
}