import XCTest
@testable import LedgerPro


@MainActor
final class APIServiceTests: XCTestCase {
    var sut: APIService!
    var testFileURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create API service
        sut = APIService()
        
        // Setup test environment
        setupTestFile()
    }
    
    override func tearDown() async throws {
        // Clean up test file
        if let testFileURL = testFileURL {
            try? FileManager.default.removeItem(at: testFileURL)
        }
        
        // Clean up auth token
        UserDefaults.standard.removeObject(forKey: "auth_token")
        
        sut = nil
        testFileURL = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Setup Helpers
    
    private func setupTestFile() {
        // Create a temporary test file
        let tempDir = FileManager.default.temporaryDirectory
        testFileURL = tempDir.appendingPathComponent("test_\(UUID().uuidString).csv")
        
        let testContent = """
        Date,Description,Amount
        2024-01-01,STARBUCKS COFFEE,-5.50
        2024-01-02,SALARY DEPOSIT,3000.00
        2024-01-03,UBER RIDE,-25.00
        """
        
        do {
            try testContent.write(to: testFileURL, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("Failed to create test file: \(error)")
        }
    }
    
    // MARK: - Service Initialization Tests
    
    func testAPIService_initialization_setsDefaultValues() {
        // Given/When - Service initialized in setUp
        
        // Then
        XCTAssertFalse(sut.isHealthy)
        XCTAssertFalse(sut.isUploading)
        XCTAssertEqual(sut.uploadProgress, 0.0)
        XCTAssertNil(sut.lastError)
    }
    
    func testAPIService_initialization_loadsAuthToken() {
        // Given
        UserDefaults.standard.set("test-token-123", forKey: "auth_token")
        
        // When
        let serviceWithToken = APIService()
        
        // Then
        XCTAssertTrue(serviceWithToken.isAuthenticated)
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    // MARK: - Authentication Tests
    
    func testIsAuthenticated_withToken_returnsTrue() {
        // Given
        UserDefaults.standard.set("test-token-123", forKey: "auth_token")
        let apiService = APIService()
        
        // When/Then
        XCTAssertTrue(apiService.isAuthenticated)
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    func testIsAuthenticated_withoutToken_returnsFalse() {
        // Given
        UserDefaults.standard.removeObject(forKey: "auth_token")
        let apiService = APIService()
        
        // When/Then
        XCTAssertFalse(apiService.isAuthenticated)
    }
    
    func testAuthToken_persistsAcrossInstances() {
        // Given
        UserDefaults.standard.set("persistent-token", forKey: "auth_token")
        
        // When
        let firstInstance = APIService()
        let secondInstance = APIService()
        
        // Then
        XCTAssertTrue(firstInstance.isAuthenticated)
        XCTAssertTrue(secondInstance.isAuthenticated)
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    // MARK: - File Handling Tests
    
    func testUploadFile_withValidFile_attemptsUpload() async {
        // Given - File exists and has content
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))
        
        // When - Attempt upload (will fail due to no server, but should not crash)
        do {
            let _ = try await sut.uploadFile(testFileURL)
            // If we reach here, that's unexpected since no server is running
            XCTFail("Upload should have failed due to no server")
        } catch {
            // Then - Should fail gracefully with a network error
            XCTAssertTrue(error.localizedDescription.contains("network") || 
                         error.localizedDescription.contains("connect") ||
                         error.localizedDescription.contains("server"))
        }
    }
    
    func testUploadFile_withNonExistentFile_throwsError() async {
        // Given
        let nonExistentFile = URL(fileURLWithPath: "/non/existent/file.csv")
        
        // When/Then
        do {
            _ = try await sut.uploadFile(nonExistentFile)
            XCTFail("Should have thrown an error for non-existent file")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("read") || 
                         error.localizedDescription.contains("file"))
        }
    }
    
    func testUploadFile_withEmptyFile_handlesCorrectly() async {
        // Given - Empty file
        let emptyFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("empty_\(UUID().uuidString).csv")
        
        do {
            try "".write(to: emptyFileURL, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("Failed to create empty test file")
            return
        }
        
        defer {
            try? FileManager.default.removeItem(at: emptyFileURL)
        }
        
        // When/Then
        do {
            _ = try await sut.uploadFile(emptyFileURL)
            XCTFail("Upload should have failed")
        } catch {
            // Should fail gracefully (either due to empty file or network error)
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - State Management Tests
    
    func testUploadProgress_initialValue() {
        // Given/When - Fresh service
        
        // Then
        XCTAssertEqual(sut.uploadProgress, 0.0)
        XCTAssertFalse(sut.isUploading)
    }
    
    func testHealthStatus_initialValue() {
        // Given/When - Fresh service
        
        // Then
        XCTAssertFalse(sut.isHealthy)
        XCTAssertNil(sut.lastError)
    }
    
    func testHealthCheck_failure_updatesState() async {
        // Given - No server running
        let initialError = sut.lastError
        
        // When
        do {
            _ = try await sut.healthCheck()
            XCTFail("Health check should have failed (no server)")
        } catch {
            // Then
            XCTAssertFalse(sut.isHealthy)
            XCTAssertNotNil(sut.lastError)
            XCTAssertNotEqual(sut.lastError, initialError)
        }
    }
    
    // MARK: - Model Tests
    
    func testHealthStatus_decodingFromJSON() throws {
        // Given
        let json = """
        {
            "status": "healthy",
            "timestamp": "2024-01-01T12:00:00Z",
            "version": "1.0.0",
            "message": "API is running",
            "processor": "camelot"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        
        // When
        let health = try JSONDecoder().decode(HealthStatus.self, from: data)
        
        // Then
        XCTAssertEqual(health.status, "healthy")
        XCTAssertEqual(health.timestamp, "2024-01-01T12:00:00Z")
        XCTAssertEqual(health.version, "1.0.0")
        XCTAssertEqual(health.message, "API is running")
        XCTAssertEqual(health.processor, "camelot")
    }
    
    func testUploadResponse_decodingFromJSON() throws {
        // Given
        let json = """
        {
            "job_id": "test-job-123",
            "status": "queued",
            "message": "File uploaded successfully"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        
        // When
        let response = try JSONDecoder().decode(UploadResponse.self, from: data)
        
        // Then
        XCTAssertEqual(response.jobId, "test-job-123")
        XCTAssertEqual(response.status, "queued")
        XCTAssertEqual(response.message, "File uploaded successfully")
    }
    
    func testJobStatus_decodingFromJSON() throws {
        // Given
        let json = """
        {
            "job_id": "test-job-123",
            "status": "completed",
            "progress": 100.0,
            "filename": "test.csv",
            "created_at": "2024-01-01T12:00:00Z",
            "completed_at": "2024-01-01T12:01:00Z",
            "error": null
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        
        // When
        let status = try JSONDecoder().decode(JobStatus.self, from: data)
        
        // Then
        XCTAssertEqual(status.jobId, "test-job-123")
        XCTAssertEqual(status.status, "completed")
        XCTAssertEqual(status.progress, 100.0)
        XCTAssertEqual(status.filename, "test.csv")
        XCTAssertEqual(status.createdAt, "2024-01-01T12:00:00Z")
        XCTAssertEqual(status.completedAt, "2024-01-01T12:01:00Z")
        XCTAssertNil(status.error)
    }
    
    func testJobStatus_withError_decodingFromJSON() throws {
        // Given
        let json = """
        {
            "job_id": "failed-job-456",
            "status": "error",
            "progress": 0.0,
            "filename": "invalid.csv",
            "created_at": "2024-01-01T12:00:00Z",
            "completed_at": null,
            "error": "Invalid file format"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        
        // When
        let status = try JSONDecoder().decode(JobStatus.self, from: data)
        
        // Then
        XCTAssertEqual(status.jobId, "failed-job-456")
        XCTAssertEqual(status.status, "error")
        XCTAssertEqual(status.progress, 0.0)
        XCTAssertEqual(status.filename, "invalid.csv")
        XCTAssertEqual(status.error, "Invalid file format")
        XCTAssertNil(status.completedAt)
    }
    
    func testTransactionResults_decodingFromJSON() throws {
        // Given
        let json = """
        {
            "job_id": "test-job-123",
            "status": "completed",
            "transactions": [
                {
                    "id": "txn-1",
                    "date": "2024-01-01",
                    "description": "STARBUCKS COFFEE",
                    "amount": -5.50,
                    "category": "Food & Dining",
                    "original_amount": -4.50,
                    "original_currency": "EUR",
                    "exchange_rate": 1.22,
                    "has_forex": true
                }
            ],
            "account": {
                "id": "acc-1",
                "name": "Checking Account",
                "institution": "Test Bank",
                "account_type": "checking",
                "identifier": "1234",
                "is_new": true
            },
            "metadata": {
                "filename": "test.csv",
                "total_transactions": 1,
                "processing_time": "1.5s"
            },
            "summary": {
                "total_income": 0.00,
                "total_expenses": 5.50,
                "net_amount": -5.50,
                "transaction_count": 1
            }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        
        // When
        let results = try JSONDecoder().decode(TransactionResults.self, from: data)
        
        // Then
        XCTAssertEqual(results.jobId, "test-job-123")
        XCTAssertEqual(results.status, "completed")
        XCTAssertEqual(results.transactions.count, 1)
        
        // Test transaction
        let transaction = results.transactions[0]
        XCTAssertEqual(transaction.description, "STARBUCKS COFFEE")
        XCTAssertEqual(transaction.amount, -5.50)
        XCTAssertEqual(transaction.originalAmount, -4.50)
        XCTAssertEqual(transaction.originalCurrency, "EUR")
        XCTAssertEqual(transaction.exchangeRate, 1.22)
        XCTAssertEqual(transaction.hasForex, true)
        
        // Test account
        let account = try XCTUnwrap(results.account)
        XCTAssertEqual(account.name, "Checking Account")
        XCTAssertEqual(account.institution, "Test Bank")
        XCTAssertEqual(account.accountType, "checking")
        XCTAssertEqual(account.identifier, "1234")
        XCTAssertTrue(account.isNew)
        
        // Test metadata
        XCTAssertEqual(results.metadata.filename, "test.csv")
        XCTAssertEqual(results.metadata.totalTransactions, 1)
        XCTAssertEqual(results.metadata.processingTime, "1.5s")
        
        // Test summary
        XCTAssertEqual(results.summary.totalIncome, 0.00)
        XCTAssertEqual(results.summary.totalExpenses, 5.50)
        XCTAssertEqual(results.summary.netAmount, -5.50)
        XCTAssertEqual(results.summary.transactionCount, 1)
    }
    
    func testAPIAccount_decodingFromJSON() throws {
        // Given
        let json = """
        {
            "id": "acc-123",
            "name": "My Checking",
            "institution": "Chase Bank",
            "account_type": "checking",
            "identifier": "5678",
            "is_new": false
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        
        // When
        let account = try JSONDecoder().decode(APIAccount.self, from: data)
        
        // Then
        XCTAssertEqual(account.id, "acc-123")
        XCTAssertEqual(account.name, "My Checking")
        XCTAssertEqual(account.institution, "Chase Bank")
        XCTAssertEqual(account.accountType, "checking")
        XCTAssertEqual(account.identifier, "5678")
        XCTAssertFalse(account.isNew)
    }
    
    // MARK: - Error Type Tests
    
    func testAPIError_networkError_hasCorrectDescription() {
        // Given
        let error = APIError.networkError("Connection failed")
        
        // When/Then
        XCTAssertEqual(error.errorDescription, "Network Error: Connection failed")
    }
    
    func testAPIError_httpError_hasCorrectDescription() {
        // Given
        let error = APIError.httpError(404, "Not found")
        
        // When/Then
        XCTAssertEqual(error.errorDescription, "HTTP 404: Not found")
    }
    
    func testAPIError_uploadError_hasCorrectDescription() {
        // Given
        let error = APIError.uploadError("File too large")
        
        // When/Then
        XCTAssertEqual(error.errorDescription, "Upload Error: File too large")
    }
    
    func testAPIError_timeout_hasCorrectDescription() {
        // Given
        let error = APIError.timeout("Request timed out")
        
        // When/Then
        XCTAssertEqual(error.errorDescription, "Timeout: Request timed out")
    }
    
    // MARK: - Published Property Tests
    
    func testPublishedProperties_initialValues() {
        // Given/When - Fresh service
        
        // Then - Test that @Published properties have correct initial values
        XCTAssertFalse(sut.isHealthy)
        XCTAssertFalse(sut.isUploading)
        XCTAssertEqual(sut.uploadProgress, 0.0)
        XCTAssertNil(sut.lastError)
    }
    
    func testPublishedProperties_observability() async {
        // Given
        var healthUpdates: [Bool] = []
        var progressUpdates: [Double] = []
        var uploadingUpdates: [Bool] = []
        var errorUpdates: [String?] = []
        
        let healthObserver = sut.$isHealthy.sink { healthUpdates.append($0) }
        let progressObserver = sut.$uploadProgress.sink { progressUpdates.append($0) }
        let uploadingObserver = sut.$isUploading.sink { uploadingUpdates.append($0) }
        let errorObserver = sut.$lastError.sink { errorUpdates.append($0) }
        
        // When - Trigger a health check (will fail but should update state)
        do {
            _ = try await sut.healthCheck()
        } catch {
            // Expected to fail
        }
        
        // Give a moment for published values to update
        do {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        } catch {
            // Ignore sleep errors in tests
        }
        
        // Then
        XCTAssertGreaterThan(healthUpdates.count, 1) // Should have initial + updated value
        XCTAssertGreaterThan(errorUpdates.count, 1) // Should have initial + error value
        
        // Cleanup observers
        healthObserver.cancel()
        progressObserver.cancel()
        uploadingObserver.cancel()
        errorObserver.cancel()
    }
    
    // MARK: - Integration Tests (Without Network)
    
    func testFileReading_withValidCSV_readsCorrectly() throws {
        // Given - Test file created in setUp
        
        // When
        let fileData = try Data(contentsOf: testFileURL)
        let fileContent = String(data: fileData, encoding: .utf8)
        
        // Then
        XCTAssertNotNil(fileContent)
        XCTAssertTrue(fileContent!.contains("STARBUCKS COFFEE"))
        XCTAssertTrue(fileContent!.contains("SALARY DEPOSIT"))
        XCTAssertTrue(fileContent!.contains("UBER RIDE"))
    }
    
    func testFileAttributes_withValidFile_hasCorrectProperties() throws {
        // Given - Test file created in setUp
        
        // When
        let attributes = try FileManager.default.attributesOfItem(atPath: testFileURL.path)
        
        // Then
        XCTAssertNotNil(attributes[.size])
        if let size = attributes[.size] as? NSNumber {
            XCTAssertGreaterThan(size.intValue, 0)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))
        XCTAssertTrue(FileManager.default.isReadableFile(atPath: testFileURL.path))
    }
    
    // MARK: - Edge Case Tests
    
    func testGetJobStatus_invalidJobId_failsGracefully() async {
        // Given - Invalid job ID
        let invalidJobId = "non-existent-job-12345"
        
        // When/Then
        do {
            _ = try await sut.getJobStatus(invalidJobId)
            XCTFail("Should have failed with invalid job ID")
        } catch {
            // Expected to fail gracefully
            XCTAssertNotNil(error)
        }
    }
    
    func testGetTransactions_invalidJobId_failsGracefully() async {
        // Given - Invalid job ID
        let invalidJobId = "non-existent-job-12345"
        
        // When/Then
        do {
            _ = try await sut.getTransactions(invalidJobId)
            XCTFail("Should have failed with invalid job ID")
        } catch {
            // Expected to fail gracefully
            XCTAssertNotNil(error)
        }
    }
    
    func testPollJobUntilComplete_invalidJobId_failsGracefully() async {
        // Given - Invalid job ID
        let invalidJobId = "non-existent-job-12345"
        
        // When/Then
        do {
            _ = try await sut.pollJobUntilComplete(invalidJobId, maxRetries: 1, intervalSeconds: 1)
            XCTFail("Should have failed with invalid job ID")
        } catch {
            // Expected to fail gracefully
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Performance Tests
    
    func testMultipleFileCreation_performance() {
        // Given - Test creating multiple temporary files
        var fileURLs: [URL] = []
        
        let startTime = Date()
        
        // When - Create 10 temporary files
        for i in 0..<10 {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("perf_test_\(i)_\(UUID().uuidString).csv")
            
            do {
                try "test,data\n1,2".write(to: tempURL, atomically: true, encoding: .utf8)
                fileURLs.append(tempURL)
            } catch {
                XCTFail("Failed to create test file \(i): \(error)")
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertEqual(fileURLs.count, 10)
        XCTAssertLessThan(duration, 1.0, "Creating 10 files should take less than 1 second")
        
        // Cleanup
        for url in fileURLs {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func testJSONDecoding_performance() throws {
        // Given - Large JSON string
        let largeJSON = """
        {
            "job_id": "test-job-123",
            "status": "completed",
            "transactions": [
                \(Array(repeating: """
                {
                    "id": "txn-1",
                    "date": "2024-01-01",
                    "description": "TEST TRANSACTION",
                    "amount": -10.00,
                    "category": "Other"
                }
                """, count: 100).joined(separator: ","))
            ],
            "account": null,
            "metadata": {
                "filename": "test.csv",
                "total_transactions": 100,
                "processing_time": "1.0s"
            },
            "summary": {
                "total_income": 0.00,
                "total_expenses": 1000.00,
                "net_amount": -1000.00,
                "transaction_count": 100
            }
        }
        """
        let data = try XCTUnwrap(largeJSON.data(using: .utf8))
        
        // When
        let startTime = Date()
        let results = try JSONDecoder().decode(TransactionResults.self, from: data)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertEqual(results.transactions.count, 100)
        XCTAssertLessThan(duration, 0.5, "Decoding 100 transactions should take less than 0.5 seconds")
    }
}