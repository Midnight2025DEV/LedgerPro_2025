#!/usr/bin/env python3
"""
Camelot-based PDF Financial Statement Processor.

Superior table extraction for bank/credit card statements using advanced
PDF parsing techniques and machine learning for transaction analysis.
"""

import csv
import json
import logging
import os
import re
from datetime import datetime
from typing import Any, Dict, List, Optional

import camelot
import pandas as pd
import pdfminer.high_level

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class CamelotProcessor:
    """
    Advanced PDF processor using camelot for superior table extraction
    """

    def __init__(
        self,
        config: Optional[Dict[str, Any]] = None,
        verbose: bool = False,
        enable_deduplication: bool = False,
        dedup_tolerance: float = 0.01,
    ):
        """Initialize the CamelotProcessor with configuration options.

        Args:
            config: Configuration dictionary for processing options
            verbose: Enable verbose logging output
            enable_deduplication: Enable automatic duplicate transaction removal
            dedup_tolerance: Dollar amount tolerance for duplicate matching
        """
        if config is None:
            config = {}
        self.config = {
            "table_areas": config.get("table_areas", None),
            "columns": config.get("columns", None),
            "edge_tol": config.get("edge_tol", 500),
            "row_tol": config.get("row_tol", 10),
            "strip_text": config.get("strip_text", "\n"),
            "process_background": config.get("process_background", False),
            "suppress_stdout": config.get("suppress_stdout", True),
            "pages": config.get("pages", "all"),
            **(config or {}),
        }
        self.verbose = verbose
        self.enable_deduplication = enable_deduplication
        self.dedup_tolerance = dedup_tolerance

        # Financial statement patterns
        self.transaction_patterns = {
            "date_patterns": [
                r"(\d{1,2}/\d{1,2}/\d{4})",
                r"(\d{1,2}-\d{1,2}-\d{4})",
                r"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{1,2})",
                r"(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)",
            ],
            "amount_patterns": [
                r"\$([\d,]+\.\d{2})",
                r"([\d,]+\.\d{2})",
                r"-\$([\d,]+\.\d{2})",
                r"\(([\d,]+\.\d{2})\)",
            ],
        }

        # Bank-specific configurations
        self.bank_configs = {
            "capital_one": {
                "table_areas": ["0,800,612,50"],  # Transaction table area
                "columns": ["50,150,300,450,550"],  # Date, Description, Amount columns
                "date_format": "%m/%d/%Y",
                "amount_column": -1,  # Last column
                "description_column": 1,  # Second column
            },
            "navy_federal": {
                "table_areas": ["0,800,612,50"],
                "columns": ["50,150,250,350,450,550"],
                "date_format": "%m/%d/%Y",
                "amount_column": -2,
                "description_column": 1,
            },
            "chase": {
                "table_areas": ["0,800,612,50"],
                "columns": ["50,150,300,450,550"],
                "date_format": "%m/%d/%Y",
                "amount_column": -1,
                "description_column": 1,
            },
        }

    def detect_bank_type(self, pdf_path: str) -> str:
        """Auto-detect bank type from PDF content.

        Args:
            pdf_path: Path to the PDF file to analyze

        Returns:
            String identifier for the detected bank type
        """
        try:
            # Extract text to detect bank
            text = pdfminer.high_level.extract_text(pdf_path, maxpages=1)
            text_lower = text.lower()

            if "capital one" in text_lower:
                return "capital_one"
            elif "navy federal" in text_lower:
                return "navy_federal"
            elif "chase" in text_lower:
                return "chase"
            else:
                return "generic"

        except Exception as e:
            logger.warning(f"Could not detect bank type: {e}")
            return "generic"

    def extract_tables_with_camelot(
        self, pdf_path: str, bank_type: Optional[str] = None
    ) -> List[pd.DataFrame]:
        """
        Extract tables using camelot with bank-specific optimization
        """
        if not bank_type:
            bank_type = self.detect_bank_type(pdf_path)
        bank_config = self.bank_configs.get(bank_type, {})
        try:
            # Default to stream for Capital One, lattice for others
            flavor = "stream" if bank_type == "capital_one" else "lattice"
            table_kwargs = {
                "pages": self.config["pages"],
                "flavor": flavor,
                "strip_text": self.config["strip_text"],
                "suppress_stdout": self.config["suppress_stdout"],
            }
            # Only pass columns/edge_tol/row_tol for stream flavor
            if flavor == "stream":
                if bank_config.get("table_areas"):
                    table_kwargs["table_areas"] = bank_config["table_areas"]
                if bank_config.get("columns"):
                    table_kwargs["columns"] = bank_config["columns"]
                if self.config.get("edge_tol") is not None:
                    table_kwargs["edge_tol"] = self.config["edge_tol"]
                if self.config.get("row_tol") is not None:
                    table_kwargs["row_tol"] = self.config["row_tol"]
            logger.info(
                f"Extracting tables with camelot for {bank_type} (flavor={flavor})..."
            )
            tables = camelot.read_pdf(pdf_path, **table_kwargs)
            logger.info(f"Found {len(tables)} tables")
            dataframes = []
            for i, table in enumerate(tables):
                if self.verbose:
                    print(
                        f"  📋 Processing table {i+1}/{len(tables)} (accuracy: {table.parsing_report['accuracy']:.1f}%)"
                    )

                if table.parsing_report["accuracy"] > 50:
                    df = table.df
                    df = self.clean_table_dataframe(df, bank_type)
                    if not df.empty:
                        dataframes.append(df)
                        logger.info(
                            f"Table {i+1}: {len(df)} rows, accuracy: {table.parsing_report['accuracy']:.1f}%"
                        )
                        # Save raw table for inspection
                        csv_filename = f"raw_table_{i+1}_{bank_type}.csv"
                        df.to_csv(csv_filename, index=False)
                        logger.info(f"Saved raw table {i+1} to: {csv_filename}")
                elif self.verbose:
                    print(
                        f"  ⚠️  Skipping table {i+1} (low accuracy: {table.parsing_report['accuracy']:.1f}%)"
                    )
            return dataframes
        except Exception as e:
            logger.error(f"Error extracting tables with camelot: {e}")
            return []

    def clean_table_dataframe(self, df: pd.DataFrame, bank_type: str) -> pd.DataFrame:
        """
        Clean and structure the extracted table data
        """
        if df.empty:
            return df

        logger.info(f"Cleaning table with {len(df)} rows for {bank_type}")

        # Remove empty rows and columns
        df = df.dropna(how="all").dropna(axis=1, how="all")

        # Clean cell values
        df = df.applymap(
            lambda x: self.clean_cell_value(x) if isinstance(x, str) else x
        )

        # Try to identify transaction table
        logger.info("Attempting to identify transaction table...")
        df = self.identify_transaction_table(df, bank_type)

        return df

    def clean_cell_value(self, value: Any) -> Any:
        """
        Clean individual cell values
        """
        if not isinstance(value, str):
            return value

        # Remove extra whitespace and newlines
        cleaned = re.sub(r"\s+", " ", value.strip())

        # Remove common PDF artifacts
        cleaned = re.sub(r"[^\w\s\-\.\,\$\(\)\/]", "", cleaned)

        return cleaned

    def identify_transaction_table(
        self, df: pd.DataFrame, bank_type: str
    ) -> pd.DataFrame:
        """
        Identify and structure transaction table
        """
        logger.info(
            f"identify_transaction_table called with {len(df)} rows for {bank_type}"
        )

        if df.empty:
            logger.info("DataFrame is empty, returning")
            return df

        # Special handling for Capital One format - check this first
        if bank_type == "capital_one":
            logger.info("Checking for Capital One specific headers...")
            # Look for Capital One specific headers
            for idx, row in df.iterrows():
                row_text = " ".join(row.astype(str))
                logger.info(
                    f"Checking row {idx} for Capital One headers: {row_text[:100]}..."
                )
                # Check for individual headers that might be in the same row
                if (
                    "Trans Date" in row_text or "Post Date" in row_text
                ) and "Description" in row_text:
                    logger.info(f"Found Capital One transaction table at row {idx}")
                    return self.structure_capital_one_table(df, idx)

        # Look for transaction-related headers (generic fallback)
        transaction_keywords = [
            "date",
            "description",
            "amount",
            "debit",
            "credit",
            "transaction",
        ]

        # Check if any row contains transaction keywords
        for idx, row in df.iterrows():
            row_text = " ".join(row.astype(str)).lower()
            logger.info(
                f"Checking row {idx} for transaction keywords: {row_text[:50]}..."
            )
            if any(keyword in row_text for keyword in transaction_keywords):
                # This might be a header row, try to structure the table
                logger.info(f"Found transaction keywords in row {idx}")
                return self.structure_transaction_table(df, idx, bank_type)

        logger.info("No transaction table identified")
        return df

    def structure_transaction_table(
        self, df: pd.DataFrame, header_row: int, bank_type: str
    ) -> pd.DataFrame:
        """
        Structure the table with proper column headers
        """
        if header_row >= len(df):
            return df

        # Use the header row as column names
        headers = df.iloc[header_row].tolist()

        # Clean and standardize headers
        clean_headers = []
        for header in headers:
            if isinstance(header, str):
                clean_header = header.lower().strip()
                # Map to standard column names
                if "date" in clean_header:
                    clean_headers.append("date")
                elif "desc" in clean_header or "merchant" in clean_header:
                    clean_headers.append("description")
                elif "amount" in clean_header:
                    clean_headers.append("amount")
                elif "debit" in clean_header:
                    clean_headers.append("debit")
                elif "credit" in clean_header:
                    clean_headers.append("credit")
                else:
                    clean_headers.append(f"col_{len(clean_headers)}")
            else:
                clean_headers.append(f"col_{len(clean_headers)}")

        # Create new DataFrame with clean headers
        new_df = df.iloc[header_row + 1 :].copy()
        new_df.columns = clean_headers

        return new_df

    def structure_capital_one_table(
        self, df: pd.DataFrame, header_row: int
    ) -> pd.DataFrame:
        """
        Structure Capital One transaction table with their specific format
        """
        if header_row >= len(df):
            return df

        # Use the header row as column names
        headers = df.iloc[header_row].tolist()

        # Clean and standardize Capital One headers
        clean_headers = []
        for i, header in enumerate(headers):
            if isinstance(header, str):
                clean_header = header.lower().strip()
                # Map Capital One specific headers
                if "trans date" in clean_header:
                    clean_headers.append("trans_date")
                elif "post date" in clean_header:
                    clean_headers.append("post_date")
                elif "description" in clean_header:
                    clean_headers.append("description")
                elif i == 4:  # Amount column in Capital One format
                    clean_headers.append("amount")
                else:
                    clean_headers.append(f"col_{len(clean_headers)}")
            else:
                clean_headers.append(f"col_{len(clean_headers)}")

        # Create new DataFrame with clean headers
        new_df = df.iloc[header_row + 1 :].copy()
        new_df.columns = clean_headers

        return new_df

    def extract_transactions_from_tables(
        self, tables: List[pd.DataFrame], bank_type: str
    ) -> List[Dict[str, Any]]:
        """
        Extract transactions from identified tables
        """
        transactions = []

        for i, table in enumerate(tables):
            if self.verbose:
                print(
                    f"  💳 Extracting transactions from table {i+1}/{len(tables)} ({len(table)} rows)"
                )
            logger.info(f"Processing table {i+1} with {len(table)} rows")

            if table.empty:
                continue

            # Check if this table has the expected structure
            logger.info(f"Table {i+1} columns: {list(table.columns)}")

            table_transactions = 0
            # Try to extract transactions from each row
            for idx, row in table.iterrows():
                transaction = self.parse_transaction_row(row, bank_type)
                if transaction:
                    transactions.append(transaction)
                    table_transactions += 1
                    logger.info(
                        f"Extracted transaction: {transaction['description'][:50]}... ${transaction['amount']}"
                    )

            if self.verbose and table_transactions > 0:
                print(f"    ✅ Found {table_transactions} transactions in table {i+1}")

        logger.info(f"Total transactions extracted: {len(transactions)}")
        if len(transactions) > 0:
            print(f"✅ Extracted {len(transactions)} transactions total")
        return transactions

    def parse_transaction_row(
        self, row: pd.Series, bank_type: str
    ) -> Optional[Dict[str, Any]]:
        """
        Parse a single transaction row
        """
        try:
            # Special handling for Capital One format
            if bank_type == "capital_one":
                return self.parse_capital_one_transaction_row(row)

            # Extract date
            date = self.extract_date_from_row(row, bank_type)
            if not date:
                return None

            # Extract description
            description = self.extract_description_from_row(row, bank_type)
            if not description:
                return None

            # Extract amount
            amount = self.extract_amount_from_row(row, bank_type)
            if amount is None:
                return None

            # Determine transaction type
            transaction_type = "debit" if amount < 0 else "credit"

            # Categorize transaction
            category = self.categorize_transaction(description)

            return {
                "date": date,
                "description": description,
                "amount": amount,
                "type": transaction_type,
                "category": category,
                "bank_type": bank_type,
                "extraction_method": "camelot_table",
            }

        except Exception as e:
            logger.warning(f"Error parsing transaction row: {e}")
            return None

    def parse_capital_one_transaction_row(
        self, row: pd.Series
    ) -> Optional[Dict[str, Any]]:
        """
        Parse Capital One transaction row using proven working logic
        """
        try:
            # Handle both named columns and position-based access
            if hasattr(row, "trans_date") and "trans_date" in row.index:
                # Use named columns (new table structure)
                trans_date = str(row.get("trans_date", "")).strip()
                post_date = str(row.get("post_date", "")).strip()
                description = str(row.get("description", "")).strip()
                # Amount is in col_5 (last column) in the new structure
                amount_str = str(row.get("col_5", "")).strip()
            else:
                # Fall back to position-based access
                row_data = [
                    str(row.iloc[i]).strip() if pd.notna(row.iloc[i]) else ""
                    for i in range(len(row))
                ]
                if len(row_data) < 6:
                    return None
                trans_date = row_data[0]
                post_date = row_data[1]
                description = row_data[2]
                amount_str = row_data[5]  # col_5 is index 5

            # Validate this looks like a transaction row
            if (
                not trans_date
                or trans_date == "nan"
                or not re.match(
                    r"^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2}$",
                    trans_date,
                )
                or not description
                or description == "nan"
                or not amount_str
                or amount_str == "nan"
                or "$" not in amount_str
            ):  # Must have dollar sign
                return None

            # Parse date (Capital One "Apr 16" format)
            try:
                if len(trans_date) <= 6:  # "Apr 16" format
                    full_date = f"{trans_date} 2025"
                    parsed_date = datetime.strptime(full_date, "%b %d %Y")
                    date_str = parsed_date.strftime("%Y-%m-%d")
                else:
                    return None
            except:
                return None

            # Parse amount
            try:
                # Check for payment patterns
                is_payment = (
                    "PAYMENT" in description.upper() or "PYM" in description.upper()
                )

                # Clean amount
                amount_clean = re.sub(
                    r"[^\d\.\-]", "", amount_str.replace("$", "").replace(",", "")
                )
                if not amount_clean:
                    return None

                amount = float(amount_clean)

                # Apply correct sign
                if is_payment:
                    amount = abs(amount)  # Payments are positive (money coming in)
                else:
                    amount = -abs(amount)  # Purchases are negative (money going out)

            except:
                return None

            # Clean description
            description_clean = (
                description.replace("TST*", "").replace("*", " ").strip()
            )
            description_clean = re.sub(r"\s+", " ", description_clean)

            # Determine type and category
            if is_payment:
                transaction_type = "payment"
                category = "Payment"
            else:
                transaction_type = "purchase"
                category = self.categorize_transaction(description_clean)

            return {
                "date": date_str,
                "description": description_clean,
                "amount": amount,
                "type": transaction_type,
                "category": category,
                "bank_type": "capital_one",
                "extraction_method": "camelot_table_fixed",
            }

        except Exception as e:
            logger.warning(f"Error parsing Capital One transaction row: {e}")
            return None

    def parse_capital_one_date(self, date_str: str) -> Optional[str]:
        """
        Parse Capital One date format (e.g., "Apr 16", "Apr 18")
        """
        try:
            # Capital One uses format like "Apr 16", "Apr 18"
            month_map = {
                "Jan": "01",
                "Feb": "02",
                "Mar": "03",
                "Apr": "04",
                "May": "05",
                "Jun": "06",
                "Jul": "07",
                "Aug": "08",
                "Sep": "09",
                "Oct": "10",
                "Nov": "11",
                "Dec": "12",
            }

            # Extract month and day
            parts = date_str.strip().split()
            if len(parts) >= 2:
                month_name = parts[0]
                day = parts[1]

                if month_name in month_map and day.isdigit():
                    month_num = month_map[month_name]
                    day_num = day.zfill(2)
                    # Assume 2025 for the year
                    return f"2025-{month_num}-{day_num}"

            return None

        except Exception as e:
            logger.warning(f"Error parsing Capital One date '{date_str}': {e}")
            return None

    def extract_date_from_row(self, row: pd.Series, bank_type: str) -> Optional[str]:
        """
        Extract and parse date from row
        """
        for value in row:
            if isinstance(value, str):
                # Try different date patterns
                for pattern in self.transaction_patterns["date_patterns"]:
                    match = re.search(pattern, value)
                    if match:
                        try:
                            date_str = match.group(0)
                            # Parse and standardize date
                            parsed_date = self.parse_date_string(date_str, bank_type)
                            if parsed_date:
                                return parsed_date
                        except Exception:
                            continue
        return None

    def extract_description_from_row(
        self, row: pd.Series, bank_type: str
    ) -> Optional[str]:
        """
        Extract description from row
        """
        # Look for the longest text field that's not a date or amount
        descriptions = []

        for value in row:
            if isinstance(value, str) and value.strip():
                # Skip if it looks like a date or amount
                if not self.is_date_or_amount(value):
                    descriptions.append(value.strip())

        if descriptions:
            # Return the longest description
            return max(descriptions, key=len)

        return None

    def extract_amount_from_row(
        self, row: pd.Series, bank_type: str
    ) -> Optional[float]:
        """
        Extract and parse amount from row
        """
        for value in row:
            if isinstance(value, str):
                for pattern in self.transaction_patterns["amount_patterns"]:
                    match = re.search(pattern, value)
                    if match:
                        try:
                            amount_str = match.group(1)
                            # Clean amount string
                            amount_str = re.sub(r"[^\d\.\-]", "", amount_str)
                            amount = float(amount_str)

                            # Determine sign based on context
                            if "(" in value or "-" in value:
                                amount = -abs(amount)

                            return amount
                        except Exception:
                            continue
        return None

    def is_date_or_amount(self, value: str) -> bool:
        """
        Check if value looks like a date or amount
        """
        # Date patterns
        date_patterns = [
            r"\d{1,2}/\d{1,2}/\d{4}",
            r"\d{1,2}-\d{1,2}-\d{4}",
            r"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2}",
        ]

        # Amount patterns
        amount_patterns = [r"\$[\d,]+\.\d{2}", r"[\d,]+\.\d{2}", r"\([\d,]+\.\d{2}\)"]

        for pattern in date_patterns + amount_patterns:
            if re.search(pattern, value):
                return True

        return False

    def parse_date_string(self, date_str: str, bank_type: str) -> Optional[str]:
        """
        Parse date string to YYYY-MM-DD format
        """
        try:
            # Try different date formats
            date_formats = ["%m/%d/%Y", "%m-%d-%Y", "%d/%m/%Y", "%Y-%m-%d"]

            for fmt in date_formats:
                try:
                    parsed_date = datetime.strptime(date_str, fmt)
                    return parsed_date.strftime("%Y-%m-%d")
                except Exception:
                    continue

            # Try month name format
            month_map = {
                "jan": "01",
                "feb": "02",
                "mar": "03",
                "apr": "04",
                "may": "05",
                "jun": "06",
                "jul": "07",
                "aug": "08",
                "sep": "09",
                "oct": "10",
                "nov": "11",
                "dec": "12",
            }

            for month_name, month_num in month_map.items():
                if month_name in date_str.lower():
                    # Extract day and year
                    day_match = re.search(r"(\d{1,2})", date_str)
                    year_match = re.search(r"(\d{4})", date_str)

                    if day_match and year_match:
                        day = day_match.group(1).zfill(2)
                        year = year_match.group(1)
                        return f"{year}-{month_num}-{day}"

            return None

        except Exception as e:
            logger.warning(f"Error parsing date '{date_str}': {e}")
            return None

    def categorize_transaction(self, description: str) -> str:
        """
        Enhanced categorization based on personal spending patterns
        """
        desc_lower = description.lower()

        # Tax payments (highest priority - specific to you)
        if any(word in desc_lower for word in ["tax", "franchise tax board"]):
            return "Taxes"

        # Real Estate / Business
        if any(word in desc_lower for word in ["centro inmobiliario", "wood city"]):
            return "Business"

        # Dining & Food (your frequent categories)
        if any(
            word in desc_lower
            for word in [
                "restaurant",
                "taco bell",
                "uber eats",
                "coco ichibanya",
                "carniceria",
                "fruteria",
                "churrascaria",
                "panera",
                "tejate",
            ]
        ):
            return "Dining"

        # Transportation (including your Uber usage)
        if any(
            word in desc_lower
            for word in ["uber trip", "exxon", "chevron", "jiffy lube", "76", "mirus"]
        ):
            return "Transportation"

        # Groceries & Convenience (your frequent stores)
        if any(
            word in desc_lower for word in ["7-eleven", "oxxo", "wal-mart", "walmart"]
        ):
            return "Groceries"

        # Subscriptions & Digital Services
        if any(
            word in desc_lower
            for word in [
                "crunchyroll",
                "netflix",
                "google",
                "youtube",
                "coursera",
                "freetaxusa",
            ]
        ):
            return "Subscriptions"

        # Healthcare
        if any(word in desc_lower for word in ["chopo"]):
            return "Healthcare"

        # Shopping & Retail
        if any(
            word in desc_lower
            for word in ["ocean rainbow", "followyourlegend", "farm roma"]
        ):
            return "Shopping"

        # Lodging
        if any(word in desc_lower for word in ["motel"]):
            return "Lodging"

        # Utilities & Services
        if any(
            word in desc_lower for word in ["gas tijuan", "otay mesa", "compania gas"]
        ):
            return "Utilities"

        # Payments (Capital One specific)
        if any(word in desc_lower for word in ["payment", "pym", "capital one mobile"]):
            return "Payment"

        return "Other"

    def fallback_to_pdfminer(self, pdf_path: str) -> List[Dict[str, Any]]:
        """
        Fallback to pdfminer for text extraction when camelot fails
        """
        logger.info("Falling back to pdfminer text extraction...")
        print("📝 Extracting text from PDF...")

        try:
            text = pdfminer.high_level.extract_text(pdf_path)
            print("🔍 Searching for transaction patterns...")
            transactions = self.extract_transactions_from_text(text)
            if len(transactions) > 0:
                print(f"✅ Found {len(transactions)} transactions via text extraction")
            return transactions
        except Exception as e:
            logger.error(f"Error with pdfminer fallback: {e}")
            return []

    def extract_transactions_from_text(self, text: str) -> List[Dict[str, Any]]:
        """
        Extract transactions from raw text using regex patterns
        """
        transactions = []

        # Split text into lines
        lines = text.split("\n")

        for line in lines:
            transaction = self.parse_transaction_line(line)
            if transaction:
                transaction["extraction_method"] = "pdfminer_text"
                transactions.append(transaction)

        return transactions

    def parse_transaction_line(self, line: str) -> Optional[Dict[str, Any]]:
        """
        Parse a single line for transaction data
        """
        # Enhanced patterns for different statement formats
        patterns = [
            # Capital One format: Apr 26 Apr 28 MERCHANT $AMOUNT
            (
                r"(Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|Jan|Feb|Mar)\s+"
                r"(\d{1,2})\s+([^$]+?)\s+\$([\d,]+\.\d{2})"
            ),
            # Standard format: MM/DD/YYYY DESCRIPTION $AMOUNT
            r"(\d{1,2}/\d{1,2}/\d{4})\s+([^$]+?)\s+\$([\d,]+\.\d{2})",
            # Alternative format: DESCRIPTION $AMOUNT MM/DD
            r"([^$]+?)\s+\$([\d,]+\.\d{2})\s+(\d{1,2}/\d{1,2})",
        ]

        for pattern in patterns:
            match = re.search(pattern, line)
            if match:
                try:
                    if len(match.groups()) == 4:  # Capital One format
                        month, day, description, amount = match.groups()
                        date = self.parse_date_string(
                            f"{month} {day} 2024", "capital_one"
                        )
                    elif len(match.groups()) == 3:
                        if "/" in match.group(1):  # Standard format
                            date_str, description, amount = match.groups()
                            date = self.parse_date_string(date_str, "generic")
                        else:  # Alternative format
                            description, amount, date_str = match.groups()
                            date = self.parse_date_string(f"{date_str}/2024", "generic")

                    if date:
                        amount_val = float(re.sub(r"[^\d\.\-]", "", amount))
                        # Determine sign based on context
                        if "(" in line or "credit" in line.lower():
                            amount_val = abs(amount_val)
                        else:
                            amount_val = -abs(amount_val)  # Assume debit by default

                        return {
                            "date": date,
                            "description": description.strip(),
                            "amount": amount_val,
                            "type": "debit" if amount_val < 0 else "credit",
                            "category": self.categorize_transaction(description),
                            "extraction_method": "pdfminer_text",
                        }
                except Exception:
                    continue

        return None

    def process_pdf(
        self, pdf_path: str, bank_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Main processing method - try camelot first, fallback to pdfminer
        """
        logger.info(f"Processing PDF: {pdf_path}")

        # Progress: Detect bank type
        if not bank_type or bank_type == "auto":
            print("🔍 Detecting bank type...")
            bank_type = self.detect_bank_type(pdf_path)
            print(f"✅ Detected bank: {bank_type}")
        else:
            print(f"🏦 Using specified bank: {bank_type}")

        logger.info(f"Detected bank type: {bank_type}")

        # Progress: Extract tables
        print("📊 Extracting tables from PDF...")
        tables = self.extract_tables_with_camelot(pdf_path, bank_type)

        if tables:
            print(f"✅ Found {len(tables)} tables")
            logger.info("Successfully extracted tables with camelot")

            # Progress: Process transactions
            print("💰 Parsing transactions...")
            transactions = self.extract_transactions_from_tables(tables, bank_type)
            extraction_method = "camelot_tables"
        else:
            print("⚠️  No tables found, trying text extraction...")
            logger.info("No tables found, falling back to text extraction")
            transactions = self.fallback_to_pdfminer(pdf_path)
            extraction_method = "pdfminer_text"

        # Progress: Deduplicate transactions
        if hasattr(self, "enable_deduplication") and self.enable_deduplication:
            print("🔄 Removing duplicate transactions...")
            original_count = len(transactions)
            transactions = self.deduplicate_transactions(
                transactions,
                enable_dedup=self.enable_deduplication,
                match_tolerance=getattr(self, "dedup_tolerance", 0.01),
            )
            if len(transactions) < original_count:
                duplicate_count = original_count - len(transactions)
                logger.info(f"Removed {duplicate_count} duplicate transactions")

        # Progress: Generate summary
        print("📈 Generating summary...")
        summary = self.generate_summary(transactions)
        # Add error handling for empty results
        if not transactions or not summary or "net_amount" not in summary:
            logger.warning("No transactions extracted or summary incomplete.")
            summary = {
                "total_transactions": 0,
                "net_amount": 0,
                "total_debits": 0,
                "total_credits": 0,
                "category_breakdown": {},
                "date_range": None,
            }
        return {
            "transactions": transactions,
            "summary": summary,
            "metadata": {
                "bank_type": bank_type,
                "extraction_method": extraction_method,
                "total_tables_found": len(tables),
                "processing_timestamp": datetime.now().isoformat(),
                "pdf_path": pdf_path,
                "deduplication_enabled": getattr(self, "enable_deduplication", False),
            },
        }

    def deduplicate_transactions(
        self,
        transactions: List[Dict[str, Any]],
        enable_dedup: bool = True,
        match_tolerance: float = 0.01,
    ) -> List[Dict[str, Any]]:
        """
        Remove duplicate transactions using configurable matching criteria

        Args:
            transactions: List of transaction dictionaries
            enable_dedup: Whether to perform deduplication
            match_tolerance: Dollar amount tolerance for matching (default: $0.01)

        Returns:
            List of deduplicated transactions
        """
        if not enable_dedup or not transactions:
            return transactions

        print("🔍 Checking for duplicate transactions...")

        unique_transactions: List[Dict[str, Any]] = []
        duplicate_count = 0

        for transaction in transactions:
            is_duplicate = False

            # Check against existing unique transactions
            for existing in unique_transactions:
                if self._transactions_match(transaction, existing, match_tolerance):
                    duplicate_count += 1
                    is_duplicate = True
                    if self.verbose:
                        print(
                            f"  🗑️  Duplicate found: {transaction['description'][:40]}... ${transaction['amount']}"
                        )
                    break

            if not is_duplicate:
                unique_transactions.append(transaction)

        if duplicate_count > 0:
            print(f"✅ Removed {duplicate_count} duplicate transactions")
            print(f"📊 {len(unique_transactions)} unique transactions remaining")
        else:
            print("✅ No duplicates found")

        return unique_transactions

    def _transactions_match(
        self, t1: Dict[str, Any], t2: Dict[str, Any], tolerance: float = 0.01
    ) -> bool:
        """
        Check if two transactions are duplicates based on matching criteria

        Matching criteria:
        1. Same date
        2. Same amount (within tolerance)
        3. Similar description (fuzzy match)
        """
        # Date must match exactly
        if t1.get("date") != t2.get("date"):
            return False

        # Amount must match within tolerance
        amount_diff = abs(t1.get("amount", 0) - t2.get("amount", 0))
        if amount_diff > tolerance:
            return False

        # Description similarity check
        desc1 = t1.get("description", "").lower().strip()
        desc2 = t2.get("description", "").lower().strip()

        # Exact match
        if desc1 == desc2:
            return True

        # Fuzzy match - check if one description contains the other (for formatting differences)
        if len(desc1) > 0 and len(desc2) > 0:
            shorter = desc1 if len(desc1) < len(desc2) else desc2
            longer = desc2 if len(desc1) < len(desc2) else desc1

            # If shorter description is contained in longer one, consider it a match
            if len(shorter) >= 10 and shorter in longer:
                return True

            # Check for similar merchant names (remove common words)
            desc1_clean = self._clean_description_for_matching(desc1)
            desc2_clean = self._clean_description_for_matching(desc2)

            if desc1_clean and desc2_clean and len(desc1_clean) >= 5:
                # Check if cleaned descriptions match or have significant overlap
                if desc1_clean == desc2_clean:
                    return True

                # Check for partial matches (e.g., "walmart supercenter" vs "walmart")
                desc1_words = set(desc1_clean.split())
                desc2_words = set(desc2_clean.split())
                common_words = desc1_words.intersection(desc2_words)

                # If they share significant words, consider it a match
                if (
                    len(common_words) >= 2
                    and len(common_words)
                    >= min(len(desc1_words), len(desc2_words)) * 0.6
                ):
                    return True

        return False

    def _clean_description_for_matching(self, description: str) -> str:
        """
        Clean description for better duplicate matching
        Remove common words, dates, and formatting
        """
        # Remove common transaction words
        common_words = [
            "purchase",
            "payment",
            "debit",
            "credit",
            "card",
            "transaction",
            "pos",
            "online",
            "recurring",
            "automatic",
            "auth",
            "pending",
        ]

        # Remove dates and numbers at the end
        import re

        cleaned = re.sub(r"\d{1,2}/\d{1,2}(/\d{2,4})?$", "", description)
        cleaned = re.sub(r"\d{4,}$", "", cleaned)  # Remove trailing transaction IDs

        # Split into words and filter
        words = cleaned.split()
        filtered_words = []

        for word in words:
            word_clean = re.sub(r"[^\w]", "", word.lower())
            if (
                len(word_clean) >= 3
                and word_clean not in common_words
                and not word_clean.isdigit()
            ):
                filtered_words.append(word_clean)

        # Return the merchant/main identifier
        return " ".join(filtered_words[:3])  # Take first 3 significant words

    def generate_summary(self, transactions: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Generate processing summary
        """
        if not transactions:
            return {"total_transactions": 0}

        total_amount = sum(t["amount"] for t in transactions)
        debits = [t for t in transactions if t["amount"] < 0]
        credits = [t for t in transactions if t["amount"] > 0]

        # Category breakdown
        category_stats = {}
        for transaction in transactions:
            category = transaction["category"]
            if category not in category_stats:
                category_stats[category] = {"count": 0, "total": 0}
            category_stats[category]["count"] += 1
            category_stats[category]["total"] += transaction["amount"]

        return {
            "total_transactions": len(transactions),
            "net_amount": total_amount,
            "total_debits": sum(abs(t["amount"]) for t in debits),
            "total_credits": sum(t["amount"] for t in credits),
            "category_breakdown": category_stats,
            "date_range": (
                {
                    "earliest": min(t["date"] for t in transactions),
                    "latest": max(t["date"] for t in transactions),
                }
                if transactions
                else None
            ),
        }

    def export_transactions_to_csv(
        self,
        transactions: List[Dict[str, Any]],
        csv_path: str,
        include_metadata: bool = True,
    ) -> bool:
        """
        Export transactions to CSV format for spreadsheet use

        Args:
            transactions: List of transaction dictionaries
            csv_path: Path for the output CSV file
            include_metadata: Whether to include technical fields

        Returns:
            bool: True if export successful, False otherwise
        """
        if not transactions:
            print("⚠️  No transactions to export")
            return False

        print(f"📊 Exporting {len(transactions)} transactions to CSV...")

        try:
            # Define CSV column structure for maximum spreadsheet compatibility
            if include_metadata:
                fieldnames = [
                    "Date",
                    "Description",
                    "Amount",
                    "Type",
                    "Category",
                    "Bank",
                    "Extraction Method",
                ]

                def format_row(transaction: Dict[str, Any]) -> Dict[str, Any]:
                    return {
                        "Date": transaction.get("date", ""),
                        "Description": transaction.get("description", ""),
                        "Amount": transaction.get("amount", 0),
                        "Type": transaction.get("type", "").title(),
                        "Category": transaction.get("category", ""),
                        "Bank": (
                            transaction.get("bank_type", "").replace("_", " ").title()
                        ),
                        "Extraction Method": (
                            transaction.get("extraction_method", "")
                            .replace("_", " ")
                            .title()
                        ),
                    }

            else:
                # Simplified format for basic spreadsheet use
                fieldnames = ["Date", "Description", "Amount", "Type", "Category"]

                def format_row(transaction: Dict[str, Any]) -> Dict[str, Any]:
                    return {
                        "Date": transaction.get("date", ""),
                        "Description": transaction.get("description", ""),
                        "Amount": transaction.get("amount", 0),
                        "Type": transaction.get("type", "").title(),
                        "Category": transaction.get("category", ""),
                    }

            # Write CSV file
            with open(csv_path, "w", newline="", encoding="utf-8") as csvfile:
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()

                # Sort transactions by date for better spreadsheet viewing
                sorted_transactions = sorted(
                    transactions, key=lambda x: x.get("date", "")
                )

                for transaction in sorted_transactions:
                    try:
                        row = format_row(transaction)
                        writer.writerow(row)
                    except Exception as e:
                        logger.warning(f"Error writing transaction to CSV: {e}")
                        continue

            print(f"✅ CSV export completed: {csv_path}")
            logger.info(
                f"Successfully exported {len(transactions)} transactions to {csv_path}"
            )
            return True

        except Exception as e:
            print(f"❌ CSV export failed: {str(e)}")
            logger.error(f"Error exporting to CSV: {e}")
            return False

    def generate_summary_csv(self, summary: Dict[str, Any], csv_path: str) -> bool:
        """
        Export summary statistics to CSV format

        Args:
            summary: Summary dictionary from generate_summary()
            csv_path: Path for the output summary CSV file

        Returns:
            bool: True if export successful, False otherwise
        """
        try:
            # Create summary rows
            summary_rows = [
                ["Metric", "Value"],
                ["Total Transactions", summary.get("total_transactions", 0)],
                ["Net Amount", f"${summary.get('net_amount', 0):.2f}"],
                ["Total Debits", f"${summary.get('total_debits', 0):.2f}"],
                ["Total Credits", f"${summary.get('total_credits', 0):.2f}"],
            ]

            # Add date range if available
            date_range = summary.get("date_range")
            if date_range:
                summary_rows.extend(
                    [
                        ["Earliest Transaction", date_range.get("earliest", "")],
                        ["Latest Transaction", date_range.get("latest", "")],
                    ]
                )

            # Add empty row before category breakdown
            summary_rows.append(["", ""])
            summary_rows.append(["Category", "Count", "Total Amount"])

            # Add category breakdown
            category_breakdown = summary.get("category_breakdown", {})
            for category, stats in category_breakdown.items():
                summary_rows.append(
                    [category, stats.get("count", 0), f"${stats.get('total', 0):.2f}"]
                )

            # Write summary CSV
            with open(csv_path, "w", newline="", encoding="utf-8") as csvfile:
                writer = csv.writer(csvfile)
                for row in summary_rows:
                    writer.writerow(row)

            print(f"✅ Summary CSV exported: {csv_path}")
            return True

        except Exception as e:
            print(f"❌ Summary CSV export failed: {str(e)}")
            logger.error(f"Error exporting summary to CSV: {e}")
            return False

    def save_results(self, results: Dict[str, Any], output_path: str) -> None:
        """
        Save results to JSON file
        """
        try:
            with open(output_path, "w") as f:
                json.dump(results, f, indent=2)
            logger.info(f"Results saved to: {output_path}")
        except Exception as e:
            logger.error(f"Error saving results: {e}")


def main() -> None:
    """
    Example usage and testing
    """
    import sys

    if len(sys.argv) < 2:
        print("Usage: python camelot_processor.py <pdf_file> [output_file]")
        sys.exit(1)

    pdf_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else "camelot_results.json"

    if not os.path.exists(pdf_path):
        print(f"Error: PDF file '{pdf_path}' not found")
        sys.exit(1)

    # Initialize processor
    processor = CamelotProcessor()

    # Process PDF
    print(f"Processing {pdf_path}...")
    results = processor.process_pdf(pdf_path)

    # Display results
    print(f"\n📊 Processing Results:")
    print(f"  Total transactions: {results['summary']['total_transactions']}")
    print(f"  Net amount: ${results['summary']['net_amount']:.2f}")
    print(f"  Extraction method: {results['metadata']['extraction_method']}")
    print(f"  Bank type: {results['metadata']['bank_type']}")

    if results["transactions"]:
        print(f"\n💰 Top transactions:")
        sorted_transactions = sorted(
            results["transactions"], key=lambda x: abs(x["amount"]), reverse=True
        )
        for i, t in enumerate(sorted_transactions[:5]):
            print(
                f"  {i+1}. {t['date']} - {t['description'][:50]}... - ${t['amount']:.2f}"
            )

    # Save results
    processor.save_results(results, output_path)
    print(f"\n✅ Results saved to: {output_path}")


# Alias for backwards compatibility
CamelotFinancialProcessor = CamelotProcessor

if __name__ == "__main__":
    main()
