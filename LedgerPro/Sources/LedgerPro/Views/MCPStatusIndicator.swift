import SwiftUI

struct MCPStatusIndicator: View {
    @ObservedObject var mcpBridge: MCPBridge
    @State private var showingDetails = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if mcpBridge.isConnected {
                Text("(\(mcpBridge.servers.values.filter { $0.isConnected }.count)/\(mcpBridge.servers.count))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onTapGesture {
            showingDetails.toggle()
        }
        .popover(isPresented: $showingDetails) {
            MCPServerDetailsView(mcpBridge: mcpBridge)
                .frame(width: 300, height: 200)
        }
        .help(helpText)
    }
    
    private var statusColor: Color {
        if !mcpBridge.isConnected {
            return .red
        } else if mcpBridge.servers.values.allSatisfy({ $0.isConnected }) {
            return .green
        } else {
            return .orange
        }
    }
    
    private var statusText: String {
        if !mcpBridge.isConnected {
            return "MCP Offline"
        } else if mcpBridge.servers.values.allSatisfy({ $0.isConnected }) {
            return "MCP Ready"
        } else {
            return "MCP Partial"
        }
    }
    
    private var helpText: String {
        if !mcpBridge.isConnected {
            return "MCP servers are not connected. Click to view details."
        } else {
            let activeCount = mcpBridge.servers.values.filter { $0.isConnected }.count
            return "\(activeCount) of \(mcpBridge.servers.count) MCP servers are active. Click for details."
        }
    }
}

struct MCPServerDetailsView: View {
    @ObservedObject var mcpBridge: MCPBridge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MCP Server Status")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(Array(mcpBridge.servers.values), id: \.id) { server in
                HStack {
                    Circle()
                        .fill(server.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(server.info.name)
                            .font(.system(.body, design: .monospaced))
                        Text(server.info.description ?? "No description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if server.isConnected {
                        Text("Connected")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if !mcpBridge.isConnected {
                Button("Connect to MCP") {
                    Task {
                        await mcpBridge.connectAll()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
    }
}