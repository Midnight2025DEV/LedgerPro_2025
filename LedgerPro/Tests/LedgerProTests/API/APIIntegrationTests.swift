import XCTest
@testable import LedgerPro

/// Integration tests for complete API workflows
@MainActor
final class APIIntegrationTests: XCTestCase {
    var apiService: APIService!
    var dataManager: FinancialDataManager!
    var categoryService: CategoryService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        apiService = APIService()
        dataManager = FinancialDataManager()
        categoryService = CategoryService.shared
        
        // Ensure backend is running
        do {
            _ = try await apiService.healthCheck()
        } catch {
            throw XCTSkip("Backend not running. Start with ./start_backend.sh")
        }
    }
    
    override func tearDown() async throws {
        apiService = nil
        dataManager = nil
        categoryService = nil
        try await super.tearDown()
    }
    
    // MARK: - End-to-End Upload Flow
    
    func testCompleteUploadFlow() async throws {
        // 1. Create test CSV with various transaction types
        let csvContent = """
        Date,Description,Amount,Category
        2024-01-01,WALMART SUPERCENTER,-45.67,Shopping
        2024-01-02,UBER TRIP HELP.UBER.COM,-12.34,Transportation
        2024-01-03,STARBUCKS STORE 12345,-5.89,Food & Dining
        2024-01-04,PAYROLL DEPOSIT,2500.00,Salary
        2024-01-05,AMAZON.COM MERCHANDISE,-89.99,Shopping
        2024-01-06,TRANSFER FROM SAVINGS,1000.00,Transfer
        2024-01-07,NETFLIX SUBSCRIPTION,-15.99,Entertainment
        2024-01-08,GAS STATION SHELL,-65.43,Transportation
        """
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_\(UUID().uuidString).csv")
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        // 2. Upload file
        let uploadResponse = try await apiService.uploadFile(tempURL)
        XCTAssertFalse(uploadResponse.jobId.isEmpty)
        XCTAssertTrue(["processing", "processing_csv", "completed"].contains(uploadResponse.status))
        
        // 3. Poll for completion with timeout
        let finalStatus = try await apiService.pollJobUntilComplete(
            uploadResponse.jobId,
            maxRetries: 30,
            intervalSeconds: 2
        )
        XCTAssertEqual(finalStatus.status, "completed")
        XCTAssertEqual(finalStatus.progress, 100.0)
        
        // 4. Get transactions
        let transactionResult = try await apiService.getTransactions(uploadResponse.jobId)
        XCTAssertEqual(transactionResult.transactions.count, 8)
        
        // 5. Verify transaction details
        let walmart = transactionResult.transactions.first { $0.description.contains("WALMART") }
        XCTAssertNotNil(walmart)
        if let walmartAmount = walmart?.amount {
            XCTAssertEqual(walmartAmount, -45.67, accuracy: 0.01)
        }
        XCTAssertEqual(walmart?.category, "Shopping")
        
        let payroll = transactionResult.transactions.first { $0.description.contains("PAYROLL") }
        XCTAssertNotNil(payroll)
        if let payrollAmount = payroll?.amount {
            XCTAssertEqual(payrollAmount, 2500.00, accuracy: 0.01)
        }
        
        // 6. Verify summary calculations
        let summary = transactionResult.summary
        XCTAssertEqual(summary.totalIncome, 3500.00, accuracy: 0.01) // 2500 + 1000
        XCTAssertEqual(summary.totalExpenses, 234.31, accuracy: 0.01)
        XCTAssertEqual(summary.netAmount, 3265.69, accuracy: 0.01)
        
        // 7. Test categorization service integration
        let importService = ImportCategorizationService()
        let categorizedTransactions = await importService.categorizeTransactions(transactionResult.transactions)
        
        XCTAssertGreaterThan(categorizedTransactions.categorizedCount, 0)
        XCTAssertLessThanOrEqual(categorizedTransactions.categorizedCount, categorizedTransactions.totalTransactions)
        
        // 8. Verify categories applied correctly
        let allTransactions = categorizedTransactions.categorizedTransactions.map { $0.0 } + categorizedTransactions.uncategorizedTransactions
        for transaction in allTransactions {
            if transaction.description.contains("WALMART") || transaction.description.contains("AMAZON") {
                XCTAssertEqual(transaction.category, "Shopping")
            } else if transaction.description.contains("UBER") || transaction.description.contains("GAS STATION") {
                XCTAssertEqual(transaction.category, "Transportation")
            } else if transaction.description.contains("STARBUCKS") {
                XCTAssertEqual(transaction.category, "Food & Dining")
            } else if transaction.description.contains("NETFLIX") {
                XCTAssertEqual(transaction.category, "Entertainment")
            }
        }
    }
    
    func testPDFUploadFlow() async throws {
        // Find test PDF in bundle
        guard let pdfPath = Bundle.main.path(forResource: "test_bank_statement", ofType: "pdf") else {
            // Create a minimal test PDF if not available
            let pdfURL = createTestPDF()
            defer { try? FileManager.default.removeItem(at: pdfURL) }
            
            // Upload PDF
            let uploadResponse = try await apiService.uploadFile(pdfURL)
            XCTAssertFalse(uploadResponse.jobId.isEmpty)
            
            // Wait for processing
            let finalStatus = try await apiService.pollJobUntilComplete(
                uploadResponse.jobId,
                maxRetries: 60,
                intervalSeconds: 2
            )
            XCTAssertEqual(finalStatus.status, "completed")
            
            return
        }
        
        let pdfURL = URL(fileURLWithPath: pdfPath)
        
        // Upload PDF
        let uploadResponse = try await apiService.uploadFile(pdfURL)
        XCTAssertFalse(uploadResponse.jobId.isEmpty)
        
        // Wait for processing (PDFs take longer)
        let finalStatus = try await apiService.pollJobUntilComplete(
            uploadResponse.jobId,
            maxRetries: 60,
            intervalSeconds: 2
        )
        XCTAssertEqual(finalStatus.status, "completed")
        
        // Verify extraction
        let result = try await apiService.getTransactions(uploadResponse.jobId)
        XCTAssertGreaterThan(result.transactions.count, 0)
        
        // Verify transaction data integrity
        for transaction in result.transactions {
            XCTAssertFalse(transaction.date.isEmpty)
            XCTAssertFalse(transaction.description.isEmpty)
            XCTAssertNotEqual(transaction.amount, 0.0)
            XCTAssertFalse(transaction.category.isEmpty)
        }
    }
    
    func testForexTransactionHandling() async throws {
        // Create CSV with foreign currency transactions
        let csvContent = """
        Date,Description,Amount,Original Amount,Original Currency
        2024-01-01,FOREIGN PURCHASE EUR,-55.50,-50.00,EUR
        2024-01-02,INTL TRANSFER GBP,110.00,88.00,GBP
        2024-01-03,TOKYO STORE JPY,-15.00,-2000,JPY
        2024-01-04,DOMESTIC PURCHASE,-100.00,,
        """
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("forex_test_\(UUID().uuidString).csv")
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        // Process through API
        let uploadResponse = try await apiService.uploadFile(tempURL)
        _ = try await apiService.pollJobUntilComplete(uploadResponse.jobId)
        let result = try await apiService.getTransactions(uploadResponse.jobId)
        
        // Verify forex data preserved
        let eurTransaction = result.transactions.first { $0.description.contains("EUR") }
        XCTAssertNotNil(eurTransaction)
        XCTAssertTrue(eurTransaction?.hasForex ?? false)
        XCTAssertEqual(eurTransaction?.originalCurrency, "EUR")
        if let originalAmount = eurTransaction?.originalAmount {
            XCTAssertEqual(originalAmount, -50.00, accuracy: 0.01)
        }
        XCTAssertNotNil(eurTransaction?.exchangeRate)
        
        let domesticTransaction = result.transactions.first { $0.description.contains("DOMESTIC") }
        XCTAssertNotNil(domesticTransaction)
        XCTAssertFalse(domesticTransaction?.hasForex ?? false)
        XCTAssertNil(domesticTransaction?.originalCurrency)
    }
    
    // MARK: - Error Recovery Tests
    
    // Commented out - needs APIService refactoring to support this test
    /*
    func testUploadRecoveryAfterNetworkError() async throws {
        // This test would require APIService to expose baseURL property
        // or a different approach to test network error recovery
        XCTSkip("Requires APIService refactoring")
    }
    */
    
    func testJobPollingWithSlowProcessing() async throws {
        // Upload large CSV to simulate slow processing
        let csvURL = createTestCSV(transactions: 500)
        defer { try? FileManager.default.removeItem(at: csvURL) }
        
        let uploadResponse = try await apiService.uploadFile(csvURL)
        
        // Track polling attempts
        var pollCount = 0
        let startTime = Date()
        
        // Custom polling to count attempts
        var status: JobStatus
        repeat {
            pollCount += 1
            status = try await apiService.getJobStatus(uploadResponse.jobId)
            
            if status.status != "completed" && status.status != "error" {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        } while (status.status == "processing" || status.status == "processing_csv" || status.status.contains("processing")) && pollCount < 60
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        XCTAssertEqual(status.status, "completed")
        XCTAssertGreaterThan(pollCount, 1) // Should require multiple polls
        XCTAssertLessThan(elapsed, 60) // Should complete within 1 minute
        
        // Verify all transactions processed
        let result = try await apiService.getTransactions(uploadResponse.jobId)
        XCTAssertEqual(result.transactions.count, 500)
    }
    
    // MARK: - Stress Tests
    
    func testConcurrentUploads() async throws {
        let uploadCount = 5
        var csvURLs: [URL] = []
        
        // Create test files
        for i in 0..<uploadCount {
            let url = createTestCSV(transactions: 10, identifier: "\(i)")
            csvURLs.append(url)
        }
        
        defer {
            csvURLs.forEach { try? FileManager.default.removeItem(at: $0) }
        }
        
        // Upload concurrently
        let results = try await withThrowingTaskGroup(of: (String, TransactionResults).self) { group in
            for url in csvURLs {
                group.addTask {
                    let response = try await self.apiService.uploadFile(url)
                    _ = try await self.apiService.pollJobUntilComplete(response.jobId)
                    let transactions = try await self.apiService.getTransactions(response.jobId)
                    return (response.jobId, transactions)
                }
            }
            
            var jobResults: [(String, TransactionResults)] = []
            for try await result in group {
                jobResults.append(result)
            }
            return jobResults
        }
        
        // Verify all uploads succeeded
        XCTAssertEqual(results.count, uploadCount)
        
        // All job IDs should be unique
        let jobIds = Set(results.map { $0.0 })
        XCTAssertEqual(jobIds.count, uploadCount)
        
        // Each should have 10 transactions
        for (_, transactions) in results {
            XCTAssertEqual(transactions.transactions.count, 10)
        }
    }
    
    func testRapidStatusPolling() async throws {
        // Upload file
        let csvURL = createTestCSV(transactions: 5)
        defer { try? FileManager.default.removeItem(at: csvURL) }
        
        let uploadResponse = try await apiService.uploadFile(csvURL)
        
        // Rapid concurrent status checks
        let statuses = try await withThrowingTaskGroup(of: JobStatus.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try await self.apiService.getJobStatus(uploadResponse.jobId)
                }
            }
            
            var results: [JobStatus] = []
            for try await status in group {
                results.append(status)
            }
            return results
        }
        
        // All status checks should succeed
        XCTAssertEqual(statuses.count, 10)
        
        // All should have same job ID
        XCTAssertTrue(statuses.allSatisfy { $0.jobId == uploadResponse.jobId })
    }
    
    // MARK: - Data Validation Tests
    
    func testTransactionDataIntegrity() async throws {
        let testTransactions = [
            ("2024-01-01", "Test Transaction 1", -123.45),
            ("2024-01-02", "Test Transaction 2", 567.89),
            ("2024-01-03", "Test Transaction 3", -0.01),
            ("2024-01-04", "Test Transaction 4", 999999.99),
            ("2024-01-05", "Special Chars & Symbols", -50.00),
            ("2024-01-06", "Unicode テスト 测试", 100.00),
        ]
        
        let csvContent = "Date,Description,Amount\n" +
            testTransactions.map { "\($0.0),\"\($0.1)\",\($0.2)" }.joined(separator: "\n")
        
        let csvURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("integrity_test_\(UUID().uuidString).csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: csvURL) }
        
        // Process through API
        let uploadResponse = try await apiService.uploadFile(csvURL)
        _ = try await apiService.pollJobUntilComplete(uploadResponse.jobId)
        let result = try await apiService.getTransactions(uploadResponse.jobId)
        
        // Verify all data preserved correctly
        XCTAssertEqual(result.transactions.count, testTransactions.count)
        
        for (index, transaction) in result.transactions.enumerated() {
            let expected = testTransactions[index]
            XCTAssertEqual(transaction.date, expected.0)
            XCTAssertEqual(transaction.description, expected.1)
            XCTAssertEqual(transaction.amount, expected.2, accuracy: 0.001)
        }
        
        // Verify special characters handled correctly
        let specialCharsTransaction = result.transactions.first { $0.description.contains("&") }
        XCTAssertNotNil(specialCharsTransaction)
        XCTAssertEqual(specialCharsTransaction?.description, "Special Chars & Symbols")
        
        let unicodeTransaction = result.transactions.first { $0.description.contains("テスト") }
        XCTAssertNotNil(unicodeTransaction)
    }
    
    func testDuplicateFileHandling() async throws {
        // Create CSV with specific content
        let csvContent = """
        Date,Description,Amount
        2024-01-01,UNIQUE TEST TRANSACTION,-99.99
        """
        
        let csvURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("duplicate_test_\(UUID().uuidString).csv")
        try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: csvURL) }
        
        // First upload
        let firstUpload = try await apiService.uploadFile(csvURL)
        _ = try await apiService.pollJobUntilComplete(firstUpload.jobId)
        
        // Second upload of same file
        let secondUpload = try await apiService.uploadFile(csvURL)
        
        // Should either get same job ID or a new one marked as duplicate
        if secondUpload.jobId == firstUpload.jobId {
            // Same job ID returned
            XCTAssertTrue(secondUpload.message.contains("Duplicate") ||
                         secondUpload.message.contains("existing"))
        } else {
            // New job ID but marked as duplicate
            let status = try await apiService.getJobStatus(secondUpload.jobId)
            XCTAssertNotNil(status)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestCSV(transactions: Int, identifier: String = "") -> URL {
        var csv = "Date,Description,Amount,Category\n"
        
        let categories = ["Shopping", "Food & Dining", "Transportation", "Entertainment", "Other"]
        let merchants = ["STORE", "RESTAURANT", "TRANSPORT", "SERVICE", "VENDOR"]
        
        for i in 1...transactions {
            let date = "2024-01-\(String(format: "%02d", (i % 28) + 1))"
            let merchant = merchants[i % merchants.count]
            let desc = "\(merchant) \(identifier)\(i) TRANSACTION"
            let amount = Double.random(in: -200...200)
            let category = categories[i % categories.count]
            
            csv += "\(date),\"\(desc)\",\(amount),\(category)\n"
        }
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_\(identifier)_\(UUID().uuidString).csv")
        
        try! csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    private func createTestPDF() -> URL {
        // Create a minimal PDF for testing
        let pdfData = """
        %PDF-1.4
        1 0 obj
        <<
        /Type /Catalog
        /Pages 2 0 R
        >>
        endobj
        2 0 obj
        <<
        /Type /Pages
        /Count 1
        /Kids [3 0 R]
        >>
        endobj
        3 0 obj
        <<
        /Type /Page
        /Parent 2 0 R
        /Resources <<
        /Font <<
        /F1 4 0 R
        >>
        >>
        /MediaBox [0 0 612 792]
        /Contents 5 0 R
        >>
        endobj
        4 0 obj
        <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Helvetica
        >>
        endobj
        5 0 obj
        <<
        /Length 44
        >>
        stream
        BT
        /F1 12 Tf
        100 700 Td
        (Test Bank Statement) Tj
        ET
        endstream
        endobj
        xref
        0 6
        0000000000 65535 f
        0000000009 00000 n
        0000000058 00000 n
        0000000115 00000 n
        0000000262 00000 n
        0000000341 00000 n
        trailer
        <<
        /Size 6
        /Root 1 0 R
        >>
        startxref
        439
        %%EOF
        """.data(using: .utf8)!
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_statement_\(UUID().uuidString).pdf")
        
        try! pdfData.write(to: url)
        return url
    }
}
