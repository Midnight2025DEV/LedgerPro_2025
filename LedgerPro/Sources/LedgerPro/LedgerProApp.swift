import SwiftUI

@main
struct LedgerProApp: App {
    @StateObject private var dataManager = FinancialDataManager()
    @StateObject private var apiService = APIService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(apiService)
                .onAppear {
                    dataManager.loadStoredData()
                }
        }
        .defaultSize(width: 1200, height: 800)
    }
}