import SwiftUI
import Combine

@main
struct LedgerProApp: App {
    @StateObject private var dataManager = FinancialDataManager()
    @StateObject private var apiService = APIService()
    @StateObject private var categoryService = CategoryService.shared
    @StateObject private var mcpBridge: MCPBridge
    @StateObject private var mcpLauncher: MCPServerLauncher
    
    init() {
        // Create a single MCPBridge instance and share it
        let bridge = MCPBridge()
        _mcpBridge = StateObject(wrappedValue: bridge)
        _mcpLauncher = StateObject(wrappedValue: MCPServerLauncher(mcpBridge: bridge))
        
        // Setup MCP servers if needed
        MCPServerLauncher.setupMCPServersIfNeeded()
        
        // Handle UI testing mode
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            // Disable animations for UI tests on macOS
            NSAnimationContext.current.duration = 0
        }
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
                    
                    // Load stored data or test data
                    if ProcessInfo.processInfo.arguments.contains("--uitesting") {
                        dataManager.loadTestData()
                    } else {
                        dataManager.loadStoredData()
                    }
                    
                    // Start MCP servers
                    Task {
                        try await mcpLauncher.launchCoreServers()
                    }
                }
                .onDisappear {
                    // Cleanup MCP servers when app closes
                    mcpLauncher.stopAllServers()
                }
                .environmentObject(dataManager)
                .environmentObject(apiService)
                .environmentObject(categoryService)
                .environmentObject(mcpBridge)
                .environmentObject(mcpLauncher)
        }
        .defaultSize(width: 1200, height: 800)
    }
}