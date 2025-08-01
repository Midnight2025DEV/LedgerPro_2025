#!/usr/bin/env python3
"""
AI Financial Accountant - Secure FastAPI Server with Rate Limiting
================================================================

Production API server with comprehensive security protections:
- File size limits (50MB)
- Request rate limiting per IP
- Body size limits middleware  
- Concurrent job limits per IP
- Enhanced authentication with bypass privileges
- Comprehensive monitoring and metrics
"""

import asyncio
import hashlib
import os
import tempfile
import uuid
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta
from typing import Any, Dict, Optional

import aiofiles

# FastAPI and security imports
from fastapi import (
    FastAPI,
    File,
    HTTPException,
    UploadFile,
    status,
    WebSocket,
    WebSocketDisconnect,
    Request,
    Depends,
)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from starlette.middleware.base import BaseHTTPMiddleware

# Rate limiting imports
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# Import the real processors
from processors.python.camelot_processor import CamelotFinancialProcessor
from processors.python.csv_processor_enhanced import EnhancedCSVProcessor

# MARK: - Security Configuration

# File size limits
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB limit
MAX_BODY_SIZE = 52 * 1024 * 1024  # 52MB body limit (slightly larger for overhead)

# Rate limiting configuration
DEFAULT_UPLOAD_RATE = "10/minute"  # 10 uploads per minute for unauthenticated
AUTH_UPLOAD_RATE = "30/minute"     # 30 uploads per minute for authenticated
JOB_STATUS_RATE = "60/minute"      # 60 job status checks per minute
TRANSACTION_RATE = "30/minute"     # 30 transaction requests per minute
METRICS_RATE = "5/minute"          # 5 metrics requests per minute

# Concurrent job limits
MAX_CONCURRENT_JOBS_PER_IP = 3
IP_LIMIT_RESET_HOURS = 1

# Enhanced processor setup
enhanced_processor = EnhancedCSVProcessor()
executor = ThreadPoolExecutor(max_workers=2)
processor = CamelotFinancialProcessor()

# MARK: - Security Middleware

class BodySizeLimitMiddleware(BaseHTTPMiddleware):
    """Middleware to limit request body size and prevent memory exhaustion"""
    
    def __init__(self, app, max_body_size: int = MAX_BODY_SIZE):
        super().__init__(app)
        self.max_body_size = max_body_size
    
    async def dispatch(self, request, call_next):
        if request.headers.get("content-length"):
            content_length = int(request.headers["content-length"])
            if content_length > self.max_body_size:
                request_metrics["large_body_rejections"] += 1
                return JSONResponse(
                    status_code=413,
                    content={
                        "detail": f"Request body too large. Maximum size is {self.max_body_size // (1024*1024)}MB"
                    }
                )
        return await call_next(request)

# MARK: - FastAPI App Setup

# Initialize FastAPI app with security-focused configuration
app = FastAPI(
    title="AI Financial Accountant API (Secure)",
    description="Production API with comprehensive security protections and rate limiting",
    version="2.0.0",
    docs_url="/docs" if os.getenv("ENABLE_DOCS", "false").lower() == "true" else None,
    redoc_url="/redoc" if os.getenv("ENABLE_DOCS", "false").lower() == "true" else None,
)

# MARK: - Rate Limiting Setup

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# MARK: - Security Middleware Setup

# Add body size limiting middleware
app.add_middleware(BodySizeLimitMiddleware, max_body_size=MAX_BODY_SIZE)

# CORS middleware with security-focused configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173", 
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# MARK: - Security and Monitoring State

# In-memory storage (in production, use Redis or database)
processing_jobs: Dict[str, Dict] = {}
user_sessions: Dict[str, Dict] = {}
file_hashes: Dict[str, str] = {}

# IP-based job tracking for rate limiting
ip_job_counts = defaultdict(lambda: {"count": 0, "reset_time": datetime.now()})

# Request metrics and monitoring
request_metrics = {
    "total_requests": 0,
    "failed_requests": 0,
    "rate_limited_requests": 0,
    "large_file_rejections": 0,
    "large_body_rejections": 0,
    "concurrent_limit_hits": 0,
    "auth_bypass_uses": 0,
    "by_endpoint": defaultdict(int),
    "by_ip": defaultdict(int),
    "hourly_stats": defaultdict(lambda: {
        "requests": 0,
        "uploads": 0,
        "errors": 0
    })
}

# MARK: - Authentication Setup

security = HTTPBearer(auto_error=False)

async def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
) -> Optional[Dict[str, Any]]:
    """Optional authentication - returns user if authenticated, None otherwise"""
    if not credentials:
        return None
    
    token = credentials.credentials
    if token in user_sessions:
        session = user_sessions[token]
        if datetime.now() < session["expires_at"]:
            return session["user"]
        else:
            # Clean up expired session
            del user_sessions[token]
    
    return None

# MARK: - Security Helper Functions

def check_ip_job_limit(ip_address: str) -> bool:
    """Check if IP has reached concurrent job limit"""
    now = datetime.now()
    ip_data = ip_job_counts[ip_address]
    
    # Reset counter every hour
    if now > ip_data["reset_time"] + timedelta(hours=IP_LIMIT_RESET_HOURS):
        ip_data["count"] = 0
        ip_data["reset_time"] = now
    
    if ip_data["count"] >= MAX_CONCURRENT_JOBS_PER_IP:
        # Check if any jobs have actually completed
        active_jobs = sum(1 for job in processing_jobs.values() 
                         if job.get("ip_address") == ip_address 
                         and job["status"] in ["processing", "extracting_tables", "analyzing_transactions"])
        ip_data["count"] = active_jobs
        
        if active_jobs >= MAX_CONCURRENT_JOBS_PER_IP:
            return False
    
    return True

def update_request_metrics(endpoint: str, ip_address: str, success: bool = True):
    """Update request metrics for monitoring"""
    request_metrics["total_requests"] += 1
    request_metrics["by_endpoint"][endpoint] += 1
    request_metrics["by_ip"][ip_address] += 1
    
    if not success:
        request_metrics["failed_requests"] += 1
    
    # Update hourly stats
    hour_key = datetime.now().strftime("%Y-%m-%d-%H")
    request_metrics["hourly_stats"][hour_key]["requests"] += 1
    if not success:
        request_metrics["hourly_stats"][hour_key]["errors"] += 1

def validate_file_size(file_content: bytes, filename: str) -> None:
    """Validate file size and raise appropriate exception if too large"""
    if len(file_content) > MAX_FILE_SIZE:
        request_metrics["large_file_rejections"] += 1
        raise HTTPException(
            status_code=413,
            detail=f"File '{filename}' is too large. Maximum size is {MAX_FILE_SIZE // (1024*1024)}MB. "
                   f"Current size: {len(file_content) // (1024*1024)}MB"
        )

# MARK: - Custom Rate Limit Exception Handler

@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    """Custom handler for rate limit exceeded"""
    request_metrics["rate_limited_requests"] += 1
    client_ip = get_remote_address(request)
    request_metrics["by_ip"][client_ip] += 1
    
    update_request_metrics(str(request.url.path), client_ip, success=False)
    
    return JSONResponse(
        status_code=429,
        content={
            "detail": f"Rate limit exceeded: {exc.detail}",
            "retry_after": "60",
            "tip": "Consider authenticating for higher rate limits"
        },
        headers={"Retry-After": "60"}
    )

# MARK: - Pydantic Models

class LoginRequest(BaseModel):
    email: str
    password: str

class LoginResponse(BaseModel):
    token: str
    user: Dict[str, Any]

class UploadResponse(BaseModel):
    job_id: str
    status: str
    message: str

class MetricsResponse(BaseModel):
    metrics: Dict[str, Any]
    active_jobs: int
    unique_ips: int
    timestamp: str

# MARK: - API Endpoints

@app.get("/api/health")
@limiter.limit("30/minute")
async def health_check(request: Request):
    """Health check endpoint with basic rate limiting"""
    client_ip = get_remote_address(request)
    update_request_metrics("/api/health", client_ip)
    
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "2.0.0",
        "message": "AI Financial Accountant API is running (SECURE + RATE LIMITED)",
        "processor": "CamelotFinancialProcessor",
        "security_features": [
            "File size limits",
            "Rate limiting",
            "Body size limits", 
            "Concurrent job limits",
            "Enhanced authentication",
            "Request monitoring"
        ]
    }

@app.post("/api/auth/login", response_model=LoginResponse)
@limiter.limit("10/minute")
async def login(request: Request, login_request: LoginRequest):
    """Enhanced authentication endpoint with rate limiting"""
    client_ip = get_remote_address(request)
    update_request_metrics("/api/auth/login", client_ip)
    
    # Demo credentials for local testing
    demo_users = {
        "demo@example.com": {"password": "demo123", "name": "Demo User", "role": "user"},
        "test@financiai.com": {"password": "test123", "name": "Test User", "role": "user"},
        "admin@financiai.com": {"password": "admin123", "name": "Admin User", "role": "admin"},
    }

    user_info = demo_users.get(login_request.email.lower())
    if not user_info or user_info["password"] != login_request.password:
        update_request_metrics("/api/auth/login", client_ip, success=False)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Invalid email or password"
        )

    # Create session token
    token = str(uuid.uuid4())
    user_data = {
        "id": str(uuid.uuid4()),
        "email": login_request.email,
        "name": user_info["name"],
        "role": user_info["role"],
        "created_at": datetime.now().isoformat(),
    }

    # Store session with 24 hour expiry
    user_sessions[token] = {
        "user": user_data,
        "expires_at": datetime.now() + timedelta(hours=24),
        "ip_address": client_ip,
        "created_at": datetime.now().isoformat()
    }

    return LoginResponse(token=token, user=user_data)

@app.post("/api/upload", response_model=UploadResponse)
@app.post("/api/v1/upload", response_model=UploadResponse)
@limiter.limit(DEFAULT_UPLOAD_RATE)
async def upload_file(
    request: Request,
    file: UploadFile = File(...),
    current_user = Depends(get_current_user_optional)
):
    """Secure upload endpoint with comprehensive protection"""
    client_ip = get_remote_address(request)
    
    # Apply different rate limits based on authentication
    if current_user:
        request_metrics["auth_bypass_uses"] += 1
        # Check higher rate limit for authenticated users
        try:
            await limiter.check_request(request, AUTH_UPLOAD_RATE)
        except RateLimitExceeded as e:
            raise e
    
    # Update metrics
    update_request_metrics("/api/upload", client_ip)
    request_metrics["hourly_stats"][datetime.now().strftime("%Y-%m-%d-%H")]["uploads"] += 1
    
    # Validate file type
    if not file.filename.lower().endswith((".pdf", ".csv")):
        update_request_metrics("/api/upload", client_ip, success=False)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only PDF and CSV files are supported",
        )

    # Read file content and validate size
    file_content = await file.read()
    await file.seek(0)  # Reset file pointer
    
    # SECURITY: File size validation
    validate_file_size(file_content, file.filename)

    # Calculate file hash for duplicate detection
    file_hash = hashlib.sha256(file_content).hexdigest()

    # Check for duplicates
    if file_hash in file_hashes:
        existing_job_id = file_hashes[file_hash]
        existing_job = processing_jobs.get(existing_job_id)

        if existing_job:
            return UploadResponse(
                job_id=existing_job_id,
                status=existing_job["status"],
                message=f"Duplicate file detected. Returning existing job for {file.filename}. "
                       f"Original processed on {existing_job['created_at'][:10]}",
            )

    # SECURITY: Check concurrent job limits (skip for authenticated users)
    if not current_user and not check_ip_job_limit(client_ip):
        request_metrics["concurrent_limit_hits"] += 1
        raise HTTPException(
            status_code=429,
            detail=f"Too many concurrent uploads. Maximum {MAX_CONCURRENT_JOBS_PER_IP} active jobs per IP. "
                   f"Please authenticate for higher limits."
        )

    # Create new job ID
    job_id = str(uuid.uuid4())

    # Store file hash mapping
    file_hashes[file_hash] = job_id

    # Initialize comprehensive job tracking
    processing_jobs[job_id] = {
        "status": "processing",
        "filename": file.filename,
        "file_hash": file_hash,
        "file_size": len(file_content),
        "ip_address": client_ip,
        "user_id": current_user["id"] if current_user else None,
        "is_authenticated": current_user is not None,
        "created_at": datetime.now().isoformat(),
        "progress": 0,
    }

    # Increment IP job counter (only for unauthenticated users)
    if not current_user:
        ip_job_counts[client_ip]["count"] += 1

    # Start processing based on file type
    if file.filename.lower().endswith(".csv"):
        asyncio.create_task(process_csv_file_async(job_id, file.filename, file_content))
    else:
        asyncio.create_task(process_pdf_with_camelot(job_id, file.filename, file_content))

    return UploadResponse(
        job_id=job_id,
        status="processing",
        message=f"Processing started for {file.filename} (authenticated: {current_user is not None})",
    )

@app.get("/api/jobs/{job_id}")
@app.get("/api/v1/jobs/{job_id}")
@limiter.limit(JOB_STATUS_RATE)
async def get_job_status(request: Request, job_id: str):
    """Get job status with rate limiting"""
    client_ip = get_remote_address(request)
    update_request_metrics("/api/jobs", client_ip)
    
    if job_id not in processing_jobs:
        update_request_metrics("/api/jobs", client_ip, success=False)
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Job not found"
        )

    job = processing_jobs[job_id]

    # Check if this job was the result of a duplicate file
    is_duplicate = False
    if "file_hash" in job:
        original_job_id = file_hashes.get(job["file_hash"])
        is_duplicate = original_job_id != job_id

    return {
        "job_id": job_id,
        "status": job["status"],
        "progress": job.get("progress", 0),
        "filename": job.get("filename"),
        "file_size": job.get("file_size"),
        "created_at": job.get("created_at"),
        "completed_at": job.get("completed_at"),
        "error": job.get("error"),
        "is_duplicate": is_duplicate,
        "is_authenticated": job.get("is_authenticated", False)
    }

@app.get("/api/transactions/{job_id}")
@app.get("/api/v1/transactions/{job_id}")
@limiter.limit(TRANSACTION_RATE)
async def get_transactions(request: Request, job_id: str):
    """Get processed transactions with rate limiting"""
    client_ip = get_remote_address(request)
    update_request_metrics("/api/transactions", client_ip)
    
    if job_id not in processing_jobs:
        update_request_metrics("/api/transactions", client_ip, success=False)
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Job not found"
        )

    job = processing_jobs[job_id]

    if job["status"] == "error":
        update_request_metrics("/api/transactions", client_ip, success=False)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Processing failed: {job.get('error', 'Unknown error')}",
        )

    if job["status"] != "completed":
        raise HTTPException(
            status_code=status.HTTP_202_ACCEPTED,
            detail=f"Processing still in progress: {job['status']}",
        )

    results = job.get("results")
    if results is None:
        update_request_metrics("/api/transactions", client_ip, success=False)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Processing results not available",
        )

    return {
        "job_id": job_id,
        "status": "completed",
        "transactions": results.get("transactions", []),
        "metadata": results.get("metadata", {}),
        "summary": results.get("summary", {}),
    }

@app.get("/api/metrics", response_model=MetricsResponse)
@limiter.limit(METRICS_RATE)
async def get_metrics(
    request: Request, 
    current_user = Depends(get_current_user_optional)
):
    """Get comprehensive API metrics (authenticated users only)"""
    if not current_user:
        raise HTTPException(
            status_code=401, 
            detail="Authentication required for metrics access"
        )
    
    client_ip = get_remote_address(request)
    update_request_metrics("/api/metrics", client_ip)
    
    # Calculate active jobs
    active_jobs = len([j for j in processing_jobs.values() 
                      if j["status"] in ["processing", "extracting_tables", "analyzing_transactions"]])
    
    # Get unique IP count
    unique_ips = len(ip_job_counts)
    
    # Clean old hourly stats (keep last 24 hours)
    current_time = datetime.now()
    cutoff_time = current_time - timedelta(hours=24)
    cutoff_key = cutoff_time.strftime("%Y-%m-%d-%H")
    
    # Remove old hourly stats
    old_keys = [k for k in request_metrics["hourly_stats"].keys() if k < cutoff_key]
    for old_key in old_keys[:10]:  # Remove up to 10 old entries per request
        del request_metrics["hourly_stats"][old_key]
    
    return MetricsResponse(
        metrics=dict(request_metrics),
        active_jobs=active_jobs,
        unique_ips=unique_ips,
        timestamp=datetime.now().isoformat()
    )

@app.get("/api/jobs")
@limiter.limit("30/minute")
async def list_jobs(request: Request):
    """List all processing jobs for debugging (with rate limiting)"""
    client_ip = get_remote_address(request)
    update_request_metrics("/api/jobs", client_ip)
    
    return {
        "jobs": [
            {
                "job_id": job_id,
                "status": job["status"],
                "filename": job.get("filename"),
                "file_size": job.get("file_size"),
                "created_at": job.get("created_at"),
                "is_authenticated": job.get("is_authenticated", False),
                "is_duplicate": (
                    job.get("file_hash") in file_hashes
                    and file_hashes[job["file_hash"]] != job_id
                    if job.get("file_hash")
                    else False
                ),
            }
            for job_id, job in processing_jobs.items()
        ],
        "total_jobs": len(processing_jobs),
        "unique_files": len(file_hashes),
        "duplicate_uploads": len(processing_jobs) - len(file_hashes),
        "security_stats": {
            "rate_limited_requests": request_metrics["rate_limited_requests"],
            "large_file_rejections": request_metrics["large_file_rejections"],
            "concurrent_limit_hits": request_metrics["concurrent_limit_hits"],
        }
    }

# MARK: - Processing Functions (with cleanup tracking)

async def process_csv_file_async(job_id: str, filename: str, file_content: bytes):
    """Process CSV file with enhanced tracking and cleanup"""
    temp_path = None
    client_ip = processing_jobs[job_id].get("ip_address")
    
    try:
        # Update status
        processing_jobs[job_id]["status"] = "processing_csv"
        processing_jobs[job_id]["progress"] = 20
        await manager.send_job_update(
            job_id,
            {
                "job_id": job_id,
                "status": "processing_csv",
                "progress": 20,
                "message": "Starting CSV processing...",
            },
        )

        # Create temporary file
        temp_dir = tempfile.gettempdir()
        temp_path = os.path.join(temp_dir, f"{job_id}_{filename}")

        # Save file asynchronously
        async with aiofiles.open(temp_path, "wb") as f:
            await f.write(file_content)

        processing_jobs[job_id]["progress"] = 50
        await manager.send_job_update(
            job_id,
            {
                "job_id": job_id,
                "status": "processing_csv",
                "progress": 50,
                "message": "Parsing CSV data...",
            },
        )

        # Process the CSV file
        print(f"🔄 Processing {filename} with enhanced CSV processor...")
        try:
            result = await asyncio.wait_for(
                asyncio.get_event_loop().run_in_executor(
                    executor, enhanced_processor.process_csv_file, temp_path
                ),
                timeout=30.0,
            )
        except asyncio.TimeoutError:
            raise HTTPException(
                status_code=408,
                detail=f"CSV processing timeout after 30 seconds for {filename}",
            )

        # Process results and complete job
        processing_jobs[job_id]["status"] = "analyzing_transactions"
        processing_jobs[job_id]["progress"] = 80

        # Convert results
        transactions = []
        total_income = 0
        total_expenses = 0

        if result and "transactions" in result:
            for transaction in result["transactions"]:
                raw_data = transaction.get("raw_data", {})
                
                transaction_data = {
                    "date": transaction["date"],
                    "description": transaction["description"],
                    "amount": transaction["amount"],
                    "category": transaction["category"],
                    "confidence": transaction.get("confidence", 1.0),
                    "raw_data": raw_data,
                }

                # Add forex fields if present
                if transaction.get("has_forex"):
                    transaction_data.update({
                        "original_amount": transaction.get("original_amount"),
                        "original_currency": transaction.get("original_currency"),
                        "exchange_rate": transaction.get("exchange_rate"),
                        "has_forex": True,
                    })

                transactions.append(transaction_data)

                if transaction["amount"] > 0:
                    total_income += transaction["amount"]
                else:
                    total_expenses += abs(transaction["amount"])

        # Mark as complete
        processing_jobs[job_id].update({
            "status": "completed",
            "progress": 100,
            "results": {
                "transactions": transactions,
                "metadata": result.get("metadata", {}),
                "summary": {
                    "total_income": total_income,
                    "total_expenses": total_expenses,
                    "net_amount": total_income - total_expenses,
                    "transaction_count": len(transactions),
                },
            },
            "completed_at": datetime.now().isoformat(),
        })

        print(f"✅ CSV processing complete: {len(transactions)} transactions found")

        await manager.send_job_update(
            job_id,
            {
                "job_id": job_id,
                "status": "completed",
                "progress": 100,
                "message": f"Successfully processed {len(transactions)} CSV transactions",
                "completed": True,
            },
        )

    except Exception as e:
        print(f"❌ CSV processing error: {str(e)}")
        processing_jobs[job_id].update({
            "status": "error",
            "error": str(e),
            "completed_at": datetime.now().isoformat(),
        })
        update_request_metrics("/api/upload", client_ip, success=False)
        
    finally:
        # Cleanup: Decrement IP counter for unauthenticated users
        if not processing_jobs[job_id].get("is_authenticated", False):
            if client_ip and ip_job_counts[client_ip]["count"] > 0:
                ip_job_counts[client_ip]["count"] -= 1
        
        # Clean up temp file
        if temp_path:
            try:
                os.unlink(temp_path)
            except Exception as cleanup_error:
                print(f"⚠️ Failed to cleanup temp file: {cleanup_error}")

async def process_pdf_with_camelot(job_id: str, filename: str, file_content: bytes):
    """Process PDF with enhanced tracking and cleanup"""
    temp_path = None
    client_ip = processing_jobs[job_id].get("ip_address")
    
    try:
        # Update status
        processing_jobs[job_id]["status"] = "extracting_tables"
        processing_jobs[job_id]["progress"] = 10

        await manager.send_job_update(
            job_id,
            {
                "job_id": job_id,
                "status": "extracting_tables",
                "progress": 10,
                "message": "Starting PDF table extraction...",
            },
        )

        # Create temporary file
        temp_dir = tempfile.gettempdir()
        temp_path = os.path.join(temp_dir, f"{job_id}_{filename}")

        # Save file asynchronously
        async with aiofiles.open(temp_path, "wb") as f:
            await f.write(file_content)

        processing_jobs[job_id]["progress"] = 30
        await manager.send_job_update(
            job_id,
            {
                "job_id": job_id,
                "status": "extracting_tables",
                "progress": 30,
                "message": "PDF saved, starting table extraction...",
            },
        )

        # Process with CamelotProcessor
        print(f"🔄 Processing {filename} with CamelotProcessor...")
        try:
            result = await asyncio.wait_for(
                asyncio.get_event_loop().run_in_executor(
                    executor, processor.process_pdf, temp_path
                ),
                timeout=60.0,
            )
        except asyncio.TimeoutError:
            raise HTTPException(
                status_code=408,
                detail=f"PDF processing timeout after 60 seconds for {filename}",
            )

        processing_jobs[job_id]["status"] = "analyzing_transactions"
        processing_jobs[job_id]["progress"] = 70

        # Convert results (similar to CSV processing)
        transactions = []
        total_income = 0
        total_expenses = 0

        if result and "transactions" in result:
            for transaction in result["transactions"]:
                amount = float(transaction.get("amount", 0))

                transaction_data = {
                    "date": transaction.get("date", ""),
                    "description": transaction.get("description", ""),
                    "amount": amount,
                    "category": transaction.get("category", "Other"),
                    "confidence": transaction.get("confidence", 0.8),
                }

                # Add forex fields if present
                if transaction.get("has_forex"):
                    transaction_data.update({
                        "original_amount": transaction.get("original_amount"),
                        "original_currency": transaction.get("original_currency"),
                        "exchange_rate": transaction.get("exchange_rate"),
                        "has_forex": True,
                    })

                transactions.append(transaction_data)

                if amount > 0:
                    total_income += amount
                else:
                    total_expenses += abs(amount)

        # Complete processing
        processing_jobs[job_id]["status"] = "completed"
        processing_jobs[job_id]["progress"] = 100
        processing_jobs[job_id]["results"] = {
            "transactions": transactions,
            "metadata": {
                "filename": filename,
                "total_transactions": len(transactions),
                "processing_time": "Real processing completed",
            },
            "summary": {
                "total_income": total_income,
                "total_expenses": total_expenses,
                "net_amount": total_income - total_expenses,
                "transaction_count": len(transactions),
            },
        }
        processing_jobs[job_id]["completed_at"] = datetime.now().isoformat()

        print(f"✅ Successfully processed {filename}: {len(transactions)} transactions found")

        await manager.send_job_update(
            job_id,
            {
                "job_id": job_id,
                "status": "completed",
                "progress": 100,
                "message": f"Successfully processed {len(transactions)} transactions",
                "completed": True,
            },
        )

    except Exception as e:
        processing_jobs[job_id]["status"] = "error"
        processing_jobs[job_id]["error"] = str(e)
        processing_jobs[job_id]["completed_at"] = datetime.now().isoformat()
        print(f"❌ Error processing {filename}: {e}")
        update_request_metrics("/api/upload", client_ip, success=False)
        
    finally:
        # Cleanup: Decrement IP counter for unauthenticated users
        if not processing_jobs[job_id].get("is_authenticated", False):
            if client_ip and ip_job_counts[client_ip]["count"] > 0:
                ip_job_counts[client_ip]["count"] -= 1
        
        # Clean up temporary file
        if temp_path and os.path.exists(temp_path):
            try:
                os.unlink(temp_path)
            except OSError:
                pass

# MARK: - WebSocket Support (unchanged but with rate limiting awareness)

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, job_id: str):
        await websocket.accept()
        self.active_connections[job_id] = websocket

    def disconnect(self, job_id: str):
        if job_id in self.active_connections:
            del self.active_connections[job_id]

    async def send_job_update(self, job_id: str, data: dict):
        if job_id in self.active_connections:
            try:
                await self.active_connections[job_id].send_json(data)
            except Exception:
                self.disconnect(job_id)

manager = ConnectionManager()

@app.websocket("/api/ws/progress/{job_id}")
@app.websocket("/api/v1/ws/progress/{job_id}")
async def websocket_progress(websocket: WebSocket, job_id: str):
    """WebSocket endpoint for real-time job progress updates"""
    await manager.connect(websocket, job_id)

    try:
        if job_id in processing_jobs:
            await websocket.send_json({
                "job_id": job_id,
                "status": processing_jobs[job_id]["status"],
                "progress": processing_jobs[job_id].get("progress", 0),
                "filename": processing_jobs[job_id].get("filename", ""),
            })

        while True:
            await websocket.receive_text()

            if job_id in processing_jobs:
                job = processing_jobs[job_id]
                await websocket.send_json({
                    "job_id": job_id,
                    "status": job["status"],
                    "progress": job.get("progress", 0),
                    "filename": job.get("filename", ""),
                    "completed": job["status"] in ["completed", "error"],
                    "error": job.get("error") if job["status"] == "error" else None,
                })

                if job["status"] in ["completed", "error"]:
                    break

    except WebSocketDisconnect:
        manager.disconnect(job_id)
    except Exception as e:
        print(f"WebSocket error for job {job_id}: {e}")
        manager.disconnect(job_id)

# MARK: - Server Startup

if __name__ == "__main__":
    import uvicorn

    print("🚀 Starting AI Financial Accountant API Server (SECURE + RATE LIMITED)...")
    print("📊 Backend: http://localhost:8000")
    print("📱 Frontend: http://localhost:5173")
    print("📖 API Docs: http://localhost:8000/docs (if enabled)")
    print("🏥 Health Check: http://localhost:8000/api/health")
    print("📊 Metrics: http://localhost:8000/api/metrics (auth required)")
    print("🔄 Processor: CamelotFinancialProcessor (REAL PDF PROCESSING)")
    print()
    print("🔒 Security Features Enabled:")
    print(f"  📏 File Size Limit: {MAX_FILE_SIZE // (1024*1024)}MB")
    print(f"  ⏱️  Rate Limits: {DEFAULT_UPLOAD_RATE} (unauth), {AUTH_UPLOAD_RATE} (auth)")
    print(f"  🔢 Concurrent Jobs: {MAX_CONCURRENT_JOBS_PER_IP} per IP")
    print(f"  📦 Body Size Limit: {MAX_BODY_SIZE // (1024*1024)}MB")
    print("  🛡️  IP-based rate limiting with authentication bypass")
    print("  📊 Comprehensive request monitoring and metrics")
    print()
    print("Demo Login Credentials:")
    print("  📧 Email: demo@example.com / admin@financiai.com")
    print("  🔑 Password: demo123 / admin123")

    host = os.getenv("HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(
        "api_server_secure:app", 
        host=host, 
        port=port, 
        reload=True, 
        log_level="info"
    )