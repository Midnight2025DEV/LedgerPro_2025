#!/usr/bin/env python3
"""
Security Configuration for LedgerPro API
=======================================

Centralized configuration for all security settings.
Environment variables override defaults.
"""

import os
from typing import Dict, List

class SecurityConfig:
    """Centralized security configuration"""
    
    # File size limits
    MAX_FILE_SIZE_MB: int = int(os.getenv("MAX_FILE_SIZE_MB", "50"))
    MAX_BODY_SIZE_MB: int = int(os.getenv("MAX_BODY_SIZE_MB", "52"))
    
    # Rate limiting configuration
    RATE_LIMIT_UPLOADS_UNAUTH: str = os.getenv("RATE_LIMIT_UPLOADS_UNAUTH", "10/minute")
    RATE_LIMIT_UPLOADS_AUTH: str = os.getenv("RATE_LIMIT_UPLOADS_AUTH", "30/minute")
    RATE_LIMIT_JOBS: str = os.getenv("RATE_LIMIT_JOBS", "60/minute")
    RATE_LIMIT_TRANSACTIONS: str = os.getenv("RATE_LIMIT_TRANSACTIONS", "30/minute")
    RATE_LIMIT_METRICS: str = os.getenv("RATE_LIMIT_METRICS", "5/minute")
    RATE_LIMIT_HEALTH: str = os.getenv("RATE_LIMIT_HEALTH", "30/minute")
    
    # Concurrent job limits
    MAX_CONCURRENT_JOBS_PER_IP: int = int(os.getenv("MAX_CONCURRENT_JOBS_PER_IP", "3"))
    IP_LIMIT_RESET_HOURS: int = int(os.getenv("IP_LIMIT_RESET_HOURS", "1"))
    
    # Session configuration
    SESSION_EXPIRY_HOURS: int = int(os.getenv("SESSION_EXPIRY_HOURS", "24"))
    
    # Processing timeouts
    CSV_PROCESSING_TIMEOUT: int = int(os.getenv("CSV_PROCESSING_TIMEOUT", "30"))
    PDF_PROCESSING_TIMEOUT: int = int(os.getenv("PDF_PROCESSING_TIMEOUT", "60"))
    
    # Thread pool configuration
    MAX_WORKERS: int = int(os.getenv("MAX_WORKERS", "2"))
    
    # CORS configuration
    ALLOWED_ORIGINS: List[str] = os.getenv(
        "ALLOWED_ORIGINS", 
        "http://localhost:5173,http://127.0.0.1:5173,http://localhost:3000,http://127.0.0.1:3000"
    ).split(",")
    
    # API documentation
    ENABLE_DOCS: bool = os.getenv("ENABLE_DOCS", "false").lower() == "true"
    
    # Demo credentials (for development only)
    DEMO_USERS: Dict[str, Dict[str, str]] = {
        "demo@example.com": {
            "password": os.getenv("DEMO_PASSWORD", "demo123"),
            "name": "Demo User",
            "role": "user"
        },
        "test@financiai.com": {
            "password": os.getenv("TEST_PASSWORD", "test123"),
            "name": "Test User", 
            "role": "user"
        },
        "admin@financiai.com": {
            "password": os.getenv("ADMIN_PASSWORD", "admin123"),
            "name": "Admin User",
            "role": "admin"
        },
    }
    
    # Server configuration
    HOST: str = os.getenv("HOST", "127.0.0.1")
    PORT: int = int(os.getenv("PORT", "8000"))
    
    # Computed properties
    @property
    def max_file_size_bytes(self) -> int:
        return self.MAX_FILE_SIZE_MB * 1024 * 1024
    
    @property
    def max_body_size_bytes(self) -> int:
        return self.MAX_BODY_SIZE_MB * 1024 * 1024
    
    def get_summary(self) -> Dict[str, any]:
        """Get configuration summary for logging/debugging"""
        return {
            "file_limits": {
                "max_file_size_mb": self.MAX_FILE_SIZE_MB,
                "max_body_size_mb": self.MAX_BODY_SIZE_MB,
            },
            "rate_limits": {
                "uploads_unauth": self.RATE_LIMIT_UPLOADS_UNAUTH,
                "uploads_auth": self.RATE_LIMIT_UPLOADS_AUTH,
                "jobs": self.RATE_LIMIT_JOBS,
                "transactions": self.RATE_LIMIT_TRANSACTIONS,
                "metrics": self.RATE_LIMIT_METRICS,
            },
            "concurrency": {
                "max_jobs_per_ip": self.MAX_CONCURRENT_JOBS_PER_IP,
                "ip_reset_hours": self.IP_LIMIT_RESET_HOURS,
                "max_workers": self.MAX_WORKERS,
            },
            "timeouts": {
                "csv_processing": self.CSV_PROCESSING_TIMEOUT,
                "pdf_processing": self.PDF_PROCESSING_TIMEOUT,
            },
            "server": {
                "host": self.HOST,
                "port": self.PORT,
                "docs_enabled": self.ENABLE_DOCS,
            }
        }

# Global configuration instance
config = SecurityConfig()

# Environment variable documentation
ENV_VARS_DOCUMENTATION = """
Environment Variables for Security Configuration:
================================================

File Size Limits:
- MAX_FILE_SIZE_MB: Maximum upload file size in MB (default: 50)
- MAX_BODY_SIZE_MB: Maximum request body size in MB (default: 52)

Rate Limiting:
- RATE_LIMIT_UPLOADS_UNAUTH: Upload rate for unauthenticated users (default: "10/minute")
- RATE_LIMIT_UPLOADS_AUTH: Upload rate for authenticated users (default: "30/minute")  
- RATE_LIMIT_JOBS: Job status check rate (default: "60/minute")
- RATE_LIMIT_TRANSACTIONS: Transaction fetch rate (default: "30/minute")
- RATE_LIMIT_METRICS: Metrics access rate (default: "5/minute")

Concurrency:
- MAX_CONCURRENT_JOBS_PER_IP: Max simultaneous jobs per IP (default: 3)
- IP_LIMIT_RESET_HOURS: Hours before IP limits reset (default: 1)
- MAX_WORKERS: Thread pool size (default: 2)

Timeouts:
- CSV_PROCESSING_TIMEOUT: CSV processing timeout in seconds (default: 30)
- PDF_PROCESSING_TIMEOUT: PDF processing timeout in seconds (default: 60)

Security:
- SESSION_EXPIRY_HOURS: Session token expiry time (default: 24)
- DEMO_PASSWORD: Demo user password (default: "demo123")
- TEST_PASSWORD: Test user password (default: "test123")
- ADMIN_PASSWORD: Admin user password (default: "admin123")

Server:
- HOST: Server host (default: "127.0.0.1")
- PORT: Server port (default: 8000)
- ENABLE_DOCS: Enable API documentation (default: false)
- ALLOWED_ORIGINS: Comma-separated CORS origins

Example Production Configuration:
=================================

export MAX_FILE_SIZE_MB=100
export RATE_LIMIT_UPLOADS_UNAUTH="5/minute"
export RATE_LIMIT_UPLOADS_AUTH="50/minute"
export MAX_CONCURRENT_JOBS_PER_IP=5
export SESSION_EXPIRY_HOURS=8
export ENABLE_DOCS=false
export ADMIN_PASSWORD="secure_random_password_here"
"""

if __name__ == "__main__":
    print("Security Configuration Summary:")
    print("=" * 50)
    import json
    print(json.dumps(config.get_summary(), indent=2))
    print()
    print(ENV_VARS_DOCUMENTATION)