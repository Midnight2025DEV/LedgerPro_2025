import Foundation

/// Quick validation to ensure MCP system is ready
print("🔍 Validating MCP Infrastructure...")
print("==================================\n")

// Check 1: MCPBridge can be instantiated
print("1. MCPBridge initialization: ", terminator: "")
let bridge = MCPBridge()
print("✓ Success")

// Check 2: Server configurations are available
print("2. Server configurations: ", terminator: "")
let configs = bridge.serverConfigurations
print("✓ Found \(configs.count) servers")
for (key, config) in configs {
    print("   - \(config.name) (port \(config.port))")
}

// Check 3: MCPServerLauncher can be created
print("\n3. MCPServerLauncher: ", terminator: "")
let launcher = MCPServerLauncher(mcpBridge: bridge)
print("✓ Ready")

// Check 4: Python environment
print("\n4. Python MCP Servers:")
let fm = FileManager.default
let mcpServersPath = fm.currentDirectoryPath + "/mcp-servers"

for server in ["pdf-processor", "financial-analyzer", "openai-service"] {
    let serverPath = mcpServersPath + "/\(server)"
    let venvPath = serverPath + "/venv"
    let scriptPath = serverPath + "/\(server.replacingOccurrences(of: "-", with: "_"))_server.py"
    
    print("   \(server):")
    print("     Directory: \(fm.fileExists(atPath: serverPath) ? "✓" : "✗")")
    print("     Venv: \(fm.fileExists(atPath: venvPath) ? "✓" : "✗")")
    print("     Script: \(fm.fileExists(atPath: scriptPath) ? "✓" : "✗")")
}

print("\n✅ MCP Infrastructure validation complete!")
print("\nNext step: Run the app and test PDF import flow")
