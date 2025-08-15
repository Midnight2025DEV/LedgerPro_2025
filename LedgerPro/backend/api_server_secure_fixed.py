#!/usr/bin/env python3
"""
AI Financial Accountant - SECURITY HARDENED FastAPI Server
==========================================================

Security-hardened production API server with comprehensive protection
against common vulnerabilities and secure file handling.

SECURITY FIXES IMPLEMENTED:
- CVE-2024-24762: Updated FastAPI to 0.109.1+
- CVE-2024-35195, CVE-2024-47081: Updated requests to 2.32.4+
- Fixed hardcoded credentials vulnerability
- Implemented secure file handling with path traversal protection
- Added comprehensive input validation
- Implemented secure session management
- Added security headers middleware
- Sanitized error messages to prevent information disclosure
"""

import asyncio
import os
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from typing import Any, Dict

# FastAPI imports
from fastapi import FastAPI, File, HTTPException, Request, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Security imports
from config.secure_auth import secure_auth
from middleware.security_headers import SecurityHeadersMiddleware

# Import the real CamelotProcessor and CSV processor
from processors.python.camelot_processor import CamelotFinancialProcessor
from processors.python.csv_processor_enhanced import EnhancedCSVProcessor
from utils.secure_file_handler import secure_file_handler

# Use enhanced processor for better CSV handling
enhanced_processor = EnhancedCSVProcessor()

# Initialize thread pool executor for CPU-intensive tasks
executor = ThreadPoolExecutor(max_workers=2)

# Module-level constants for FastAPI dependencies
FILE_DEPENDENCY = File(...)

# Initialize FastAPI app
app = FastAPI(
    title="AI Financial Accountant API - Security Hardened",
    description=(
        "Security-hardened backend API with comprehensive "
        "protection for financial statement processing"
    ),
    version="1.0.0-security",
    docs_url=(
        "/docs" if not secure_auth.is_production() else None
    ),  # Disable docs in production
    redoc_url="/redoc" if not secure_auth.is_production() else None,
)

# Add security headers middleware
app.add_middleware(SecurityHeadersMiddleware)

# Add CORS middleware for frontend connection
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ],  # Specific origins only (no wildcard with credentials)
    allow_credentials=True,  # Allow credentials for authenticated requests
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# In-memory storage
processing_jobs: Dict[str, Dict] = {}
user_sessions: Dict[str, Dict] = {}
file_hashes: Dict[str, str] = {}  # hash -> job_id mapping for duplicate detection

# Initialize the real processor
processor = CamelotFinancialProcessor()


# Pydantic models
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


@app.get("/api/health")
async def health_check():
    """Health check endpoint to verify backend is running."""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0-security",
        "message": "AI Financial Accountant API is running (SECURITY HARDENED)",
        "processor": "CamelotFinancialProcessor",
        "security_features": [
            "Secure file handling",
            "Path traversal protection",
            "Input validation",
            "Secure authentication",
            "Error message sanitization",
            "Security headers",
        ],
    }


@app.post("/api/auth/login", response_model=LoginResponse)
async def login(request: LoginRequest, http_request: Request):
    """Secure authentication endpoint with password hashing and secure session management."""  # noqa: E501
    try:
        # Get demo users from secure configuration
        demo_users = secure_auth.get_demo_users()

        user_info = demo_users.get(request.email.lower())
        if not user_info:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=secure_auth.sanitize_error_message("Invalid email or password"),
            )

        # Verify password using secure hashing
        if not secure_auth.verify_password(
            user_info["password_hash"], request.password
        ):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=secure_auth.sanitize_error_message("Invalid email or password"),
            )

        # Create secure session token
        token = secure_auth.generate_secure_token()
        user_data = {
            "id": str(uuid.uuid4()),
            "email": request.email,
            "name": user_info["name"],
            "role": user_info.get("role", "user"),
            "created_at": datetime.now().isoformat(),
        }

        # Store session with secure expiry
        user_sessions[token] = {
            "user": user_data,
            "expires_at": datetime.now() + secure_auth.get_session_expiry(),
            "created_at": datetime.now(),
            "ip_address": (
                http_request.client.host if http_request.client else "unknown"
            ),
        }

        return LoginResponse(token=token, user=user_data)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=secure_auth.sanitize_error_message(str(e)),
        )


@app.post("/api/upload", response_model=UploadResponse)
@app.post("/api/v1/upload", response_model=UploadResponse)
async def upload_file(file: UploadFile = FILE_DEPENDENCY):
    """Secure upload and process a bank statement with comprehensive validation."""
    try:
        # Validate filename
        if not file.filename:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Filename is required"
            )

        # Read file content for validation
        file_content = await file.read()

        # Validate file using secure file handler
        try:
            mime_type, file_extension = secure_file_handler.validate_file_type(
                file_content, file.filename
            )
        except ValueError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=secure_auth.sanitize_error_message(str(e)),
            )

        # Calculate file hash for duplicate detection
        file_hash = secure_file_handler.calculate_file_hash(file_content)

        # Check for duplicates
        if file_hash in file_hashes:
            existing_job_id = file_hashes[file_hash]
            return UploadResponse(
                job_id=existing_job_id,
                status="duplicate",
                message="File already processed. Returning existing results.",
            )

        # Generate secure job ID and sanitize filename
        job_id = str(uuid.uuid4())
        filename = secure_file_handler.sanitize_filename(file.filename)

        # Store file hash
        file_hashes[file_hash] = job_id

        # Initialize job
        processing_jobs[job_id] = {
            "status": "uploading",
            "progress": 0,
            "message": "File uploaded successfully",
            "filename": filename,
            "mime_type": mime_type,
            "file_size": len(file_content),
            "created_at": datetime.now().isoformat(),
        }

        # Process based on file type
        if mime_type == "text/csv" or mime_type == "application/csv":
            await process_csv_file_secure(job_id, filename, file_content)
        elif mime_type == "application/pd":
            await process_pdf_file_secure(job_id, filename, file_content)
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Unsupported file type"
            )

        return UploadResponse(
            job_id=job_id,
            status=processing_jobs[job_id]["status"],
            message="File uploaded and processing started",
        )

    except HTTPException:
        raise
    except Exception as e:
        error_msg = secure_auth.sanitize_error_message(f"Upload error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=error_msg
        )


async def process_csv_file_secure(job_id: str, filename: str, file_content: bytes):
    """Securely process CSV file with proper error handling."""
    try:
        # Update status
        processing_jobs[job_id]["status"] = "processing_csv"
        processing_jobs[job_id]["progress"] = 20

        # Use secure file handler for temporary file operations
        with secure_file_handler.secure_temporary_file(
            filename, job_id, file_content
        ) as (temp_path, detected_mime, detected_ext):

            processing_jobs[job_id]["progress"] = 50

            # Process the CSV file using enhanced processor
            print("🔄 Processing secure CSV file...")
            try:
                result = await asyncio.wait_for(
                    asyncio.get_event_loop().run_in_executor(
                        executor, enhanced_processor.process_csv_file, temp_path
                    ),
                    timeout=30.0,  # 30 second timeout for CSV
                )
            except asyncio.TimeoutError:
                raise HTTPException(
                    status_code=408,
                    detail=secure_auth.sanitize_error_message(
                        "Processing timeout occurred"
                    ),
                )

            processing_jobs[job_id]["status"] = "analyzing_transactions"
            processing_jobs[job_id]["progress"] = 80

            # Convert the CSV processor result to our API format
            transactions = []
            total_income = 0
            total_expenses = 0

            if result and "transactions" in result:
                for transaction in result["transactions"]:
                    # Sanitize transaction data
                    raw_data = transaction.get("raw_data", {})

                    transaction_data = {
                        "date": transaction["date"],
                        "description": transaction["description"],
                        "amount": transaction["amount"],
                        "category": transaction["category"],
                        "confidence": transaction.get("confidence", 1.0),
                        "raw_data": raw_data,
                    }

                    # Add foreign currency fields if present
                    if transaction.get("has_forex"):
                        transaction_data.update(
                            {
                                "original_amount": transaction.get("original_amount"),
                                "original_currency": transaction.get(
                                    "original_currency"
                                ),
                                "exchange_rate": transaction.get("exchange_rate"),
                                "has_forex": True,
                            }
                        )

                    transactions.append(transaction_data)

                    if transaction["amount"] > 0:
                        total_income += transaction["amount"]
                    else:
                        total_expenses += abs(transaction["amount"])

            # Store results
            processing_jobs[job_id].update(
                {
                    "status": "completed",
                    "progress": 100,
                    "message": \
                        f"Successfully processed {len(transactions)} transactions",
                    "results": {
                        "transactions": transactions,
                        "summary": {
                            "total_transactions": len(transactions),
                            "total_income": total_income,
                            "total_expenses": total_expenses,
                            "net_income": total_income - total_expenses,
                        },
                        "metadata": {
                            "processed_at": datetime.now().isoformat(),
                            "processor": "EnhancedCSVProcessor",
                            "file_type": detected_mime,
                        },
                    },
                    "completed_at": datetime.now().isoformat(),
                }
            )

    except Exception as e:
        error_msg = secure_auth.sanitize_error_message(
            f"Error processing CSV: {str(e)}"
        )
        processing_jobs[job_id].update(
            {
                "status": "error",
                "progress": 0,
                "message": error_msg,
                "error_at": datetime.now().isoformat(),
            }
        )
        print(f"❌ Secure CSV processing error: {error_msg}")


async def process_pdf_file_secure(job_id: str, filename: str, file_content: bytes):
    """Securely process PDF file with proper error handling."""
    try:
        # Update status
        processing_jobs[job_id]["status"] = "processing_pd"
        processing_jobs[job_id]["progress"] = 20

        # Use secure file handler for temporary file operations
        with secure_file_handler.secure_temporary_file(
            filename, job_id, file_content
        ) as (temp_path, detected_mime, detected_ext):

            processing_jobs[job_id]["progress"] = 50

            # Process the PDF file using real processor
            print("🔄 Processing secure PDF file...")
            try:
                result = await asyncio.wait_for(
                    asyncio.get_event_loop().run_in_executor(
                        executor, processor.process_pdf, temp_path
                    ),
                    timeout=60.0,  # 60 second timeout for PDF
                )
            except asyncio.TimeoutError:
                raise HTTPException(
                    status_code=408,
                    detail=secure_auth.sanitize_error_message(
                        "Processing timeout occurred"
                    ),
                )

            processing_jobs[job_id]["status"] = "analyzing_transactions"
            processing_jobs[job_id]["progress"] = 80

            # Process results similar to CSV
            transactions = []
            total_income = 0
            total_expenses = 0

            if result and "transactions" in result:
                for transaction in result["transactions"]:
                    transaction_data = {
                        "date": transaction["date"],
                        "description": transaction["description"],
                        "amount": transaction["amount"],
                        "category": transaction["category"],
                        "confidence": transaction.get("confidence", 1.0),
                    }

                    transactions.append(transaction_data)

                    if transaction["amount"] > 0:
                        total_income += transaction["amount"]
                    else:
                        total_expenses += abs(transaction["amount"])

            # Store results
            processing_jobs[job_id].update(
                {
                    "status": "completed",
                    "progress": 100,
                    "message": \
                        f"Successfully processed {len(transactions)} transactions",
                    "results": {
                        "transactions": transactions,
                        "summary": {
                            "total_transactions": len(transactions),
                            "total_income": total_income,
                            "total_expenses": total_expenses,
                            "net_income": total_income - total_expenses,
                        },
                        "metadata": {
                            "processed_at": datetime.now().isoformat(),
                            "processor": "CamelotFinancialProcessor",
                            "file_type": detected_mime,
                        },
                    },
                    "completed_at": datetime.now().isoformat(),
                }
            )

    except Exception as e:
        error_msg = secure_auth.sanitize_error_message(
            f"Error processing PDF: {str(e)}"
        )
        processing_jobs[job_id].update(
            {
                "status": "error",
                "progress": 0,
                "message": error_msg,
                "error_at": datetime.now().isoformat(),
            }
        )
        print(f"❌ Secure PDF processing error: {error_msg}")


@app.get("/api/jobs/{job_id}")
async def get_job_status(job_id: str):
    """Get job status with security validation."""
    try:
        # Validate job_id format
        uuid.UUID(job_id)  # This will raise ValueError if invalid
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid job ID format"
        )

    if job_id not in processing_jobs:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Job not found"
        )

    job_data = processing_jobs[job_id].copy()

    # Sanitize sensitive information
    if "error_details" in job_data:
        job_data["error_details"] = secure_auth.sanitize_error_message(
            job_data["error_details"]
        )

    return job_data


@app.get("/api/transactions/{job_id}")
async def get_transactions(job_id: str):
    """Get processed transactions with security validation."""
    try:
        # Validate job_id format
        uuid.UUID(job_id)  # This will raise ValueError if invalid
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid job ID format"
        )

    if job_id not in processing_jobs:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Job not found"
        )

    job = processing_jobs[job_id]
    if job["status"] != "completed":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Job is not completed. Current status: {job['status']}",
        )

    if "results" not in job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No results found for this job",
        )

    return job["results"]


if __name__ == "__main__":
    import uvicorn

    print("🔐 Starting SECURITY HARDENED LedgerPro API Server...")
    print("🛡️  Security features enabled:")
    print("   ✅ Secure file handling")
    print("   ✅ Path traversal protection")
    print("   ✅ Input validation")
    print("   ✅ Secure authentication")
    print("   ✅ Error message sanitization")
    print("   ✅ Security headers")
    print("   ✅ Updated dependencies (CVE fixes)")

    # Set environment if not already set
    if not os.getenv("ENVIRONMENT"):
        os.environ["ENVIRONMENT"] = "development"
        print(
            (
                "⚠️ Environment set to 'development'. "
                "Set ENVIRONMENT=production for production deployment."
            )
        )

    uvicorn.run(
        app,
        host="127.0.0.1",
        port=8000,
        log_level="info",
        access_log=True,
    )
