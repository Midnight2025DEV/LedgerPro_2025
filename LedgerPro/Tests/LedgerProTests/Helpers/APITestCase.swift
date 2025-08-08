import XCTest
@testable import LedgerPro

/// Base test case for tests that need API functionality
/// Uses MockAPIService to avoid requiring backend server
@MainActor
class APITestCase: XCTestCase {
    var mockAPIService: MockAPIService!
    var originalAPIService: APIService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock API service
        mockAPIService = MockAPIService()
        
        // Store original if needed for restoration
        // Note: In actual implementation, we'd need dependency injection
        // For now, tests should use mockAPIService directly
    }
    
    override func tearDown() async throws {
        mockAPIService = nil
        originalAPIService = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    func createTestFile(content: String? = nil) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_\(UUID().uuidString).csv")
        
        let testContent = content ?? """
        Date,Description,Amount
        2024-01-01,STARBUCKS COFFEE,-5.50
        2024-01-02,SALARY DEPOSIT,3000.00
        2024-01-03,UBER RIDE,-25.00
        """
        
        try! testContent.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    func cleanupTestFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Test Environment Checker
extension XCTestCase {
    /// Check if backend is available for integration tests
    func isBackendAvailable() async -> Bool {
        let testService = APIService()
        await testService.checkHealth()
        return testService.isHealthy
    }
    
    /// Skip test if backend is not available
    func skipIfNoBackend() async throws {
        guard await isBackendAvailable() else {
            throw XCTSkip("Backend server not available - skipping integration test")
        }
    }
}