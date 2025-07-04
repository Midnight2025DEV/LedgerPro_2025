import SwiftUI

struct TopMerchantsView: View {
    @ObservedObject var dashboardService: DashboardDataService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Merchants")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(dashboardService.topMerchants) { merchant in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(merchant.merchantName)
                                .font(.system(size: 13, weight: .medium))
                            Text("\(merchant.transactionCount) transactions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(merchant.formattedAmount)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("\(merchant.daysSinceLastTransaction) days ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: geometry.size.width * merchantPercentage(merchant), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
            
            if dashboardService.topMerchants.isEmpty {
                Text("No merchant data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private func merchantPercentage(_ merchant: DashboardDataService.MerchantStat) -> CGFloat {
        guard let topMerchant = dashboardService.topMerchants.first,
              topMerchant.totalAmount > 0 else { return 0 }
        
        let percentage = Double(truncating: (merchant.totalAmount / topMerchant.totalAmount) as NSDecimalNumber)
        return CGFloat(percentage)
    }
}