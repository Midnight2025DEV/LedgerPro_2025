import SwiftUI

struct ToolsHubView: View {
    @State private var showingRuleBuilder = false
    @State private var showingMerchantLogos = false
    @State private var showingReviewQueue = false
    @State private var pendingReviewCount = 0
    @EnvironmentObject var dataManager: FinancialDataManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tools & Automation")
                        .font(.largeTitle.bold())
                    Text("Powerful features to automate your finances")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Feature Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    // Rule Builder
                    ToolCard(
                        icon: "line.horizontal.3.decrease.circle",
                        title: "Transaction Rules",
                        description: "Create smart rules to auto-categorize transactions",
                        color: .blue,
                        action: { showingRuleBuilder = true }
                    )
                    
                    // Review Queue
                    ToolCard(
                        icon: "checkmark.circle.badge.questionmark",
                        title: "Review Queue",
                        description: "Review transactions that need attention",
                        color: .orange,
                        badge: pendingReviewCount > 0 ? "\(pendingReviewCount)" : nil,
                        action: { showingReviewQueue = true }
                    )
                    
                    // Merchant Logos
                    ToolCard(
                        icon: "photo.circle",
                        title: "Merchant Logos",
                        description: "Customize merchant icons and colors",
                        color: .purple,
                        action: { showingMerchantLogos = true }
                    )
                    
                    // AI Insights
                    ToolCard(
                        icon: "sparkle",
                        title: "AI Assistant",
                        description: "Get smart suggestions for uncategorized transactions",
                        color: .pink,
                        action: { 
                            // Navigate to transactions with AI filter
                            NotificationCenter.default.post(name: NSNotification.Name("NavigateToUncategorized"), object: nil)
                        }
                    )
                    
                    // Split Transactions (Feature Card)
                    ToolCard(
                        icon: "scissors",
                        title: "Split Transactions",
                        description: "Divide transactions across multiple categories",
                        color: .green,
                        action: { 
                            // Could open a list of splittable transactions
                        }
                    )
                    
                    // Bulk Operations
                    ToolCard(
                        icon: "square.stack.3d.up",
                        title: "Bulk Operations",
                        description: "Apply changes to multiple transactions at once",
                        color: .indigo,
                        comingSoon: true,
                        action: { }
                    )
                }
                .padding(.horizontal)
                
                // Quick Stats Section
                QuickStatsSection()
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Tools")
        .sheet(isPresented: $showingRuleBuilder) {
            VisualRuleBuilder()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingMerchantLogos) {
            NavigationStack {
                MerchantManagerView()
                    .environmentObject(dataManager)
            }
        }
        .sheet(isPresented: $showingReviewQueue) {
            TransactionReviewQueue()
                .environmentObject(dataManager)
        }
        .onAppear {
            calculatePendingReviewCount()
        }
    }
    
    private func calculatePendingReviewCount() {
        let criteria = ReviewCriteria()
        pendingReviewCount = dataManager.transactions.filter { transaction in
            criteria.shouldReview(transaction)
        }.count
    }
}

struct ToolCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    var badge: String? = nil
    var comingSoon: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: comingSoon ? {} : action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                    }
                    
                    Spacer()
                    
                    if let badge {
                        Text(badge)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .clipShape(Capsule())
                    } else if comingSoon {
                        Text("Soon")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray)
                            .clipShape(Capsule())
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding()
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isHovered ? color.opacity(0.05) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isHovered ? color.opacity(0.3) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(comingSoon)
        .opacity(comingSoon ? 0.6 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering && !comingSoon
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

struct QuickStatsSection: View {
    @EnvironmentObject var dataManager: FinancialDataManager
    
    var uncategorizedCount: Int {
        dataManager.transactions.filter { $0.category.isEmpty || $0.category == "Uncategorized" }.count
    }
    
    var duplicateCount: Int {
        // Simple duplicate detection based on same merchant and amount on same day
        var seen = Set<String>()
        var duplicates = 0
        
        for transaction in dataManager.transactions {
            let key = "\(transaction.merchantName)_\(transaction.amount)_\(transaction.date)"
            if seen.contains(key) {
                duplicates += 1
            } else {
                seen.insert(key)
            }
        }
        
        return duplicates
    }
    
    var uniqueMerchants: Int {
        Set(dataManager.transactions.map { $0.merchantName }).count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Statistics")
                .font(.title3.bold())
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Uncategorized",
                    count: uncategorizedCount,
                    icon: "tag.slash",
                    color: .orange
                )
                
                StatItem(
                    title: "Duplicates",
                    count: duplicateCount,
                    icon: "doc.on.doc",
                    color: .red
                )
                
                StatItem(
                    title: "Merchants",
                    count: uniqueMerchants,
                    icon: "building.2",
                    color: .blue
                )
                
                StatItem(
                    title: "Total Transactions",
                    count: dataManager.transactions.count,
                    icon: "list.bullet",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}