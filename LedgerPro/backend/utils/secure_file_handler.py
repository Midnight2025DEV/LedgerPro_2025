"""
Secure File Handler
==================

Secure file handling utilities to prevent path traversal, ensure proper
file validation, and handle temporary files securely.
"""

import hashlib
import os
import secrets
import tempfile
from contextlib import contextmanager
from pathlib import Path
from typing import Optional, Tuple

import aiofiles
import magic
from config.logging_config import get_logger, security_logger

# Initialize logger
logger = get_logger(__name__)


class SecureFileHandler:
    """Handles file operations securely to prevent path traversal and other attacks."""

    # Allowed MIME types for uploads
    ALLOWED_MIME_TYPES = {
        "application/pd": [".pd"],
        "text/csv": [".csv"],
        "application/csv": [".csv"],
        "text/plain": [".csv", ".txt"],  # Some CSV files are detected as text/plain
    }

    # Maximum file size (50MB)
    MAX_FILE_SIZE = 50 * 1024 * 1024

    def __init__(self, secure_temp_dir: Optional[str] = None):
        """Initialize with optional secure temporary directory."""
        self.secure_temp_dir = secure_temp_dir or self._create_secure_temp_dir()

    def _create_secure_temp_dir(self) -> str:
        """Create a secure temporary directory with restricted permissions."""
        temp_dir = tempfile.mkdtemp(prefix="ledgerpro_secure_")
        # Set restrictive permissions (owner read/write/execute only)
        os.chmod(temp_dir, 0o700)
        return temp_dir

    def sanitize_filename(self, filename: str) -> str:
        """Sanitize filename to prevent path traversal and other attacks."""
        if not filename:
            raise ValueError("Filename cannot be empty")

        # Check if original filename contains null bytes
        has_null_bytes = "\x00" in filename

        # Remove null bytes
        filename_no_nulls = filename.replace("\x00", "")

        # Check for directory traversal attempts
        import urllib.parse

        # Decode URL encoding
        decoded = urllib.parse.unquote(filename_no_nulls)
        decoded = urllib.parse.unquote(decoded)  # Double decode for double encoding

        # Check for various path traversal patterns
        dangerous_patterns = [
            "..",
            "/",
            "\\",
            "....",  # Multiple dots
        ]

        for pattern in dangerous_patterns:
            if pattern in decoded:
                if has_null_bytes:
                    # This is null byte injection attack - sanitize by taking only the final part  # noqa: E501
                    parts = decoded.replace("\\", "/").split("/")
                    clean_part = parts[-1] if parts else ""
                    # If the result is still dangerous after cleaning, raise error
                    if not clean_part or clean_part in [".", ".."]:
                        raise ValueError(
                            "Invalid filename: contains directory traversal patterns"
                        )
                    filename_no_nulls = clean_part
                    break
                else:
                    # This is a direct path traversal attack - should fail
                    raise ValueError(
                        "Invalid filename: contains directory traversal patterns"
                    )

        # Remove any directory path components
        clean_name = Path(filename_no_nulls).name

        # Remove additional dangerous characters
        clean_name = clean_name.replace("\r", "").replace("\n", "")

        # Ensure filename isn't too long
        if len(clean_name) > 255:
            name_part, ext = os.path.splitext(clean_name)
            clean_name = name_part[: 255 - len(ext)] + ext

        # Ensure we still have a valid filename
        if not clean_name or clean_name == "." or clean_name == "..":
            raise ValueError("Invalid filename after sanitization")

        return clean_name

    def validate_file_type(self, file_content: bytes, filename: str) -> Tuple[str, str]:
        """Validate file type using magic numbers, not just extension."""
        if len(file_content) == 0:
            raise ValueError("File is empty")

        if len(file_content) > self.MAX_FILE_SIZE:
            raise ValueError(
                f"File too large. Maximum size: {self.MAX_FILE_SIZE // (1024*1024)}MB"
            )

        # Detect MIME type using magic numbers
        if MAGIC_AVAILABLE:
            try:
                mime_type = magic.from_buffer(file_content, mime=True)
            except Exception:
                # Fallback to basic validation if magic fails
                mime_type = self._fallback_mime_detection(file_content)
        else:
            # Use fallback detection if python-magic isn't available
            mime_type = self._fallback_mime_detection(file_content)

        # Validate against allowed types
        if mime_type not in self.ALLOWED_MIME_TYPES:
            raise ValueError(f"File type not allowed: {mime_type}")

        # Get file extension
        file_extension = Path(filename).suffix.lower()
        allowed_extensions = self.ALLOWED_MIME_TYPES[mime_type]

        if file_extension not in allowed_extensions:
            raise ValueError(
                f"File extension {file_extension} doesn't match MIME type {mime_type}"
            )

        return mime_type, file_extension

    def _fallback_mime_detection(self, file_content: bytes) -> str:
        """Fallback MIME detection when python-magic isn't available."""
        if file_content.startswith(b"%PDF"):
            return "application/pd"
        elif b"," in file_content[:1024] and b"\n" in file_content[:1024]:
            # Basic CSV detection - contains commas and newlines in first 1KB
            return "text/csv"
        else:
            raise ValueError("Cannot determine file type")

    def generate_secure_filename(self, original_filename: str, job_id: str) -> str:
        """Generate a secure filename for storage."""
        clean_name = self.sanitize_filename(original_filename)
        file_extension = Path(clean_name).suffix

        # Generate secure filename with timestamp and random component
        timestamp = int(datetime.now().timestamp())
        random_component = secrets.token_hex(8)

        secure_name = f"{job_id}_{timestamp}_{random_component}{file_extension}"
        return secure_name

    def get_secure_file_path(self, filename: str, job_id: str) -> Path:
        """Get a secure file path within the temporary directory."""
        # First sanitize the filename to check for path traversal
        try:
            sanitized_filename = self.sanitize_filename(filename)
        except ValueError as e:
            raise ValueError(f"Invalid filename: {e}")

        secure_filename = self.generate_secure_filename(sanitized_filename, job_id)
        file_path = Path(self.secure_temp_dir) / secure_filename

        # Ensure the path is within our secure directory
        try:
            file_path.resolve().relative_to(Path(self.secure_temp_dir).resolve())
        except ValueError:
            raise ValueError("Invalid file path: outside secure directory")

        return file_path

    @contextmanager
    def secure_temporary_file(self, filename: str, job_id: str, file_content: bytes):
        """Context manager for secure temporary file handling."""
        # Validate file first
        mime_type, file_extension = self.validate_file_type(file_content, filename)

        # Get secure file path
        secure_path = self.get_secure_file_path(filename, job_id)

        try:
            # Write file with secure permissions
            with open(secure_path, "wb") as f:
                f.write(file_content)

            # Set restrictive permissions
            os.chmod(secure_path, 0o600)  # Owner read/write only

            yield str(secure_path), mime_type, file_extension

        finally:
            # Always clean up the temporary file
            try:
                if secure_path.exists():
                    secure_path.unlink()
            except Exception as e:
                logger.warning(f"Could not delete temporary file", temp_path=str(secure_path), error=str(e))

    async def secure_write_file(self, file_path: Path, content: bytes) -> None:
        """Securely write file content with proper permissions."""
        # Ensure parent directory exists
        file_path.parent.mkdir(parents=True, exist_ok=True)

        # Write file
        async with aiofiles.open(file_path, "wb") as f:
            await f.write(content)

        # Set secure permissions
        os.chmod(file_path, 0o600)

    def calculate_file_hash(self, file_content: bytes) -> str:
        """Calculate SHA-256 hash of file content for integrity checking."""
        return hashlib.sha256(file_content).hexdigest()

    def cleanup_temp_dir(self) -> None:
        """Clean up the secure temporary directory."""
        try:
            import shutil

            shutil.rmtree(self.secure_temp_dir, ignore_errors=True)
        except Exception as e:
            logger.warning(f"Could not clean up temporary directory", temp_dir=self.secure_temp_dir, error=str(e))


# Try to import python-magic, fall back gracefully
try:
    import magic

    MAGIC_AVAILABLE = True
except ImportError:
    logger.warning("python-magic not available, using fallback MIME detection")
    magic = None
    MAGIC_AVAILABLE = False

from datetime import datetime

# Global secure file handler instance
secure_file_handler = SecureFileHandler()
