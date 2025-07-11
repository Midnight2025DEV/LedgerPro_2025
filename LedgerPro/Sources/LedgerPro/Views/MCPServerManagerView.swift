import SwiftUI

/// MCP Server Manager View - Control panel for managing MCP servers
struct MCPServerManagerView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var mcpLauncher: MCPServerLauncher
    @State private var showingAdvancedOptions = false
    @State private var selectedServerType: ServerType?
    @State private var autoLaunchEnabled = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar with close button
            HStack {
                Text("MCP Server Manager")
                    .font(.headline)
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close (Esc)")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Header
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "server.rack")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MCP Server Manager")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Manage AI-powered backend services")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Auto-launch toggle
                    Toggle("Auto-launch", isOn: $autoLaunchEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
                
                // Status banner
                statusBanner
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Server list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(ServerType.allCases.filter { $0 != .custom }, id: \.rawValue) { serverType in
                        ServerCard(
                            serverType: serverType,
                            mcpLauncher: mcpLauncher,
                            isSelected: selectedServerType == serverType
                        )
                        .onTapGesture {
                            selectedServerType = selectedServerType == serverType ? nil : serverType
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer controls
            HStack {
                Button("Launch Core Servers") {
                    Task {
                        try? await mcpLauncher.launchCoreServers()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(mcpLauncher.isLaunching || mcpLauncher.launchedServers.count >= 2)
                
                Button("Stop All") {
                    mcpLauncher.stopAllServers()
                }
                .buttonStyle(.bordered)
                .disabled(mcpLauncher.launchedServers.isEmpty)
                
                Spacer()
                
                Button("Advanced") {
                    showingAdvancedOptions.toggle()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 400, height: 500)
        .onAppear {
            if autoLaunchEnabled && mcpLauncher.launchedServers.isEmpty && !mcpLauncher.isLaunching {
                Task {
                    try? await mcpLauncher.launchCoreServers()
                }
            }
        }
        .sheet(isPresented: $showingAdvancedOptions) {
            AdvancedServerOptionsView(mcpLauncher: mcpLauncher)
        }
    }
    
    // MARK: - Status Banner
    
    @ViewBuilder
    private var statusBanner: some View {
        HStack {
            statusIcon
            
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if mcpLauncher.isLaunching {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(statusBackgroundColor)
        .cornerRadius(8)
    }
    
    private var statusIcon: some View {
        Image(systemName: statusIconName)
            .font(.title3)
            .foregroundColor(statusColor)
    }
    
    private var statusIconName: String {
        switch mcpLauncher.launchStatus {
        case .idle:
            return "moon.zzz"
        case .launching:
            return "gearshape.2"
        case .running:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusColor: Color {
        switch mcpLauncher.launchStatus {
        case .idle:
            return .secondary
        case .launching:
            return .blue
        case .running:
            return .green
        case .error:
            return .red
        }
    }
    
    private var statusTitle: String {
        switch mcpLauncher.launchStatus {
        case .idle:
            return "Servers Idle"
        case .launching(let serverType):
            return "Launching \(serverType.displayName)..."
        case .running(let activeServers):
            return "\(activeServers) Server\(activeServers == 1 ? "" : "s") Running"
        case .error:
            return "Server Error"
        }
    }
    
    private var statusSubtitle: String {
        switch mcpLauncher.launchStatus {
        case .idle:
            return "Ready to launch AI services"
        case .launching:
            return "Initializing server process..."
        case .running:
            return "AI services are active and ready"
        case .error(let error):
            return error.localizedDescription
        }
    }
    
    private var statusBackgroundColor: Color {
        switch mcpLauncher.launchStatus {
        case .idle:
            return Color.secondary.opacity(0.1)
        case .launching:
            return Color.blue.opacity(0.1)
        case .running:
            return Color.green.opacity(0.1)
        case .error:
            return Color.red.opacity(0.1)
        }
    }
}

// MARK: - Server Card

struct ServerCard: View {
    let serverType: ServerType
    @ObservedObject var mcpLauncher: MCPServerLauncher
    let isSelected: Bool
    
    @State private var showingLogs = false
    
    var isRunning: Bool {
        mcpLauncher.isServerRunning(serverType)
    }
    
    var healthStatus: ServerHealthStatus? {
        mcpLauncher.getHealthStatus().first { $0.type == serverType }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Icon and name
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(serverType.accentColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: serverType.iconName)
                            .font(.title3)
                            .foregroundColor(serverType.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(serverType.displayName)
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text(serverDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Status and controls
                VStack(alignment: .trailing, spacing: 4) {
                    statusIndicator
                    
                    HStack(spacing: 8) {
                        if isRunning {
                            Button("Stop") {
                                mcpLauncher.stopServer(serverType)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        } else {
                            Button("Start") {
                                Task {
                                    try? await mcpLauncher.launchServer(serverType)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(mcpLauncher.isLaunching)
                        }
                    }
                }
            }
            
            // Expanded details
            if isSelected {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    if let health = healthStatus {
                        serverDetails(health: health)
                    } else {
                        Text("Server not running")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.05) : Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
    
    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isRunning ? .green : .secondary)
                .frame(width: 8, height: 8)
            
            Text(isRunning ? "Running" : "Stopped")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isRunning ? .green : .secondary)
        }
    }
    
    private var serverDescription: String {
        switch serverType {
        case .financialAnalyzer:
            return "Advanced financial analysis and pattern detection"
        case .openAIService:
            return "AI-powered transaction categorization and insights"
        case .pdfProcessor:
            return "Enhanced PDF document processing and data extraction"
        case .custom:
            return "Custom MCP server implementation"
        }
    }
    
    private func serverDetails(health: ServerHealthStatus) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ServerDetailRow(label: "Status", value: health.statusDescription)
            ServerDetailRow(label: "Port", value: "\\(health.port)")
            ServerDetailRow(label: "Uptime", value: health.statusDescription.contains("Healthy") ? 
                      DateComponentsFormatter().string(from: health.uptime) ?? "0s" : "N/A")
            
            if let lastCheck = health.lastHealthCheck {
                ServerDetailRow(label: "Last Check", value: RelativeDateTimeFormatter().localizedString(for: lastCheck, relativeTo: Date()))
            }
        }
    }
}

// MARK: - Advanced Options

struct AdvancedServerOptionsView: View {
    let mcpLauncher: MCPServerLauncher
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Advanced MCP Server Options")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Health monitoring
                GroupBox("Health Monitoring") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Perform Health Check") {
                            Task {
                                await mcpLauncher.performHealthCheck()
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Text("Check the health status of all running servers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Server logs
                GroupBox("Server Logs") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Server logs are available in Console.app")
                            .font(.body)
                        
                        Text("Filter by 'com.ledgerpro.mcp' to see MCP server output")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Open Console") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systemlogger:")!)
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Advanced Options")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}

// MARK: - Extensions

extension ServerType {
    var iconName: String {
        switch self {
        case .financialAnalyzer:
            return "chart.line.uptrend.xyaxis"
        case .openAIService:
            return "brain.head.profile"
        case .pdfProcessor:
            return "doc.text.magnifyingglass"
        case .custom:
            return "gearshape.2"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .financialAnalyzer:
            return .blue
        case .openAIService:
            return .green
        case .pdfProcessor:
            return .orange
        case .custom:
            return .purple
        }
    }
}

struct ServerDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    MCPServerManagerView(isPresented: .constant(true))
}