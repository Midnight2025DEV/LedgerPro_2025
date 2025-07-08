# Test Data Directory

This directory is for test PDFs and sample data files.

## Required Test Files:

1. **Bank Statement PDFs**
   - Add any bank statement PDF here for testing
   - Supported banks: Chase, Bank of America, Wells Fargo, Citibank
   - Generic PDFs will also work with basic parsing

2. **Sample Files to Add:**
   - `chase_statement_sample.pdf` - Chase bank statement
   - `bofa_statement_sample.pdf` - Bank of America statement
   - `generic_bank_statement.pdf` - Any other bank

## Security Note:
- Use redacted or sample statements only
- Don't commit real financial data to git
- Add `*.pdf` to .gitignore in this directory

## Testing Instructions:
1. Place a PDF file in this directory
2. Run the app
3. Use Import → Select the test PDF
4. Verify transactions are extracted correctly
