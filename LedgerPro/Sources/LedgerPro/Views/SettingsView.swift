import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var dataManager: FinancialDataManager
    @EnvironmentObject private var apiService: APIService
    @State private var showingClearDataAlert = false
    @State private var showingAbout = false
    @State private var backendURL = "http://127.0.0.1:8000"
    @State private var enableNotifications = true
    @State private var autoUpload = false
    @State private var dataRetentionDays = 90
    @State private var exportFormat: ExportFormat = .csv
    @State private var showingDataExport = false
    @State private var exportProgress = 0.0
    @State private var isExporting = false
    @State private var showingMCPManager = false
    @State private var escKeyMonitor: Any?
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        case pdf = "PDF"
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            case .pdf: return "pdf"
            }
        }
    }
    
    var body: some View {
        Form {
            // Backend Configuration
            Section("Backend Configuration") {
                HStack {
                    Text("Server URL")
                    Spacer()
                    TextField("Backend URL", text: $backendURL)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                }
                
                HStack {
                    Text("Connection Status")
                    Spacer()
                    HStack {
                        Circle()
                            .fill(apiService.isHealthy ? .green : .red)
                            .frame(width: 8, height: 8)
                        Text(apiService.isHealthy ? "Connected" : "Disconnected")
                            .font(.caption)
                            .foregroundColor(apiService.isHealthy ? .green : .red)
                    }
                }
                
                Button("Test Connection") {
                    Task {
                        try? await apiService.healthCheck()
                    }
                }
                .buttonStyle(.bordered)
            }
            
            // MCP AI Services
            Section("AI Services") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("MCP Server Manager")
                        Text("Manage AI-powered backend services")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Manage Servers") {
                        showingMCPManager = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Features")
                        .fontWeight(.medium)
                    Text("Enable advanced transaction categorization, financial analysis, and PDF processing with AI-powered MCP servers.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Data Management
            Section("Data Management") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Transactions")
                        Text("\(dataManager.transactions.count) records")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Remove Duplicates") {
                        dataManager.removeDuplicates()
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Accounts")
                        Text("\(dataManager.bankAccounts.count) accounts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Uploaded Statements")
                        Text("\(dataManager.uploadedStatements.count) files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                Button("Clear All Data") {
                    showingClearDataAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            
            // Privacy & Security
            Section("Privacy & Security") {
                Toggle("Enable Notifications", isOn: $enableNotifications)
                Toggle("Auto-upload Statements", isOn: $autoUpload)
                
                HStack {
                    Text("Data Retention")
                    Spacer()
                    Picker("Days", selection: $dataRetentionDays) {
                        Text("30 days").tag(30)
                        Text("60 days").tag(60)
                        Text("90 days").tag(90)
                        Text("1 year").tag(365)
                        Text("Indefinite").tag(0)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Storage")
                        .fontWeight(.medium)
                    Text("All financial data is stored locally on your device. No data is shared with third parties without your explicit consent.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Export & Backup
            Section("Export & Backup") {
                HStack {
                    Text("Export Format")
                    Spacer()
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
                
                if isExporting {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exporting data...")
                            .font(.caption)
                        ProgressView(value: exportProgress)
                    }
                } else {
                    Button("Export Financial Data") {
                        // Track export action
                        Analytics.shared.trackExportPerformed(
                            format: exportFormat.rawValue,
                            transactionCount: dataManager.transactions.count
                        )
                        exportData()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Create Backup") {
                    createBackup()
                }
                .buttonStyle(.bordered)
            }
            
            // Analytics Dashboard
            Section("Analytics") {
                AnalyticsDashboardView()
            }
            
            // Application Info
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("2024.1")
                        .foregroundColor(.secondary)
                }
                
                Button("About LedgerPro") {
                    showingAbout = true
                }
                .buttonStyle(.bordered)
                
                if let privacyURL = URL(string: "https://example.com/privacy") {
                    Link("Privacy Policy", destination: privacyURL)
                }
                if let termsURL = URL(string: "https://example.com/terms") {
                    Link("Terms of Service", destination: termsURL)
                }
            }
            
            // Developer Tools
            Section("Developer Tools") {
                Button("Load Demo Data") {
                    dataManager.loadDemoData()
                }
                .buttonStyle(.bordered)
                
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .buttonStyle(.bordered)
                
                if let lastError = apiService.lastError {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Error")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(lastError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                dataManager.clearAllData()
            }
        } message: {
            Text("This will permanently delete all transactions, accounts, and uploaded statements. This action cannot be undone.")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .overlay {
            if showingMCPManager {
                ZStack {
                    // Semi-transparent background that captures clicks
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingMCPManager = false
                        }
                    
                    // The actual popup - pass the binding so it can dismiss itself
                    MCPServerManagerView(isPresented: $showingMCPManager)
                        .frame(width: 500, height: 600)
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(12)
                        .shadow(radius: 20)
                }
                // TODO: ESC key dismissal not working - needs investigation
                // Attempted solutions:
                // 1. onKeyPress with focusable() - requires macOS 14+
                // 2. NSEvent.addLocalMonitorForEvents - not capturing ESC properly
                // Consider alternative approaches:
                // - Using a custom NSWindow subclass
                // - Implementing NSWindowDelegate methods
                // - Using a proper sheet presentation instead of overlay
                .onAppear {
                    escKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                        if event.keyCode == 53 && showingMCPManager { // ESC key
                            showingMCPManager = false
                            return nil
                        }
                        return event
                    }
                }
                .onDisappear {
                    if let monitor = escKeyMonitor {
                        NSEvent.removeMonitor(monitor)
                        escKeyMonitor = nil
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeInOut(duration: 0.2), value: showingMCPManager)
            }
        }
        .onAppear {
            loadSettings()
        }
        .onChange(of: backendURL) {
            saveSettings()
        }
        .onChange(of: enableNotifications) {
            saveSettings()
        }
        .onChange(of: autoUpload) {
            saveSettings()
        }
        .onChange(of: dataRetentionDays) {
            saveSettings()
        }
    }
    
    private func exportData() {
        isExporting = true
        exportProgress = 0.0
        
        let panel = NSSavePanel()
        if let contentType = UTType(filenameExtension: exportFormat.fileExtension) {
            panel.allowedContentTypes = [contentType]
        } else {
            panel.allowedContentTypes = [.data] // Fallback to generic data type
        }
        panel.nameFieldStringValue = "financial_data.\(exportFormat.fileExtension)"
        
        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await performExport(to: url)
            }
        } else {
            isExporting = false
        }
    }
    
    private func performExport(to url: URL) async {
        // Simulate export progress
        for i in 1...10 {
            await MainActor.run {
                exportProgress = Double(i) * 0.1
            }
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }
        
        do {
            let data: Data
            
            switch exportFormat {
            case .csv:
                data = try generateCSV()
            case .json:
                data = try generateJSON()
            case .pdf:
                data = try generatePDF()
            }
            
            try data.write(to: url)
            
            await MainActor.run {
                isExporting = false
                exportProgress = 0.0
            }
        } catch {
            await MainActor.run {
                isExporting = false
                exportProgress = 0.0
                // Handle error
                AppLogger.shared.error("Export failed: \(error)")
            }
        }
    }
    
    private func generateCSV() throws -> Data {
        var csv = "Date,Description,Amount,Category,Account\n"
        
        for transaction in dataManager.transactions {
            let accountName = dataManager.bankAccounts.first { $0.id == transaction.accountId }?.name ?? "Unknown"
            csv += "\"\(transaction.date)\",\"\(transaction.description)\",\(transaction.amount),\"\(transaction.category)\",\"\(accountName)\"\n"
        }
        
        return csv.data(using: .utf8) ?? Data()
    }
    
    private func generateJSON() throws -> Data {
        let exportData = ExportData(
            transactions: dataManager.transactions,
            accounts: dataManager.bankAccounts,
            summary: dataManager.summary,
            exportDate: ISO8601DateFormatter().string(from: Date())
        )
        
        return try JSONEncoder().encode(exportData)
    }
    
    private func generatePDF() throws -> Data {
        // For now, return JSON data wrapped as PDF content
        // In a real implementation, you'd use PDFKit to create a formatted PDF
        let jsonData = try generateJSON()
        return jsonData
    }
    
    private func createBackup() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "ledgerpro_backup_\(Date().timeIntervalSince1970).json"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let backupData = try generateJSON()
                try backupData.write(to: url)
            } catch {
                AppLogger.shared.error("Backup failed: \(error)")
            }
        }
    }
    
    private func resetToDefaults() {
        backendURL = "http://127.0.0.1:8000"
        enableNotifications = true
        autoUpload = false
        dataRetentionDays = 90
        exportFormat = .csv
        saveSettings()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        backendURL = defaults.string(forKey: "backend_url") ?? "http://127.0.0.1:8000"
        enableNotifications = defaults.bool(forKey: "enable_notifications")
        autoUpload = defaults.bool(forKey: "auto_upload")
        dataRetentionDays = defaults.integer(forKey: "data_retention_days")
        
        if dataRetentionDays == 0 {
            dataRetentionDays = 90
        }
        
        if let formatString = defaults.string(forKey: "export_format"),
           let format = ExportFormat(rawValue: formatString) {
            exportFormat = format
        }
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(backendURL, forKey: "backend_url")
        defaults.set(enableNotifications, forKey: "enable_notifications")
        defaults.set(autoUpload, forKey: "auto_upload")
        defaults.set(dataRetentionDays, forKey: "data_retention_days")
        defaults.set(exportFormat.rawValue, forKey: "export_format")
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // App Icon and Name
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("LedgerPro")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("AI-Powered Financial Analysis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 16) {
                    Text("About LedgerPro")
                        .font(.headline)
                    
                    Text("LedgerPro is a privacy-first financial analysis tool that helps you understand your spending patterns, track your financial health, and make informed decisions about your money.")
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Features:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "doc.text", text: "PDF and CSV statement processing")
                        FeatureRow(icon: "chart.bar", text: "Interactive financial dashboards")
                        FeatureRow(icon: "brain", text: "AI-powered insights and analysis")
                        FeatureRow(icon: "lock.shield", text: "Local data storage for privacy")
                        FeatureRow(icon: "building.columns", text: "Multi-account management")
                        FeatureRow(icon: "arrow.up.arrow.down", text: "Data export and backup")
                    }
                }
                
                Spacer()
                
                // Credits
                VStack(spacing: 8) {
                    Text("Built with SwiftUI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("© 2024 LedgerPro. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(32)
            .frame(width: 400, height: 500)
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 16)
            Text(text)
                .font(.body)
        }
    }
}

struct ExportData: Codable {
    let transactions: [Transaction]
    let accounts: [BankAccount]
    let summary: FinancialSummary
    let exportDate: String
}

// MARK: - Analytics Dashboard View
struct AnalyticsDashboardView: View {
    @StateObject private var analytics = Analytics.shared
    @State private var analyticsData = AnalyticsData(events: [], timings: [])
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Usage Analytics")
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Toggle Analytics") {
                    analytics.setEnabled(!analytics.isEnabled)
                }
                .buttonStyle(.bordered)
                .foregroundColor(analytics.isEnabled ? .red : .green)
            }
            
            if analytics.isEnabled {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    AnalyticsMetricCard(
                        title: "Imports This Month",
                        value: "\(analyticsData.importsThisMonth)",
                        icon: "doc.badge.plus",
                        color: .blue
                    )
                    
                    AnalyticsMetricCard(
                        title: "Avg. Categorization",
                        value: "\(Int(analyticsData.averageCategorizationRate * 100))%",
                        icon: "folder.badge.gearshape",
                        color: .green
                    )
                    
                    AnalyticsMetricCard(
                        title: "Avg. Import Time",
                        value: String(format: "%.1fs", analyticsData.averageImportTime),
                        icon: "clock",
                        color: .orange
                    )
                    
                    AnalyticsMetricCard(
                        title: "Top Categories",
                        value: "\(analyticsData.mostUsedCategories.count)",
                        icon: "chart.bar",
                        color: .purple
                    )
                }
                
                if !analyticsData.mostUsedCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Most Used Categories")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        ForEach(Array(analyticsData.mostUsedCategories.prefix(3).enumerated()), id: \.offset) { index, item in
                            HStack {
                                Text("\(index + 1).")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, alignment: .leading)
                                
                                Text(item.category)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text("\(item.count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            } else {
                Text("Analytics disabled for privacy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .onAppear {
            refreshAnalyticsData()
        }
        .onChange(of: analytics.isEnabled) { _, _ in
            refreshAnalyticsData()
        }
    }
    
    private func refreshAnalyticsData() {
        if analytics.isEnabled {
            analyticsData = analytics.getAnalyticsData()
        } else {
            analyticsData = AnalyticsData(events: [], timings: [])
        }
    }
}

struct AnalyticsMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Spacer()
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(FinancialDataManager())
            .environmentObject(APIService())
    }
}