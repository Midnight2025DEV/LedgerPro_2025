import SwiftUI
import Combine

@main
struct LedgerProApp: App {
    @StateObject private var dataManager = FinancialDataManager()
    @StateObject private var apiService = APIService()
    @StateObject private var categoryService = CategoryService.shared
    @StateObject private var mcpBridge: MCPBridge
    @StateObject private var mcpLauncher: MCPServerLauncher
    @StateObject private var backendManager = BackendManager()
    
    init() {
        // Create a single MCPBridge instance and share it
        let bridge = MCPBridge()
        _mcpBridge = StateObject(wrappedValue: bridge)
        _mcpLauncher = StateObject(wrappedValue: MCPServerLauncher(mcpBridge: bridge))
        
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
                    
                    // Load stored data
                    dataManager.loadStoredData()
                    
                    // Start backend automatically
                    Task {
                        await backendManager.start()
                    }
                    
                    // Start MCP servers
                    Task {
                        try await mcpLauncher.launchCoreServers()
                    }
                }
                .onDisappear {
                    // Cleanup servers when app closes
                    mcpLauncher.stopAllServers()
                    backendManager.stop()
                }
                .environmentObject(dataManager)
                .environmentObject(apiService)
                .environmentObject(categoryService)
                .environmentObject(mcpBridge)
                .environmentObject(mcpLauncher)
                .environmentObject(backendManager)
        }
        .defaultSize(width: 1200, height: 800)
    }
}