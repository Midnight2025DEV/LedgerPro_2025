import SwiftUI

// MARK: - Auto-Categorization Visual Components

extension View {
    // Add auto-categorized styling to transaction rows
    func autoCategorizedStyle(_ transaction: Transaction) -> some View {
        let isAuto = transaction.wasAutoCategorized == true
        return self
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isAuto ? Color.blue.opacity(0.02) : Color.clear)
                    .animation(.easeInOut(duration: 0.3), value: isAuto)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isAuto ? Color.blue.opacity(0.1) : Color.clear,
                        lineWidth: 1
                    )
                    .animation(.easeInOut(duration: 0.3), value: isAuto)
            )
    }
}

// MARK: - Auto-Category Indicator

struct AutoCategoryIndicator: View {
    let transaction: Transaction
    
    var body: some View {
        if transaction.wasAutoCategorized == true {
            HStack(spacing: 4) {
                // Auto badge
                HStack(spacing: 3) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    
                    Text("AUTO")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Confidence indicator
                ConfidenceIndicator(confidence: transaction.confidence ?? 0.0)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Confidence Indicator

struct ConfidenceIndicator: View {
    let confidence: Double
    
    var confidenceLevel: (text: String, color: Color) {
        switch confidence {
        case 0.9...:
            return ("High", .green)
        case 0.7..<0.9:
            return ("Medium", .orange)
        default:
            return ("Low", .red)
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < Int(confidence * 3) ? confidenceLevel.color : Color.gray.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
        .help("Confidence: \\(confidenceLevel.text) (\\(Int(confidence * 100))%)")
    }
}

// MARK: - Auto-Categorization Stats Banner

struct AutoCategorizationStatsBanner: View {
    let autoCategorizedCount: Int
    let totalCount: Int
    @State private var showDetails = false
    @State private var animateIn = false
    
    var percentage: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(autoCategorizedCount) / Double(totalCount)) * 100)
    }
    
    var improvementFromLastMonth: Int {
        // TODO: Calculate actual improvement
        return 15 // Placeholder
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main banner
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(animateIn ? 0 : -30))
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateIn)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\\(percentage)% Auto-categorized")
                            .font(.headline)
                        
                        if improvementFromLastMonth > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text("+\\(improvementFromLastMonth)% from last month")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Stats
                HStack(spacing: 16) {
                    VStack(alignment: .trailing) {
                        Text("\\(autoCategorizedCount)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Text("Automated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .trailing) {
                        Text("\\(totalCount - autoCategorizedCount)")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Manual")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: { withAnimation { showDetails.toggle() } }) {
                    Image(systemName: "chevron.down.circle")
                        .rotationEffect(.degrees(showDetails ? 180 : 0))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Expandable details
            if showDetails {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(
                            icon: "building.2",
                            title: "Top Auto-categorized Merchants",
                            value: "Uber, Starbucks, Amazon"
                        )
                        
                        DetailRow(
                            icon: "brain",
                            title: "Learning Rate",
                            value: "3 new patterns this week"
                        )
                        
                        DetailRow(
                            icon: "clock.arrow.circlepath",
                            title: "Time Saved",
                            value: "~12 minutes this month"
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateIn = true
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}