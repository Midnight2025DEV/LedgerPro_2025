"""
Data Sanitization Module for LedgerPro
Redacts PII from financial data before sending to LLM APIs
"""

import re
import hashlib
import uuid
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple, Any
from enum import Enum
from collections import defaultdict
import yaml
from pathlib import Path

logger = logging.getLogger(__name__)


class PrivacyLevel(Enum):
    """Privacy levels for data sanitization"""

    STRICT = "strict"
    BALANCED = "balanced"
    MINIMAL = "minimal"


class DataSanitizer:
    """
    Sanitizes financial data by redacting PII while preserving analytical value.
    Supports reversible tokenization and configurable privacy levels.
    """

    # Comprehensive regex patterns for PII detection
    PATTERNS = {
        # Account numbers (US checking/savings - typically 8-17 digits)
        "us_account": [
            r"\b\d{8,17}\b(?=.*(?:account|acct|checking|savings))",
            r"(?:account|acct)[\s#:-]*\d{8,17}\b",
        ],
        # Routing numbers (US - exactly 9 digits starting with 0-3)
        "routing": [
            r"\b[0-3]\d{8}\b",
            r"(?:routing|rtn|aba)[\s#:-]*[0-3]\d{8}\b",
        ],
        # IBAN (International Bank Account Number)
        "iban": [
            r"\b[A-Z]{2}\d{2}[A-Z0-9]{1,30}\b",
        ],
        # SWIFT/BIC codes (must be exactly 8 or 11 characters, all caps)
        "swift": [
            r"(?:swift|bic)[\s#:-]*[A-Z]{6}[A-Z0-9]{2}(?:[A-Z0-9]{3})?\b",
            r"\b[A-Z]{6}[A-Z0-9]{2}(?:[A-Z0-9]{3})?\b(?=.*(?:swift|bic|bank))",
        ],
        # Credit card numbers (with spaces/dashes)
        "credit_card": [
            # Visa (starts with 4)
            r"\b4\d{3}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b",
            # Mastercard (starts with 51-55 or 2221-2720)
            r"\b5[1-5]\d{2}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b",
            r"\b2(?:22[1-9]|2[3-9]\d|[3-6]\d{2}|7[01]\d|720)[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b",
            # American Express (starts with 34 or 37)
            r"\b3[47]\d{2}[\s-]?\d{6}[\s-]?\d{5}\b",
            # Discover (starts with 6011, 622126-622925, 644-649, 65)
            r"\b6(?:011|5\d{2}|4[4-9]\d|22(?:1(?:2[6-9]|[3-9]\d)|[2-8]\d{2}|9(?:[01]\d|2[0-5])))\d{12}\b",
            # Generic 13-19 digit pattern
            r"\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{1,7}\b",
        ],
        # SSN patterns
        "ssn": [
            r"\b\d{3}-\d{2}-\d{4}\b",
            r"\b\d{3}\s\d{2}\s\d{4}\b",
            r"(?:ssn|social|security)[\s#:-]*\d{9}\b",
            r"\b\d{9}\b(?=.*(?:ssn|social|security))",
        ],
        # Phone numbers (multiple formats)
        "phone": [
            r"\b(?:\+?1[\s-]?)?\(?[2-9]\d{2}\)?[\s-]?\d{3}[\s-]?\d{4}\b",
            r"\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b",
            r"\b\(\d{3}\)\s?\d{3}-\d{4}\b",
        ],
        # Email addresses
        "email": [
            r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b",
        ],
        # US addresses (street address patterns)
        "address": [
            r"\b\d{1,5}\s+[A-Za-z\s]+(?:street|st|avenue|ave|road|rd|boulevard|blvd|lane|ln|drive|dr|court|ct|plaza|pl|terrace|ter|way|parkway|pkwy)\.?\b",
            r"\b(?:p\.?o\.?\s*box|po\s*box)\s+\d+\b",
            r"\b\d{1,5}\s+\w+\s+(?:apt|apartment|suite|ste|unit|#)\s*\w+\b",
        ],
        # Driver's license patterns (state-specific)
        "drivers_license": [
            r"\b[A-Z]{1,2}\d{6,8}\b",  # Generic pattern
            r"(?:dl|driver\'?s?\s*license|license)[\s#:-]*[A-Z0-9]{5,12}\b",
        ],
        # Passport numbers
        "passport": [
            r"\b[A-Z]\d{8}\b",  # US passport
            r"(?:passport)[\s#:-]*[A-Z0-9]{6,9}\b",
        ],
        # ZIP codes
        "zip_code": [
            r"\b\d{5}(?:-\d{4})?\b",
        ],
    }

    # Merchant categories to preserve
    MERCHANT_CATEGORIES = {
        "WALMART",
        "TARGET",
        "AMAZON",
        "COSTCO",
        "KROGER",
        "SAFEWAY",
        "STARBUCKS",
        "MCDONALDS",
        "SUBWAY",
        "CHIPOTLE",
        "SHELL",
        "CHEVRON",
        "EXXON",
        "BP",
        "UBER",
        "LYFT",
        "AIRBNB",
        "NETFLIX",
        "SPOTIFY",
    }

    def __init__(self, config: Optional[Dict] = None):
        """
        Initialize sanitizer with configurable privacy levels.

        Args:
            config: Configuration dict with privacy level and options
        """
        self.config = config or {}
        self.privacy_level = PrivacyLevel(
            self.config.get("level", PrivacyLevel.BALANCED.value)
        )

        # Storage for reversible mappings
        self.mappings = defaultdict(dict)
        self.mapping_id = str(uuid.uuid4())

        # Load additional config if available
        self._load_config()

        # Audit log
        self.audit_log = []

        logger.info(
            f"DataSanitizer initialized with privacy level: {self.privacy_level.value}"
        )

    def _load_config(self):
        """Load configuration from YAML file if exists"""
        config_path = (
            Path(__file__).parent.parent.parent / "config" / "privacy_config.yaml"
        )
        if config_path.exists():
            with open(config_path, "r") as f:
                yaml_config = yaml.safe_load(f)
                # Merge with provided config
                self.config = {**yaml_config, **self.config}

    def _log_redaction(self, field: str, pattern_type: str, original_length: int):
        """Log redaction action for audit trail"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "field": field,
            "pattern_type": pattern_type,
            "original_length": original_length,
            "privacy_level": self.privacy_level.value,
        }
        self.audit_log.append(log_entry)
        logger.debug(f"Redacted {pattern_type} in {field}")

    def _tokenize(self, value: str, token_type: str) -> str:
        """Create a reversible token for a value"""
        token = f"{token_type.upper()}_{hashlib.sha256(value.encode()).hexdigest()[:8]}"
        self.mappings[self.mapping_id][token] = value
        return token

    def _detect_and_redact(
        self,
        text: str,
        pattern_type: str,
        patterns: List[str],
        preserve_format: bool = False,
    ) -> Tuple[str, bool]:
        """
        Detect and redact patterns in text.

        Returns:
            Tuple of (redacted_text, was_redacted)
        """
        redacted = False
        result = text

        for pattern in patterns:
            matches = list(re.finditer(pattern, text, re.IGNORECASE))
            if matches:
                redacted = True
                for match in reversed(
                    matches
                ):  # Process in reverse to maintain positions
                    original = match.group()

                    if pattern_type == "credit_card" and preserve_format:
                        # Keep last 4 digits for credit cards
                        digits_only = re.sub(r"[^\d]", "", original)
                        replacement = (
                            f"****{digits_only[-4:]}"
                            if len(digits_only) >= 4
                            else "****"
                        )
                    elif pattern_type == "email":
                        # Tokenize email
                        replacement = self._tokenize(original, "EMAIL")
                    elif pattern_type == "phone":
                        # Keep area code pattern
                        replacement = f"({original[1:4] if original[0] == '(' else 'XXX'}) XXX-XXXX"
                    elif pattern_type == "ssn":
                        replacement = "XXX-XX-XXXX"
                    elif (
                        pattern_type == "zip_code"
                        and self.privacy_level != PrivacyLevel.STRICT
                    ):
                        # Keep first 3 digits for general area
                        replacement = f"{original[:3]}XX"
                    elif pattern_type == "address":
                        # Tokenize addresses completely
                        replacement = self._tokenize(original, "ADDRESS")
                    else:
                        # Generic tokenization
                        replacement = self._tokenize(original, pattern_type)

                    result = (
                        result[: match.start()] + replacement + result[match.end() :]
                    )
                    self._log_redaction("text", pattern_type, len(original))

        return result, redacted

    def _sanitize_transaction_description(self, description: str) -> str:
        """
        Smart redaction of transaction descriptions.
        Preserves merchant category while removing specific identifiers.
        """
        if not description:
            return description

        sanitized = description

        # First, redact any PII patterns
        for pattern_type, patterns in self.PATTERNS.items():
            if pattern_type not in ["zip_code"]:  # Handle zip codes specially
                sanitized, _ = self._detect_and_redact(
                    sanitized, pattern_type, patterns
                )

        # Smart merchant redaction
        # Remove store numbers but keep merchant name
        sanitized = re.sub(r"#\d+", "#[STORE]", sanitized)

        # Redact specific location info but keep state
        sanitized = re.sub(r"\b\d{5}\b", "[ZIP]", sanitized)

        # Remove transaction IDs and reference numbers from descriptions
        sanitized = re.sub(r"\*[A-Z0-9]{6,}", "*[REF]", sanitized)
        sanitized = re.sub(r"[A-Z0-9]{8,}", "[ID]", sanitized)

        return sanitized

    def _sanitize_amount(self, amount: float) -> float:
        """Optionally round amounts based on privacy level"""
        if amount is None:
            return None

        if self.privacy_level == PrivacyLevel.STRICT:
            # Round to nearest $10
            return round(amount / 10) * 10
        elif self.privacy_level == PrivacyLevel.BALANCED:
            # Round to nearest dollar
            return round(amount)
        else:
            # Keep original precision
            return amount

    def _sanitize_date(self, date: str) -> str:
        """Optionally generalize dates based on privacy level"""
        if self.privacy_level == PrivacyLevel.STRICT:
            # Convert to week
            try:
                dt = datetime.fromisoformat(date)
                week_start = dt - timedelta(days=dt.weekday())
                return f"Week of {week_start.strftime('%Y-%m-%d')}"
            except:
                return date
        elif self.privacy_level == PrivacyLevel.BALANCED:
            # Keep day precision
            return date
        else:
            # Keep full precision
            return date

    def sanitize_transaction(
        self, transaction: Dict, preserve_mapping: bool = True
    ) -> Dict:
        """
        Sanitize a single transaction.

        Args:
            transaction: Transaction dictionary
            preserve_mapping: Whether to store original->sanitized mappings

        Returns:
            Sanitized transaction dictionary
        """
        if not preserve_mapping:
            self.mappings[self.mapping_id].clear()

        sanitized = transaction.copy()

        # Sanitize description
        if "description" in sanitized:
            sanitized["description"] = self._sanitize_transaction_description(
                sanitized["description"]
            )

        # Sanitize amount
        if "amount" in sanitized:
            sanitized["amount"] = self._sanitize_amount(sanitized["amount"])

        # Sanitize date
        if "date" in sanitized:
            sanitized["date"] = self._sanitize_date(sanitized["date"])

        # Sanitize account information
        if "account_number" in sanitized:
            if len(str(sanitized["account_number"])) > 4:
                sanitized["account_suffix"] = (
                    f"****{str(sanitized['account_number'])[-4:]}"
                )
            del sanitized["account_number"]

        # Sanitize any reference numbers
        for field in ["reference_number", "transaction_id", "confirmation_number"]:
            if field in sanitized:
                sanitized[field] = self._tokenize(str(sanitized[field]), "REF")

        # Check all string fields for PII
        for key, value in list(sanitized.items()):
            if isinstance(value, str) and key not in [
                "description",
                "date",
                "category",
            ]:
                for pattern_type, patterns in self.PATTERNS.items():
                    new_value, was_redacted = self._detect_and_redact(
                        value, pattern_type, patterns, preserve_format=True
                    )
                    if was_redacted:
                        sanitized[key] = new_value
                        break  # Only apply first match to avoid over-processing

        # Add metadata
        sanitized["sanitized"] = True
        sanitized["privacy_level"] = self.privacy_level.value
        sanitized["transaction_token"] = self._tokenize(
            json.dumps(transaction, sort_keys=True), "TXN"
        )

        return sanitized

    def sanitize_transactions_batch(self, transactions: List[Dict]) -> List[Dict]:
        """
        Sanitize multiple transactions efficiently.

        Args:
            transactions: List of transaction dictionaries

        Returns:
            List of sanitized transaction dictionaries
        """
        logger.info(f"Sanitizing batch of {len(transactions)} transactions")

        sanitized_transactions = []
        for transaction in transactions:
            sanitized = self.sanitize_transaction(transaction, preserve_mapping=True)
            sanitized_transactions.append(sanitized)

        logger.info(
            f"Batch sanitization complete. Audit log has {len(self.audit_log)} entries"
        )
        return sanitized_transactions

    def sanitize_document_metadata(self, metadata: Dict) -> Dict:
        """
        Sanitize PDF/CSV metadata and headers.

        Args:
            metadata: Document metadata dictionary

        Returns:
            Sanitized metadata dictionary
        """
        sanitized = metadata.copy()

        # Fields that commonly contain PII
        sensitive_fields = [
            "account_holder",
            "account_name",
            "customer_name",
            "address",
            "email",
            "phone",
            "account_number",
        ]

        for field in sensitive_fields:
            if field in sanitized:
                if field in ["account_holder", "account_name", "customer_name"]:
                    sanitized[field] = self._tokenize(sanitized[field], "NAME")
                elif field == "account_number":
                    sanitized[field] = (
                        f"****{sanitized[field][-4:]}"
                        if len(sanitized[field]) > 4
                        else "****"
                    )
                else:
                    # Check for PII patterns
                    for pattern_type, patterns in self.PATTERNS.items():
                        new_value, was_redacted = self._detect_and_redact(
                            sanitized[field], pattern_type, patterns
                        )
                        if was_redacted:
                            sanitized[field] = new_value

        # Check all remaining string values
        for key, value in list(sanitized.items()):
            if isinstance(value, str) and key not in sensitive_fields:
                for pattern_type, patterns in self.PATTERNS.items():
                    new_value, was_redacted = self._detect_and_redact(
                        value, pattern_type, patterns
                    )
                    if was_redacted:
                        sanitized[key] = new_value

        sanitized["sanitized"] = True
        sanitized["privacy_level"] = self.privacy_level.value

        return sanitized

    def create_anonymized_summary(self, transactions: List[Dict]) -> Dict:
        """
        Create an anonymized summary suitable for LLM analysis.

        Args:
            transactions: List of transaction dictionaries

        Returns:
            Anonymized summary dictionary
        """
        if not transactions:
            return {
                "total_transactions": 0,
                "date_range": None,
                "categories": {},
                "patterns": {},
                "sanitized": True,
                "privacy_level": self.privacy_level.value,
            }

        # Sanitize transactions first
        sanitized_transactions = self.sanitize_transactions_batch(transactions)

        # Calculate summary statistics
        summary = {
            "total_transactions": len(sanitized_transactions),
            "date_range": {
                "start": min(t.get("date", "") for t in sanitized_transactions),
                "end": max(t.get("date", "") for t in sanitized_transactions),
            },
            "categories": defaultdict(lambda: {"count": 0, "total": 0}),
            "merchant_types": defaultdict(int),
            "time_patterns": {
                "by_day_of_week": defaultdict(int),
                "by_week_of_month": defaultdict(int),
            },
            "amount_statistics": {
                "total_income": 0,
                "total_expenses": 0,
                "average_transaction": 0,
                "median_transaction": 0,
            },
            "sanitized": True,
            "privacy_level": self.privacy_level.value,
            "audit_summary": {
                "total_redactions": len(self.audit_log),
                "redaction_types": defaultdict(int),
            },
        }

        # Analyze sanitized transactions
        amounts = []
        for transaction in sanitized_transactions:
            # Category analysis
            category = transaction.get("category", "Uncategorized")
            amount = transaction.get("amount", 0)

            summary["categories"][category]["count"] += 1
            summary["categories"][category]["total"] += amount

            # Amount analysis
            amounts.append(amount)
            if amount > 0:
                summary["amount_statistics"]["total_income"] += amount
            else:
                summary["amount_statistics"]["total_expenses"] += abs(amount)

            # Time pattern analysis (if dates aren't too generalized)
            if "date" in transaction and "Week of" not in transaction["date"]:
                try:
                    dt = datetime.fromisoformat(transaction["date"])
                    summary["time_patterns"]["by_day_of_week"][dt.strftime("%A")] += 1
                    week_of_month = (dt.day - 1) // 7 + 1
                    summary["time_patterns"]["by_week_of_month"][
                        f"Week {week_of_month}"
                    ] += 1
                except:
                    pass

        # Calculate statistics
        if amounts:
            summary["amount_statistics"]["average_transaction"] = sum(amounts) / len(
                amounts
            )
            sorted_amounts = sorted(amounts)
            mid = len(sorted_amounts) // 2
            summary["amount_statistics"]["median_transaction"] = (
                sorted_amounts[mid]
                if len(sorted_amounts) % 2
                else (sorted_amounts[mid - 1] + sorted_amounts[mid]) / 2
            )

        # Convert defaultdicts to regular dicts for JSON serialization
        summary["categories"] = dict(summary["categories"])
        summary["merchant_types"] = dict(summary["merchant_types"])
        summary["time_patterns"]["by_day_of_week"] = dict(
            summary["time_patterns"]["by_day_of_week"]
        )
        summary["time_patterns"]["by_week_of_month"] = dict(
            summary["time_patterns"]["by_week_of_month"]
        )

        # Audit summary
        for log_entry in self.audit_log:
            summary["audit_summary"]["redaction_types"][log_entry["pattern_type"]] += 1
        summary["audit_summary"]["redaction_types"] = dict(
            summary["audit_summary"]["redaction_types"]
        )

        return summary

    def restore_original_data(self, sanitized_data: Dict, mapping_id: str) -> Dict:
        """
        Restore original data using stored mappings (for internal use only).

        Args:
            sanitized_data: Sanitized data dictionary
            mapping_id: Mapping ID to use for restoration

        Returns:
            Original data dictionary (where possible)
        """
        if mapping_id not in self.mappings:
            logger.warning(f"No mappings found for ID: {mapping_id}")
            return sanitized_data

        restored = sanitized_data.copy()
        mappings = self.mappings[mapping_id]

        # Recursively restore tokens
        def restore_value(value):
            if isinstance(value, str):
                # Check if it's a token we can restore
                if value in mappings:
                    return mappings[value]
                # Check for partial tokens (e.g., in descriptions)
                for token, original in mappings.items():
                    if token in value:
                        value = value.replace(token, original)
                return value
            elif isinstance(value, dict):
                return {k: restore_value(v) for k, v in value.items()}
            elif isinstance(value, list):
                return [restore_value(item) for item in value]
            else:
                return value

        restored = restore_value(restored)

        # Remove sanitization metadata
        restored.pop("sanitized", None)
        restored.pop("privacy_level", None)
        restored.pop("transaction_token", None)

        return restored

    def validate_no_pii(self, data: Any) -> List[Dict]:
        """
        Validate that no PII remains in the data.

        Args:
            data: Data to validate (dict, list, or string)

        Returns:
            List of validation issues found
        """
        issues = []

        def check_value(value: Any, path: str = ""):
            if isinstance(value, str):
                for pattern_type, patterns in self.PATTERNS.items():
                    for pattern in patterns:
                        if re.search(pattern, value, re.IGNORECASE):
                            issues.append(
                                {
                                    "path": path,
                                    "pattern_type": pattern_type,
                                    "value_sample": (
                                        value[:50] + "..." if len(value) > 50 else value
                                    ),
                                }
                            )
            elif isinstance(value, dict):
                for k, v in value.items():
                    check_value(v, f"{path}.{k}" if path else k)
            elif isinstance(value, list):
                for i, item in enumerate(value):
                    check_value(item, f"{path}[{i}]")

        check_value(data)

        if issues:
            logger.warning(f"PII validation found {len(issues)} potential issues")
        else:
            logger.info("PII validation passed - no issues found")

        return issues

    def get_audit_log(self) -> List[Dict]:
        """Get the audit log of all redaction actions"""
        return self.audit_log.copy()

    def clear_mappings(self, mapping_id: Optional[str] = None):
        """
        Clear stored mappings for security.

        Args:
            mapping_id: Specific mapping ID to clear, or None to clear all
        """
        if mapping_id:
            self.mappings.pop(mapping_id, None)
            logger.info(f"Cleared mappings for ID: {mapping_id}")
        else:
            self.mappings.clear()
            logger.info("Cleared all mappings")


__all__ = ["DataSanitizer", "PrivacyLevel"]
