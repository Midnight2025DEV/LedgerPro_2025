#!/usr/bin/env python3
"""
AI Financial Accountant - Real FastAPI Server with CamelotProcessor
================================================================

Production API server that actually processes PDFs using the real CamelotProcessor.
"""

import asyncio
import hashlib
import os
import tempfile
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta
from typing import Any, Dict

import aiofiles

# FastAPI imports
from fastapi import (
    FastAPI,
    File,
    HTTPException,
    UploadFile,
    status,
    WebSocket,
    WebSocketDisconnect,
)
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Import the real CamelotProcessor and CSV processor
from processors.python.camelot_processor import CamelotFinancialProcessor
from processors.python.csv_processor import process_csv_file

# Initialize thread pool executor for CPU-intensive tasks
executor = ThreadPoolExecutor(max_workers=2)

# Initialize FastAPI app
app = FastAPI(
    title="AI Financial Accountant API",
    description="Real Processing Version - Backend API with CamelotProcessor for actual PDF financial statement processing",
    version="1.0.0",
)

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
        "version": "1.0.0",
        "message": "AI Financial Accountant API is running (REAL PROCESSING)",
        "processor": "CamelotFinancialProcessor",
    }


@app.post("/api/auth/login", response_model=LoginResponse)
async def login(request: LoginRequest):
    """Simple authentication endpoint for local development."""
    # Demo credentials for local testing
    demo_users = {
        "demo@example.com": {"password": "demo123", "name": "Demo User"},
        "test@financiai.com": {"password": "test123", "name": "Test User"},
        "admin@financiai.com": {"password": "admin123", "name": "Admin User"},
    }

    user_info = demo_users.get(request.email.lower())
    if not user_info or user_info["password"] != request.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password"
        )

    # Create session token
    token = str(uuid.uuid4())
    user_data = {
        "id": str(uuid.uuid4()),
        "email": request.email,
        "name": user_info["name"],
        "created_at": datetime.now().isoformat(),
    }

    # Store session
    user_sessions[token] = {
        "user": user_data,
        "expires_at": datetime.now() + timedelta(hours=24),
    }

    return LoginResponse(token=token, user=user_data)


@app.post("/api/upload", response_model=UploadResponse)
@app.post("/api/v1/upload", response_model=UploadResponse)
async def upload_file(file: UploadFile = File(...)):
    """Upload and process a bank statement PDF using real CamelotProcessor."""
    # Validate file type
    if not file.filename.lower().endswith((".pdf", ".csv")):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only PDF and CSV files are supported",
        )

    # Read file content to calculate hash
    file_content = await file.read()
    await file.seek(0)  # Reset file pointer

    # Calculate file hash for duplicate detection
    file_hash = hashlib.sha256(file_content).hexdigest()

    # Check if this exact file has been processed before
    if file_hash in file_hashes:
        existing_job_id = file_hashes[file_hash]
        existing_job = processing_jobs.get(existing_job_id)

        if existing_job:
            return UploadResponse(
                job_id=existing_job_id,
                status=existing_job["status"],
                message=f"Duplicate file detected. Returning existing job for {file.filename}. Original processed on {existing_job['created_at'][:10]}",
            )

    # Create new job ID
    job_id = str(uuid.uuid4())

    # Store file hash mapping
    file_hashes[file_hash] = job_id

    # Initialize job tracking
    processing_jobs[job_id] = {
        "status": "processing",
        "filename": file.filename,
        "file_hash": file_hash,
        "file_size": len(file_content),
        "created_at": datetime.now().isoformat(),
        "progress": 0,
    }

    # Start REAL processing - choose processor based on file type
    if file.filename.lower().endswith(".csv"):
        asyncio.create_task(process_csv_file_async(job_id, file.filename, file_content))
    else:
        asyncio.create_task(
            process_pdf_with_camelot(job_id, file.filename, file_content)
        )

    return UploadResponse(
        job_id=job_id,
        status="processing",
        message=f"Processing started for {file.filename}",
    )


async def process_csv_file_async(job_id: str, filename: str, file_content: bytes):
    """Process CSV file using csv_processor with async operations."""
    temp_path = None
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

        # Create temporary file path using secure temp directory
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

        # Process the CSV file using executor
        print(f"🔄 Processing {filename} with CSV processor...")
        try:
            result = await asyncio.wait_for(
                asyncio.get_event_loop().run_in_executor(
                    executor, process_csv_file, temp_path
                ),
                timeout=30.0,  # 30 second timeout for CSV
            )
        except asyncio.TimeoutError:
            raise HTTPException(
                status_code=408,
                detail=f"CSV processing timeout after 30 seconds for {filename}",
            )

        processing_jobs[job_id]["status"] = "analyzing_transactions"
        processing_jobs[job_id]["progress"] = 80
        await manager.send_job_update(
            job_id,
            {
                "job_id": job_id,
                "status": "analyzing_transactions",
                "progress": 80,
                "message": "Analyzing CSV transactions...",
            },
        )

        # Convert the CSV processor result to our API format
        transactions = []
        total_income = 0
        total_expenses = 0

        if result and "transactions" in result:
            for transaction in result["transactions"]:
                # Debug: Check if raw_data is present
                raw_data = transaction.get("raw_data", {})
                print(
                    f"API Server - Transaction raw_data keys: {list(raw_data.keys())}"
                )

                # CSV processor already returns correct format
                transactions.append(
                    {
                        "date": transaction["date"],
                        "description": transaction["description"],
                        "amount": transaction["amount"],
                        "category": transaction["category"],
                        "confidence": transaction.get("confidence", 1.0),
                        "raw_data": raw_data,  # ✅ Preserve raw CSV data
                    }
                )

                if transaction["amount"] > 0:
                    total_income += transaction["amount"]
                else:
                    total_expenses += abs(transaction["amount"])

        # Mark as complete
        processing_jobs[job_id].update(
            {
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
            }
        )

        print(f"✅ CSV processing complete: {len(transactions)} transactions found")

        # Send final WebSocket update
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
        processing_jobs[job_id].update(
            {
                "status": "error",
                "error": str(e),
                "completed_at": datetime.now().isoformat(),
            }
        )
    finally:
        # Clean up temp file
        if temp_path:
            try:
                os.unlink(temp_path)
            except Exception as cleanup_error:
                print(f"⚠️ Failed to cleanup temp file: {cleanup_error}")


async def process_pdf_with_camelot(job_id: str, filename: str, file_content: bytes):
    """Real PDF processing using CamelotProcessor with async operations."""
    temp_path = None
    try:
        # Update status
        processing_jobs[job_id]["status"] = "extracting_tables"
        processing_jobs[job_id]["progress"] = 10

        # Send WebSocket update
        await manager.send_job_update(
            job_id,
            {
                "job_id": job_id,
                "status": "extracting_tables",
                "progress": 10,
                "message": "Starting PDF table extraction...",
            },
        )

        # Create temporary file path using secure temp directory
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

        # Process the PDF with the real CamelotProcessor using executor
        print(f"🔄 Processing {filename} with CamelotProcessor...")
        try:
            result = await asyncio.wait_for(
                asyncio.get_event_loop().run_in_executor(
                    executor, processor.process_pdf, temp_path
                ),
                timeout=60.0,  # 60 second timeout
            )
        except asyncio.TimeoutError:
            raise HTTPException(
                status_code=408,
                detail=f"PDF processing timeout after 60 seconds for {filename}",
            )

        processing_jobs[job_id]["status"] = "analyzing_transactions"
        processing_jobs[job_id]["progress"] = 70
        await manager.send_job_update(
            job_id,
            {
                "job_id": job_id,
                "status": "analyzing_transactions",
                "progress": 70,
                "message": "Analyzing extracted transactions...",
            },
        )

        # Convert the processor result to our API format
        transactions = []
        total_income = 0
        total_expenses = 0

        if result and "transactions" in result:
            for transaction in result["transactions"]:
                # Map processor fields to API fields
                amount = float(transaction.get("amount", 0))
                transactions.append(
                    {
                        "date": transaction.get("date", ""),
                        "description": transaction.get("description", ""),
                        "amount": amount,
                        "category": transaction.get("category", "Other"),
                        "confidence": transaction.get("confidence", 0.8),
                    }
                )

                if amount > 0:
                    total_income += amount
                else:
                    total_expenses += amount

        # If no transactions found, provide helpful message
        if not transactions:
            processing_jobs[job_id]["status"] = "completed"
            processing_jobs[job_id]["progress"] = 100
            processing_jobs[job_id]["results"] = {
                "transactions": [],
                "metadata": {
                    "filename": filename,
                    "total_transactions": 0,
                    "processing_time": "Real processing completed",
                },
                "summary": {
                    "total_income": 0,
                    "total_expenses": 0,
                    "net_amount": 0,
                    "transaction_count": 0,
                },
            }
            print(f"⚠️  No transactions extracted from {filename}")
            return

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
                "net_amount": total_income + total_expenses,
                "transaction_count": len(transactions),
            },
        }
        processing_jobs[job_id]["completed_at"] = datetime.now().isoformat()

        print(
            f"✅ Successfully processed {filename}: {len(transactions)} transactions found"
        )

        # Send final WebSocket update
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
    finally:
        # Clean up temporary file
        if temp_path and os.path.exists(temp_path):
            try:
                os.unlink(temp_path)
            except OSError:
                pass  # File might already be deleted


@app.get("/api/jobs/{job_id}")
@app.get("/api/v1/jobs/{job_id}")
async def get_job_status(job_id: str):
    """Get the status of a processing job."""
    if job_id not in processing_jobs:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Job not found"
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
    }


@app.get("/api/transactions/{job_id}")
@app.get("/api/v1/transactions/{job_id}")
async def get_transactions(job_id: str):
    """Get processed transaction results for a job."""
    if job_id not in processing_jobs:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Job not found"
        )

    job = processing_jobs[job_id]

    if job["status"] == "error":
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Processing failed: {job.get('error', 'Unknown error')}",
        )

    if job["status"] != "completed":
        raise HTTPException(
            status_code=status.HTTP_202_ACCEPTED,
            detail=f"Processing still in progress: {job['status']}",
        )

    results = job.get("results", {})

    return {
        "job_id": job_id,
        "status": "completed",
        "transactions": results.get("transactions", []),
        "metadata": results.get("metadata", {}),
        "summary": results.get("summary", {}),
    }


@app.get("/api/jobs")
async def list_jobs():
    """List all processing jobs for debugging."""
    return {
        "jobs": [
            {
                "job_id": job_id,
                "status": job["status"],
                "filename": job.get("filename"),
                "file_size": job.get("file_size"),
                "created_at": job.get("created_at"),
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
    }


@app.get("/api/duplicates")
async def get_duplicate_stats():
    """Get duplicate file upload statistics."""
    duplicate_groups = {}

    for file_hash, original_job_id in file_hashes.items():
        duplicate_jobs = [
            job_id
            for job_id, job in processing_jobs.items()
            if job.get("file_hash") == file_hash
        ]

        if len(duplicate_jobs) > 1:
            original_job = processing_jobs[original_job_id]
            duplicate_groups[file_hash] = {
                "filename": original_job["filename"],
                "original_job_id": original_job_id,
                "total_uploads": len(duplicate_jobs),
                "duplicate_job_ids": [
                    jid for jid in duplicate_jobs if jid != original_job_id
                ],
                "first_upload": original_job["created_at"],
            }

    return {
        "total_unique_files": len(file_hashes),
        "total_uploads": len(processing_jobs),
        "files_with_duplicates": len(duplicate_groups),
        "total_duplicate_uploads": sum(
            len(group["duplicate_job_ids"]) for group in duplicate_groups.values()
        ),
        "duplicate_groups": duplicate_groups,
    }


# WebSocket connection manager
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
                # Connection might be closed
                self.disconnect(job_id)


manager = ConnectionManager()


@app.websocket("/api/ws/progress/{job_id}")
@app.websocket("/api/v1/ws/progress/{job_id}")
async def websocket_progress(websocket: WebSocket, job_id: str):
    """WebSocket endpoint for real-time job progress updates."""
    await manager.connect(websocket, job_id)

    try:
        # Send initial status
        if job_id in processing_jobs:
            await websocket.send_json(
                {
                    "job_id": job_id,
                    "status": processing_jobs[job_id]["status"],
                    "progress": processing_jobs[job_id].get("progress", 0),
                    "filename": processing_jobs[job_id].get("filename", ""),
                }
            )

        # Keep connection alive and send updates
        while True:
            # Wait for any message from client (ping/pong)
            await websocket.receive_text()

            # Send current status
            if job_id in processing_jobs:
                job = processing_jobs[job_id]
                await websocket.send_json(
                    {
                        "job_id": job_id,
                        "status": job["status"],
                        "progress": job.get("progress", 0),
                        "filename": job.get("filename", ""),
                        "completed": job["status"] in ["completed", "error"],
                        "error": job.get("error") if job["status"] == "error" else None,
                    }
                )

                # If job is complete, close connection
                if job["status"] in ["completed", "error"]:
                    break

    except WebSocketDisconnect:
        manager.disconnect(job_id)
    except Exception as e:
        print(f"WebSocket error for job {job_id}: {e}")
        manager.disconnect(job_id)


if __name__ == "__main__":
    import uvicorn

    print("🚀 Starting AI Financial Accountant API Server (REAL PROCESSING)...")
    print("📊 Backend: http://localhost:8000")
    print("📱 Frontend: http://localhost:5173")
    print("📖 API Docs: http://localhost:8000/docs")
    print("🏥 Health Check: http://localhost:8000/api/health")
    print("🔄 Processor: CamelotFinancialProcessor (REAL PDF PROCESSING)")
    print()
    print("Demo Login Credentials:")
    print("  📧 Email: demo@example.com")
    print("  🔑 Password: demo123")

    host = os.getenv("HOST", "127.0.0.1")  # Secure default
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(
        "api_server_real:app", host=host, port=port, reload=True, log_level="info"
    )
