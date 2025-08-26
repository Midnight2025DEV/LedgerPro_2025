#!/usr/bin/env python3
"""
Data Sanitization Demo
Shows how PII is removed before sending to LLMs
"""

import sys
from pathlib import Path

# Add backend to path
sys.path.append(str(Path(__file__).parent.parent))

from processors.python.data_sanitizer import DataSanitizer, PrivacyLevel


def main():
    print("=== LedgerPro Data Sanitization Demo ===\n")

    # Sample transactions with PII
    sample_transactions = [
        {
            "date": "2024-03-15",
            "description": "WALMART #5274 AUSTIN TX 78701",
            "amount": -125.43,
            "category": "Shopping",
            "account_number": "1234567890123456",
            "reference_number": "REF20240315ABC123",
            "memo": "Payment to john.doe@email.com for order",
        },
        {
            "date": "2024-03-16",
            "description": "Direct Deposit from EMPLOYER INC - Employee ID: 12345",
            "amount": 2500.00,
            "category": "Income",
            "account_number": "9876543210",
            "confirmation": "CONF-789456",
            "notes": "Contact HR at (512) 555-1234 for questions",
        },
        {
            "date": "2024-03-17",
            "description": "CHASE CREDIT CARD 4111111111111111 PAYMENT",
            "amount": -500.00,
            "category": "Credit Card Payment",
            "ssn_note": "SSN ending in 6789 verified",
            "address": "Statement mailed to 123 Main St, Austin, TX 78701",
        },
    ]

    # Test different privacy levels
    for level in [PrivacyLevel.MINIMAL, PrivacyLevel.BALANCED, PrivacyLevel.STRICT]:
        print(f"\n{'='*60}")
        print(f"Privacy Level: {level.value.upper()}")
        print("=" * 60)

        # Create sanitizer
        sanitizer = DataSanitizer({"level": level.value})

        # Sanitize the first transaction
        original = sample_transactions[0]
        sanitized = sanitizer.sanitize_transaction(original)

        print("\nOriginal Transaction:")
        print(f"  Description: {original['description']}")
        print(f"  Amount: ${original['amount']}")
        print(f"  Account: {original['account_number']}")
        print(f"  Memo: {original['memo']}")

        print("\nSanitized Transaction:")
        print(f"  Description: {sanitized['description']}")
        print(f"  Amount: ${sanitized['amount']}")
        print(f"  Account: {sanitized.get('account_suffix', 'REMOVED')}")
        print(f"  Memo: {sanitized['memo']}")

        # Show audit log
        audit = sanitizer.get_audit_log()
        print(f"\nRedactions Made: {len(audit)}")
        if audit:
            redaction_types = {}
            for entry in audit:
                redaction_types[entry["pattern_type"]] = (
                    redaction_types.get(entry["pattern_type"], 0) + 1
                )
            print(f"  Types: {dict(redaction_types)}")

    # Demonstrate batch processing and summary
    print(f"\n\n{'='*60}")
    print("BATCH PROCESSING & ANONYMIZED SUMMARY")
    print("=" * 60)

    sanitizer = DataSanitizer({"level": PrivacyLevel.BALANCED.value})

    # Sanitize all transactions
    safe_transactions = sanitizer.sanitize_transactions_batch(sample_transactions)

    print(f"\nProcessed {len(safe_transactions)} transactions")
    print(f"Total redactions: {len(sanitizer.get_audit_log())}")

    # Create anonymized summary
    summary = sanitizer.create_anonymized_summary(sample_transactions)

    print("\nAnonymized Summary (safe for LLM):")
    print(f"  Total transactions: {summary['total_transactions']}")
    print(
        f"  Date range: {summary['date_range']['start']} to {summary['date_range']['end']}"
    )
    print(f"  Categories: {list(summary['categories'].keys())}")
    print(f"  Total income: ${summary['amount_statistics']['total_income']:,.2f}")
    print(f"  Total expenses: ${summary['amount_statistics']['total_expenses']:,.2f}")
    print(f"  Privacy level: {summary['privacy_level']}")

    # Validate no PII remains
    print("\n\nPII Validation:")
    issues = sanitizer.validate_no_pii(safe_transactions)
    if issues:
        print(f"  ⚠️ Found {len(issues)} potential PII issues")
        for issue in issues[:3]:
            print(f"    - {issue['pattern_type']} in {issue['path']}")
    else:
        print("  ✅ No PII detected in sanitized data")

    # Show example API call
    print(f"\n\n{'='*60}")
    print("EXAMPLE API USAGE")
    print("=" * 60)

    print("\nTo get sanitized data via API:")
    print("  GET /api/transactions/{job_id}/sanitized?privacy_level=balanced")
    print("\nResponse includes:")
    print("  - Sanitized transactions")
    print("  - Anonymized summary")
    print("  - Audit information")
    print("  - Privacy level applied")
    print("\nThis data is safe to send to OpenAI, Claude, or other LLMs!")


if __name__ == "__main__":
    main()
