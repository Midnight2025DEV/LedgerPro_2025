# LedgerPro Installation Guide

Welcome to LedgerPro - your comprehensive financial management solution! This guide will help you get started quickly.

## What's New in This Version ✨

We've addressed the top user concerns and made LedgerPro truly user-friendly:

### ✅ **No More Terminal Commands Required**
- Backend server starts automatically when you launch the app
- No manual setup or technical knowledge needed
- One-click installation with bundled dependencies

### ✅ **Manual Transaction Entry**
- Add transactions without uploading statements
- Complete form with date, amount, category, merchant, and notes
- Perfect for cash transactions or quick entries

### ✅ **Full Budgeting Features**
- Create budgets by category with spending limits
- Track progress with visual indicators
- Get alerts when approaching or exceeding limits
- Monthly, weekly, or custom budget periods

## Quick Start Guide

### Option 1: Download Pre-built App (Recommended)

1. **Download the latest release** from [GitHub Releases](https://github.com/Midnight2025DEV/LedgerPro_2025/releases)
2. **Double-click** the `.dmg` file to mount
3. **Drag** LedgerPro to your Applications folder
4. **Launch** LedgerPro from Applications
5. **Start budgeting!** - The backend starts automatically

### Option 2: Build from Source

#### Prerequisites
- macOS 14.0+ (required for SwiftUI features)
- Xcode 15.0+
- Python 3.9+ (for backend processing)

#### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Midnight2025DEV/LedgerPro_2025.git
   cd LedgerPro_2025/LedgerPro
   ```

2. **Quick setup (installs dependencies and checks backend):**
   ```bash
   make setup
   ```

3. **Build and run:**
   ```bash
   make build && make run
   ```

## Features Overview

### 📊 **Dashboard**
- Financial overview with balance and savings tracking
- Quick access to all features
- Visual financial health score

### 💳 **Transaction Management**
- **Upload** PDF or CSV bank statements
- **Manual entry** for cash transactions or quick additions
- **Auto-categorization** with smart merchant recognition
- **Bulk editing** for multiple transactions
- **Search and filter** by category, amount, or date

### 💰 **Budgeting System**
- **Create budgets** by category with spending limits
- **Track spending** against budget in real-time
- **Visual progress bars** show spending vs. budget
- **Alerts** when approaching or exceeding limits
- **Multiple periods**: monthly, weekly, or custom

### 🏦 **Account Management**
- Multiple bank account support
- Account balance tracking
- Transaction history by account

### 📈 **Insights & Analytics**
- Spending trends and patterns
- Category breakdown charts
- Month-over-month comparisons
- Financial health scoring

## Usage Tips

### Getting Started
1. **Add your first transaction** using the "+" button
2. **Create your first budget** in the Budgets tab
3. **Upload a bank statement** to import existing transactions
4. **Let auto-categorization** handle the heavy lifting

### Best Practices
- **Set realistic budgets** based on your spending history
- **Review categories** regularly and adjust as needed
- **Use manual entry** for cash transactions
- **Check insights** monthly to track your financial progress

### Import Bank Statements
- **Supported formats**: PDF statements and CSV exports
- **Auto-detection**: Works with most major banks
- **Duplicate prevention**: Automatically detects and prevents duplicate imports
- **Real-time processing**: Watch your transactions appear as they're processed

## Troubleshooting

### App Won't Start
- Ensure you're running macOS 14.0+
- Check that the app isn't quarantined by macOS security
- Try right-click → Open if you get security warnings

### Backend Issues
- The backend starts automatically - no action needed
- If you see connectivity issues, restart the app
- Backend runs on localhost:8000 (automatically managed)

### Performance
- Large statement processing may take 30-60 seconds
- The app will show progress during processing
- Background processing doesn't block the UI

## Security & Privacy

- **Local processing only** - your data never leaves your Mac
- **No cloud uploads** - everything stays on your device
- **Secure storage** - data encrypted in local files
- **Bank-grade security** for statement processing

## Support

### Need Help?
- **GitHub Issues**: [Report bugs or request features](https://github.com/Midnight2025DEV/LedgerPro_2025/issues)
- **Documentation**: Check the README.md for technical details
- **Logs**: Located in ~/Library/Logs/LedgerPro for troubleshooting

### Development Commands (for developers)
```bash
# Test the app
make test

# Format code
make format

# Lint code
make lint

# Clean build
make clean

# Start backend manually (if needed)
./start_backend.sh
```

## What Makes LedgerPro Different

### vs. Mint/YNAB/Personal Capital
✅ **No account linking required** - your privacy is protected  
✅ **No monthly fees** - completely free and open source  
✅ **Full offline functionality** - works without internet  
✅ **No data sharing** - your financial data stays on your Mac  

### vs. Excel/Spreadsheets  
✅ **Auto-categorization** - smart merchant recognition  
✅ **Beautiful visualizations** - charts and insights built-in  
✅ **Statement import** - no manual data entry needed  
✅ **Real-time budgeting** - instant spending vs. budget tracking  

---

**Ready to take control of your finances?** Download LedgerPro today and experience budgeting the way it should be - simple, private, and powerful! 🚀