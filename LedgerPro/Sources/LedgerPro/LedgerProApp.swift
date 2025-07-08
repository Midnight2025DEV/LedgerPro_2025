import SwiftUI

@main
struct LedgerProApp: App {
    @StateObject private var dataManager = FinancialDataManager()
    @StateObject private var apiService = APIService()
    @StateObject private var categoryService = CategoryService.shared
    
    init() {
        // Setup MCP servers if needed
        MCPServerLauncher.setupMCPServersIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 800)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    if let window = NSApplication.shared.windows.first {
                        window.makeKeyAndOrderFront(nil)
                        window.center()
                    }
                }
                .environmentObject(dataManager)
                .environmentObject(apiService)
                .environmentObject(categoryService)
                .onAppear {
                    dataManager.loadStoredData()
                }
        }
        .defaultSize(width: 1200, height: 800)
    }
}