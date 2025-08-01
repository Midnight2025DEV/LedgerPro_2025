import pytest
import asyncio
import json
import io
import threading
import time
import hashlib
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock, AsyncMock
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api_server_real import app, processing_jobs, file_hashes

client = TestClient(app)


class TestAPIEndpoints:
    """Ultra-detailed API endpoint tests"""
    
    @pytest.fixture(autouse=True)
    def setup_and_teardown(self):
        """Setup and teardown for each test"""
        # Clear state before each test
        processing_jobs.clear()
        file_hashes.clear()
        yield
        # Clear state after each test
        processing_jobs.clear()
        file_hashes.clear()
    
    # MARK: - Health Check Tests
    
    def test_health_check_success(self):
        """Test successful health check"""
        response = client.get("/api/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "message" in data
        assert "timestamp" in data
        assert "version" in data
        assert data["processor"] == "CamelotFinancialProcessor"
    
    def test_health_check_headers(self):
        """Test health check response headers"""
        response = client.get("/api/health")
        assert "content-type" in response.headers
        assert "application/json" in response.headers["content-type"]
    
    def test_health_check_cors(self):
        """Test CORS headers on health check"""
        # Test GET request with Origin header to check CORS
        response = client.get("/api/health", headers={"Origin": "http://localhost:5173"})
        assert response.status_code == 200
        # CORS headers should be present in the response
        assert "access-control-allow-origin" in response.headers or "Access-Control-Allow-Origin" in response.headers
    
    # MARK: - Upload Tests
    
    def test_upload_pdf_success(self):
        """Test successful PDF upload"""
        # Create mock PDF file
        pdf_content = b"%PDF-1.4\n%fake pdf content for testing"
        files = {"file": ("test.pdf", io.BytesIO(pdf_content), "application/pdf")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 200
        data = response.json()
        assert "job_id" in data
        assert data["status"] == "processing"
        assert "message" in data
        
        # Verify job was created
        job_id = data["job_id"]
        assert job_id in processing_jobs
        assert processing_jobs[job_id]["status"] in ["processing", "extracting_tables"]
        assert processing_jobs[job_id]["filename"] == "test.pdf"
    
    def test_upload_csv_success(self):
        """Test successful CSV upload"""
        csv_content = b"Date,Description,Amount\n2024-01-01,Test Transaction,-50.00"
        files = {"file": ("test.csv", io.BytesIO(csv_content), "text/csv")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 200
        data = response.json()
        assert "job_id" in data
        assert data["status"] == "processing"
        
        # Verify file hash was recorded
        file_hash = hashlib.sha256(csv_content).hexdigest()
        assert file_hash in file_hashes
        assert file_hashes[file_hash] == data["job_id"]
    
    def test_upload_invalid_file_type(self):
        """Test upload with invalid file type"""
        txt_content = b"invalid file type"
        files = {"file": ("test.txt", io.BytesIO(txt_content), "text/plain")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 400
        data = response.json()
        assert "detail" in data
        assert "PDF and CSV" in data["detail"]
    
    def test_upload_empty_file(self):
        """Test upload with empty file"""
        files = {"file": ("empty.pdf", io.BytesIO(b""), "application/pdf")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 200  # Empty files are accepted
        data = response.json()
        assert "job_id" in data
    
    def test_upload_large_file(self):
        """Test upload with large file (10MB)"""
        # Create 10MB file
        large_content = b"x" * (10 * 1024 * 1024)
        files = {"file": ("large.pdf", io.BytesIO(large_content), "application/pdf")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 200
        data = response.json()
        assert "job_id" in data
        
        # Verify file size recorded
        job_id = data["job_id"]
        assert processing_jobs[job_id]["file_size"] == len(large_content)
    
    def test_upload_malformed_pdf(self):
        """Test upload with malformed PDF"""
        bad_pdf = b"not really a pdf but claims to be"
        files = {"file": ("bad.pdf", io.BytesIO(bad_pdf), "application/pdf")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 200  # Should accept for processing
        data = response.json()
        assert "job_id" in data
        
        # The actual processing will fail, but upload succeeds
        job_id = data["job_id"]
        assert processing_jobs[job_id]["status"] in ["processing", "extracting_tables", "processing_csv"]
    
    def test_upload_duplicate_prevention(self):
        """Test duplicate file upload prevention"""
        csv_content = b"Date,Description,Amount\n2024-01-01,Test,-50.00"
        
        # First upload
        files1 = {"file": ("test.csv", io.BytesIO(csv_content), "text/csv")}
        response1 = client.post("/api/upload", files=files1)
        assert response1.status_code == 200
        job_id1 = response1.json()["job_id"]
        
        # Second upload (same content, different filename)
        files2 = {"file": ("different_name.csv", io.BytesIO(csv_content), "text/csv")}
        response2 = client.post("/api/upload", files=files2)
        assert response2.status_code == 200
        data2 = response2.json()
        
        # Should return same job ID with duplicate message
        assert data2["job_id"] == job_id1
        assert "Duplicate" in data2["message"]
        assert "existing job" in data2["message"]
    
    def test_upload_missing_file(self):
        """Test upload with missing file parameter"""
        response = client.post("/api/upload")
        assert response.status_code == 422  # Unprocessable entity
        data = response.json()
        assert "detail" in data
    
    def test_upload_multiple_files(self):
        """Test upload with multiple files (should only process first)"""
        files = [
            ("file", ("test1.csv", io.BytesIO(b"data1"), "text/csv")),
            ("file", ("test2.csv", io.BytesIO(b"data2"), "text/csv"))
        ]
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 200
        # FastAPI will only process the first file
    
    # MARK: - Job Status Tests
    
    def test_job_status_not_found(self):
        """Test job status with invalid ID"""
        response = client.get("/api/jobs/invalid-job-id-12345")
        assert response.status_code == 404
        data = response.json()
        assert "detail" in data
        assert "not found" in data["detail"].lower()
    
    def test_job_status_processing(self):
        """Test job status while processing"""
        # First create a job
        csv_content = b"Date,Description,Amount\n2024-01-01,Test,-50.00"
        files = {"file": ("test.csv", io.BytesIO(csv_content), "text/csv")}
        upload_response = client.post("/api/upload", files=files)
        job_id = upload_response.json()["job_id"]
        
        # Check status immediately
        response = client.get(f"/api/jobs/{job_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["job_id"] == job_id
        assert data["status"] in ["processing", "processing_csv", "analyzing_transactions", "completed"]
        assert "progress" in data
        assert data["progress"] >= 0 and data["progress"] <= 100
        assert data["filename"] == "test.csv"
        assert "created_at" in data
    
    def test_job_status_completed(self):
        """Test job status when completed"""
        # Create a mock completed job
        job_id = "test-completed-123"
        processing_jobs[job_id] = {
            "status": "completed",
            "progress": 100,
            "filename": "test.csv",
            "file_size": 1024,
            "created_at": "2024-01-01T12:00:00",
            "completed_at": "2024-01-01T12:01:00",
            "results": {"transaction_count": 5}
        }
        
        response = client.get(f"/api/jobs/{job_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"
        assert data["progress"] == 100
        assert data["completed_at"] is not None
    
    def test_job_status_error(self):
        """Test job status when job failed"""
        # Create a mock failed job
        job_id = "test-error-456"
        processing_jobs[job_id] = {
            "status": "error",
            "progress": 0,
            "filename": "bad.pdf",
            "created_at": "2024-01-01T12:00:00",
            "completed_at": "2024-01-01T12:00:30",
            "error": "PDF extraction failed: Unable to parse tables"
        }
        
        response = client.get(f"/api/jobs/{job_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "error"
        assert data["error"] == "PDF extraction failed: Unable to parse tables"
    
    def test_job_status_duplicate_detection(self):
        """Test duplicate detection in job status"""
        # Create original job
        file_hash = "abc123"
        original_job_id = "original-123"
        file_hashes[file_hash] = original_job_id
        
        # Create duplicate job
        duplicate_job_id = "duplicate-456"
        processing_jobs[duplicate_job_id] = {
            "status": "completed",
            "file_hash": file_hash,
            "filename": "duplicate.csv",
            "created_at": "2024-01-01T12:00:00"
        }
        
        response = client.get(f"/api/jobs/{duplicate_job_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["is_duplicate"] is True
    
    # MARK: - Transaction Retrieval Tests
    
    def test_get_transactions_success(self):
        """Test successful transaction retrieval"""
        job_id = "test-transactions-123"
        processing_jobs[job_id] = {
            "status": "completed",
            "results": {
                "transactions": [
                    {
                        "date": "2024-01-01",
                        "description": "Test Transaction 1",
                        "amount": -50.00,
                        "category": "Shopping",
                        "confidence": 0.95
                    },
                    {
                        "date": "2024-01-02",
                        "description": "Salary Deposit",
                        "amount": 3000.00,
                        "category": "Income",
                        "confidence": 1.0
                    }
                ],
                "metadata": {
                    "filename": "test.csv",
                    "total_transactions": 2,
                    "processing_time": "1.5s"
                },
                "summary": {
                    "total_income": 3000.00,
                    "total_expenses": 50.00,
                    "net_amount": 2950.00,
                    "transaction_count": 2
                }
            }
        }
        
        response = client.get(f"/api/transactions/{job_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["job_id"] == job_id
        assert data["status"] == "completed"
        assert len(data["transactions"]) == 2
        assert data["transactions"][0]["description"] == "Test Transaction 1"
        assert data["summary"]["net_amount"] == 2950.00
    
    def test_get_transactions_with_forex(self):
        """Test transaction retrieval with foreign currency data"""
        job_id = "test-forex-123"
        processing_jobs[job_id] = {
            "status": "completed",
            "results": {
                "transactions": [
                    {
                        "date": "2024-01-01",
                        "description": "Foreign Purchase EUR",
                        "amount": -55.50,
                        "category": "Shopping",
                        "original_amount": -50.00,
                        "original_currency": "EUR",
                        "exchange_rate": 1.11,
                        "has_forex": True
                    }
                ],
                "metadata": {"filename": "forex.csv", "total_transactions": 1},
                "summary": {
                    "total_income": 0,
                    "total_expenses": 55.50,
                    "net_amount": -55.50,
                    "transaction_count": 1
                }
            }
        }
        
        response = client.get(f"/api/transactions/{job_id}")
        assert response.status_code == 200
        data = response.json()
        transaction = data["transactions"][0]
        assert transaction["has_forex"] is True
        assert transaction["original_currency"] == "EUR"
        assert transaction["original_amount"] == -50.00
        assert transaction["exchange_rate"] == 1.11
    
    def test_get_transactions_not_ready(self):
        """Test transaction retrieval when job not complete"""
        job_id = "test-processing-789"
        processing_jobs[job_id] = {
            "status": "processing",
            "progress": 50,
            "filename": "processing.csv"
        }
        
        response = client.get(f"/api/transactions/{job_id}")
        assert response.status_code == 202  # Accepted but not ready
        data = response.json()
        assert "still in progress" in data["detail"]
    
    def test_get_transactions_failed_job(self):
        """Test transaction retrieval for failed job"""
        job_id = "test-failed-999"
        processing_jobs[job_id] = {
            "status": "error",
            "error": "PDF extraction failed: No tables found"
        }
        
        response = client.get(f"/api/transactions/{job_id}")
        assert response.status_code == 500
        data = response.json()
        assert "Processing failed" in data["detail"]
        assert "No tables found" in data["detail"]
    
    def test_get_transactions_not_found(self):
        """Test transaction retrieval for non-existent job"""
        response = client.get("/api/transactions/non-existent-job")
        assert response.status_code == 404
        data = response.json()
        assert "not found" in data["detail"].lower()
    
    # MARK: - List Jobs Tests
    
    def test_list_jobs_empty(self):
        """Test listing jobs when none exist"""
        response = client.get("/api/jobs")
        assert response.status_code == 200
        data = response.json()
        assert data["total_jobs"] == 0
        assert data["unique_files"] == 0
        assert data["duplicate_uploads"] == 0
        assert len(data["jobs"]) == 0
    
    def test_list_jobs_with_data(self):
        """Test listing jobs with multiple jobs"""
        # Create some test jobs
        processing_jobs["job1"] = {
            "status": "completed",
            "filename": "file1.csv",
            "file_size": 1024,
            "created_at": "2024-01-01T10:00:00",
            "file_hash": "hash1"
        }
        processing_jobs["job2"] = {
            "status": "processing",
            "filename": "file2.pdf",
            "file_size": 2048,
            "created_at": "2024-01-01T11:00:00",
            "file_hash": "hash2"
        }
        
        file_hashes["hash1"] = "job1"
        file_hashes["hash2"] = "job2"
        
        response = client.get("/api/jobs")
        assert response.status_code == 200
        data = response.json()
        assert data["total_jobs"] == 2
        assert data["unique_files"] == 2
        assert data["duplicate_uploads"] == 0
        assert len(data["jobs"]) == 2
        
        # Verify job details
        job_ids = [job["job_id"] for job in data["jobs"]]
        assert "job1" in job_ids
        assert "job2" in job_ids
    
    # MARK: - Duplicate Statistics Tests
    
    def test_duplicate_stats_no_duplicates(self):
        """Test duplicate statistics with no duplicates"""
        response = client.get("/api/duplicates")
        assert response.status_code == 200
        data = response.json()
        assert data["total_unique_files"] == 0
        assert data["total_uploads"] == 0
        assert data["files_with_duplicates"] == 0
        assert data["total_duplicate_uploads"] == 0
        assert len(data["duplicate_groups"]) == 0
    
    def test_duplicate_stats_with_duplicates(self):
        """Test duplicate statistics with duplicate uploads"""
        # Create original and duplicate jobs
        file_hash = "duplicate_hash_123"
        
        # Original upload
        file_hashes[file_hash] = "original-job"
        processing_jobs["original-job"] = {
            "status": "completed",
            "file_hash": file_hash,
            "filename": "original.csv",
            "created_at": "2024-01-01T10:00:00"
        }
        
        # Duplicate uploads
        processing_jobs["dup-job-1"] = {
            "status": "completed",
            "file_hash": file_hash,
            "filename": "duplicate1.csv",
            "created_at": "2024-01-01T11:00:00"
        }
        processing_jobs["dup-job-2"] = {
            "status": "completed",
            "file_hash": file_hash,
            "filename": "duplicate2.csv",
            "created_at": "2024-01-01T12:00:00"
        }
        
        response = client.get("/api/duplicates")
        assert response.status_code == 200
        data = response.json()
        assert data["total_unique_files"] == 1
        assert data["total_uploads"] == 3
        assert data["files_with_duplicates"] == 1
        assert data["total_duplicate_uploads"] == 2
        
        # Check duplicate group details
        dup_group = data["duplicate_groups"][file_hash]
        assert dup_group["original_job_id"] == "original-job"
        assert dup_group["total_uploads"] == 3
        assert len(dup_group["duplicate_job_ids"]) == 2
        assert "dup-job-1" in dup_group["duplicate_job_ids"]
        assert "dup-job-2" in dup_group["duplicate_job_ids"]
    
    # MARK: - Edge Cases and Error Scenarios
    
    def test_malformed_json_request(self):
        """Test handling of malformed JSON"""
        response = client.post(
            "/api/some-endpoint",
            data="not json",
            headers={"content-type": "application/json"}
        )
        assert response.status_code in [400, 404, 422]
    
    def test_missing_content_type(self):
        """Test request without content-type header"""
        response = client.post("/api/upload", data=b"some data")
        assert response.status_code == 422  # Unprocessable entity
    
    def test_concurrent_uploads(self):
        """Test handling concurrent file uploads"""
        results = []
        
        def upload_file(index):
            csv_content = f"Date,Description,Amount\n2024-01-01,Test {index},-{index}.00".encode()
            files = {"file": (f"test{index}.csv", io.BytesIO(csv_content), "text/csv")}
            response = client.post("/api/upload", files=files)
            results.append((index, response.status_code, response.json()))
        
        # Create 5 concurrent upload threads
        threads = [threading.Thread(target=upload_file, args=(i,)) for i in range(5)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        
        # All should succeed
        assert all(result[1] == 200 for result in results)
        
        # All should have unique job IDs
        job_ids = [result[2]["job_id"] for result in results]
        assert len(set(job_ids)) == 5
    
    def test_special_characters_in_filename(self):
        """Test upload with special characters in filename"""
        csv_content = b"Date,Description,Amount\n2024-01-01,Test,-50.00"
        special_filename = "test & file (with) [special] chars!.csv"
        files = {"file": (special_filename, io.BytesIO(csv_content), "text/csv")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 200
        data = response.json()
        
        # Verify job created with correct filename
        job_id = data["job_id"]
        assert processing_jobs[job_id]["filename"] == special_filename
    
    def test_unicode_in_csv_content(self):
        """Test CSV with unicode characters"""
        csv_content = "Date,Description,Amount\n2024-01-01,Café ☕ Purchase €,-10.50\n2024-01-02,日本料理 🍱,-25.00".encode('utf-8')
        files = {"file": ("unicode.csv", io.BytesIO(csv_content), "text/csv")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 200
    
    # MARK: - Performance Tests
    
    def test_response_time_health_check(self):
        """Test health check response time"""
        start = time.time()
        response = client.get("/api/health")
        elapsed = time.time() - start
        
        assert response.status_code == 200
        assert elapsed < 0.1  # Should respond in less than 100ms
    
    def test_large_transaction_response(self):
        """Test handling large transaction sets"""
        # Create job with 1000 transactions
        transactions = [
            {
                "date": f"2024-01-{(i % 28) + 1:02d}",
                "description": f"Transaction {i}",
                "amount": -50.00 * (i % 10),
                "category": ["Shopping", "Food", "Transport", "Other"][i % 4]
            }
            for i in range(1, 1001)
        ]
        
        job_id = "large-transaction-test"
        processing_jobs[job_id] = {
            "status": "completed",
            "results": {
                "transactions": transactions,
                "metadata": {
                    "filename": "large.csv",
                    "total_transactions": 1000,
                    "processing_time": "5.2s"
                },
                "summary": {
                    "total_income": 0,
                    "total_expenses": sum(abs(t["amount"]) for t in transactions),
                    "net_amount": sum(t["amount"] for t in transactions),
                    "transaction_count": 1000
                }
            }
        }
        
        start = time.time()
        response = client.get(f"/api/transactions/{job_id}")
        elapsed = time.time() - start
        
        assert response.status_code == 200
        assert len(response.json()["transactions"]) == 1000
        assert elapsed < 1.0  # Should handle 1000 transactions in < 1s
    
    def test_job_list_performance_with_many_jobs(self):
        """Test job list performance with many jobs"""
        # Create 100 test jobs
        for i in range(100):
            job_id = f"perf-test-{i}"
            processing_jobs[job_id] = {
                "status": "completed" if i % 2 == 0 else "processing",
                "filename": f"file{i}.csv",
                "file_size": 1024 * (i + 1),
                "created_at": f"2024-01-01T{i % 24:02d}:00:00",
                "file_hash": f"hash{i}"
            }
            file_hashes[f"hash{i}"] = job_id
        
        start = time.time()
        response = client.get("/api/jobs")
        elapsed = time.time() - start
        
        assert response.status_code == 200
        data = response.json()
        assert data["total_jobs"] == 100
        assert len(data["jobs"]) == 100
        assert elapsed < 0.5  # Should list 100 jobs in < 500ms
    
    # MARK: - Authentication Tests
    
    def test_login_success(self):
        """Test successful login"""
        login_data = {
            "email": "demo@example.com",
            "password": "demo123"
        }
        response = client.post("/api/auth/login", json=login_data)
        assert response.status_code == 200
        data = response.json()
        assert "token" in data
        assert "user" in data
        assert data["user"]["email"] == "demo@example.com"
        assert data["user"]["name"] == "Demo User"
    
    def test_login_invalid_credentials(self):
        """Test login with invalid credentials"""
        login_data = {
            "email": "demo@example.com",
            "password": "wrongpassword"
        }
        response = client.post("/api/auth/login", json=login_data)
        assert response.status_code == 401
        data = response.json()
        assert "Invalid email or password" in data["detail"]
    
    def test_login_case_insensitive_email(self):
        """Test login with different email casing"""
        login_data = {
            "email": "DEMO@EXAMPLE.COM",
            "password": "demo123"
        }
        response = client.post("/api/auth/login", json=login_data)
        assert response.status_code == 200
        data = response.json()
        assert data["user"]["email"] == "DEMO@EXAMPLE.COM"
    
    # MARK: - WebSocket Tests (would require async test client)
    
    def test_websocket_endpoint_exists(self):
        """Test that WebSocket endpoint is registered"""
        # Just verify the route exists
        routes = [route.path for route in app.routes]
        assert "/api/ws/progress/{job_id}" in routes or "/api/v1/ws/progress/{job_id}" in routes
    
    # MARK: - CSV Processing Tests
    
    @patch('api_server_real.enhanced_processor')
    async def test_csv_processing_async(self, mock_processor):
        """Test CSV processing with mocked processor"""
        # Mock the processor response
        mock_processor.process_csv_file.return_value = {
            "transactions": [
                {
                    "date": "2024-01-01",
                    "description": "Test Transaction",
                    "amount": -50.00,
                    "category": "Shopping",
                    "confidence": 0.95,
                    "raw_data": {"original_line": "2024-01-01,Test Transaction,-50.00"}
                }
            ],
            "metadata": {
                "row_count": 1,
                "parsed_count": 1
            }
        }
        
        csv_content = b"Date,Description,Amount\n2024-01-01,Test Transaction,-50.00"
        files = {"file": ("test.csv", io.BytesIO(csv_content), "text/csv")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 200
        
        # Wait a bit for async processing
        await asyncio.sleep(0.5)
        
        # Verify processor was called
        mock_processor.process_csv_file.assert_called_once()
    
    # MARK: - PDF Processing Tests
    
    @patch('api_server_real.processor')
    async def test_pdf_processing_async(self, mock_processor):
        """Test PDF processing with mocked processor"""
        # Mock the processor response
        mock_processor.process_pdf.return_value = {
            "transactions": [
                {
                    "date": "2024-01-01",
                    "description": "PDF Transaction",
                    "amount": -100.00,
                    "category": "Other",
                    "confidence": 0.8,
                    "has_forex": True,
                    "original_amount": -90.00,
                    "original_currency": "EUR",
                    "exchange_rate": 1.11
                }
            ]
        }
        
        pdf_content = b"%PDF-1.4\n%test pdf"
        files = {"file": ("test.pdf", io.BytesIO(pdf_content), "application/pdf")}
        
        response = client.post("/api/upload", files=files)
        assert response.status_code == 200
        
        # Wait a bit for async processing
        await asyncio.sleep(0.5)
        
        # Verify processor was called
        mock_processor.process_pdf.assert_called_once()


class TestAPIErrorHandling:
    """Test error handling scenarios"""
    
    def test_500_error_format(self):
        """Test that 500 errors return proper format"""
        # Force an internal error by accessing invalid job
        job_id = "test-error-job"
        processing_jobs[job_id] = {
            "status": "completed",
            "results": None  # This will cause an error
        }
        
        response = client.get(f"/api/transactions/{job_id}")
        assert response.status_code == 500
        data = response.json()
        assert "detail" in data
    
    def test_timeout_handling(self):
        """Test timeout error handling"""
        # This would require mocking the async timeout
        pass
    
    def test_memory_limit_handling(self):
        """Test handling of memory limit errors"""
        # This would require setting up memory constraints
        pass


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
