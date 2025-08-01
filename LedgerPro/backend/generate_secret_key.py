#!/usr/bin/env python3
"""
Generate a secure secret key for LedgerPro
=========================================

This script generates a cryptographically secure 256-bit secret key
suitable for use with the LEDGER_SECRET_KEY environment variable.
"""

import secrets


def generate_secret_key() -> str:
    """Generate a secure 256-bit secret key."""
    return secrets.token_urlsafe(32)  # 32 bytes = 256 bits


def main():
    """Generate and display a secure secret key."""
    print("🔐 LedgerPro Secret Key Generator")
    print("=" * 35)

    secret_key = generate_secret_key()

    print("\nGenerated Secret Key:")
    print(f"{secret_key}")

    print("\nAdd this to your .env file:")
    print(f"LEDGER_SECRET_KEY={secret_key}")

    print("\n⚠️  Security Notes:")
    print("- Keep this key secret and secure")
    print("- Use different keys for different environments")
    print("- Never commit this key to version control")
    print("- Store securely in production (e.g., AWS Secrets Manager)")


if __name__ == "__main__":
    main()
