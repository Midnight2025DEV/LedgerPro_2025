import SwiftUI
import UniformTypeIdentifiers

struct FileUploadView: View {
    @EnvironmentObject private var apiService: APIService
    @EnvironmentObject private var dataManager: FinancialDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isDragOver = false
    @State private var selectedFile: URL?
    @State private var isProcessing = false
    @State private var currentJobId: String?
    @State private var processingStatus = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var processingProgress = 0.0
    
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
            
            // Action Buttons
            if !isProcessing {
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    if selectedFile != nil {
                        Button("Upload") {
                            print("🎯 STEP 17: 🚀 UPLOAD BUTTON CLICKED!")
                            uploadFile()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Choose File") {
                            print("🎯 STEP 3: Choose File button clicked")
                            selectFile()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding(32)
        .frame(width: 700, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            print("🎯 STEP 2: FileUploadView appeared")
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
            .frame(height: 200)
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
                    Text(fileSizeString(for: file))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    if let file = selectedFile {
                        // Clean up temporary file
                        try? FileManager.default.removeItem(at: file)
                        print("🗑️ Cleaned up temporary file: \(file.lastPathComponent)")
                    }
                    selectedFile = nil
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
        VStack(spacing: 20) {
            ProgressView(value: processingProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(1.2)
            
            VStack(spacing: 8) {
                Text("Processing...")
                    .font(.headline)
                
                Text(processingStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let jobId = currentJobId {
                Text("Job ID: \(jobId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospaced()
            }
        }
        .padding()
    }
    
    private func selectFile() {
        print("🎯 STEP 4: selectFile() called")
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf, .commaSeparatedText, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        print("🎯 STEP 5: About to show file picker")
        let result = panel.runModal()
        print("🎯 STEP 6: File picker result: \(result.rawValue)")
        
        if result == .OK, let url = panel.url {
            print("🎯 STEP 7: File selected: \(url.absoluteString)")
            // Start accessing the security scoped resource
            print("🎯 STEP 8: Attempting to access security scoped resource")
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ STEP 8 FAILED: Failed to start accessing security scoped resource")
                errorMessage = "Cannot access the selected file. Please ensure the file is not in a restricted location and try again."
                showingError = true
                return
            }
            
            print("🎯 STEP 9: ✅ Security scoped resource access granted for: \(url.lastPathComponent)")
            
            // Immediately test file access and copy to temp location
            do {
                print("🎯 STEP 10: Attempting to read file data")
                // Test reading the file
                let testData = try Data(contentsOf: url)
                print("🎯 STEP 11: ✅ Successfully read \(testData.count) bytes from selected file")
                
                // Copy to temporary location to avoid security scoped resource issues
                print("🎯 STEP 12: Creating temporary file")
                let tempDir = FileManager.default.temporaryDirectory
                let tempFileName = "\(UUID().uuidString)_\(url.lastPathComponent)"
                let tempURL = tempDir.appendingPathComponent(tempFileName)
                
                print("🎯 STEP 13: Writing to temp location: \(tempURL.path)")
                try testData.write(to: tempURL)
                print("🎯 STEP 14: ✅ Copied file to temporary location: \(tempURL.path)")
                
                // Use the temporary file URL instead
                selectedFile = tempURL
                print("🎯 STEP 15: ✅ selectedFile set to temp URL")
                
                // Stop accessing the original file since we have a copy
                url.stopAccessingSecurityScopedResource()
                print("🎯 STEP 16: ✅ Released security scoped resource")
                
            } catch {
                print("❌ Failed to read or copy file: \(error)")
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
    
    private func uploadFile() {
        print("🎯 STEP 18: uploadFile() called")
        guard let file = selectedFile else { 
            print("❌ STEP 18 FAILED: No file selected")
            return 
        }
        
        print("🎯 STEP 19: File available: \(file.lastPathComponent)")
        // File should be a temporary copy, so no security scoped resource needed
        print("🎯 STEP 20: Using temporary file copy for upload")
        
        print("✅ Starting upload for file: \(file.lastPathComponent)")
        print("📁 File path: \(file.path)")
        print("📏 File exists: \(FileManager.default.fileExists(atPath: file.path))")
        
        isProcessing = true
        processingStatus = "Uploading file..."
        processingProgress = 0.0
        
        Task {
            do {
                // Verify file size
                let fileSize = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                print("📏 File size: \(fileSize) bytes")
                
                if fileSize == 0 {
                    throw APIError.uploadError("File is empty or cannot be read")
                }
                
                if fileSize > 100_000_000 { // 100MB limit
                    throw APIError.uploadError("File too large (max 100MB)")
                }
                
                // Upload file
                print("📤 Calling apiService.uploadFile...")
                let uploadResponse = try await apiService.uploadFile(file)
                currentJobId = uploadResponse.jobId
                print("✅ Upload response received, jobId: \(uploadResponse.jobId)")
                
                await MainActor.run {
                    processingStatus = "Processing document..."
                    processingProgress = 0.3
                }
                
                // Poll for completion
                print("⏳ Polling for job completion...")
                let finalStatus = try await apiService.pollJobUntilComplete(uploadResponse.jobId)
                print("🔍 Final status: \(finalStatus.status)")
                
                if finalStatus.status == "completed" {
                    await MainActor.run {
                        processingStatus = "Retrieving results..."
                        processingProgress = 0.8
                    }
                    
                    // Get transaction results
                    print("📊 Getting transaction results...")
                    let results = try await apiService.getTransactions(uploadResponse.jobId)
                    print("✅ Retrieved \(results.transactions.count) transactions")
                    
                    await MainActor.run {
                        processingProgress = 1.0
                        
                        // Add transactions to data manager
                        dataManager.addTransactions(
                            results.transactions,
                            jobId: results.jobId,
                            filename: results.metadata.filename
                        )
                        
                        print("🎉 Upload completed successfully!")
                        // Close the modal
                        dismiss()
                    }
                } else {
                    print("❌ Processing failed with status: \(finalStatus.status)")
                    await MainActor.run {
                        errorMessage = finalStatus.error ?? "Processing failed with status: \(finalStatus.status)"
                        showingError = true
                        isProcessing = false
                    }
                }
                
            } catch {
                print("❌ Upload error: \(error)")
                if let apiError = error as? APIError {
                    print("🔍 API Error details: \(apiError.errorDescription ?? "Unknown")")
                }
                
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isProcessing = false
                    selectedFile = nil
                }
            }
        }
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
    
    private func fileSizeString(for url: URL) -> String {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues.fileSize {
                let formatter = ByteCountFormatter()
                formatter.countStyle = .file
                return formatter.string(fromByteCount: Int64(fileSize))
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return "Unknown size"
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
            .frame(width: 600, height: 400)
            .navigationTitle("Error Details")
        }
    }
}

#Preview {
    FileUploadView()
        .environmentObject(APIService())
        .environmentObject(FinancialDataManager())
}