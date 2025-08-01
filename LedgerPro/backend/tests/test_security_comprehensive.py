"""
Comprehensive Security Test Suite
================================

Tests for security vulnerabilities and hardening measures.
Covers authentication, file handling, input validation, and more.
"""

import hashlib
import os
from unittest.mock import MagicMock, patch

import pytest

# Import our security modules
from config.secure_auth import SecureAuthConfig
from middleware.security_headers import SecurityHeadersMiddleware
from utils.secure_file_handler import SecureFileHandler


class TestSecureAuth:
    """Test secure authentication functionality."""

    def setup_method(self):
        """Set up test environment."""
        self.auth = SecureAuthConfig()

    def test_password_hashing(self):
        """Test password hashing and verification."""
        password = "test_password_123"

        # Hash the password
        password_hash = self.auth._hash_password(password)

        # Verify correct password
        assert self.auth.verify_password(password_hash, password)

        # Verify incorrect password fails
        assert not self.auth.verify_password(password_hash, "wrong_password")

        # Verify hashed password contains salt
        assert len(password_hash) > 64  # Salt (64 chars) + hash

    def test_secure_token_generation(self):
        """Test secure token generation."""
        token1 = self.auth.generate_secure_token()
        token2 = self.auth.generate_secure_token()

        # Tokens should be different
        assert token1 != token2

        # Tokens should be long enough (secure)
        assert len(token1) >= 32
        assert len(token2) >= 32

    def test_error_message_sanitization(self):
        """Test error message sanitization."""
        # Test production mode sanitization
        sensitive_error = (
            "Database connection failed "
            "at /usr/local/db/config.sql with password=secret123"
        )
        sanitized = self.auth.sanitize_error_message(
            sensitive_error, is_production=True
        )

        assert "password=secret123" not in sanitized
        assert "/usr/local/db/config.sql" not in sanitized
        assert sanitized == "Database error"  # Generic message

        # Test development mode sanitization
        dev_sanitized = self.auth.sanitize_error_message(
            sensitive_error, is_production=False
        )
        assert "password=secret123" not in dev_sanitized  # Should still be redacted
        assert "[REDACTED]" in dev_sanitized

    def test_demo_users_from_environment(self):
        """Test demo user creation from environment variables."""
        with patch.dict(
            os.environ,
            {
                "DEMO_USER_EMAIL": "test@secure.com",
                "DEMO_USER_PASSWORD": "secure_password_456",
                "DEMO_USER_NAME": "Test User",
            },
        ):
            auth = SecureAuthConfig()
            demo_users = auth.get_demo_users()

            assert "test@secure.com" in demo_users
            user = demo_users["test@secure.com"]
            assert user["name"] == "Test User"
            assert auth.verify_password(user["password_hash"], "secure_password_456")


class TestSecureFileHandler:
    """Test secure file handling functionality."""

    def setup_method(self):
        """Set up test environment."""
        self.handler = SecureFileHandler()

    def test_filename_sanitization(self):
        """Test filename sanitization against path traversal."""
        # Test normal filename
        assert self.handler.sanitize_filename("test.pd") == "test.pd"

        # Test path traversal attempts
        with pytest.raises(ValueError, match="directory traversal"):
            self.handler.sanitize_filename("../../../etc/passwd")

        with pytest.raises(ValueError, match="directory traversal"):
            self.handler.sanitize_filename("..\\windows\\system32")

        with pytest.raises(ValueError, match="directory traversal"):
            self.handler.sanitize_filename("test/../../../secret.txt")

        # Test null byte injection
        clean = self.handler.sanitize_filename("test\x00.pd")
        assert "\x00" not in clean

        # Test empty filename
        with pytest.raises(ValueError, match="empty"):
            self.handler.sanitize_filename("")

        # Test dot files
        with pytest.raises(ValueError, match="Invalid filename"):
            self.handler.sanitize_filename(".")

        with pytest.raises(ValueError, match="Invalid filename"):
            self.handler.sanitize_filename("..")

    def test_file_type_validation(self):
        """Test file type validation using magic numbers."""
        # Create test PDF content
        pdf_content = b(
            "%PDF-1.4\n1 0 obj\n<<>>\nendobj\nxref\n0 "
            "1\n0000000000 65535 f \ntrailer\n<<>>\nstartxref\n0\n%%EOF"
        )

        # Create test CSV content
        csv_content = b"Date,Description,Amount\n2024-01-01,Test Transaction,100.00\n"

        # Test valid PDF
        mime_type, ext = self.handler.validate_file_type(pdf_content, "test.pd")
        assert mime_type == "application/pd"
        assert ext == ".pd"

        # Test valid CSV
        mime_type, ext = self.handler.validate_file_type(csv_content, "test.csv")
        assert mime_type in ["text/csv", "application/csv", "text/plain"]
        assert ext == ".csv"

        # Test empty file
        with pytest.raises(ValueError, match="empty"):
            self.handler.validate_file_type(b"", "test.pd")

        # Test file too large
        large_content = b"x" * (51 * 1024 * 1024)  # 51MB
        with pytest.raises(ValueError, match="too large"):
            self.handler.validate_file_type(large_content, "large.pd")

        # Test invalid file type
        exe_content = b"MZ\x90\x00"  # PE/EXE header
        with pytest.raises(ValueError, match="not allowed"):
            self.handler.validate_file_type(exe_content, "malware.exe")

    def test_secure_file_path_generation(self):
        """Test secure file path generation."""
        job_id = "test-job-123"
        filename = "statement.pd"

        secure_path = self.handler.get_secure_file_path(filename, job_id)

        # Path should be within secure directory
        assert str(secure_path).startswith(self.handler.secure_temp_dir)

        # Filename should contain job_id
        assert job_id in str(secure_path.name)

        # Should handle path traversal in filename
        with pytest.raises(ValueError):
            self.handler.get_secure_file_path("../../../etc/passwd", job_id)

    def test_secure_temporary_file_context(self):
        """Test secure temporary file context manager."""
        job_id = "test-context-job"
        filename = "test.csv"
        content = b"Date,Description,Amount\n2024-01-01,Test,100.00\n"

        with self.handler.secure_temporary_file(filename, job_id, content) as (
            temp_path,
            mime_type,
            ext,
        ):
            # File should exist
            assert os.path.exists(temp_path)

            # File should have correct content
            with open(temp_path, "rb") as f:
                assert f.read() == content

            # File should have restrictive permissions
            file_stat = os.stat(temp_path)
            # Check that file is readable/writable by owner only (0o600)
            assert oct(file_stat.st_mode)[-3:] == "600"

        # File should be cleaned up after context
        assert not os.path.exists(temp_path)

    def test_file_hash_calculation(self):
        """Test file hash calculation for integrity."""
        content = b"test content for hashing"
        expected_hash = hashlib.sha256(content).hexdigest()

        calculated_hash = self.handler.calculate_file_hash(content)
        assert calculated_hash == expected_hash


class TestPathTraversalAttacks:
    """Test various path traversal attack vectors."""

    def setup_method(self):
        """Set up test environment."""
        self.handler = SecureFileHandler()

    def test_unix_path_traversal(self):
        """Test Unix-style path traversal attacks."""
        attacks = [
            "../../../etc/passwd",
            "..%2F..%2F..%2Fetc%2Fpasswd",  # URL encoded
            "..%252F..%252F..%252Fetc%252Fpasswd",  # Double URL encoded
            "....//....//....//etc/passwd",  # Double dots with slash
        ]

        for attack in attacks:
            with pytest.raises(ValueError):
                self.handler.sanitize_filename(attack)

    def test_windows_path_traversal(self):
        """Test Windows-style path traversal attacks."""
        attacks = [
            "..\\..\\..\\windows\\system32\\config\\sam",
            "..%5C..%5C..%5Cwindows%5Csystem32",  # URL encoded
            "....\\\\....\\\\....\\\\windows\\system32",
        ]

        for attack in attacks:
            with pytest.raises(ValueError):
                self.handler.sanitize_filename(attack)

    def test_null_byte_injection(self):
        """Test null byte injection attacks."""
        attacks = [
            "innocent.txt\x00.php",
            "test\x00.exe",
            "file.pdf\x00../../../etc/passwd",
        ]

        for attack in attacks:
            clean = self.handler.sanitize_filename(attack)
            assert "\x00" not in clean


class TestSecurityHeaders:
    """Test security headers middleware."""

    def setup_method(self):
        """Set up test environment."""
        # Mock FastAPI app
        self.mock_app = MagicMock()
        self.middleware = SecurityHeadersMiddleware(self.mock_app)

    @pytest.mark.asyncio
    async def test_security_headers_added(self):
        """Test that security headers are added to responses."""
        # Mock request and response
        mock_request = MagicMock()
        mock_response = MagicMock()
        mock_response.headers = {}

        # Mock call_next to return our mock response
        async def mock_call_next(request):
            return mock_response

        # Call the middleware
        result = await self.middleware.dispatch(mock_request, mock_call_next)

        # Check that security headers were added
        headers = result.headers

        # Check required security headers
        assert "Content-Security-Policy" in headers
        assert "X-Content-Type-Options" in headers
        assert "X-Frame-Options" in headers
        assert "X-XSS-Protection" in headers
        assert "Referrer-Policy" in headers
        assert "Permissions-Policy" in headers
        assert "X-Security-Policy" in headers

        # Check CSP contains required directives
        csp = headers["Content-Security-Policy"]
        assert "default-src 'sel'" in csp
        assert "object-src 'none'" in csp
        assert "frame-src 'none'" in csp

        # Check frame options
        assert headers["X-Frame-Options"] == "DENY"

        # Check content type options
        assert headers["X-Content-Type-Options"] == "nosnif"

    @pytest.mark.asyncio
    async def test_production_headers(self):
        """Test stricter headers in production mode."""
        # Mock production environment
        with patch.dict(os.environ, {"ENVIRONMENT": "production"}):
            middleware = SecurityHeadersMiddleware(self.mock_app)

            mock_request = MagicMock()
            mock_response = MagicMock()
            mock_response.headers = {}

            async def mock_call_next(request):
                return mock_response

            result = await middleware.dispatch(mock_request, mock_call_next)
            headers = result.headers

            # Check for HSTS header in production
            assert "Strict-Transport-Security" in headers
            hsts = headers["Strict-Transport-Security"]
            assert "max-age=31536000" in hsts
            assert "includeSubDomains" in hsts


class TestInputValidation:
    """Test input validation and sanitization."""

    def test_job_id_validation(self):
        """Test job ID format validation."""
        # Valid UUIDs should pass
        valid_ids = [
            "550e8400-e29b-41d4-a716-446655440000",
            "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
        ]

        for valid_id in valid_ids:
            # Should not raise exception
            import uuid

            uuid.UUID(valid_id)

        # Invalid formats should fail
        invalid_ids = [
            "not-a-uuid",
            "123",
            "../../../etc/passwd",
            "'; DROP TABLE users; --",
            "<script>alert('xss')</script>",
        ]

        for invalid_id in invalid_ids:
            with pytest.raises(ValueError):
                import uuid

                uuid.UUID(invalid_id)


class TestSecurityConfiguration:
    """Test security configuration and environment handling."""

    def test_production_mode_detection(self):
        """Test production mode detection."""
        auth = SecureAuthConfig()

        # Test development mode (default)
        with patch.dict(os.environ, {}, clear=True):
            assert not auth.is_production()

        # Test production mode
        with patch.dict(os.environ, {"ENVIRONMENT": "production"}):
            auth_prod = SecureAuthConfig()
            assert auth_prod.is_production()

    def test_secret_key_handling(self):
        """Test secret key generation and handling."""
        # Test with environment variable
        with patch.dict(os.environ, {"LEDGER_SECRET_KEY": "test_secret_key_123"}):
            auth = SecureAuthConfig()
            assert auth.secret_key == "test_secret_key_123"

        # Test without environment variable (should generate)
        with patch.dict(os.environ, {}, clear=True):
            auth = SecureAuthConfig()
            assert len(auth.secret_key) >= 32  # Should be a secure random key


if __name__ == "__main__":
    # Run tests with pytest
    import subprocess
    import sys

    print("🔐 Running Comprehensive Security Test Suite...")
    result = subprocess.run(
        [sys.executable, "-m", "pytest", __file__, "-v", "--tb=short"],
        capture_output=False,
    )

    if result.returncode == 0:
        print("✅ All security tests passed!")
    else:
        print("❌ Some security tests failed!")
        sys.exit(1)
