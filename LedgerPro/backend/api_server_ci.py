#!/usr/bin/env python3
"""
CI-specific API server for GitHub Actions testing
Simplified version of api_server_secure.py with CI-friendly configuration
"""

import os
import sys
import asyncio
from datetime import datetime

# FastAPI imports
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Set environment variables for CI
os.environ["CI_MODE"] = "true"
os.environ["DEBUG_MODE"] = "false"


# Initialize FastAPI app with CI configuration
app = FastAPI(
    title="AI Financial Accountant API (CI)",
    description="CI-friendly version for automated testing",
    version="1.0.0-ci",
    docs_url="/docs",  # Enable docs in CI for debugging
    redoc_url="/redoc",
)

# Simple CORS configuration for CI
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins in CI
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Simple response models
class HealthResponse(BaseModel):
    status: str
    timestamp: str
    version: str
    environment: str
    message: str


class SimpleResponse(BaseModel):
    message: str
    status: str


# In-memory storage for CI
test_data = {"jobs": {}, "health_checks": 0}


@app.get("/", response_model=SimpleResponse)
async def root():
    """Root endpoint"""
    return SimpleResponse(
        message="AI Financial Accountant API (CI Mode)", status="running"
    )


@app.get("/api/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint optimized for CI"""
    test_data["health_checks"] += 1

    return HealthResponse(
        status="healthy",
        timestamp=datetime.now().isoformat(),
        version="1.0.0-ci",
        environment="ci",
        message=f"CI server running - {test_data['health_checks']} health checks",
    )


@app.get("/api/status")
async def status():
    """Simple status endpoint"""
    return {
        "status": "ok",
        "mode": "ci",
        "checks": test_data["health_checks"],
        "jobs": len(test_data["jobs"]),
    }


@app.post("/api/test")
async def test_endpoint():
    """Test endpoint for CI validation"""
    return {
        "test": "success",
        "timestamp": datetime.now().isoformat(),
        "environment": "ci",
    }


# Simple error handler
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler for CI debugging"""
    print(f"CI Server Error: {exc}")
    return HTTPException(status_code=500, detail=f"CI Server Error: {str(exc)}")


def main():
    """Main entry point for CI server"""
    print("🚀 Starting CI-specific API server...")
    print("=" * 50)
    print("Environment: CI Mode")
    print(f"Python version: {sys.version}")
    print("FastAPI version: Starting server...")
    print("=" * 50)

    try:
        import uvicorn

        # Simple configuration for CI
        uvicorn.run(
            "api_server_ci:app",
            host="127.0.0.1",
            port=8000,
            log_level="info",
            access_log=True,
            reload=False,  # No reload in CI
        )
    except Exception as e:
        print(f"❌ Failed to start CI server: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
