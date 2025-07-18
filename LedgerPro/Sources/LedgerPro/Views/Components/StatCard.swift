import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let change: String
    let subtitle: String?
    let color: Color
    let icon: String
    
    init(title: String, value: String, change: String, subtitle: String? = nil, color: Color, icon: String) {
        self.title = title
        self.value = value
        self.change = change
        self.subtitle = subtitle
        self.color = color
        self.icon = icon
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Text(change)
                    .font(.caption)
                    .foregroundColor(changeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(changeColor.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private var changeColor: Color {
        if change.starts(with: "+") {
            return .green
        } else if change.starts(with: "-") {
            return .red
        }
        return .secondary
    }
}

#Preview {
    StatCard(
        title: "Balance",
        value: "$2,450.00",
        change: "+5.2%",
        subtitle: "vs last month",
        color: .blue,
        icon: "banknote.fill"
    )
}