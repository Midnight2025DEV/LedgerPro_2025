import Foundation
@testable import LedgerPro

/// Mock API Service for testing without requiring backend server
@MainActor
class MockAPIService: APIService {
    var shouldFailHealthCheck = false
    var shouldFailUpload = false
    var mockJobId = "mock-job-\(UUID().uuidString)"
    var mockTransactions: [Transaction] = []
    var uploadCallCount = 0
    var healthCheckCallCount = 0
    
    override func checkHealth() async {
        healthCheckCallCount += 1
        if shouldFailHealthCheck {
            isHealthy = false
            healthStatus = HealthStatus(status: "error", version: "1.0.0", services: [:])
        } else {
            isHealthy = true
            healthStatus = HealthStatus(status: "healthy", version: "1.0.0", services: [
                "pdf_processor": true,
                "csv_processor": true,
                "database": true
            ])
        }
    }
    
    override func uploadFile(_ fileURL: URL) async throws -> String {
        uploadCallCount += 1
        
        if shouldFailUpload {
            throw APIError.uploadFailed("Mock upload failure")
        }
        
        // Simulate successful upload
        uploadProgress = 0.5
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        uploadProgress = 1.0
        
        return mockJobId
    }
    
    override func getJobStatus(_ jobId: String) async throws -> JobStatus {
        // Return mock job status
        return JobStatus(
            jobId: jobId,
            status: "completed",
            progress: 100,
            filename: "test.csv",
            message: "Processing complete",
            transactionCount: mockTransactions.count,
            error: nil
        )
    }
    
    override func getTransactions(_ jobId: String) async throws -> [Transaction] {
        // Return mock transactions
        if mockTransactions.isEmpty {
            // Generate default test transactions
            return [
                Transaction(
                    id: "mock-1",
                    date: "2024-01-01",
                    description: "STARBUCKS",
                    amount: -5.50,
                    category: "Food & Dining",
                    account: "Test Account",
                    tags: ["coffee"],
                    confidence: 0.95
                ),
                Transaction(
                    id: "mock-2",
                    date: "2024-01-02",
                    description: "UBER RIDE",
                    amount: -25.00,
                    category: "Transportation",
                    account: "Test Account",
                    tags: ["rideshare"],
                    confidence: 0.90
                ),
                Transaction(
                    id: "mock-3",
                    date: "2024-01-03",
                    description: "SALARY DEPOSIT",
                    amount: 3000.00,
                    category: "Income",
                    account: "Test Account",
                    tags: ["paycheck"],
                    confidence: 1.0
                )
            ]
        }
        return mockTransactions
    }
    
    override func pollJobUntilComplete(_ jobId: String, maxAttempts: Int = 60) async throws -> JobStatus {
        // Return completed status immediately for tests
        return JobStatus(
            jobId: jobId,
            status: "completed",
            progress: 100,
            filename: "test.csv",
            message: "Processing complete",
            transactionCount: mockTransactions.isEmpty ? 3 : mockTransactions.count,
            error: nil
        )
    }
}

// MARK: - Mock URL Session for isolated testing
class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        let data = mockData ?? Data()
        let response = mockResponse ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (data, response)
    }
}