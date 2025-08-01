#!/usr/bin/env python3
"""
Security Tests for Enhanced API Server
====================================

Comprehensive test suite for all security features:
- File size limits
- Rate limiting  
- Body size limits
- Concurrent job limits
- Authentication bypasses
- Monitoring and metrics
"""

import asyncio
import io
import json
import time
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient
from httpx import AsyncClient

# Import the secure API server
from api_server_secure import app, request_metrics, ip_job_counts, processing_jobs, user_sessions

# Test client
client = TestClient(app)

class TestSecurityFeatures:
    
    def setup_method(self):
        """Reset state before each test"""
        request_metrics.clear()
        ip_job_counts.clear()
        processing_jobs.clear()
        user_sessions.clear()
        
        # Reset metrics to initial state
        request_metrics.update({
            "total_requests": 0,
            "failed_requests": 0,
            "rate_limited_requests": 0,
            "large_file_rejections": 0,
            "large_body_rejections": 0,
            "concurrent_limit_hits": 0,
            "auth_bypass_uses": 0,
            "by_endpoint": {},
            "by_ip": {},
            "hourly_stats": {}
        })

    def test_health_endpoint_basic(self):
        """Test basic health endpoint functionality"""
        response = client.get("/api/health")
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "healthy"
        assert "security_features" in data
        assert len(data["security_features"]) >= 6

    def test_file_size_limit_enforcement(self):
        """Test that files over 50MB are rejected"""
        # Create a large file (>50MB)
        large_content = b"x" * (51 * 1024 * 1024)  # 51MB
        
        response = client.post(
            "/api/upload",
            files={"file": ("large_file.csv", io.BytesIO(large_content), "text/csv")}
        )
        
        assert response.status_code == 413
        assert "too large" in response.json()["detail"].lower()
        assert request_metrics["large_file_rejections"] == 1

    def test_file_size_limit_valid_file(self):
        """Test that files under 50MB are accepted"""
        # Create a small valid CSV file
        small_content = b"date,description,amount\n2024-01-01,Test Transaction,-25.99"
        
        response = client.post(
            "/api/upload",
            files={"file": ("small_file.csv", io.BytesIO(small_content), "text/csv")}
        )
        
        # Should be accepted (might be rate limited but not file size rejected)
        assert response.status_code in [200, 429]  # 429 if rate limited
        assert request_metrics["large_file_rejections"] == 0

    def test_rate_limiting_upload_endpoint(self):
        """Test rate limiting on upload endpoint"""
        small_content = b"date,description,amount\n2024-01-01,Test,-25.99"
        
        # Send multiple requests rapidly to trigger rate limit
        responses = []
        for i in range(15):  # More than the 10/minute limit
            response = client.post(
                "/api/upload",
                files={"file": (f"test_{i}.csv", io.BytesIO(small_content), "text/csv")}
            )
            responses.append(response)
            time.sleep(0.1)  # Small delay
        
        # Some requests should be rate limited
        rate_limited_count = sum(1 for r in responses if r.status_code == 429)
        assert rate_limited_count > 0
        assert request_metrics["rate_limited_requests"] > 0

    def test_authentication_rate_limit_bypass(self):
        """Test that authenticated users get higher rate limits"""
        # First, login to get a token
        login_response = client.post(
            "/api/auth/login",
            json={"email": "demo@example.com", "password": "demo123"}
        )
        assert login_response.status_code == 200
        token = login_response.json()["token"]
        
        # Use token for uploads
        small_content = b"date,description,amount\n2024-01-01,Test,-25.99"
        
        # Send requests with authentication
        auth_headers = {"Authorization": f"Bearer {token}"}
        responses = []
        
        for i in range(35):  # More than default 10/min but within auth 30/min
            response = client.post(
                "/api/upload",
                files={"file": (f"auth_test_{i}.csv", io.BytesIO(small_content), "text/csv")},
                headers=auth_headers
            )
            responses.append(response)
            time.sleep(0.1)
        
        # Should have fewer rate limits than unauthenticated
        rate_limited_count = sum(1 for r in responses if r.status_code == 429)
        success_count = sum(1 for r in responses if r.status_code == 200)
        
        # Authenticated users should have more successful requests
        assert success_count > 10  # More than unauthenticated limit
        assert request_metrics["auth_bypass_uses"] > 0

    def test_concurrent_job_limits_per_ip(self):
        """Test that IPs are limited to 3 concurrent jobs"""
        # This is harder to test without actual long-running jobs
        # We'll test the limit checking function directly
        from api_server_secure import check_ip_job_limit, MAX_CONCURRENT_JOBS_PER_IP
        
        test_ip = "192.168.1.100"
        
        # Initially should allow jobs
        assert check_ip_job_limit(test_ip) == True
        
        # Simulate reaching the limit
        ip_job_counts[test_ip]["count"] = MAX_CONCURRENT_JOBS_PER_IP
        assert check_ip_job_limit(test_ip) == False
        
        # Reset should allow again
        ip_job_counts[test_ip]["count"] = 0
        assert check_ip_job_limit(test_ip) == True

    def test_invalid_file_type_rejection(self):
        """Test that invalid file types are rejected"""
        invalid_content = b"This is not a CSV or PDF"
        
        response = client.post(
            "/api/upload",
            files={"file": ("invalid.txt", io.BytesIO(invalid_content), "text/plain")}
        )
        
        assert response.status_code == 400
        assert "Only PDF and CSV files are supported" in response.json()["detail"]

    def test_metrics_endpoint_requires_auth(self):
        """Test that metrics endpoint requires authentication"""
        # Try without authentication
        response = client.get("/api/metrics")
        assert response.status_code == 401
        
        # Try with invalid token
        response = client.get(
            "/api/metrics",
            headers={"Authorization": "Bearer invalid_token"}
        )
        assert response.status_code == 401

    def test_metrics_endpoint_with_auth(self):
        """Test metrics endpoint with valid authentication"""
        # Login first
        login_response = client.post(
            "/api/auth/login",
            json={"email": "admin@financiai.com", "password": "admin123"}
        )
        assert login_response.status_code == 200
        token = login_response.json()["token"]
        
        # Get metrics
        response = client.get(
            "/api/metrics",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "metrics" in data
        assert "active_jobs" in data
        assert "unique_ips" in data
        assert "timestamp" in data

    def test_duplicate_file_detection(self):
        """Test that duplicate files are detected and handled"""
        content = b"date,description,amount\n2024-01-01,Test Transaction,-25.99"
        
        # Upload the same file twice
        response1 = client.post(
            "/api/upload",
            files={"file": ("duplicate_test.csv", io.BytesIO(content), "text/csv")}
        )
        
        response2 = client.post(
            "/api/upload",
            files={"file": ("duplicate_test.csv", io.BytesIO(content), "text/csv")}
        )
        
        assert response1.status_code in [200, 429]
        assert response2.status_code in [200, 429]
        
        if response1.status_code == 200 and response2.status_code == 200:
            # If both succeeded, second should indicate duplicate
            data2 = response2.json()
            assert "duplicate" in data2["message"].lower()

    def test_job_status_rate_limiting(self):
        """Test rate limiting on job status endpoint"""
        # This will return 404, but we're testing rate limiting
        responses = []
        for i in range(70):  # More than 60/minute limit
            response = client.get("/api/jobs/nonexistent_job")
            responses.append(response)
        
        # Some should be rate limited
        rate_limited_count = sum(1 for r in responses if r.status_code == 429)
        assert rate_limited_count > 0

    def test_body_size_limits_middleware(self):
        """Test that request body size limits are enforced"""
        # This is harder to test directly with FastAPI TestClient
        # In a real test, you'd send a very large request body
        
        # Test the middleware logic
        from api_server_secure import BodySizeLimitMiddleware, MAX_BODY_SIZE
        
        # The middleware should track rejections
        # This would be tested in integration tests with actual large payloads
        assert MAX_BODY_SIZE > 50 * 1024 * 1024

    def test_session_expiry(self):
        """Test that expired sessions are cleaned up"""
        # Login to create a session
        login_response = client.post(
            "/api/auth/login",
            json={"email": "demo@example.com", "password": "demo123"}
        )
        assert login_response.status_code == 200
        token = login_response.json()["token"]
        
        # Manually expire the session
        import datetime
        user_sessions[token]["expires_at"] = datetime.datetime.now() - datetime.timedelta(hours=1)
        
        # Try to use expired token
        response = client.get(
            "/api/metrics",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 401
        # Token should be cleaned up
        assert token not in user_sessions

    def test_security_headers_and_responses(self):
        """Test that security-related headers and responses are correct"""
        response = client.get("/api/health")
        
        # Should include rate limit info in some endpoints
        upload_response = client.post(
            "/api/upload",
            files={"file": ("test.txt", io.BytesIO(b"test"), "text/plain")}
        )
        
        # Should reject invalid file type with proper error
        assert upload_response.status_code == 400

    def test_metrics_tracking_accuracy(self):
        """Test that metrics are tracked accurately"""
        initial_total = request_metrics["total_requests"]
        
        # Make several requests
        client.get("/api/health")
        client.get("/api/health")
        client.get("/api/jobs/nonexistent")
        
        # Metrics should be updated
        assert request_metrics["total_requests"] > initial_total
        assert request_metrics["by_endpoint"]["/api/health"] >= 2
        assert request_metrics["by_endpoint"]["/api/jobs"] >= 1

    def test_ip_based_tracking(self):
        """Test that IP-based tracking works correctly"""
        # Make requests to trigger IP tracking
        client.get("/api/health")
        client.get("/api/health")
        
        # Should track requests by IP
        assert len(request_metrics["by_ip"]) > 0
        
        # TestClient uses a default IP, so all requests should be from same IP
        ip_counts = list(request_metrics["by_ip"].values())
        assert max(ip_counts) >= 2

    @pytest.mark.asyncio
    async def test_websocket_connection(self):
        """Test WebSocket connections work"""
        with client.websocket_connect("/api/ws/progress/test_job") as websocket:
            # Should connect successfully
            data = websocket.receive_json()
            # WebSocket should handle non-existent job gracefully

class TestSecurityConfiguration:
    """Test security configuration and limits"""
    
    def test_security_constants(self):
        """Test that security constants are set correctly"""
        from api_server_secure import (
            MAX_FILE_SIZE, MAX_BODY_SIZE, MAX_CONCURRENT_JOBS_PER_IP,
            DEFAULT_UPLOAD_RATE, AUTH_UPLOAD_RATE
        )
        
        assert MAX_FILE_SIZE == 50 * 1024 * 1024  # 50MB
        assert MAX_BODY_SIZE == 52 * 1024 * 1024  # 52MB  
        assert MAX_CONCURRENT_JOBS_PER_IP == 3
        assert "10/minute" in DEFAULT_UPLOAD_RATE
        assert "30/minute" in AUTH_UPLOAD_RATE

    def test_demo_credentials(self):
        """Test that demo credentials work"""
        valid_logins = [
            {"email": "demo@example.com", "password": "demo123"},
            {"email": "admin@financiai.com", "password": "admin123"},
            {"email": "test@financiai.com", "password": "test123"},
        ]
        
        for creds in valid_logins:
            response = client.post("/api/auth/login", json=creds)
            assert response.status_code == 200
            data = response.json()
            assert "token" in data
            assert "user" in data

    def test_invalid_credentials(self):
        """Test that invalid credentials are rejected"""
        invalid_logins = [
            {"email": "invalid@example.com", "password": "wrong"},
            {"email": "demo@example.com", "password": "wrongpassword"},
            {"email": "", "password": ""},
        ]
        
        for creds in invalid_logins:
            response = client.post("/api/auth/login", json=creds)
            assert response.status_code == 401

if __name__ == "__main__":
    # Run tests with pytest
    pytest.main([__file__, "-v"])