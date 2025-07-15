#!/bin/bash

echo "🚀 Setting up LedgerPro Development Environment"
echo "=============================================="

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check Xcode
if ! command -v swift &> /dev/null; then
    echo "❌ Swift not found. Please install Xcode."
    exit 1
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3.9+."
    exit 1
fi

echo "✅ Swift found: $(swift --version | head -1)"
echo "✅ Python found: $(python3 --version)"

# Install SwiftLint
echo ""
echo "📦 Installing SwiftLint..."
if command -v brew &> /dev/null; then
    brew install swiftlint || echo "SwiftLint installation failed (continuing...)"
else
    echo "⚠️  Homebrew not found. Please install SwiftLint manually."
fi

# Setup Swift package
echo ""
echo "📦 Setting up Swift package..."
cd LedgerPro
swift package resolve

# Setup Python backend
echo ""
echo "🐍 Setting up Python backend..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate
cd ..

# Run initial tests
echo ""
echo "🧪 Running initial tests..."
../Scripts/run_all_tests.sh

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Open LedgerPro.xcworkspace in Xcode"
echo "2. Build and run the project"
echo "3. Start the backend: cd LedgerPro/backend && ./start_backend.sh"
echo "4. Run tests: ./Scripts/run_all_tests.sh"
echo ""
echo "🔗 Useful commands:"
echo "- Run tests: swift test"
echo "- Run backend: cd LedgerPro/backend && python api_server_real.py"
echo "- Lint code: swiftlint"
echo "- Clean build: swift package clean"