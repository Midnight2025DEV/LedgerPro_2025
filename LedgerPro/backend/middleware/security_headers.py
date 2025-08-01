"""
Security Headers Middleware
==========================

FastAPI middleware to add security headers to all responses.
Helps protect against various web vulnerabilities.
"""

import os

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Middleware to add security headers to all responses."""

    def __init__(self, app: ASGIApp):
        super().__init__(app)
        self.is_production = os.getenv("ENVIRONMENT", "").lower() == "production"

    async def dispatch(self, request: Request, call_next):
        """Add security headers to response."""
        response = await call_next(request)

        # Content Security Policy
        csp_directives = [
            "default-src 'sel'",
            "script-src 'sel' 'unsafe-inline' 'unsafe-eval'",  # Relaxed for development
            "style-src 'sel' 'unsafe-inline'",
            "img-src 'sel' data: https:",
            "font-src 'sel'",
            "connect-src 'sel'",
            "media-src 'none'",
            "object-src 'none'",
            "frame-src 'none'",
            "base-uri 'sel'",
            "form-action 'sel'",
        ]

        if self.is_production:
            # Stricter CSP for production
            csp_directives[1] = "script-src 'self'"  # Remove unsafe-inline/eval

        response.headers["Content-Security-Policy"] = "; ".join(csp_directives)

        # HTTP Strict Transport Security (HTTPS only)
        if self.is_production:
            response.headers["Strict-Transport-Security"] = (
                "max-age=31536000; includeSubDomains; preload"
            )

        # Prevent MIME type sniffing
        response.headers["X-Content-Type-Options"] = "nosnif"

        # Clickjacking protection
        response.headers["X-Frame-Options"] = "DENY"

        # XSS Protection (legacy but still useful)
        response.headers["X-XSS-Protection"] = "1; mode=block"

        # Referrer Policy
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"

        # Permissions Policy (formerly Feature-Policy)
        permissions_directives = [
            "camera=()",
            "microphone=()",
            "geolocation=()",
            "payment=()",
            "usb=()",
            "magnetometer=()",
            "accelerometer=()",
            "gyroscope=()",
        ]
        response.headers["Permissions-Policy"] = ", ".join(permissions_directives)

        # Remove server headers that might reveal information
        response.headers.pop("server", None)
        response.headers.pop("x-powered-by", None)

        # Custom security header to identify our application
        response.headers["X-Security-Policy"] = "LedgerPro-Security-v1.0"

        return response
