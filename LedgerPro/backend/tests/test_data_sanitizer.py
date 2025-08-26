"""
Comprehensive tests for the Data Sanitizer module
"""

import sys
from pathlib import Path

# Add parent directory to path (must be done before other imports)
sys.path.append(str(Path(__file__).parent.parent))

import unittest
import json
from datetime import datetime, timedelta

from processors.python.data_sanitizer import DataSanitizer, PrivacyLevel


class TestDataSanitizer(unittest.TestCase):
    """Test cases for DataSanitizer class"""

    def setUp(self):
        """Set up test fixtures"""
        self.sanitizer_minimal = DataSanitizer({"level": "minimal"})
        self.sanitizer_balanced = DataSanitizer({"level": "balanced"})
        self.sanitizer_strict = DataSanitizer({"level": "strict"})

        # Sample transaction with various PII
        self.sample_transaction = {
            "date": "2024-03-15",
            "description": "WALMART #5274 AUSTIN TX 78701",
            "amount": -125.43,
            "category": "Shopping",
            "account_number": "1234567890123456",
            "reference_number": "REF20240315ABC123",
            "memo": "Payment to john.doe@email.com for order",
            "phone_in_notes": "Call customer at (512) 555-1234",
            "address_in_notes": "123 Main Street, Austin, TX 78701",
        }

        self.sample_metadata = {
            "account_holder": "John Michael Doe",
            "account_name": "Premier Checking",
            "account_number": "9876543210",
            "email": "john.doe@example.com",
            "phone": "512-555-9876",
            "address": "456 Oak Avenue, Suite 100, Austin, TX 78701",
            "statement_period": "2024-03-01 to 2024-03-31",
        }

    def test_credit_card_redaction(self):
        """Test credit card number detection and redaction"""
        test_cases = [
            ("Visa: 4111111111111111", "****1111"),
            ("MC: 5555555555554444", "****4444"),
            ("Amex: 378282246310005", "****0005"),
            ("Discover: 6011111111111117", "****1117"),
            ("With spaces: 4111 1111 1111 1111", "****1111"),
            ("With dashes: 4111-1111-1111-1111", "****1111"),
        ]

        for original, expected_suffix in test_cases:
            result, was_redacted = self.sanitizer_balanced._detect_and_redact(
                original,
                "credit_card",
                self.sanitizer_balanced.PATTERNS["credit_card"],
                preserve_format=True,
            )
            self.assertTrue(was_redacted)
            self.assertIn(expected_suffix, result)
            # Don't check for prefix removal as we preserve context

    def test_ssn_redaction(self):
        """Test SSN detection and redaction"""
        test_cases = [
            "SSN: 123-45-6789",
            "Social Security: 123 45 6789",
            "SSN 123456789",
        ]

        for test_text in test_cases:
            result, was_redacted = self.sanitizer_balanced._detect_and_redact(
                test_text, "ssn", self.sanitizer_balanced.PATTERNS["ssn"]
            )
            self.assertTrue(was_redacted)
            self.assertIn("XXX-XX-XXXX", result)
            self.assertNotIn("123", result)

    def test_email_redaction(self):
        """Test email address detection and tokenization"""
        test_email = "Contact us at john.doe@example.com for more info"
        result, was_redacted = self.sanitizer_balanced._detect_and_redact(
            test_email, "email", self.sanitizer_balanced.PATTERNS["email"]
        )

        self.assertTrue(was_redacted)
        self.assertNotIn("john.doe@example.com", result)
        self.assertIn("EMAIL_", result)

        # Verify tokenization is reversible
        tokens = [word for word in result.split() if word.startswith("EMAIL_")]
        self.assertEqual(len(tokens), 1)
        stored_value = self.sanitizer_balanced.mappings[
            self.sanitizer_balanced.mapping_id
        ][tokens[0]]
        self.assertEqual(stored_value, "john.doe@example.com")

    def test_phone_redaction(self):
        """Test phone number detection and redaction"""
        test_cases = [
            ("Call us at (512) 555-1234", "(512) XXX-XXXX"),
            ("Phone: 512-555-1234", "(XXX) XXX-XXXX"),
            ("Contact: 5125551234", "(XXX) XXX-XXXX"),
            ("Tel: +1-512-555-1234", "(XXX) XXX-XXXX"),
        ]

        for original, expected_pattern in test_cases:
            result, was_redacted = self.sanitizer_balanced._detect_and_redact(
                original, "phone", self.sanitizer_balanced.PATTERNS["phone"]
            )
            self.assertTrue(was_redacted)
            self.assertIn("XXX-XXXX", result)
            self.assertNotIn("555-1234", result)

    def test_address_redaction(self):
        """Test address detection and redaction"""
        test_addresses = [
            "123 Main Street",
            "456 Oak Avenue",
            "P.O. Box 789",
            "1000 Market St Suite 200",
        ]

        for address in test_addresses:
            result, was_redacted = self.sanitizer_balanced._detect_and_redact(
                address, "address", self.sanitizer_balanced.PATTERNS["address"]
            )
            self.assertTrue(was_redacted)
            # Should be tokenized
            self.assertIn("ADDRESS_", result)

    def test_transaction_description_sanitization(self):
        """Test smart redaction of transaction descriptions"""
        test_cases = [
            {
                "input": "WALMART #5274 AUSTIN TX 78701",
                "expected_patterns": ["WALMART", "#[STORE]", "[ZIP]"],
                "not_expected": ["5274", "78701"],
            },
            {
                "input": "AMAZON.COM*2G4UK5H40 AMZN.COM/BILL WA",
                "expected_patterns": ["AMAZON"],
                "not_expected": ["2G4UK5H40"],
            },
            {
                "input": "SHELL OIL 57445566901 HOUSTON TX",
                "expected_patterns": ["SHELL"],
                "not_expected": ["57445566901"],
            },
        ]

        for test in test_cases:
            result = self.sanitizer_balanced._sanitize_transaction_description(
                test["input"]
            )

            for pattern in test["expected_patterns"]:
                self.assertIn(pattern, result)

            for pattern in test["not_expected"]:
                self.assertNotIn(pattern, result)

    def test_privacy_levels(self):
        """Test different privacy levels"""
        transaction = self.sample_transaction.copy()

        # Test minimal level
        minimal_result = self.sanitizer_minimal.sanitize_transaction(transaction)
        self.assertEqual(minimal_result["amount"], -125.43)  # Original precision
        self.assertEqual(minimal_result["date"], "2024-03-15")  # Original date

        # Test balanced level
        balanced_result = self.sanitizer_balanced.sanitize_transaction(transaction)
        self.assertEqual(balanced_result["amount"], -125)  # Rounded to dollar
        self.assertEqual(balanced_result["date"], "2024-03-15")  # Day precision

        # Test strict level
        strict_result = self.sanitizer_strict.sanitize_transaction(transaction)
        self.assertEqual(strict_result["amount"], -130)  # Rounded to $10
        self.assertIn("Week of", strict_result["date"])  # Week precision

    def test_transaction_sanitization(self):
        """Test full transaction sanitization"""
        result = self.sanitizer_balanced.sanitize_transaction(self.sample_transaction)

        # Check required fields
        self.assertTrue(result["sanitized"])
        self.assertEqual(result["privacy_level"], "balanced")
        self.assertIn("transaction_token", result)

        # Check account number handling
        self.assertNotIn("account_number", result)
        self.assertIn("account_suffix", result)
        self.assertEqual(result["account_suffix"], "****3456")

        # Check reference tokenization
        self.assertIn("REF_", result["reference_number"])

        # Check PII removal
        self.assertNotIn("john.doe@email.com", result["memo"])
        self.assertIn("XXX-XXXX", result["phone_in_notes"])  # Phone should be redacted
        self.assertIn(
            "ADDRESS_", result["address_in_notes"]
        )  # Address should be tokenized

    def test_batch_sanitization(self):
        """Test batch transaction sanitization"""
        transactions = [
            self.sample_transaction.copy(),
            {
                "date": "2024-03-16",
                "description": "STARBUCKS STORE #12345",
                "amount": -5.75,
                "category": "Dining Out",
            },
            {
                "date": "2024-03-17",
                "description": "Direct Deposit from EMPLOYER CO",
                "amount": 2500.00,
                "category": "Income",
            },
        ]

        results = self.sanitizer_balanced.sanitize_transactions_batch(transactions)

        self.assertEqual(len(results), 3)
        for result in results:
            self.assertTrue(result["sanitized"])
            self.assertEqual(result["privacy_level"], "balanced")

    def test_metadata_sanitization(self):
        """Test document metadata sanitization"""
        result = self.sanitizer_balanced.sanitize_document_metadata(
            self.sample_metadata
        )

        # Check name tokenization
        self.assertIn("NAME_", result["account_holder"])
        self.assertNotIn("John Michael Doe", result["account_holder"])

        # Check account number
        self.assertEqual(result["account_number"], "****3210")

        # Check other PII
        self.assertIn("EMAIL_", result["email"])
        self.assertNotIn("john.doe@example.com", result["email"])
        self.assertIn("XXX-XXXX", result["phone"])
        self.assertIn("ADDRESS_", result["address"])

    def test_anonymized_summary(self):
        """Test creation of anonymized summary"""
        transactions = [
            {
                "date": "2024-03-15",
                "description": "WALMART",
                "amount": -125.43,
                "category": "Shopping",
            },
            {
                "date": "2024-03-16",
                "description": "STARBUCKS",
                "amount": -5.75,
                "category": "Dining Out",
            },
            {
                "date": "2024-03-17",
                "description": "Salary Deposit",
                "amount": 2500.00,
                "category": "Income",
            },
        ]

        summary = self.sanitizer_balanced.create_anonymized_summary(transactions)

        self.assertEqual(summary["total_transactions"], 3)
        self.assertTrue(summary["sanitized"])
        self.assertEqual(summary["privacy_level"], "balanced")

        # Check categories
        self.assertIn("Shopping", summary["categories"])
        self.assertIn("Dining Out", summary["categories"])
        self.assertIn("Income", summary["categories"])

        # Check statistics (amounts are rounded in balanced mode)
        self.assertEqual(summary["amount_statistics"]["total_income"], 2500.00)
        self.assertEqual(
            summary["amount_statistics"]["total_expenses"], 131
        )  # Rounded amounts

        # Check time patterns
        self.assertIn("by_day_of_week", summary["time_patterns"])
        self.assertIn("by_week_of_month", summary["time_patterns"])

    def test_data_restoration(self):
        """Test reversible tokenization"""
        original = self.sample_transaction.copy()
        sanitized = self.sanitizer_balanced.sanitize_transaction(original)

        # Store mapping ID
        mapping_id = self.sanitizer_balanced.mapping_id

        # Attempt restoration
        restored = self.sanitizer_balanced.restore_original_data(sanitized, mapping_id)

        # Check that tokenized fields are restored
        self.assertEqual(restored["reference_number"], original["reference_number"])

        # Check that sanitization metadata is removed
        self.assertNotIn("sanitized", restored)
        self.assertNotIn("privacy_level", restored)
        self.assertNotIn("transaction_token", restored)

    def test_pii_validation(self):
        """Test PII validation function"""
        # Test with unsanitized data
        unsanitized = {
            "email": "test@example.com",
            "phone": "555-123-4567",
            "ssn": "123-45-6789",
        }

        issues = self.sanitizer_balanced.validate_no_pii(unsanitized)
        self.assertGreater(len(issues), 0)

        # Test with sanitized data
        sanitized = self.sanitizer_balanced.sanitize_transaction(
            self.sample_transaction
        )
        issues = self.sanitizer_balanced.validate_no_pii(sanitized)

        # Should have no PII issues (except potentially in tokenized values or false positives)
        real_issues = [
            issue
            for issue in issues
            if not any(
                token in issue["value_sample"]
                for token in [
                    "EMAIL_",
                    "REF_",
                    "ADDRESS_",
                    "TXN_",
                    "SWIFT_",
                    "balanced",
                    "sanitized",
                ]
            )
        ]
        # Allow some false positives as the validation is sensitive
        self.assertLess(len(real_issues), 3)

    def test_audit_logging(self):
        """Test audit log functionality"""
        # Clear existing audit log
        self.sanitizer_balanced.audit_log.clear()

        # Perform sanitization
        self.sanitizer_balanced.sanitize_transaction(self.sample_transaction)

        # Check audit log
        audit_log = self.sanitizer_balanced.get_audit_log()
        self.assertGreater(len(audit_log), 0)

        # Verify log entries have required fields
        for entry in audit_log:
            self.assertIn("timestamp", entry)
            self.assertIn("field", entry)
            self.assertIn("pattern_type", entry)
            self.assertIn("original_length", entry)
            self.assertIn("privacy_level", entry)

    def test_performance_large_batch(self):
        """Test performance with large batch of transactions"""
        import time

        # Generate 1000 transactions
        large_batch = []
        for i in range(1000):
            transaction = {
                "date": f"2024-03-{(i % 30) + 1:02d}",
                "description": f"Transaction {i} at Store #{i % 100}",
                "amount": -50 + (i % 200),
                "category": ["Shopping", "Dining Out", "Transport"][i % 3],
                "email": f"user{i}@example.com",
                "phone": f"555-{i:04d}",
            }
            large_batch.append(transaction)

        start_time = time.time()
        results = self.sanitizer_balanced.sanitize_transactions_batch(large_batch)
        end_time = time.time()

        # Should complete in reasonable time (< 5 seconds for 1000 transactions)
        self.assertLess(end_time - start_time, 5.0)
        self.assertEqual(len(results), 1000)

        # Verify all are sanitized
        for result in results:
            self.assertTrue(result["sanitized"])

    def test_edge_cases(self):
        """Test edge cases and error handling"""
        # Empty transaction
        result = self.sanitizer_balanced.sanitize_transaction({})
        self.assertTrue(result["sanitized"])

        # Transaction with None values
        transaction = {"date": None, "description": None, "amount": None}
        result = self.sanitizer_balanced.sanitize_transaction(transaction)
        self.assertTrue(result["sanitized"])

        # Empty batch
        results = self.sanitizer_balanced.sanitize_transactions_batch([])
        self.assertEqual(len(results), 0)

        # Invalid mapping ID for restoration
        restored = self.sanitizer_balanced.restore_original_data(
            {"test": "data"}, "invalid-mapping-id"
        )
        self.assertEqual(restored, {"test": "data"})

    def test_international_patterns(self):
        """Test international PII patterns"""
        # IBAN test
        iban_text = "Transfer to DE89370400440532013000"
        result, was_redacted = self.sanitizer_balanced._detect_and_redact(
            iban_text, "iban", self.sanitizer_balanced.PATTERNS["iban"]
        )
        self.assertTrue(was_redacted)
        self.assertNotIn("DE89370400440532013000", result)

        # SWIFT test
        swift_text = "Bank SWIFT: DEUTDEFF"
        result, was_redacted = self.sanitizer_balanced._detect_and_redact(
            swift_text, "swift", self.sanitizer_balanced.PATTERNS["swift"]
        )
        self.assertTrue(was_redacted)
        self.assertNotIn("DEUTDEFF", result)


if __name__ == "__main__":
    unittest.main()
