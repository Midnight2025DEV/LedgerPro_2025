import SwiftUI
import UniformTypeIdentifiers
import AppKit

// MARK: - Supporting Types

struct DetailedError {
    let title: String
    let message: String
    let technicalDetails: String
    let suggestions: [String]
    let isRecoverable: Bool
}

struct ImportHistoryItem: Codable, Identifiable {
    let id: UUID
    let filename: String
    let date: Date
    let transactionCount: Int
    let status: ImportStatus
    let fileSize: String
    let processingTime: TimeInterval
    
    init(filename: String, date: Date, transactionCount: Int, status: ImportStatus, fileSize: String, processingTime: TimeInterval) {
        self.id = UUID()
        self.filename = filename
        self.date = date
        self.transactionCount = transactionCount
        self.status = status
        self.fileSize = fileSize
        self.processingTime = processingTime
    }
    
    enum ImportStatus: String, Codable {
        case success = "Success"
        case partialSuccess = "Partial Success"
        case failed = "Failed"
        
        var color: Color {
            switch self {
            case .success: return .green
            case .partialSuccess: return .orange
            case .failed: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .partialSuccess: return "exclamationmark.triangle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
    }
}

struct FileUploadView: View {
    @EnvironmentObject private var apiService: APIService
    @EnvironmentObject private var dataManager: FinancialDataManager
    @EnvironmentObject private var categoryService: CategoryService
    @EnvironmentObject private var mcpBridge: MCPBridge
    @State private var useMCPProcessing = false
    @Environment(\.dismiss) private var dismiss
    
    private let logger = AppLogger.shared
    
    @State private var isDragOver = false
    @State private var selectedFile: URL?
    @State private var isProcessing = false
    @State private var currentJobId: String?
    @State private var processingStatus = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var processingProgress = 0.0
    @State private var importResult: ImportResult?
    @State private var showingImportSummary = false
    @State private var cachedFileSize: String? = nil
    @State private var uploadStartTime: CFAbsoluteTime = 0
    
    // Enhanced progress tracking
    @State private var detailedStatus = ""
    @State private var estimatedTimeRemaining: TimeInterval = 0
    @State private var currentStep = 0
    @State private var totalSteps = 5
    @State private var transactionCount = 0
    @State private var categorizedCount = 0
    @State private var currentPage = 0
    @State private var totalPages = 0
    @State private var showSuccessAnimation = false
    
    // Error handling
    @State private var detailedError: DetailedError?
    @State private var showingDetailedError = false
    
    // Import history
    @State private var importHistory: [ImportHistoryItem] = []
    @State private var showingImportHistory = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Upload Financial Statement")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Upload PDF or CSV files to analyze your transactions")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Upload Area
            if selectedFile == nil && !isProcessing {
                dropZone
            } else if let file = selectedFile, !isProcessing {
                selectedFileView(file: file)
            } else if isProcessing {
                processingView
            }
            
            // MCP Processing Toggle
            if selectedFile != nil && !isProcessing {
                HStack {
                    Toggle("Use Local MCP Processing", isOn: $useMCPProcessing)
                        .toggleStyle(SwitchToggleStyle())
                        .help("Process documents locally using MCP servers instead of backend API")
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Action Buttons
            if !isProcessing {
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    if selectedFile != nil {
                        Button("Upload") {
                            logger.info("Upload button clicked", category: "Upload")
                            Task {
                                await uploadFile()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isProcessing)
                        .accessibilityIdentifier("uploadButton")
                    } else {
                        Button("Choose File") {
                            logger.debug("Choose File button clicked", category: "UI")
                            selectFile()
                        }
                        .accessibilityIdentifier("chooseFileButton")
                        .buttonStyle(.borderedProminent)
                        
                        Button("Test MCP") {
                            testMCPConnection()
                        }
                        .buttonStyle(.bordered)
                        .help("Test MCP server connection and capabilities")
                        
                        Button("Diagnostic Categories") {
                            categoryService.runComprehensiveDiagnostics()
                        }
                        .buttonStyle(.bordered)
                        .help("Run comprehensive category system diagnostics")
                        
                        Button("Toggle Log Level") {
                            DiagnosticLogManager.shared.toggleLogLevel()
                        }
                        .buttonStyle(.bordered)
                        .help("Switch between Summary, Detailed, and Verbose logging")
                        
                        Button("Test Categorization") {
                            Task {
                                let testTransactions = [
                                    Transaction(date: "2024-01-01", description: "WALMART SUPERCENTER #1234", amount: -45.67, category: "Other"),
                                    Transaction(date: "2024-01-02", description: "UBER TRIP HELP.UBER.COM", amount: -12.34, category: "Other"),
                                    Transaction(date: "2024-01-03", description: "STARBUCKS STORE 12345", amount: -5.89, category: "Other"),
                                    Transaction(date: "2024-01-04", description: "PAYROLL DEPOSIT", amount: 2500.00, category: "Other"),
                                    Transaction(date: "2024-01-05", description: "AMAZON.COM MERCHANDISE", amount: -89.99, category: "Other")
                                ]
                                
                                let service = ImportCategorizationService()
                                let result = await service.categorizeTransactions(testTransactions)
                                
                                AppLogger.shared.info("🧪 TEST RESULTS: \(result.categorizedCount)/\(result.totalTransactions) categorized (\(Int(result.successRate * 100))%)")
                                
                                for (transaction, category, confidence) in result.categorizedTransactions {
                                    AppLogger.shared.info("✅ \(transaction.description) → \(category.name) (\(Int(confidence * 100))%)")
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .help("Test auto-categorization with sample transactions")
                    }
                }
            }
            
            // Import History Section
            if !importHistory.isEmpty && !isProcessing {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Imports")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("View All") {
                            showingImportHistory = true
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                    }
                    
                    LazyVStack(spacing: 8) {
                        ForEach(importHistory.prefix(3)) { item in
                            ImportHistoryRowView(item: item)
                        }
                    }
                }
                .padding(.top, 20)
            }
        }
        .padding(32)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            logger.debug("FileUploadView appeared", category: "UI")
            loadImportHistory()
        }
        .sheet(isPresented: $showingImportSummary) {
            if let result = importResult {
                ImportSummaryView(result: result) {
                    showingImportSummary = false
                    dismiss()
                }
                // 1️⃣ Tell SwiftUI "my content area is 1200×900"
                .frame(minWidth: 1200, idealWidth: 1200, maxWidth: 1200,
                       minHeight: 900, idealHeight: 900, maxHeight: 900)
                .onAppear {
                    DispatchQueue.main.async {
                        logger.debug("All windows count: \(NSApplication.shared.windows.count)", category: "UI")
                        for (index, window) in NSApplication.shared.windows.enumerated() {
                            logger.debug("Window \(index): \(window.title) - Size: \(window.frame)", category: "UI")
                        }
                        
                        if let sheet = NSApplication.shared.windows.last {
                            logger.debug("Sheet BEFORE: \(sheet.frame)", category: "UI")
                            sheet.setContentSize(NSSize(width: 1200, height: 900))
                            sheet.styleMask.remove(.resizable)
                            logger.debug("Sheet AFTER: \(sheet.frame)", category: "UI")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingDetailedError) {
            if let error = detailedError {
                DetailedErrorView(error: error) {
                    showingDetailedError = false
                    detailedError = nil
                }
            }
        }
        .sheet(isPresented: $showingImportHistory) {
            ImportHistoryView(history: importHistory) {
                showingImportHistory = false
            }
        }
        .alert("Upload Error", isPresented: $showingError) {
            Button("OK") { 
                errorMessage = ""
            }
            Button("Copy Error") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(errorMessage, forType: .string)
            }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Error occurred during upload:")
                    .font(.headline)
                
                Text(errorMessage)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
    }
    
    private var dropZone: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isDragOver ? Color.blue.opacity(0.2) : Color(NSColor.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isDragOver ? Color.blue : Color.gray.opacity(0.5),
                        style: StrokeStyle(lineWidth: 2, dash: [8])
                    )
            )
            .overlay(
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 48))
                        .foregroundColor(isDragOver ? .blue : .secondary)
                    
                    Text("Drop files here or click to browse")
                        .font(.headline)
                        .foregroundColor(isDragOver ? .blue : .primary)
                    
                    Text("Supports PDF and CSV files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
            .frame(minHeight: 200)
            .onTapGesture {
                selectFile()
            }
            .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                handleDrop(providers: providers)
            }
    }
    
    private func selectedFileView(file: URL) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: fileIcon(for: file))
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(file.lastPathComponent)
                        .font(.headline)
                    Text(cachedFileSize ?? "Calculating...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .onAppear {
                            if cachedFileSize == nil {
                                Task {
                                    await calculateFileSize(for: file)
                                }
                            }
                        }
                }
                
                Spacer()
                
                Button {
                    if let file = selectedFile {
                        // Clean up temporary file
                        try? FileManager.default.removeItem(at: file)
                        AppLogger.shared.debug("Cleaned up temporary file: \(file.lastPathComponent)")
                    }
                    selectedFile = nil
                    cachedFileSize = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Text("Ready to upload")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 24) {
            // Success Animation
            if showSuccessAnimation {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                    }
                    .scaleEffect(showSuccessAnimation ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSuccessAnimation)
                    
                    Text("Import Successful!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                // Enhanced Progress Bar
                VStack(spacing: 12) {
                    HStack {
                        Text("Step \(currentStep) of \(totalSteps)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(processingProgress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: processingProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 0.3), value: processingProgress)
                    
                    if estimatedTimeRemaining > 0 {
                        Text("About \(formatTimeRemaining(estimatedTimeRemaining)) remaining")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Current Step with Animation
                VStack(spacing: 12) {
                    Text(processingStatus)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .animation(.easeInOut(duration: 0.3), value: processingStatus)
                    
                    if !detailedStatus.isEmpty {
                        Text(detailedStatus)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .fontWeight(.medium)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.easeInOut(duration: 0.3), value: detailedStatus)
                    }
                    
                    // Batch Progress (for large files)
                    if let batchProgress = dataManager.batchProgress {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Processing Batch \(batchProgress.currentBatch) of \(batchProgress.totalBatches)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(Int(batchProgress.percentComplete * 100))%")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                            }
                            
                            ProgressView(value: batchProgress.percentComplete)
                                .progressViewStyle(LinearProgressViewStyle())
                                .scaleEffect(1.5)
                                .animation(.easeInOut(duration: 0.3), value: batchProgress.percentComplete)
                            
                            HStack(spacing: 24) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Processed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(batchProgress.processedItems)/\(batchProgress.totalItems)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .monospacedDigit()
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Time Remaining")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatTimeInterval(batchProgress.estimatedTimeRemaining))
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .monospacedDigit()
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Speed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(batchProgress.itemsPerSecond)) trans/sec")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .monospacedDigit()
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Memory")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(batchProgress.currentMemoryMB)MB")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                        .monospacedDigit()
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .transition(.opacity.combined(with: .scale))
                    }
                    
                    // Transaction Progress (for regular processing)
                    else if transactionCount > 0 {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Transactions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(transactionCount)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            if categorizedCount > 0 {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Categorized")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(categorizedCount)/\(transactionCount)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            if totalPages > 0 {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Pages")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(currentPage)/\(totalPages)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Enhanced Processing Steps
                HStack(spacing: 16) {
                    EnhancedProcessingStepView(
                        title: "Prepare",
                        icon: "doc.text",
                        isCompleted: processingProgress > 0.1,
                        isCurrent: processingProgress <= 0.1
                    )
                    
                    ConnectorLine(isActive: processingProgress > 0.1)
                    
                    EnhancedProcessingStepView(
                        title: "Extract",
                        icon: "doc.text.magnifyingglass",
                        isCompleted: processingProgress > 0.3,
                        isCurrent: processingProgress > 0.1 && processingProgress <= 0.3
                    )
                    
                    ConnectorLine(isActive: processingProgress > 0.3)
                    
                    EnhancedProcessingStepView(
                        title: "Validate",
                        icon: "checkmark.shield",
                        isCompleted: processingProgress > 0.7,
                        isCurrent: processingProgress > 0.3 && processingProgress <= 0.7
                    )
                    
                    ConnectorLine(isActive: processingProgress > 0.7)
                    
                    EnhancedProcessingStepView(
                        title: "Categorize",
                        icon: "folder.badge.gearshape",
                        isCompleted: processingProgress >= 1.0,
                        isCurrent: processingProgress > 0.7
                    )
                }
                .padding(.horizontal)
                
                // Technical Details (if needed)
                if let jobId = currentJobId {
                    Text("Job ID: \(jobId)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .monospaced()
                }
            }
        }
        .padding()
        .onAppear {
            // Add haptic feedback
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        }
    }
    
    private struct EnhancedProcessingStepView: View {
        let title: String
        let icon: String
        let isCompleted: Bool
        let isCurrent: Bool
        
        var body: some View {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : (isCurrent ? Color.blue : Color.gray.opacity(0.3)))
                        .frame(width: 32, height: 32)
                        .scaleEffect(isCurrent ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isCurrent)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(isCurrent ? .white : .secondary)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isCompleted ? .green : (isCurrent ? .blue : .secondary))
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .animation(.easeInOut(duration: 0.2), value: isCurrent)
            }
        }
    }
    
    private struct ConnectorLine: View {
        let isActive: Bool
        
        var body: some View {
            Rectangle()
                .fill(isActive ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 20, height: 2)
                .animation(.easeInOut(duration: 0.3), value: isActive)
        }
    }
    
    private func selectFile() {
        logger.debug("selectFile() called", category: "Upload")
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf, .commaSeparatedText, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        logger.debug("About to show file picker", category: "Upload")
        let result = panel.runModal()
        logger.debug("File picker result: \(result.rawValue)", category: "Upload")
        
        if result == .OK, let url = panel.url {
            logger.info("File selected: \(url.absoluteString)", category: "Upload")
            // Start accessing the security scoped resource
            logger.debug("Attempting to access security scoped resource", category: "Upload")
            guard url.startAccessingSecurityScopedResource() else {
                AppLogger.shared.error("Failed to start accessing security scoped resource")
                errorMessage = "Cannot access the selected file. Please ensure the file is not in a restricted location and try again."
                showingError = true
                return
            }
            
            logger.info("Security scoped resource access granted for: \(url.lastPathComponent)", category: "Upload")
            
            // Immediately test file access and copy to temp location
            do {
                logger.debug("Attempting to read file data", category: "Upload")
                // Test reading the file
                let testData = try Data(contentsOf: url)
                logger.info("Successfully read \(testData.count) bytes from selected file", category: "Upload")
                
                // Copy to temporary location to avoid security scoped resource issues
                logger.debug("Creating temporary file", category: "Upload")
                let tempDir = FileManager.default.temporaryDirectory
                let tempFileName = "\(UUID().uuidString)_\(url.lastPathComponent)"
                let tempURL = tempDir.appendingPathComponent(tempFileName)
                
                logger.debug("Writing to temp location: \(tempURL.path)", category: "Upload")
                try testData.write(to: tempURL)
                logger.info("Copied file to temporary location: \(tempURL.path)", category: "Upload")
                
                // Use the temporary file URL instead
                selectedFile = tempURL
                logger.debug("selectedFile set to temp URL", category: "Upload")
                
                // Stop accessing the original file since we have a copy
                url.stopAccessingSecurityScopedResource()
                logger.debug("Released security scoped resource", category: "Upload")
                
            } catch {
                logger.error("Failed to read or copy file: \(error)", category: "Upload")
                url.stopAccessingSecurityScopedResource()
                errorMessage = "Cannot read the selected file: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            selectedFile = url
                        }
                    }
                }
                return true
            }
        }
        return false
    }
    
    private func uploadFile() async {
        logger.info("uploadFile() called", category: "Upload")
        guard let file = selectedFile else { 
            logger.error("No file selected", category: "Upload")
            return 
        }
        
        logger.info("File available: \(file.lastPathComponent)", category: "Upload")
        
        // Track upload start time
        uploadStartTime = CACurrentMediaTime()
        
        // Update UI state on main thread
        await MainActor.run {
            isProcessing = true
            processingStatus = "Preparing Import"
            detailedStatus = "Validating file and checking permissions..."
            processingProgress = 0.0
            currentStep = 1
            totalSteps = 5
            transactionCount = 0
            categorizedCount = 0
            currentPage = 0
            totalPages = 0
            showSuccessAnimation = false
        }
        
        do {
            // Move file operations to background thread
            let (fileSize, filename) = try await Task.detached {
                AppLogger.shared.info("Starting upload for file: \(file.lastPathComponent)")
                AppLogger.shared.debug("File path: \(file.path)")
                AppLogger.shared.debug("File exists: \(FileManager.default.fileExists(atPath: file.path))")
                
                // Verify file size on background thread
                let resourceValues = try file.resourceValues(forKeys: [.fileSizeKey])
                let size = resourceValues.fileSize ?? 0
                await logger.debug("File size: \(size) bytes", category: "Upload")
                
                if size == 0 {
                    throw APIError.uploadError("File is empty or cannot be read")
                }
                
                if size > 100_000_000 { // 100MB limit
                    throw APIError.uploadError("File too large (max 100MB)")
                }
                
                return (size, file.lastPathComponent)
            }.value
            
            // Update UI with file validation complete
            await MainActor.run {
                processingStatus = "Uploading Document"
                detailedStatus = "Securely transferring \(filename) to processing server..."
                processingProgress = 0.1
                currentStep = 2
                estimatedTimeRemaining = estimateProcessingTime(fileSize: fileSize)
            }
            
            // Choose processing method based on toggle
            let transactions: [Transaction]
            let finalFilename: String
            
            if useMCPProcessing {
                // Use MCP processing
                await MainActor.run {
                    processingStatus = "Processing Locally"
                    detailedStatus = "Using AI-powered MCP servers for document analysis..."
                    processingProgress = 0.3
                    currentStep = 3
                }
                
                transactions = try await self.processDocumentWithMCP(file)
                finalFilename = filename
                logger.info("MCP processed \(transactions.count) transactions", category: "MCP")
            } else {
                // Use backend API processing (already async)
                AppLogger.shared.debug("Calling apiService.uploadFile...")
                let uploadResponse = try await apiService.uploadFile(file)
                currentJobId = uploadResponse.jobId
                logger.info("Upload response received, jobId: \(uploadResponse.jobId)", category: "Upload")
                
                await MainActor.run {
                    processingStatus = "Analyzing Document"
                    detailedStatus = "Detecting tables and extracting transaction data..."
                    processingProgress = 0.3
                    currentStep = 3
                }
                
                // Poll for completion
                logger.debug("Polling for job completion...", category: "Upload")
                let finalStatus = try await apiService.pollJobUntilComplete(uploadResponse.jobId)
                logger.debug("Final status: \(finalStatus.status)", category: "Upload")
                
                if finalStatus.status == "completed" {
                    await MainActor.run {
                        processingStatus = "Retrieving Results"
                        detailedStatus = "Downloading processed transaction data..."
                        processingProgress = 0.8
                        currentStep = 4
                    }
                    
                    // Get transaction results
                    AppLogger.shared.debug("Getting transaction results...")
                    let results = try await apiService.getTransactions(uploadResponse.jobId)
                    transactions = results.transactions
                    finalFilename = results.metadata.filename
                    
                    // DEBUG: Log API processing results
                    AppLogger.shared.info("📄 Backend API processing complete for jobId: \(uploadResponse.jobId)")
                    AppLogger.shared.info("📊 API returned \(transactions.count) transactions")
                    AppLogger.shared.info("📁 Filename: \(finalFilename)")
                    
                    for (index, transaction) in transactions.prefix(3).enumerated() {
                        AppLogger.shared.info("   API Transaction \(index + 1): \(transaction.description) - \(transaction.amount) - ID: \(transaction.id)")
                    }
                    
                    logger.info("Retrieved \(transactions.count) transactions", category: "Upload")
                    
                    // Update transaction count
                    await MainActor.run {
                        transactionCount = transactions.count
                        detailedStatus = "Found \(transactions.count) transactions, preparing for categorization..."
                    }
                } else {
                    throw APIError.uploadError("Document processing failed: \(finalStatus.status)")
                }
            }
            
            // Process forex data in background, but categorization on main thread
            await Task.detached {
                // Debug: Check if any transactions have forex data
                let forexTransactions = transactions.filter { $0.hasForex == true }
                if !forexTransactions.isEmpty {
                    AppLogger.shared.info("Found \(forexTransactions.count) foreign currency transactions")
                    for transaction in forexTransactions {
                        await logger.debug("Foreign currency transaction: \(transaction.description): \(transaction.originalAmount ?? 0) \(transaction.originalCurrency ?? "??") @ \(transaction.exchangeRate ?? 0)", category: "Upload")
                    }
                } else {
                    await logger.warning("No foreign currency transactions found", category: "Upload")
                }
            }.value
            
            // Auto-categorize transactions on main thread (required by @MainActor)
            await MainActor.run {
                processingStatus = "Smart Categorization"
                detailedStatus = "Analyzing transaction patterns and applying rules..."
                processingProgress = 0.9
                currentStep = 5
            }
            
            AppLogger.shared.info("🔄 FileUploadView: Starting auto-categorization of \(transactions.count) transactions...")
            
            // Log sample input transactions
            AppLogger.shared.info("🔍 SAMPLE INPUT TRANSACTIONS TO CATEGORIZATION:")
            for (index, transaction) in transactions.prefix(3).enumerated() {
                AppLogger.shared.info("   \(index + 1). '\(transaction.description)' (current category: '\(transaction.category)')")
            }
            
            let categorizationService = ImportCategorizationService()
            let categorizedResult = await categorizationService.categorizeTransactions(transactions)
            
            AppLogger.shared.info("📦 FileUploadView: Received categorization result")
            AppLogger.shared.info("   Result type: ImportResult")
            AppLogger.shared.info("   Total transactions: \(categorizedResult.totalTransactions)")
            AppLogger.shared.info("   Categorized count: \(categorizedResult.categorizedCount)")
            AppLogger.shared.info("   Uncategorized count: \(categorizedResult.uncategorizedCount)")
            AppLogger.shared.info("   Success rate: \(String(format: "%.1f", categorizedResult.successRate * 100))%")
            
            // Update progress after categorization (on main actor)
            await MainActor.run {
                categorizedCount = categorizedResult.categorizedCount
                let percentage = categorizedResult.categorizedCount > 0 ? Int((Double(categorizedResult.categorizedCount) / Double(categorizedResult.totalTransactions)) * 100) : 0
                detailedStatus = "Categorized \(categorizedResult.categorizedCount)/\(categorizedResult.totalTransactions) transactions (\(percentage)%)"
                
                AppLogger.shared.info("📊 FileUploadView: Updated UI with categorization results")
                AppLogger.shared.info("   UI categorizedCount: \(categorizedCount)")
                AppLogger.shared.info("   UI detailedStatus: '\(detailedStatus)'")
            }
            logger.info("Auto-categorized \(categorizedResult.categorizedCount)/\(categorizedResult.totalTransactions) transactions", category: "Upload")
            
            // Update UI with finalization progress
            await MainActor.run {
                processingStatus = "Finalizing Import"
                detailedStatus = "Saving transactions and preparing summary..."
                processingProgress = 0.95
            }
            
            // Final UI updates on main thread
            await MainActor.run {
                processingProgress = 1.0
                importResult = categorizedResult
                
                // Add categorized transactions to data manager
                AppLogger.shared.info("🏗️ FileUploadView: Assembling final transaction list")
                AppLogger.shared.info("   Categorized tuples: \(categorizedResult.categorizedTransactions.count)")
                AppLogger.shared.info("   Uncategorized transactions: \(categorizedResult.uncategorizedTransactions.count)")
                
                // Extract transactions from categorized tuples
                let categorizedTransactionsOnly = categorizedResult.categorizedTransactions.map { $0.0 }
                AppLogger.shared.info("   Extracted \(categorizedTransactionsOnly.count) transactions from categorized tuples")
                
                // Log sample categorized transactions after extraction
                if !categorizedTransactionsOnly.isEmpty {
                    AppLogger.shared.info("🔍 SAMPLE EXTRACTED CATEGORIZED TRANSACTIONS:")
                    for (index, transaction) in categorizedTransactionsOnly.prefix(3).enumerated() {
                        AppLogger.shared.info("   \(index + 1). '\(transaction.description)' -> '\(transaction.category)' (confidence: \(transaction.confidence ?? 0.0))")
                        AppLogger.shared.info("      wasAutoCategorized: \(transaction.wasAutoCategorized ?? false)")
                    }
                }
                
                let finalTransactions = categorizedTransactionsOnly + categorizedResult.uncategorizedTransactions
                
                // DEBUG: Log transaction details before adding to dataManager
                AppLogger.shared.info("📊 FileUploadView: Final transaction list assembled")
                AppLogger.shared.info("   Total final transactions: \(finalTransactions.count)")
                AppLogger.shared.info("   From categorized: \(categorizedTransactionsOnly.count)")
                AppLogger.shared.info("   From uncategorized: \(categorizedResult.uncategorizedTransactions.count)")
                
                // Log detailed breakdown of final transactions
                AppLogger.shared.info("🔍 FINAL TRANSACTION BREAKDOWN:")
                for (index, transaction) in finalTransactions.prefix(5).enumerated() {
                    AppLogger.shared.info("   \(index + 1). '\(transaction.description)' -> '\(transaction.category)' (ID: \(transaction.id))")
                    AppLogger.shared.info("      Amount: \(transaction.amount), Confidence: \(transaction.confidence ?? 0.0)")
                    AppLogger.shared.info("      WasAutoCategorized: \(transaction.wasAutoCategorized ?? false)")
                }
                
                // Use jobId if available (backend processing) or generate one for MCP
                let jobIdForData = currentJobId ?? UUID().uuidString
                AppLogger.shared.info("📋 Using jobId: \(jobIdForData) for data storage")
                
                AppLogger.shared.info("💾 FileUploadView: Adding \(finalTransactions.count) transactions")
                AppLogger.shared.info("   JobId: \(jobIdForData)")
                AppLogger.shared.info("   Filename: \(finalFilename)")
                
                // Use batch processing for large files (>1000 transactions)
                let useBatchProcessing = finalTransactions.count > 1000
                
                // Track batch threshold decision
                Analytics.shared.trackBatchThresholdDecision(
                    itemCount: finalTransactions.count,
                    usedBatchProcessing: useBatchProcessing
                )
                
                // Use regular processing for now (batch processing disabled for build fix)
                AppLogger.shared.info("💾 Using regular processing for \(finalTransactions.count) transactions")
                
                dataManager.addTransactions(
                    finalTransactions,
                    jobId: jobIdForData,
                    filename: finalFilename
                )
                
                AppLogger.shared.info("✅ FileUploadView: Transaction processing completed")
                AppLogger.shared.info("   DataManager now has: \(dataManager.transactions.count) total transactions")
                
                let processingMethod = useMCPProcessing ? "MCP Local Processing" : "Backend API"
                logger.info("Processing completed successfully with \(processingMethod)!", category: "Upload")
                
                // Track import completion analytics
                let fileType = finalFilename.hasSuffix(".pdf") ? "PDF" : "CSV"
                let processingTime = CACurrentMediaTime() - uploadStartTime
                let categorizationRate = calculateCategorizationRate(from: categorizedResult)
                
                Analytics.shared.trackImportCompleted(
                    fileType: fileType,
                    transactionCount: finalTransactions.count,
                    success: true,
                    processingTime: processingTime,
                    categorizationRate: categorizationRate
                )
                
                // Track end-to-end pipeline performance
                // Estimate timing breakdown (simplified for now)
                let uploadTime = processingTime * 0.2  // ~20% upload
                let processingTimeOnly = processingTime * 0.7  // ~70% processing  
                let uiUpdateTime = processingTime * 0.1  // ~10% UI updates
                
                Analytics.shared.trackPipelinePerformance(
                    uploadTime: uploadTime,
                    processingTime: processingTimeOnly,
                    uiUpdateTime: uiUpdateTime,
                    transactionCount: finalTransactions.count,
                    processingMethod: useMCPProcessing ? "mcp_local" : "backend_api"
                )
                
                // Show success animation briefly
                showSuccessAnimation = true
                processingStatus = "Import Complete!"
                detailedStatus = "Successfully imported \(finalTransactions.count) transactions"
                processingProgress = 1.0
                
                // Add haptic feedback for success
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                
                // Save to import history
                let historyItem = ImportHistoryItem(
                    filename: finalFilename,
                    date: Date(),
                    transactionCount: finalTransactions.count,
                    status: .success,
                    fileSize: cachedFileSize ?? "Unknown",
                    processingTime: processingTime
                )
                saveToImportHistory(historyItem)
            }
            
            // Show success animation for 2 seconds, then show summary
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                // Show import summary instead of immediately dismissing
                showingImportSummary = true
                
                // Post notification to reset transaction filters
                NotificationCenter.default.post(
                    name: NSNotification.Name("TransactionsImported"),
                    object: nil,
                    userInfo: ["count": importResult?.totalTransactions ?? 0]
                )
            }
            
        } catch {
            logger.error("Upload error: \(error)", category: "Upload")
            if let apiError = error as? APIError {
                logger.error("API Error details: \(apiError.errorDescription ?? "Unknown")", category: "Upload")
            }
            
            await MainActor.run {
                // Track failed import
                let processingTime = CACurrentMediaTime() - uploadStartTime
                if let file = selectedFile {
                    let fileType = file.pathExtension.lowercased() == "pdf" ? "PDF" : "CSV"
                    
                    Analytics.shared.trackImportCompleted(
                        fileType: fileType,
                        transactionCount: 0,
                        success: false,
                        processingTime: processingTime,
                        categorizationRate: 0.0
                    )
                }
                
                // Create detailed error
                detailedError = createDetailedError(from: error, filename: selectedFile?.lastPathComponent ?? "Unknown")
                showingDetailedError = true
                
                // Save failed import to history
                if let file = selectedFile {
                    let historyItem = ImportHistoryItem(
                        filename: file.lastPathComponent,
                        date: Date(),
                        transactionCount: 0,
                        status: .failed,
                        fileSize: cachedFileSize ?? "Unknown",
                        processingTime: processingTime
                    )
                    saveToImportHistory(historyItem)
                }
                
                // Add haptic feedback for error
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                
                errorMessage = error.localizedDescription
                showingError = true
                isProcessing = false
                selectedFile = nil
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func estimateProcessingTime(fileSize: Int) -> TimeInterval {
        // Estimate based on file size (rough calculation)
        let basePDFTime: TimeInterval = 10.0 // 10 seconds base
        let additionalTimePerMB = 2.0 // 2 seconds per MB
        let fileSizeInMB = Double(fileSize) / 1_000_000.0
        return basePDFTime + (fileSizeInMB * additionalTimePerMB)
    }
    
    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds)) seconds"
        } else {
            let minutes = Int(seconds / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
    
    private func formatTimeInterval(_ seconds: TimeInterval) -> String {
        if seconds < 1 {
            return "0s"
        } else if seconds < 60 {
            return "\(Int(seconds))s"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            let remainingSeconds = Int(seconds.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        }
    }
    
    private func createDetailedError(from error: Error, filename: String) -> DetailedError {
        let baseTitle = "Import Failed"
        
        // Enhanced error handling with specific messages
        if let apiError = error as? APIError {
            switch apiError {
            case .uploadError(let message):
                if message.contains("empty") {
                    return DetailedError(
                        title: "Empty File Detected",
                        message: "The file '\(filename)' appears to be empty or corrupted.",
                        technicalDetails: message,
                        suggestions: [
                            "Ensure the file is not corrupted",
                            "Try re-downloading the statement from your bank",
                            "Check that the file opens correctly in other applications"
                        ],
                        isRecoverable: true
                    )
                } else if message.contains("too large") {
                    return DetailedError(
                        title: "File Too Large",
                        message: "The file '\(filename)' exceeds the 100MB size limit.",
                        technicalDetails: message,
                        suggestions: [
                            "Try splitting large statements into smaller files",
                            "Compress the PDF file using a PDF editor",
                            "Upload statements for shorter time periods"
                        ],
                        isRecoverable: true
                    )
                } else if message.contains("network") || message.contains("timeout") {
                    return DetailedError(
                        title: "Network Connection Issue",
                        message: "Unable to connect to the processing server.",
                        technicalDetails: message,
                        suggestions: [
                            "Check your internet connection",
                            "Try again in a few moments",
                            "Consider using MCP local processing instead"
                        ],
                        isRecoverable: true
                    )
                } else if message.contains("no transaction") || message.contains("no table") {
                    return DetailedError(
                        title: "No Transactions Found",
                        message: "Unable to find transaction data in '\(filename)'.",
                        technicalDetails: message,
                        suggestions: [
                            "Ensure the file contains a standard bank statement format",
                            "Try a different page range if it's a multi-page PDF",
                            "Check that the statement includes transaction details",
                            "Contact support if the format should be supported"
                        ],
                        isRecoverable: true
                    )
                } else {
                    return DetailedError(
                        title: baseTitle,
                        message: "An error occurred while processing '\(filename)'.",
                        technicalDetails: message,
                        suggestions: [
                            "Try uploading the file again",
                            "Check the file format is supported (PDF or CSV)",
                            "Contact support if the problem persists"
                        ],
                        isRecoverable: true
                    )
                }
            default:
                return DetailedError(
                    title: baseTitle,
                    message: "An API error occurred while processing '\(filename)'.",
                    technicalDetails: apiError.localizedDescription,
                    suggestions: [
                        "Check your internet connection",
                        "Try again in a few moments",
                        "Contact support if the problem persists"
                    ],
                    isRecoverable: true
                )
            }
        } else {
            // Handle other error types
            let errorDesc = error.localizedDescription
            if errorDesc.contains("security") {
                return DetailedError(
                    title: "File Access Denied",
                    message: "Permission denied to access '\(filename)'.",
                    technicalDetails: errorDesc,
                    suggestions: [
                        "Move the file to your Documents folder",
                        "Check file permissions in Finder",
                        "Try selecting the file again"
                    ],
                    isRecoverable: true
                )
            } else if errorDesc.contains("format") {
                return DetailedError(
                    title: "Unsupported Format",
                    message: "The file format of '\(filename)' is not supported.",
                    technicalDetails: errorDesc,
                    suggestions: [
                        "Use PDF or CSV format only",
                        "Convert the file to a supported format",
                        "Export a new statement from your bank"
                    ],
                    isRecoverable: true
                )
            } else {
                return DetailedError(
                    title: baseTitle,
                    message: "An unexpected error occurred while processing '\(filename)'.",
                    technicalDetails: errorDesc,
                    suggestions: [
                        "Try uploading the file again",
                        "Restart the application",
                        "Contact support with the error details"
                    ],
                    isRecoverable: false
                )
            }
        }
    }
    
    private func loadImportHistory() {
        if let data = UserDefaults.standard.data(forKey: "import_history"),
           let history = try? JSONDecoder().decode([ImportHistoryItem].self, from: data) {
            // Filter out items older than 30 days
            let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
            importHistory = history.filter { $0.date > thirtyDaysAgo }
        }
    }
    
    private func saveToImportHistory(_ item: ImportHistoryItem) {
        importHistory.insert(item, at: 0)
        // Keep only last 20 items
        if importHistory.count > 20 {
            importHistory = Array(importHistory.prefix(20))
        }
        
        if let data = try? JSONEncoder().encode(importHistory) {
            UserDefaults.standard.set(data, forKey: "import_history")
        }
    }
    
    private func calculateCategorizationRate(from result: ImportResult) -> Double {
        let totalTransactions = result.totalTransactions
        guard totalTransactions > 0 else { return 0.0 }
        
        let categorizedCount = result.categorizedCount
        return Double(categorizedCount) / Double(totalTransactions)
    }
    
    private func fileIcon(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "pdf":
            return "doc.richtext"
        case "csv":
            return "tablecells"
        default:
            return "doc"
        }
    }
    
    private func calculateFileSize(for url: URL) async {
        let sizeString = await Task.detached {
            do {
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resourceValues.fileSize {
                    let formatter = ByteCountFormatter()
                    formatter.countStyle = .file
                    return formatter.string(fromByteCount: Int64(fileSize))
                }
            } catch {
                await logger.error("Error getting file size: \(error)", category: "Upload")
            }
            return "Unknown size"
        }.value
        
        await MainActor.run {
            self.cachedFileSize = sizeString
        }
    }
    
    private func fileSizeString(for url: URL) -> String {
        return cachedFileSize ?? "Calculating..."
    }
    
    // MARK: - MCP Processing
    
    private func processDocumentWithMCP(_ url: URL) async throws -> [Transaction] {
        logger.info("Processing document with MCP: \(url.lastPathComponent)", category: "MCP")
        
        // First ensure servers are connected (they might have disconnected after launch)
        if !mcpBridge.areServersReady() {
            logger.info("Servers not ready, connecting all servers...", category: "MCP")
            await mcpBridge.connectAll()
            
            // Give servers a moment to establish connections
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
        
        // Use enhanced initialization check with proper timing
        do {
            try await mcpBridge.waitForServersToInitialize(maxAttempts: 30)
            logger.info("All MCP servers fully initialized and ready", category: "MCP")
        } catch {
            logger.error("MCP server initialization failed: \(error.localizedDescription)", category: "MCP")
            throw error
        }
        
        logger.info("All MCP servers ready, processing document...", category: "MCP")
        
        // Process document through MCP
        let result = try await mcpBridge.processDocument(url)
        
        // DEBUG: Log MCP processing results
        AppLogger.shared.info("📄 MCP processing complete for \(url.lastPathComponent)")
        AppLogger.shared.info("📊 MCP returned \(result.transactions.count) transactions")
        AppLogger.shared.info("📋 Processing method: \(result.metadata.method)")
        AppLogger.shared.info("🎯 Confidence: \(result.confidence)")
        
        for (index, transaction) in result.transactions.prefix(3).enumerated() {
            AppLogger.shared.info("   MCP Transaction \(index + 1): \(transaction.description) - \(transaction.amount)")
        }
        
        return result.transactions
    }
    
    // MARK: - MCP Testing
    
    private func testMCPConnection() {
        logger.info("Testing MCP connection...", category: "MCP")
        
        Task {
            do {
                // Test connection
                await mcpBridge.connectAll()
                
                // Wait for connection establishment
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                await MainActor.run {
                    let isConnected = mcpBridge.isConnected
                    let serverCount = mcpBridge.servers.values.count
                    let activeCount = mcpBridge.servers.values.filter { $0.isConnected }.count
                    
                    let message = """
                    🧪 MCP Test Results:
                    • Connected: \(isConnected ? "✅" : "❌")
                    • Available Servers: \(serverCount)
                    • Active Servers: \(activeCount)
                    
                    Server Details:
                    \(mcpBridge.servers.values.map { "• \($0.info.name): \($0.isConnected ? "✅ Active" : "❌ Inactive")" }.joined(separator: "\n"))
                    """
                    
                    errorMessage = message
                    showingError = true
                    
                    logger.info(message, category: "MCP")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "MCP Test Failed: \(error.localizedDescription)"
                    showingError = true
                    logger.error("MCP Test Error: \(error)", category: "MCP")
                }
            }
        }
    }
}

struct ErrorDisplayView: View {
    let errorMessage: String
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("Upload Error")
                    .font(.title2)
                    .fontWeight(.bold)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Error Details:")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                }
                
                HStack(spacing: 16) {
                    Button("Copy Error") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(errorMessage, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Close") {
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(32)
            .frame(minWidth: 800, maxWidth: .infinity,
                   minHeight: 600, maxHeight: .infinity)
            .navigationTitle("Error Details")
        }
    }
}

struct ImportSummaryView: View {
    let result: ImportResult
    let onDismiss: () -> Void
    
    @State private var showingCategorizedDetails = false
    @State private var showingUncategorizedDetails = false
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Stats grid - simple layout without geometry calculations
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        statBoxes
                    }
                    
                    // Progress section
                    progressSection
                    
                    // Transaction details
                    transactionDetailsSection
                    
                    Spacer(minLength: 20)
                    
                    // Action buttons
                    actionButtonsSection
                }
                .frame(maxWidth: 1100) // FIXED WIDTH - ChatGPT's key fix
                .padding(32)
            }
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .navigationTitle("Import Summary")
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: result.totalTransactions > 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(result.totalTransactions > 0 ? .green : .orange)
            
            Text(result.totalTransactions > 0 ? "Import Complete!" : "Import Completed with Issues")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(result.totalTransactions > 0 ? 
                 "Your transactions have been imported and auto-categorized" :
                 "No transactions were found in the uploaded file")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    
    @ViewBuilder
    private var statBoxes: some View {
        StatBox(
            title: "Total",
            value: "\(result.totalTransactions)",
            color: .blue,
            icon: "list.bullet"
        )
        
        StatBox(
            title: "Categorized",
            value: "\(result.categorizedCount)",
            subtitle: "\(Int(result.successRate * 100))%",
            color: .green,
            icon: "checkmark.circle"
        )
        
        StatBox(
            title: "High Confidence",
            value: "\(result.highConfidenceCount)",
            color: .purple,
            icon: "star.fill"
        )
        
        StatBox(
            title: "Need Review",
            value: "\(result.uncategorizedCount)",
            color: .orange,
            icon: "exclamationmark.triangle"
        )
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Categorization Rate")
                    .font(.headline)
                Spacer()
                Text("\(Int(result.successRate * 100))%")
                    .font(.headline)
                    .foregroundColor(result.successRate > 0.8 ? .green : result.successRate > 0.6 ? .orange : .red)
            }
            
            ProgressView(value: result.successRate)
                .progressViewStyle(LinearProgressViewStyle(tint: result.successRate > 0.8 ? .green : result.successRate > 0.6 ? .orange : .red))
                .scaleEffect(1.2)
            
            // Success rate insights
            Text(successRateInsight)
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Insights")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                if result.highConfidenceCount > 0 {
                    Label("\(result.highConfidenceCount) transactions categorized with high confidence", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                
                if result.uncategorizedCount > 0 {
                    Label("\(result.uncategorizedCount) transactions need manual review", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if result.categorizedCount == result.totalTransactions && result.totalTransactions > 0 {
                    Label("Perfect! All transactions were categorized", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var transactionDetailsSection: some View {
        VStack(spacing: 16) {
            if result.totalTransactions == 0 {
                // Empty state - compatible with macOS 13.0+
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Transactions Found")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("The uploaded file didn't contain any recognizable transactions. Try uploading a different file or check the file format.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Upload Different File") {
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(minHeight: 200)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            } else {
                // Categorized transactions
                if !result.categorizedTransactions.isEmpty {
                    DisclosureGroup("Categorized Transactions (\(result.categorizedCount))", isExpanded: $showingCategorizedDetails) {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(result.categorizedTransactions.prefix(10).enumerated()), id: \.offset) { index, item in
                                let (transaction, category, confidence) = item
                                ImportTransactionRowView(transaction: transaction, category: category, confidence: confidence)
                            }
                            
                            if result.categorizedTransactions.count > 10 {
                                Text("... and \(result.categorizedTransactions.count - 10) more")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // Uncategorized transactions
                if !result.uncategorizedTransactions.isEmpty {
                    DisclosureGroup("Uncategorized Transactions (\(result.uncategorizedCount))", isExpanded: $showingUncategorizedDetails) {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(result.uncategorizedTransactions.prefix(10).enumerated()), id: \.offset) { index, transaction in
                                ImportTransactionRowView(transaction: transaction, category: nil, confidence: nil)
                            }
                            
                            if result.uncategorizedTransactions.count > 10 {
                                Text("... and \(result.uncategorizedTransactions.count - 10) more")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button("Continue to Dashboard") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            if result.uncategorizedCount > 0 {
                Button("Review Uncategorized (\(result.uncategorizedCount))") {
                    onDismiss()
                    
                    // Navigate to Transactions tab with uncategorized filter
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        // Find ContentView and update its state
                        NotificationCenter.default.post(
                            name: NSNotification.Name("NavigateToUncategorized"),
                            object: nil,
                            userInfo: ["count": result.uncategorizedCount]
                        )
                    }
                }
                .buttonStyle(.bordered)
            }
            
            if result.totalTransactions == 0 {
                Button("Try Different File") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    
    private var successRateInsight: String {
        switch result.successRate {
        case 0.9...1.0:
            return "Excellent! Most transactions were automatically categorized."
        case 0.7..<0.9:
            return "Good categorization rate. A few transactions need review."
        case 0.5..<0.7:
            return "Moderate success. Consider reviewing categorization rules."
        case 0.1..<0.5:
            return "Low categorization rate. Manual review recommended."
        default:
            return "No transactions were automatically categorized."
        }
    }
}

struct ImportTransactionRowView: View {
    let transaction: Transaction
    let category: Category?
    let confidence: Double?
    
    var body: some View {
        HStack(spacing: 12) {
            // Transaction type icon
            Image(systemName: transaction.isIncome ? "plus.circle.fill" : "minus.circle.fill")
                .foregroundColor(transaction.isIncome ? .green : .red)
                .font(.system(size: 16))
            
            // Transaction details
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                HStack {
                    Text(transaction.formattedDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let category = category {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(transaction.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Amount and confidence
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.displayAmount)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(transaction.isIncome ? .green : .primary)
                
                if let confidence = confidence {
                    HStack(spacing: 2) {
                        Image(systemName: confidence > 0.8 ? "star.fill" : confidence > 0.6 ? "star.leadinghalf.filled" : "star")
                            .font(.system(size: 8))
                            .foregroundColor(confidence > 0.8 ? .purple : confidence > 0.6 ? .orange : .gray)
                        
                        Text("\(Int(confidence * 100))%")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Uncategorized")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct DetailedErrorView: View {
    let error: DetailedError
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Error Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                        
                        Text(error.title)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text(error.message)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Suggestions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggested Solutions")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(Array(error.suggestions.enumerated()), id: \.offset) { index, suggestion in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(width: 20, alignment: .leading)
                            
                            Text(suggestion)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
                Divider()
                
                // Technical Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Technical Details")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(error.technicalDetails)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Copy Error Details") {
                        let errorText = """
                        Error: \(error.title)
                        Message: \(error.message)
                        Technical Details: \(error.technicalDetails)
                        """
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(errorText, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Report Issue") {
                        let errorText = """
                        Error Report:
                        Title: \(error.title)
                        Message: \(error.message)
                        Technical Details: \(error.technicalDetails)
                        """
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(errorText, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    if error.isRecoverable {
                        Button("Try Again") {
                            onDismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button("Close") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Import Error")
            .frame(minWidth: 500, minHeight: 400)
        }
    }
}

struct ImportHistoryView: View {
    let history: [ImportHistoryItem]
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Import History")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if history.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Recent Imports")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Your import history will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(history) { item in
                                ImportHistoryDetailView(item: item)
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding()
            .navigationTitle("Import History")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .frame(minWidth: 600, minHeight: 400)
        }
    }
}

struct ImportHistoryRowView: View {
    let item: ImportHistoryItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.status.icon)
                .foregroundColor(item.status.color)
                .font(.system(size: 14))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.filename)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(item.transactionCount) transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.date.formatted(.dateTime.month().day().hour().minute()))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.status.rawValue)
                    .font(.caption2)
                    .foregroundColor(item.status.color)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct ImportHistoryDetailView: View {
    let item: ImportHistoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: item.status.icon)
                    .foregroundColor(item.status.color)
                    .font(.system(size: 18))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.filename)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(item.date.formatted(.dateTime.weekday().month().day().hour().minute()))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(item.status.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(item.status.color)
                    
                    Text(String(format: "%.1fs", item.processingTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Details
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(item.transactionCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("File Size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(item.fileSize)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Processing Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1fs", item.processingTime))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    FileUploadView()
        .environmentObject(APIService())
        .environmentObject(FinancialDataManager())
        .environmentObject(CategoryService.shared)
}