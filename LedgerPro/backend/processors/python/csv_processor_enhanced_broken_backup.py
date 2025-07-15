#!/usr/bin/env python3
"""
Enhanced CSV processor for financial transactions.
Handles complex multi-section CSVs with different headers, dates without years,
and foreign currency transactions with exchange rates.
"""

import csv
import re
from datetime import datetime, date
from typing import Dict, List, Optional, Tuple
import io
import warnings

# Suppress the datetime parsing warning for year-less dates
warnings.filterwarnings(
    "ignore", category=DeprecationWarning, message=".*day of month without a year.*"
)


class EnhancedCSVProcessor:
    """Enhanced CSV processor for complex financial statement formats."""

    def __init__(self):
        self.current_year = datetime.now().year

        # Common column name mappings
        self.date_columns = [
            "date",
            "trans_date",
            "trans date",
            "transaction_date",
            "transaction date",
            "posting_date",
            "posting date",
            "post_date",
            "post date",
            "posted_date",
        ]

        self.description_columns = [
            "description",
            "merchant",
            "payee",
            "transaction",
            "details",
            "memo",
            "reference",
            "narrative",
        ]

        self.amount_columns = [
            "amount",
            "debit",
            "credit",
            "value",
            "transaction_amount",
            "transaction amount",
            "net_amount",
        ]

        self.category_columns = [
            "category",
            "type",
            "transaction_type",
            "transaction type",
        ]

    def detect_sections(self, file_content: str) -> List[Dict]:
        """Detect different sections in a multi-section CSV."""
        lines = file_content.strip().split("\n")
        sections = []
        current_section = []

        for i, line in enumerate(lines):
            line = line.strip()

            # Skip empty lines
            if not line:
                continue

            # Check if this line looks like a header
            if self._is_header_line(line):
                # Save previous section if it exists
                if current_section:
                    sections.append(
                        {
                            "header": current_section[0],
                            "data": current_section[1:],
                            "start_line": i - len(current_section) + 1,
                        }
                    )

                # Start new section
                current_section = [line]
            else:
                # Add to current section
                current_section.append(line)

        # Add final section
        if current_section:
            sections.append(
                {
                    "header": current_section[0],
                    "data": current_section[1:],
                    "start_line": len(lines) - len(current_section) + 1,
                }
            )

        return sections

    def _is_header_line(self, line: str) -> bool:
        """Determine if a line is likely a header."""
        # Split by common delimiters
        parts = re.split(r"[,;\t|]", line.lower())

        # Check for common header keywords
        header_keywords = [
            "date",
            "trans",
            "post",
            "description",
            "amount",
            "debit",
            "credit",
            "balance",
            "category",
            "type",
            "merchant",
            "payee",
        ]

        keyword_matches = sum(
            1 for part in parts if any(keyword in part for keyword in header_keywords)
        )

        # Consider it a header if >= 2 header keywords found
        return keyword_matches >= 2

    def parse_date_with_year(self, date_str: str) -> str:
        """Parse date string, assuming current year if year is missing."""
        date_str = date_str.strip()

        # Extended date formats including year-less formats
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
            "%m/%d/%y",  # 01/15/24
            "%m-%d-%y",  # 01-15-24
            "%b %d",  # Jan 15 (no year)
            "%B %d",  # January 15 (no year)
            "%m/%d",  # 01/15 (no year)
            "%m-%d",  # 01-15 (no year)
        ]

        for fmt in formats:
            try:
                parsed = datetime.strptime(date_str, fmt)

                # If year is 1900 (default for year-less formats), use current year
                if parsed.year == 1900:
                    parsed = parsed.replace(year=self.current_year)

                return parsed.strftime("%Y-%m-%d")
            except ValueError:
                continue

        # If no format matches, return as is
        return date_str

    def parse_amount_enhanced(self, amount_str: str) -> float:
        """Enhanced amount parsing with better currency symbol handling."""
        if not amount_str:
            return 0.0

        # Remove currency symbols, spaces, and other non-numeric characters
        cleaned = re.sub(r"[^\d\.\-\+,\(\)]", "", amount_str)

        # Handle parentheses for negative amounts
        if "(" in cleaned and ")" in cleaned:
            cleaned = "-" + cleaned.replace("(", "").replace(")", "")

        # Remove commas (thousand separators)
        cleaned = cleaned.replace(",", "")

        # Handle multiple decimal points (keep only the last one)
        if cleaned.count(".") > 1:
            parts = cleaned.split(".")
            cleaned = "".join(parts[:-1]) + "." + parts[-1]

        try:
            return float(cleaned)
        except ValueError:
            return 0.0

    def detect_forex_transaction(
        self, rows: List[str], current_index: int
    ) -> Optional[Dict]:
        """Detect and extract forex transaction data from subsequent rows."""
        if current_index + 2 >= len(rows):
            return None

        next_row = rows[current_index + 1] if current_index + 1 < len(rows) else ""
        exchange_row = rows[current_index + 2] if current_index + 2 < len(rows) else ""

        forex_data = {}

        # Look for foreign currency amount (e.g., "$672.51 MXN")
        forex_match = re.search(r"([\d,]+\.?\d*)\s*([A-Z]{3})", next_row)
        if forex_match:
            forex_data["original_amount"] = self.parse_amount_enhanced(
                forex_match.group(1)
            )
            forex_data["original_currency"] = forex_match.group(2)

        # Look for exchange rate (e.g., "19.436705202 Exchange Rate")
        rate_match = re.search(
            r"([\d,]+\.?\d*)\s*Exchange\s*Rate", exchange_row, re.IGNORECASE
        )
        if rate_match:
            rate_str = rate_match.group(1).replace(",", "")
            forex_data["exchange_rate"] = float(rate_str)

        # Return forex data if we found both currency and rate
        if "original_amount" in forex_data and "exchange_rate" in forex_data:
            return forex_data

        return None

    def map_columns(self, headers: List[str]) -> Dict[str, str]:
        """Map CSV headers to standard column names."""
        headers_lower = [h.lower().strip() for h in headers]

        mapping = {}

        # Map date column
        mapping["date"] = next(
            (h for h in headers_lower if any(d in h for d in self.date_columns)), None
        )

        # Map description column
        mapping["description"] = next(
            (h for h in headers_lower if any(d in h for d in self.description_columns)),
            None,
        )

        # Map amount column
        mapping["amount"] = next(
            (h for h in headers_lower if any(d in h for d in self.amount_columns)), None
        )

        # Map category column
        mapping["category"] = next(
            (h for h in headers_lower if any(c in h for c in self.category_columns)),
            None,
        )

        return mapping

    def process_section(self, section: Dict) -> List[Dict]:
        """Process a single section of the CSV."""
        if not section["data"]:
            return []

        # Parse header
        header_line = section["header"]

        # Detect delimiter
        delimiter = self._detect_delimiter(header_line)

        # Parse header and data
        header_reader = csv.reader([header_line], delimiter=delimiter)
        headers = next(header_reader)

        # Map columns
        column_mapping = self.map_columns(headers)

        print(f"Section headers: {headers}")
        print(f"Column mapping: {column_mapping}")
        print(f"Data rows count: {len(section['data'])}")

        transactions = []
        data_rows = []

        # Parse data rows
        for row_str in section["data"]:
            if not row_str.strip():
                continue

            # Skip divider rows (like "JONATHAN I HERNANDEZ 9581 Transactions")
            if self._is_divider_row(row_str):
                print(f"Skipping divider row: {row_str}")
                continue

            try:
                row_reader = csv.reader([row_str], delimiter=delimiter)
                row_data = next(row_reader)
                data_rows.append(row_data)
                print(f"Parsed row: {row_data}")
            except Exception as e:
                print(f"Error parsing row '{row_str}': {e}")
                continue

        # Process each row
        for i, row_data in enumerate(data_rows):
            # Ensure row has enough columns
            while len(row_data) < len(headers):
                row_data.append("")

            # Create row dictionary
            row_dict = {
                headers[j]
                .lower()
                .strip(): row_data[j].strip() if j < len(row_data) else ""
                for j in range(len(headers))
            }

            print(f"Processing row {i}: {row_dict}")

            transaction = {}

            # Extract date
            if column_mapping["date"] and row_dict.get(column_mapping["date"]):
                date_str = row_dict[column_mapping["date"]]
                if date_str:  # Only process if date is not empty
                    transaction["date"] = self.parse_date_with_year(date_str)
                    print(f"  Date: {date_str} -> {transaction['date']}")
                else:
                    print(f"  Skipping: no date")
                    continue
            else:
                print(f"  Skipping: no date column")
                continue  # Skip rows without dates

            # Extract description
            if column_mapping["description"] and row_dict.get(
                column_mapping["description"]
            ):
                transaction["description"] = row_dict[column_mapping["description"]]
                print(f"  Description: {transaction['description']}")
            else:
                transaction["description"] = "Unknown"
                print(f"  Description: Unknown")

            # Skip empty descriptions or forex info rows
            if (
                not transaction["description"]
                or "exchange rate" in transaction["description"].lower()
            ):
                print(f"  Skipping: empty description or forex info")
                continue

            # Extract amount
            if column_mapping["amount"] and row_dict.get(column_mapping["amount"]):
                amount_str = row_dict[column_mapping["amount"]]
                if amount_str:  # Only process if amount is not empty
                    transaction["amount"] = self.parse_amount_enhanced(amount_str)
                    print(f"  Amount: {amount_str} -> {transaction['amount']}")
                else:
                    print(f"  Skipping: no amount")
                    continue
            else:
                print(f"  Skipping: no amount column")
                continue  # Skip rows without amounts

            # Skip zero amounts
            if transaction["amount"] == 0:
                print(f"  Skipping: zero amount")
                continue

            # Extract category
            if column_mapping["category"] and row_dict.get(column_mapping["category"]):
                transaction["category"] = row_dict[column_mapping["category"]]
            else:
                transaction["category"] = self._categorize_transaction(
                    transaction["description"]
                )

            print(f"  Category: {transaction['category']}")

            # Check for forex data in subsequent rows
            forex_data = self.detect_forex_transaction(section["data"], i)
            if forex_data:
                transaction.update(forex_data)
                transaction["has_forex"] = True
                print(f"  Forex: {forex_data}")
            else:
                transaction["has_forex"] = False

            # Add confidence score
            transaction["confidence"] = 1.0

            # Store raw data
            transaction["raw_data"] = {
                headers[j].replace("_", " ").title(): row_data[j]
                for j in range(min(len(headers), len(row_data)))
                if row_data[j].strip()
            }

            print(f"  Adding transaction: {transaction}")
            transactions.append(transaction)

        return transactions

    def _detect_delimiter(self, line: str) -> str:
        """Detect CSV delimiter."""
        delimiters = [",", ";", "\t", "|"]

        for delimiter in delimiters:
            if delimiter in line:
                return delimiter

        return ","  # Default to comma

    def _is_divider_row(self, row: str) -> bool:
        """Check if row is a divider/section separator."""
        # Common patterns for divider rows
        divider_patterns = [
            r"^\s*[A-Z\s]+\d+\s+Transactions\s*$",  # "JONATHAN I HERNANDEZ 9581 Transactions"
            r"^\s*[-=]+\s*$",  # "----" or "===="
            r"^\s*[A-Z\s]+Summary\s*$",  # "Account Summary"
            r"^\s*Additional\s+Information",  # "Additional Information"
        ]

        for pattern in divider_patterns:
            if re.match(pattern, row, re.IGNORECASE):
                return True

        return False

    def _categorize_transaction(self, description: str) -> str:
        """Basic categorization for transactions."""
        description_lower = description.lower()

        # Enhanced category rules
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
                "panera",
                "starbucks",
                "mcdonald",
                "subway",
                "taco bell",
                "kfc",
                "chipotle",
            ],
            "Shopping": [
                "amazon",
                "walmart",
                "target",
                "store",
                "shop",
                "mall",
                "retail",
                "oxxo",
                "convenience",
            ],
            "Transportation": [
                "uber",
                "lyft",
                "gas",
                "fuel",
                "parking",
                "toll",
                "transit",
                "chevron",
                "shell",
                "exxon",
                "bp",
                "76",
                "py *transpor",
            ],
            "Entertainment": [
                "movie",
                "theater",
                "concert",
                "game",
                "netflix",
                "spotify",
                "crunchyroll",
                "youtube",
                "hulu",
                "disney",
            ],
            "Utilities": [
                "electric",
                "water",
                "gas",
                "internet",
                "phone",
                "utility",
                "comcast",
                "verizon",
                "att",
                "spectrum",
            ],
            "Payment": ["payment", "transfer", "deposit", "credit", "paypal", "venmo"],
            "Business": ["business", "office", "supply", "service", "consulting"],
            "Travel": [
                "hotel",
                "airline",
                "flight",
                "airbnb",
                "vacation",
                "booking",
                "motel",
                "lodge",
                "resort",
            ],
            "Healthcare": [
                "doctor",
                "hospital",
                "pharmacy",
                "medical",
                "health",
                "clinic",
            ],
            "Education": [
                "school",
                "university",
                "tuition",
                "education",
                "course",
                "coursera",
            ],
            "Groceries": [
                "grocery",
                "supermarket",
                "market",
                "carniceria",
                "fruteria",
                "kroger",
                "safeway",
                "whole foods",
            ],
            "Subscriptions": [
                "subscription",
                "claude",
                "anthropic",
                "openai",
                "chatgpt",
                "google",
            ],
        }

        for category, keywords in categories.items():
            if any(keyword in description_lower for keyword in keywords):
                return category

        return "Other"

    def process_csv_file(self, file_path: str) -> Dict:
        """Main processing method for enhanced CSV handling."""
        try:
            with open(file_path, "r", encoding="utf-8-sig") as f:
                content = f.read()

            # Detect sections
            sections = self.detect_sections(content)
            print(f"Detected {len(sections)} sections")

            all_transactions = []

            # Process each section
            for i, section in enumerate(sections):
                print(f"\nProcessing section {i+1}:")
                section_transactions = self.process_section(section)
                all_transactions.extend(section_transactions)
                print(
                    f"Extracted {len(section_transactions)} transactions from section {i+1}"
                )

            # Create metadata
            metadata = {
                "filename": file_path,
                "processing_time": datetime.now().isoformat(),
                "format": "csv",
                "total_transactions": len(all_transactions),
                "raw_text": f"Enhanced CSV file with {len(all_transactions)} transactions",
                "sections_processed": len(sections),
            }

            return {
                "transactions": all_transactions,
                "metadata": metadata,
                "status": "completed" if all_transactions else "no_transactions",
            }

        except Exception as e:
            print(f"Exception occurred: {e}")
            import traceback

            traceback.print_exc()
            return {
                "transactions": [],
                "metadata": {
                    "filename": file_path,
                    "error": str(e),
                    "total_transactions": 0,
                },
                "status": "error",
            }


def main():
    """Test the enhanced CSV processor."""
    import sys

    if len(sys.argv) != 2:
        print("Usage: python enhance_csv_processor.py <csv_file>")
        sys.exit(1)

    processor = EnhancedCSVProcessor()
    result = processor.process_csv_file(sys.argv[1])

    print(f"\nProcessing Results:")
    print(f"Status: {result['status']}")
    print(f"Total transactions: {result['metadata']['total_transactions']}")

    if result["transactions"]:
        print(f"\nFirst few transactions:")
        for i, transaction in enumerate(result["transactions"][:5]):
            print(
                f"{i+1}. {transaction['date']} - {transaction['description']} - ${transaction['amount']:.2f}"
            )
            if transaction.get("has_forex"):
                print(
                    f"   Forex: {transaction['original_amount']} {transaction['original_currency']} @ {transaction['exchange_rate']}"
                )


if __name__ == "__main__":
    main()
