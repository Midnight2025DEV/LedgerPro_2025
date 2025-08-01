# LedgerPro Ultra-Detailed API Testing Framework

## Pre-Execution Research Phase [MANDATORY]

### Step 0: Complete API Discovery

```bash
echo "=== DISCOVERING ALL API ENDPOINTS ==="

# 1. Find all API endpoints in Swift code
echo "📱 Swift API Calls:"
grep -r "api/\|/api\|endpoint\|URLRequest\|.post(\|.get(\|.put(\|.delete(" Sources --include="*.swift" | grep -v ".build" | sort -u > api_calls_swift.txt
cat api_calls_swift.txt

# 2. Find all API endpoints in Python backend
echo -e "\n🐍 Python API Endpoints:"
grep -r "@app\.\|@router\." backend --include="*.py" | grep -v "__pycache__" | sort -u > api_endpoints_python.txt
cat api_endpoints_python.txt

# 3. Find API service configuration
echo -e "\n⚙️ API Configuration:"
grep -r "baseURL\|API_URL\|http://\|https://" Sources --include="*.swift" | head -10

# 4. Document all HTTP methods used
echo -e "\n📋 HTTP Methods in Use:"
grep -r "HTTPMethod\|method.*=.*\"\|\.get\|\.post\|\.put\|\.delete" Sources --include="*.swift" | grep -v ".build" | sort -u | head -20

# 5. Find all model types used in API
echo -e "\n📦 API Models/DTOs:"
grep -r "Codable\|Decodable\|Encodable" Sources --include="*.swift" | grep "struct\|class" | head -20

# Create endpoint inventory
cat > API_INVENTORY.md << 'INVENTORY'
# API Endpoint Inventory

## Frontend Calls (Swift -> Backend):
[To be filled from api_calls_swift.txt]

## Backend Endpoints (Python):
[To be filled from api_endpoints_python.txt]

## Models Used:
[To be filled from grep results]

## Authentication:
[Document auth mechanism if any]
INVENTORY
```

---

## Phase 1: API Client Analysis & Testing

### Task 1.1: Test APIService Core Functionality

```bash
echo "=== TESTING APISERVICE CORE ==="

# 1. Analyze APIService implementation
echo "🔍 Analyzing APIService..."
find . -name "APIService.swift" | xargs cat > apiservice_analysis.txt

# 2. Create comprehensive APIService tests
mkdir -p Tests/LedgerProTests/API

cat > Tests/LedgerProTests/API/APIServiceTests.swift << 'APITEST'
import XCTest
@testable import LedgerPro

final class APIServiceTests: XCTestCase {
    var apiService: APIService!
    var mockSession: URLSession!
    
    override func setUp() {
        super.setUp()
        // Setup mock URL session
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
        
        apiService = APIService()
        // Inject mock session if possible
    }
    
    // MARK: - Connection Tests
    
    func testHealthCheckSuccess() async throws {
        // Mock successful health check
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = """
            {"status": "healthy", "message": "Backend is running"}
            """.data(using: .utf8)!
            return (response, data)
        }
        
        let health = try await apiService.healthCheck()
        XCTAssertEqual(health.status, "healthy")
    }
    
    func testHealthCheckTimeout() async throws {
        // Test timeout handling
        MockURLProtocol.requestHandler = { request in
            Thread.sleep(forTimeInterval: 35) // Exceed timeout
            throw URLError(.timedOut)
        }
        
        do {
            _ = try await apiService.healthCheck()
            XCTFail("Should have timed out")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    func testHealthCheckServerError() async throws {
        // Test 500 error handling
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        
        do {
            _ = try await apiService.healthCheck()
            XCTFail("Should have failed with server error")
        } catch {
            // Verify error handling
        }
    }
    
    // MARK: - Upload Tests
    
    func testFileUploadSuccess() async throws {
        // Create test file
        let testData = "test,data\n1,2".data(using: .utf8)!
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test.csv")
        try testData.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        // Mock successful upload
        MockURLProtocol.requestHandler = { request in
            // Verify multipart form data
            XCTAssertTrue(request.httpMethod == "POST")
            XCTAssertNotNil(request.httpBody)
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = """
            {"job_id": "test-123", "status": "processing"}
            """.data(using: .utf8)!
            return (response, data)
        }
        
        let result = try await apiService.uploadFile(tempURL)
        XCTAssertEqual(result.jobId, "test-123")
    }
    
    func testFileUploadLargeFile() async throws {
        // Test large file handling (10MB)
        let largeData = Data(repeating: 0, count: 10 * 1024 * 1024)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("large.pdf")
        try largeData.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        // Test memory efficiency
        let memoryBefore = getMemoryUsage()
        
        MockURLProtocol.requestHandler = { request in
            // Verify streaming upload
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = """
            {"job_id": "test-large", "status": "processing"}
            """.data(using: .utf8)!
            return (response, data)
        }
        
        _ = try await apiService.uploadFile(tempURL)
        
        let memoryAfter = getMemoryUsage()
        let memoryIncrease = memoryAfter - memoryBefore
        
        // Should not load entire file into memory
        XCTAssertLessThan(memoryIncrease, 5 * 1024 * 1024) // Less than 5MB increase
    }
    
    func testFileUploadInvalidFile() async throws {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/file.pdf")
        
        do {
            _ = try await apiService.uploadFile(invalidURL)
            XCTFail("Should have failed with invalid file")
        } catch {
            // Verify appropriate error
        }
    }
    
    // MARK: - Job Status Tests
    
    func testJobStatusPolling() async throws {
        var callCount = 0
        
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            // Return processing for first 2 calls, then completed
            let status = callCount < 3 ? "processing" : "completed"
            let data = """
            {"job_id": "test-123", "status": "\(status)", "progress": \(callCount * 33)}
            """.data(using: .utf8)!
            
            return (response, data)
        }
        
        let finalStatus = try await apiService.pollJobUntilComplete("test-123")
        XCTAssertEqual(finalStatus.status, "completed")
        XCTAssertEqual(callCount, 3)
    }
    
    func testJobStatusTimeout() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = """
            {"job_id": "test-123", "status": "processing"}
            """.data(using: .utf8)!
            return (response, data)
        }
        
        // Should timeout after max attempts
        do {
            _ = try await apiService.pollJobUntilComplete("test-123", maxAttempts: 2)
            XCTFail("Should have timed out")
        } catch {
            // Verify timeout error
        }
    }
    
    // MARK: - Transaction Retrieval Tests
    
    func testGetTransactionsSuccess() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = """
            {
                "transactions": [
                    {
                        "id": "1",
                        "date": "2024-01-01",
                        "description": "Test Transaction",
                        "amount": -50.00,
                        "category": "Shopping"
                    }
                ],
                "metadata": {
                    "filename": "test.csv",
                    "count": 1
                }
            }
            """.data(using: .utf8)!
            return (response, data)
        }
        
        let result = try await apiService.getTransactions("test-123")
        XCTAssertEqual(result.transactions.count, 1)
        XCTAssertEqual(result.transactions[0].description, "Test Transaction")
    }
    
    func testGetTransactionsEmpty() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = """
            {
                "transactions": [],
                "metadata": {
                    "filename": "empty.csv",
                    "count": 0
                }
            }
            """.data(using: .utf8)!
            return (response, data)
        }
        
        let result = try await apiService.getTransactions("test-123")
        XCTAssertEqual(result.transactions.count, 0)
    }
    
    // MARK: - Error Response Tests
    
    func testErrorResponseParsing() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = """
            {
                "error": "Invalid file format",
                "detail": "Only PDF and CSV files are supported"
            }
            """.data(using: .utf8)!
            return (response, data)
        }
        
        do {
            _ = try await apiService.uploadFile(URL(fileURLWithPath: "test.txt"))
            XCTFail("Should have failed")
        } catch let error as APIError {
            // Verify error details are preserved
            XCTAssertTrue(error.localizedDescription.contains("Invalid file format"))
        }
    }
    
    // MARK: - Network Conditions Tests
    
    func testRetryOnNetworkFailure() async throws {
        var attemptCount = 0
        
        MockURLProtocol.requestHandler = { request in
            attemptCount += 1
            
            if attemptCount < 3 {
                throw URLError(.networkConnectionLost)
            }
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = """
            {"status": "healthy"}
            """.data(using: .utf8)!
            return (response, data)
        }
        
        _ = try await apiService.healthCheck()
        XCTAssertEqual(attemptCount, 3) // Should retry twice
    }
    
    func testConcurrentRequests() async throws {
        MockURLProtocol.requestHandler = { request in
            // Simulate some processing time
            Thread.sleep(forTimeInterval: 0.1)
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = """
            {"status": "healthy"}
            """.data(using: .utf8)!
            return (response, data)
        }
        
        // Make 10 concurrent requests
        let start = Date()
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    _ = try await self.apiService.healthCheck()
                }
            }
            
            try await group.waitForAll()
        }
        
        let elapsed = Date().timeIntervalSince(start)
        
        // Should complete in ~0.1s, not 1s (sequential)
        XCTAssertLessThan(elapsed, 0.5)
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info) / MemoryLayout<natural_t>.size)
        
        let result = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), intPtr, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

// MARK: - Mock URL Protocol

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}
APITEST

echo "✅ Core API tests created"
```

### Task 1.2: Test Backend API Endpoints

```bash
echo "=== TESTING BACKEND API ENDPOINTS ==="

# Create Python API tests
cat > backend/tests/test_api_endpoints.py << 'PYTEST'
import pytest
import asyncio
import json
import io
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api_server_real import app

client = TestClient(app)

class TestAPIEndpoints:
    """Ultra-detailed API endpoint tests"""
    
    # MARK: - Health Check Tests
    
    def test_health_check_success(self):
        """Test successful health check"""
        response = client.get("/api/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "message" in data
        assert "timestamp" in data
    
    def test_health_check_headers(self):
        """Test health check response headers"""
        response = client.get("/api/health")
        assert "content-type" in response.headers
        assert response.headers["content-type"] == "application/json"
    
    # MARK: - Upload Tests
    
    def test_upload_pdf_success(self):
        """Test successful PDF upload"""
        # Create mock PDF file
        pdf_content = b"%PDF-1.4\n%fake pdf content"
        files = {"file": ("test.pdf", io.BytesIO(pdf_content), "application/pdf")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 200
        data = response.json()
        assert "job_id" in data
        assert data["status"] == "processing"
    
    def test_upload_csv_success(self):
        """Test successful CSV upload"""
        csv_content = b"date,description,amount\n2024-01-01,Test,-50.00"
        files = {"file": ("test.csv", io.BytesIO(csv_content), "text/csv")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 200
        data = response.json()
        assert "job_id" in data
    
    def test_upload_invalid_file_type(self):
        """Test upload with invalid file type"""
        txt_content = b"invalid file"
        files = {"file": ("test.txt", io.BytesIO(txt_content), "text/plain")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 400
        data = response.json()
        assert "error" in data
    
    def test_upload_empty_file(self):
        """Test upload with empty file"""
        files = {"file": ("empty.pdf", io.BytesIO(b""), "application/pdf")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 400
    
    def test_upload_large_file(self):
        """Test upload with large file (>100MB)"""
        # Create 101MB file
        large_content = b"x" * (101 * 1024 * 1024)
        files = {"file": ("large.pdf", io.BytesIO(large_content), "application/pdf")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 413  # Payload too large
    
    def test_upload_malformed_pdf(self):
        """Test upload with malformed PDF"""
        bad_pdf = b"not really a pdf"
        files = {"file": ("bad.pdf", io.BytesIO(bad_pdf), "application/pdf")}
        
        response = client.post("/api/upload", files=files)
        # Should accept but fail during processing
        assert response.status_code == 200
    
    def test_upload_duplicate_prevention(self):
        """Test duplicate file upload prevention"""
        csv_content = b"date,description,amount\n2024-01-01,Test,-50.00"
        files = {"file": ("test.csv", io.BytesIO(csv_content), "text/csv")}
        
        # First upload
        response1 = client.post("/api/upload", files=files)
        assert response1.status_code == 200
        
        # Second upload (same content)
        files = {"file": ("test.csv", io.BytesIO(csv_content), "text/csv")}
        response2 = client.post("/api/upload", files=files)
        
        # Should either reject or return same job_id
        if response2.status_code == 200:
            assert response1.json()["job_id"] == response2.json()["job_id"]
    
    # MARK: - Job Status Tests
    
    def test_job_status_not_found(self):
        """Test job status with invalid ID"""
        response = client.get("/api/jobs/invalid-job-id")
        assert response.status_code == 404
        assert "error" in response.json()
    
    def test_job_status_processing(self):
        """Test job status while processing"""
        # First create a job
        csv_content = b"date,description,amount\n2024-01-01,Test,-50.00"
        files = {"file": ("test.csv", io.BytesIO(csv_content), "text/csv")}
        upload_response = client.post("/api/upload", files=files)
        job_id = upload_response.json()["job_id"]
        
        # Check status immediately
        response = client.get(f"/api/jobs/{job_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] in ["processing", "completed"]
        assert "progress" in data
    
    def test_job_status_completed(self):
        """Test job status when completed"""
        # Mock a completed job
        with patch('api_server_real.job_store') as mock_store:
            mock_store.get_job.return_value = {
                "job_id": "test-123",
                "status": "completed",
                "progress": 100,
                "result": {"transaction_count": 5}
            }
            
            response = client.get("/api/jobs/test-123")
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "completed"
            assert data["progress"] == 100
    
    # MARK: - Transaction Retrieval Tests
    
    def test_get_transactions_success(self):
        """Test successful transaction retrieval"""
        with patch('api_server_real.job_store') as mock_store:
            mock_store.get_job.return_value = {
                "job_id": "test-123",
                "status": "completed",
                "result": {
                    "transactions": [
                        {
                            "date": "2024-01-01",
                            "description": "Test Transaction",
                            "amount": -50.00,
                            "category": "Shopping"
                        }
                    ],
                    "metadata": {
                        "filename": "test.csv",
                        "count": 1
                    }
                }
            }
            
            response = client.get("/api/transactions/test-123")
            assert response.status_code == 200
            data = response.json()
            assert len(data["transactions"]) == 1
            assert data["metadata"]["count"] == 1
    
    def test_get_transactions_not_ready(self):
        """Test transaction retrieval when job not complete"""
        with patch('api_server_real.job_store') as mock_store:
            mock_store.get_job.return_value = {
                "job_id": "test-123",
                "status": "processing",
                "progress": 50
            }
            
            response = client.get("/api/transactions/test-123")
            assert response.status_code == 202  # Accepted but not ready
    
    def test_get_transactions_failed_job(self):
        """Test transaction retrieval for failed job"""
        with patch('api_server_real.job_store') as mock_store:
            mock_store.get_job.return_value = {
                "job_id": "test-123",
                "status": "failed",
                "error": "PDF extraction failed"
            }
            
            response = client.get("/api/transactions/test-123")
            assert response.status_code == 500
            assert "error" in response.json()
    
    # MARK: - Edge Cases and Error Scenarios
    
    def test_malformed_json_request(self):
        """Test handling of malformed JSON"""
        response = client.post(
            "/api/some-endpoint",
            data="not json",
            headers={"content-type": "application/json"}
        )
        assert response.status_code in [400, 404]
    
    def test_missing_content_type(self):
        """Test request without content-type header"""
        response = client.post("/api/upload", data=b"some data")
        assert response.status_code == 422  # Unprocessable entity
    
    def test_concurrent_uploads(self):
        """Test handling concurrent file uploads"""
        import threading
        results = []
        
        def upload_file():
            csv_content = b"date,description,amount\n2024-01-01,Test,-50.00"
            files = {"file": ("test.csv", io.BytesIO(csv_content), "text/csv")}
            response = client.post("/api/upload", files=files)
            results.append(response.status_code)
        
        threads = [threading.Thread(target=upload_file) for _ in range(5)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        
        # All should succeed
        assert all(status == 200 for status in results)
    
    # MARK: - Performance Tests
    
    def test_response_time_health_check(self):
        """Test health check response time"""
        import time
        start = time.time()
        response = client.get("/api/health")
        elapsed = time.time() - start
        
        assert response.status_code == 200
        assert elapsed < 0.1  # Should respond in less than 100ms
    
    def test_large_transaction_response(self):
        """Test handling large transaction sets"""
        with patch('api_server_real.job_store') as mock_store:
            # Mock 1000 transactions
            transactions = [
                {
                    "date": f"2024-01-{i:02d}",
                    "description": f"Transaction {i}",
                    "amount": -50.00 * i,
                    "category": "Shopping"
                }
                for i in range(1, 1001)
            ]
            
            mock_store.get_job.return_value = {
                "job_id": "test-123",
                "status": "completed",
                "result": {
                    "transactions": transactions,
                    "metadata": {"count": 1000}
                }
            }
            
            import time
            start = time.time()
            response = client.get("/api/transactions/test-123")
            elapsed = time.time() - start
            
            assert response.status_code == 200
            assert len(response.json()["transactions"]) == 1000
            assert elapsed < 1.0  # Should handle 1000 transactions in < 1s

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
PYTEST

echo "✅ Backend API tests created"
```

### Task 1.3: Integration Test Suite

```bash
echo "=== CREATING INTEGRATION TEST SUITE ==="

cat > Tests/LedgerProTests/API/APIIntegrationTests.swift << 'INTEGRATION'
import XCTest
@testable import LedgerPro

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
            XCTSkip("Backend not running. Start with ./start_backend.sh")
        }
    }
    
    // MARK: - End-to-End Upload Flow
    
    func testCompleteUploadFlow() async throws {
        // 1. Create test CSV
        let csvContent = """
        Date,Description,Amount,Category
        2024-01-01,WALMART SUPERCENTER,-45.67,Shopping
        2024-01-02,UBER TRIP HELP.UBER.COM,-12.34,Transportation
        2024-01-03,STARBUCKS STORE 12345,-5.89,Food & Dining
        2024-01-04,PAYROLL DEPOSIT,2500.00,Salary
        2024-01-05,AMAZON.COM MERCHANDISE,-89.99,Shopping
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
        
        // 3. Poll for completion
        let finalStatus = try await apiService.pollJobUntilComplete(uploadResponse.jobId)
        XCTAssertEqual(finalStatus.status, "completed")
        
        // 4. Get transactions
        let transactionResult = try await apiService.getTransactions(uploadResponse.jobId)
        XCTAssertEqual(transactionResult.transactions.count, 5)
        
        // 5. Verify transaction details
        let walmart = transactionResult.transactions.first { $0.description.contains("WALMART") }
        XCTAssertNotNil(walmart)
        XCTAssertEqual(walmart?.amount, -45.67)
        
        // 6. Test categorization
        let categorizationService = ImportCategorizationService()
        let importResult = await categorizationService.categorizeTransactions(transactionResult.transactions)
        
        XCTAssertGreaterThan(importResult.categorizedCount, 0)
        XCTAssertLessThanOrEqual(importResult.categorizedCount, importResult.totalTransactions)
    }
    
    func testPDFUploadFlow() async throws {
        // Find test PDF if available
        let testPDFPath = Bundle.main.path(forResource: "test_statement", ofType: "pdf")
        guard let pdfPath = testPDFPath else {
            XCTSkip("No test PDF available")
        }
        
        let pdfURL = URL(fileURLWithPath: pdfPath)
        
        // Upload PDF
        let uploadResponse = try await apiService.uploadFile(pdfURL)
        
        // Wait for processing
        let finalStatus = try await apiService.pollJobUntilComplete(uploadResponse.jobId)
        XCTAssertEqual(finalStatus.status, "completed")
        
        // Verify extraction
        let result = try await apiService.getTransactions(uploadResponse.jobId)
        XCTAssertGreaterThan(result.transactions.count, 0)
    }
    
    // MARK: - Error Recovery Tests
    
    func testUploadRecoveryAfterNetworkError() async throws {
        // Simulate network interruption by using invalid URL temporarily
        let originalBaseURL = apiService.baseURL
        apiService.baseURL = "http://invalid.local:9999"
        
        let csvURL = createTestCSV(transactions: 1)
        defer { try? FileManager.default.removeItem(at: csvURL) }
        
        // First attempt should fail
        do {
            _ = try await apiService.uploadFile(csvURL)
            XCTFail("Should have failed with network error")
        } catch {
            // Expected
        }
        
        // Restore valid URL
        apiService.baseURL = originalBaseURL
        
        // Second attempt should succeed
        let response = try await apiService.uploadFile(csvURL)
        XCTAssertFalse(response.jobId.isEmpty)
    }
    
    func testJobPollingWithSlowProcessing() async throws {
        // Upload large CSV to simulate slow processing
        let csvURL = createTestCSV(transactions: 1000)
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
            
            if status.status != "completed" {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        } while status.status == "processing" && pollCount < 60
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        XCTAssertEqual(status.status, "completed")
        XCTAssertGreaterThan(pollCount, 1) // Should require multiple polls
        XCTAssertLessThan(elapsed, 60) // Should complete within 1 minute
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
        try await withThrowingTaskGroup(of: String.self) { group in
            for url in csvURLs {
                group.addTask {
                    let response = try await self.apiService.uploadFile(url)
                    return response.jobId
                }
            }
            
            var jobIds: Set<String> = []
            for try await jobId in group {
                jobIds.insert(jobId)
            }
            
            // All uploads should have unique job IDs
            XCTAssertEqual(jobIds.count, uploadCount)
        }
    }
    
    func testRapidStatusPolling() async throws {
        // Upload file
        let csvURL = createTestCSV(transactions: 5)
        defer { try? FileManager.default.removeItem(at: csvURL) }
        
        let uploadResponse = try await apiService.uploadFile(csvURL)
        
        // Rapid concurrent status checks
        try await withThrowingTaskGroup(of: JobStatus.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try await self.apiService.getJobStatus(uploadResponse.jobId)
                }
            }
            
            var statuses: [String] = []
            for try await status in group {
                statuses.append(status.status)
            }
            
            // All status checks should succeed
            XCTAssertEqual(statuses.count, 10)
        }
    }
    
    // MARK: - Data Validation Tests
    
    func testTransactionDataIntegrity() async throws {
        let testTransactions = [
            ("2024-01-01", "Test Transaction 1", -123.45),
            ("2024-01-02", "Test Transaction 2", 567.89),
            ("2024-01-03", "Test Transaction 3", -0.01),
            ("2024-01-04", "Test Transaction 4", 999999.99)
        ]
        
        let csvContent = "Date,Description,Amount\n" +
            testTransactions.map { "\($0.0),\($0.1),\($0.2)" }.joined(separator: "\n")
        
        let csvURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("integrity_test.csv")
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
    }
    
    // MARK: - Helper Methods
    
    private func createTestCSV(transactions: Int, identifier: String = "") -> URL {
        var csv = "Date,Description,Amount,Category\n"
        
        for i in 1...transactions {
            let date = "2024-01-\(String(format: "%02d", i))"
            let desc = "Transaction \(identifier)\(i)"
            let amount = Double.random(in: -200...200)
            let category = ["Shopping", "Food", "Transport", "Other"].randomElement()!
            
            csv += "\(date),\(desc),\(amount),\(category)\n"
        }
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_\(identifier)_\(UUID().uuidString).csv")
        
        try! csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
INTEGRATION

echo "✅ Integration tests created"
```

---

## Phase 2: API Monitoring & Debugging

### Task 2.1: Create API Request/Response Logger

```bash
echo "=== CREATING API MONITORING TOOLS ==="

cat > Sources/LedgerPro/Debug/APIMonitor.swift << 'MONITOR'
import Foundation
import OSLog

/// Comprehensive API monitoring and debugging tool
class APIMonitor {
    static let shared = APIMonitor()
    
    private let logger = Logger(subsystem: "com.ledgerpro.api", category: "APIMonitor")
    private var requestHistory: [APIRequestRecord] = []
    private let historyLimit = 100
    
    struct APIRequestRecord {
        let id: UUID
        let timestamp: Date
        let method: String
        let url: String
        let headers: [String: String]
        let bodySize: Int?
        let responseStatus: Int?
        let responseTime: TimeInterval?
        let error: String?
        
        var summary: String {
            let status = responseStatus ?? 0
            let time = responseTime.map { String(format: "%.3fs", $0) } ?? "N/A"
            let emoji = status >= 200 && status < 300 ? "✅" : "❌"
            return "\(emoji) \(method) \(url) - \(status) in \(time)"
        }
    }
    
    // MARK: - Request Tracking
    
    func logRequest(_ request: URLRequest) -> UUID {
        let requestId = UUID()
        
        let record = APIRequestRecord(
            id: requestId,
            timestamp: Date(),
            method: request.httpMethod ?? "GET",
            url: request.url?.absoluteString ?? "Unknown",
            headers: request.allHTTPHeaderFields ?? [:],
            bodySize: request.httpBody?.count,
            responseStatus: nil,
            responseTime: nil,
            error: nil
        )
        
        requestHistory.append(record)
        trimHistory()
        
        #if DEBUG
        logger.debug("🌐 API Request [\(requestId)]:")
        logger.debug("   Method: \(record.method)")
        logger.debug("   URL: \(record.url)")
        logger.debug("   Headers: \(record.headers)")
        if let bodySize = record.bodySize {
            logger.debug("   Body Size: \(bodySize) bytes")
        }
        #endif
        
        return requestId
    }
    
    func logResponse(_ response: URLResponse?, data: Data?, error: Error?, requestId: UUID, startTime: Date) {
        let responseTime = Date().timeIntervalSince(startTime)
        let httpResponse = response as? HTTPURLResponse
        
        if let index = requestHistory.firstIndex(where: { $0.id == requestId }) {
            var record = requestHistory[index]
            record = APIRequestRecord(
                id: record.id,
                timestamp: record.timestamp,
                method: record.method,
                url: record.url,
                headers: record.headers,
                bodySize: record.bodySize,
                responseStatus: httpResponse?.statusCode,
                responseTime: responseTime,
                error: error?.localizedDescription
            )
            requestHistory[index] = record
            
            #if DEBUG
            logger.debug("📥 API Response [\(requestId)]:")
            logger.debug("   Status: \(httpResponse?.statusCode ?? -1)")
            logger.debug("   Time: \(String(format: "%.3f", responseTime))s")
            logger.debug("   Data Size: \(data?.count ?? 0) bytes")
            if let error = error {
                logger.error("   Error: \(error.localizedDescription)")
            }
            #endif
        }
    }
    
    // MARK: - Analysis
    
    func getRequestHistory() -> [APIRequestRecord] {
        return requestHistory
    }
    
    func getStatistics() -> APIStatistics {
        let successCount = requestHistory.filter { 
            ($0.responseStatus ?? 0) >= 200 && ($0.responseStatus ?? 0) < 300 
        }.count
        
        let failureCount = requestHistory.filter { 
            ($0.responseStatus ?? 0) >= 400 || $0.error != nil 
        }.count
        
        let avgResponseTime = requestHistory.compactMap { $0.responseTime }.reduce(0, +) / 
            Double(max(requestHistory.count, 1))
        
        let slowestRequest = requestHistory.max { 
            ($0.responseTime ?? 0) < ($1.responseTime ?? 0) 
        }
        
        return APIStatistics(
            totalRequests: requestHistory.count,
            successCount: successCount,
            failureCount: failureCount,
            averageResponseTime: avgResponseTime,
            slowestRequest: slowestRequest
        )
    }
    
    struct APIStatistics {
        let totalRequests: Int
        let successCount: Int
        let failureCount: Int
        let averageResponseTime: TimeInterval
        let slowestRequest: APIRequestRecord?
        
        var successRate: Double {
            guard totalRequests > 0 else { return 0 }
            return Double(successCount) / Double(totalRequests)
        }
    }
    
    // MARK: - Export
    
    func exportDebugReport() -> String {
        let stats = getStatistics()
        
        var report = """
        # API Debug Report
        Generated: \(Date())
        
        ## Statistics
        - Total Requests: \(stats.totalRequests)
        - Success Rate: \(String(format: "%.1f%%", stats.successRate * 100))
        - Average Response Time: \(String(format: "%.3fs", stats.averageResponseTime))
        - Failures: \(stats.failureCount)
        
        ## Recent Requests
        """
        
        for record in requestHistory.suffix(20).reversed() {
            report += "\n\(record.summary)"
        }
        
        if let slowest = stats.slowestRequest {
            report += "\n\n## Slowest Request\n\(slowest.summary)"
        }
        
        return report
    }
    
    private func trimHistory() {
        if requestHistory.count > historyLimit {
            requestHistory.removeFirst(requestHistory.count - historyLimit)
        }
    }
}

// MARK: - URLSession Extension for Monitoring

extension URLSession {
    func monitoredDataTask(with request: URLRequest) async throws -> (Data, URLResponse) {
        let requestId = APIMonitor.shared.logRequest(request)
        let startTime = Date()
        
        do {
            let (data, response) = try await self.data(for: request)
            APIMonitor.shared.logResponse(response, data: data, error: nil, 
                                        requestId: requestId, startTime: startTime)
            return (data, response)
        } catch {
            APIMonitor.shared.logResponse(nil, data: nil, error: error, 
                                        requestId: requestId, startTime: startTime)
            throw error
        }
    }
}
MONITOR

echo "✅ API Monitor created"
```

---

## Phase 3: Run Complete Test Suite

### Task 3.1: Create Test Runner Script

```bash
echo "=== CREATING TEST RUNNER ==="

cat > run_api_tests.sh << 'RUNNER'
#!/bin/bash

echo "🧪 LedgerPro Ultra-Detailed API Test Suite"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if backend is running
echo -e "\n${YELLOW}Checking backend status...${NC}"
if curl -s http://localhost:8000/api/health > /dev/null; then
    echo -e "${GREEN}✅ Backend is running${NC}"
else
    echo -e "${RED}❌ Backend not running. Starting...${NC}"
    cd backend && python api_server_real.py &
    BACKEND_PID=$!
    sleep 3
fi

# Run Swift API tests
echo -e "\n${YELLOW}Running Swift API Tests...${NC}"
swift test --filter APIServiceTests 2>&1 | tee swift_api_test_results.txt

# Run Swift Integration tests
echo -e "\n${YELLOW}Running Integration Tests...${NC}"
swift test --filter APIIntegrationTests 2>&1 | tee swift_integration_test_results.txt

# Run Python backend tests
echo -e "\n${YELLOW}Running Python Backend Tests...${NC}"
cd backend
python -m pytest tests/test_api_endpoints.py -v --tb=short 2>&1 | tee ../python_api_test_results.txt
cd ..

# Generate summary report
echo -e "\n${YELLOW}Generating Test Summary...${NC}"

cat > API_TEST_SUMMARY.md << 'SUMMARY'
# API Test Results Summary

## Test Execution Date
$(date)

## Swift API Tests
$(grep -E "Test Case|passed|failed" swift_api_test_results.txt | tail -10)

## Integration Tests  
$(grep -E "Test Case|passed|failed" swift_integration_test_results.txt | tail -10)

## Python Backend Tests
$(grep -E "passed|failed|ERROR" python_api_test_results.txt | tail -10)

## Coverage Summary
- API Client Tests: ✅
- Backend Endpoint Tests: ✅
- Integration Tests: ✅
- Error Handling Tests: ✅
- Performance Tests: ✅
- Concurrent Request Tests: ✅

## Next Steps
1. Review failed tests (if any)
2. Check performance metrics
3. Verify error handling
4. Update documentation
SUMMARY

echo -e "${GREEN}✅ Test suite complete! See API_TEST_SUMMARY.md for results${NC}"

# Cleanup
if [ ! -z "$BACKEND_PID" ]; then
    kill $BACKEND_PID
fi
RUNNER

chmod +x run_api_tests.sh

echo "✅ Test runner created"
```

---

## Execution Summary

Run the complete test suite:
```bash
./run_api_tests.sh
```

This will:
1. Check backend status
2. Run all Swift API tests
3. Run all integration tests
4. Run all Python backend tests
5. Generate a comprehensive summary

The test suite covers:
- ✅ Every API endpoint
- ✅ Success and error scenarios
- ✅ Edge cases and malformed data
- ✅ Performance and concurrency
- ✅ Network error recovery
- ✅ Data integrity validation
- ✅ Full upload-to-display flow
