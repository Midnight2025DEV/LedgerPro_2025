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
    
    // Health check is now handled differently in the actual API
    func simulateHealthCheck() async {
        healthCheckCallCount += 1
        if shouldFailHealthCheck {
            isHealthy = false
        } else {
            isHealthy = true
        }
    }
    
    override func uploadFile(_ fileURL: URL) async throws -> UploadResponse {
        uploadCallCount += 1
        
        if shouldFailUpload {
            throw APIError.networkError("Mock upload failure")
        }
        
        // Simulate successful upload
        uploadProgress = 0.5
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        uploadProgress = 1.0
        
        return UploadResponse(
            jobId: mockJobId,
            status: "processing",
            message: "File uploaded successfully"
        )
    }
    
    override func getJobStatus(_ jobId: String) async throws -> JobStatus {
        // Return mock job status
        return JobStatus(
            jobId: jobId,
            status: "completed",
            progress: 100,
            filename: "test.csv",
            createdAt: "2024-01-01T00:00:00",
            completedAt: "2024-01-01T00:01:00",
            error: nil
        )
    }
    
    override func getTransactions(_ jobId: String) async throws -> TransactionResults {
        // Return mock transactions
        let transactions = mockTransactions.isEmpty ? [
            Transaction(
                id: "mock-1",
                date: "2024-01-01",
                description: "STARBUCKS",
                amount: -5.50,
                category: "Food & Dining",
                confidence: 0.95,
                accountId: "test-account-1"
            ),
            Transaction(
                id: "mock-2",
                date: "2024-01-02",
                description: "UBER RIDE",
                amount: -25.00,
                category: "Transportation",
                confidence: 0.90,
                accountId: "test-account-1"
            ),
            Transaction(
                id: "mock-3",
                date: "2024-01-03",
                description: "SALARY DEPOSIT",
                amount: 3000.00,
                category: "Income",
                confidence: 1.0,
                accountId: "test-account-1"
            )
        ] : mockTransactions
        
        return TransactionResults(
            jobId: jobId,
            status: "completed",
            transactions: transactions,
            account: APIAccount(
                id: "test-account-1",
                name: "Test Account",
                institution: "Test Bank",
                accountType: "checking",
                identifier: "1234",
                isNew: false
            ),
            metadata: TransactionResults.Metadata(
                filename: "test.csv",
                totalTransactions: transactions.count,
                processingTime: "0.1s"
            ),
            summary: TransactionResults.Summary(
                totalIncome: transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount },
                totalExpenses: abs(transactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount }),
                netAmount: transactions.reduce(0) { $0 + $1.amount },
                transactionCount: transactions.count
            )
        )
    }
    
    // pollJobUntilComplete was removed from the main APIService
    func simulatePollJobUntilComplete(_ jobId: String, maxAttempts: Int = 60) async throws -> JobStatus {
        // Return completed status immediately for tests
        return JobStatus(
            jobId: jobId,
            status: "completed",
            progress: 100,
            filename: "test.csv",
            createdAt: "2024-01-01T00:00:00",
            completedAt: "2024-01-01T00:01:00",
            error: nil
        )
    }
}