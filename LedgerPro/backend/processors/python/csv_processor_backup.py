"""Simple CSV processor for financial transaction files."""

import csv
import re
from datetime import datetime
from typing import Dict


def process_csv_file(file_path: str) -> Dict:
    """Process a CSV file containing financial transactions.

    Args:
        file_path: Path to the CSV file

    Returns:
        Dictionary containing transactions and metadata
    """
    transactions = []
    metadata = {
        "filename": file_path,
        "processing_time": datetime.now().isoformat(),
        "format": "csv",
    }

    # Common column name mappings
    date_columns = [
        "date",
        "transaction date",
        "trans date",
        "posting date",
        "posted date",
    ]
    description_columns = [
        "description",
        "merchant",
        "payee",
        "transaction",
        "details",
        "memo",
        "reference",
    ]
    amount_columns = ["amount", "debit", "credit", "value", "transaction amount"]
    category_columns = ["category", "type", "transaction type"]

    try:
        with open(file_path, "r", encoding="utf-8-sig") as f:  # Handle BOM
            # Try to detect delimiter
            sample = f.read(1024)
            f.seek(0)

            # Try different delimiters if sniffer fails
            delimiters = [",", ";", "\t", "|"]
            dialect = None

            for delimiter in delimiters:
                try:
                    dialect = csv.Sniffer().sniff(sample, delimiters=delimiter)
                    break
                except csv.Error:
                    continue

            # Fallback to comma if detection fails
            if dialect is None:
                dialect = csv.excel()  # Default comma delimiter

            reader = csv.DictReader(f, dialect=dialect)

            # Get headers and normalize them
            headers = (
                [h.lower().strip() for h in reader.fieldnames]
                if reader.fieldnames
                else []
            )

            # Debug: Print headers to understand structure
            print(f"CSV Headers found: {headers}")

            # Map columns with Navy Federal specific handling
            date_col = next(
                (h for h in headers if any(d in h for d in date_columns)), None
            )

            # Special handling for Navy Federal format - exact match for "description"
            desc_col = None
            if "description" in headers:
                desc_col = "description"
            else:
                # Fallback to generic matching, but exclude "transaction date"
                desc_col = next(
                    (
                        h
                        for h in headers
                        if any(d in h for d in description_columns)
                        and "transaction date" not in h
                    ),
                    None,
                )

            amount_col = next(
                (h for h in headers if any(d in h for d in amount_columns)), None
            )
            category_col = next(
                (h for h in headers if any(c in h for c in category_columns)), None
            )

            # Debug: Print column mappings
            print(
                f"Column mappings - date: {date_col}, desc: {desc_col}, amount: {amount_col}, category: {category_col}"
            )

            # Process rows
            for row in reader:
                # Clean row data
                row = {
                    k.lower().strip(): v.strip() if v else "" for k, v in row.items()
                }

                transaction = {}

                # Extract date
                if date_col and row.get(date_col):
                    transaction["date"] = parse_date(row[date_col])
                else:
                    continue  # Skip rows without dates

                # Extract description
                if desc_col and row.get(desc_col):
                    transaction["description"] = row[desc_col]
                else:
                    transaction["description"] = "Unknown"

                # Extract amount
                if amount_col and row.get(amount_col):
                    amount = parse_amount(row[amount_col])

                    # Check for credit/debit indicator (Navy Federal format)
                    indicator_col = next(
                        (
                            h
                            for h in headers
                            if "credit debit indicator" in h or "indicator" in h
                        ),
                        None,
                    )

                    if indicator_col and row.get(indicator_col):
                        indicator = row[indicator_col].lower().strip()
                        if indicator == "debit":
                            transaction["amount"] = -abs(amount)
                        elif indicator == "credit":
                            transaction["amount"] = abs(amount)
                        else:
                            transaction["amount"] = amount
                    else:
                        transaction["amount"] = amount
                else:
                    # Check for separate debit/credit columns
                    debit = next(
                        (
                            row.get(h, "")
                            for h in headers
                            if "debit" in h and "indicator" not in h
                        ),
                        "",
                    )
                    credit = next(
                        (
                            row.get(h, "")
                            for h in headers
                            if "credit" in h and "indicator" not in h
                        ),
                        "",
                    )

                    if debit:
                        transaction["amount"] = -abs(parse_amount(debit))
                    elif credit:
                        transaction["amount"] = abs(parse_amount(credit))
                    else:
                        continue  # Skip rows without amounts

                # Extract category
                if category_col and row.get(category_col):
                    transaction["category"] = row[category_col]
                else:
                    transaction["category"] = categorize_transaction(
                        transaction["description"]
                    )

                # Add confidence score
                transaction["confidence"] = 1.0  # CSV data is usually accurate

                # Store all original CSV data for detailed view
                transaction["raw_data"] = {}
                for key, value in row.items():
                    if value and value.strip():  # Only store non-empty values
                        # Clean up the key name for display
                        clean_key = key.replace("_", " ").title()
                        transaction["raw_data"][clean_key] = value.strip()

                transactions.append(transaction)

            metadata["total_transactions"] = len(transactions)
            metadata["raw_text"] = f"CSV file with {len(transactions)} transactions"

    except Exception as e:
        metadata["error"] = str(e)
        metadata["total_transactions"] = 0

    return {
        "transactions": transactions,
        "metadata": metadata,
        "status": "completed" if transactions else "error",
    }


def parse_date(date_str: str) -> str:
    """Parse various date formats and return YYYY-MM-DD format."""
    date_str = date_str.strip()

    # Common date formats
    formats = [
        "%Y-%m-%d",  # 2024-01-15
        "%m/%d/%Y",  # 01/15/2024
        "%m-%d-%Y",  # 01-15-2024
        "%d/%m/%Y",  # 15/01/2024
        "%Y/%m/%d",  # 2024/01/15
        "%b %d, %Y",  # Jan 15, 2024
        "%B %d, %Y",  # January 15, 2024
        "%d %b %Y",  # 15 Jan 2024
        "%d %B %Y",  # 15 January 2024
    ]

    for fmt in formats:
        try:
            parsed = datetime.strptime(date_str, fmt)
            return parsed.strftime("%Y-%m-%d")
        except ValueError:
            continue

    # If no format matches, return as is
    return date_str


def parse_amount(amount_str: str) -> float:
    """Parse amount string to float."""
    # Remove currency symbols and spaces
    amount_str = re.sub(r"[^\d\.\-\+,]", "", amount_str)

    # Handle parentheses for negative amounts
    if "(" in amount_str and ")" in amount_str:
        amount_str = "-" + amount_str.replace("(", "").replace(")", "")

    # Remove commas
    amount_str = amount_str.replace(",", "")

    try:
        return float(amount_str)
    except ValueError:
        return 0.0


def categorize_transaction(description: str) -> str:
    """Categorize transaction using simple rule-based approach."""
    description = description.lower()

    # Category rules
    categories = {
        "Food & Dining": [
            "restaurant",
            "cafe",
            "coffee",
            "food",
            "dining",
            "eat",
            "pizza",
            "burger",
            "sandwich",
            "uber eats",
            "doordash",
            "grubhub",
        ],
        "Shopping": ["amazon", "walmart", "target", "store", "shop", "mall", "retail"],
        "Transportation": ["uber", "lyft", "gas", "fuel", "parking", "toll", "transit"],
        "Entertainment": ["movie", "theater", "concert", "game", "netflix", "spotify"],
        "Utilities": ["electric", "water", "gas", "internet", "phone", "utility"],
        "Payment": ["payment", "transfer", "deposit", "credit"],
        "Business": ["business", "office", "supply", "service"],
        "Taxes": ["tax", "irs", "state tax", "federal"],
        "Healthcare": ["doctor", "hospital", "pharmacy", "medical", "health"],
        "Insurance": ["insurance", "premium", "coverage"],
        "Travel": ["hotel", "airline", "flight", "airbnb", "vacation"],
        "Education": ["school", "university", "tuition", "education", "course"],
    }

    for category, keywords in categories.items():
        if any(keyword in description for keyword in keywords):
            return category

    return "Other"
