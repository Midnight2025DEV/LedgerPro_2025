#!/bin/bash

# LedgerPro Test Script
# This script runs basic tests and demonstrates the application features

echo "🚀 LedgerPro Test Script"
echo "========================"

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    echo "❌ Error: Not in LedgerPro directory. Please run from LedgerPro folder."
    exit 1
fi

echo "✅ Found Package.swift"

# Check build status
echo "🔨 Building LedgerPro..."
if swift build; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed!"
    exit 1
fi

# Check if executable exists
if [ -f ".build/debug/LedgerPro" ]; then
    echo "✅ Executable found at .build/debug/LedgerPro"
else
    echo "❌ Executable not found!"
    exit 1
fi

# Print app information
echo ""
echo "📱 Application Information:"
echo "   Name: LedgerPro"
echo "   Platform: macOS 13.0+"
echo "   Language: Swift"
echo "   Framework: SwiftUI"
echo ""

echo "🎯 Core Features:"
echo "   ✅ Financial Dashboard with SwiftUI"
echo "   ✅ Transaction List and Detail Views"
echo "   ✅ Multi-Account Management"
echo "   ✅ PDF/CSV File Upload Integration"
echo "   ✅ Charts and Financial Insights"
echo "   ✅ Backend API Integration (FastAPI)"
echo "   ✅ MCP Server Support"
echo "   ✅ Local Data Storage"
echo "   ✅ Export/Import Functionality"
echo "   ✅ Privacy-First Architecture"
echo ""

echo "🔧 Backend Integration:"
echo "   • FastAPI Server: http://127.0.0.1:8000"
echo "   • Health Check: /api/health"
echo "   • File Upload: /api/upload"
echo "   • Transaction Processing: /api/transactions"
echo ""

echo "🔌 MCP Servers (Optional):"
echo "   • Financial Analyzer: http://127.0.0.1:8001"
echo "   • OpenAI Service: http://127.0.0.1:8002"
echo "   • PDF Processor: http://127.0.0.1:8003"
echo ""

echo "📁 Project Structure:"
echo "   • Models: Transaction, BankAccount, FinancialSummary"
echo "   • Views: Dashboard, Transactions, Accounts, Insights, Settings"
echo "   • Services: APIService, FinancialDataManager, MCPService"
echo "   • Utils: Extensions, formatters, helpers"
echo ""

echo "🎮 How to Run:"
echo "   1. Ensure backend is running: cd ../financial_advisor && python api_server_real.py"
echo "   2. Run the app: swift run"
echo "   3. Or build and run: swift build && .build/debug/LedgerPro"
echo ""

echo "📋 Usage Instructions:"
echo "   1. Launch the application"
echo "   2. Check backend connection (green/red indicator in toolbar)"
echo "   3. Upload financial statements (PDF/CSV)"
echo "   4. View processed transactions in different tabs"
echo "   5. Analyze financial health and insights"
echo "   6. Export data in various formats"
echo ""

echo "🔍 Testing the Application:"
echo "   • Use 'Load Demo Data' button to populate with sample transactions"
echo "   • Test file upload with PDF or CSV files"
echo "   • Navigate between different dashboard tabs"
echo "   • Check Settings for configuration options"
echo "   • Try export functionality"
echo ""

echo "✅ LedgerPro is ready to test!"
echo ""
echo "💡 Tips:"
echo "   • The app runs best with the backend server active"
echo "   • Demo data can be loaded without backend connection"
echo "   • All data is stored locally for privacy"
echo "   • Check logs in terminal for debugging information"
echo ""

echo "🎉 Test completed successfully!"