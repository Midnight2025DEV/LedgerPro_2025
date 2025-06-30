# LedgerPro - macOS Financial Analysis App
# Makefile for building and managing the application

.PHONY: help build run clean test deps install package lint format check-backend start-backend

# Default target
help:
	@echo "LedgerPro - macOS Financial Analysis Application"
	@echo ""
	@echo "Available commands:"
	@echo "  build          Build the application"
	@echo "  run            Run the application"
	@echo "  clean          Clean build artifacts"
	@echo "  test           Run tests"
	@echo "  deps           Resolve Swift package dependencies"
	@echo "  install        Install the application (copy to Applications)"
	@echo "  package        Create distribution package"
	@echo "  lint           Run SwiftLint (if available)"
	@echo "  format         Format Swift code (if available)"
	@echo "  check-backend  Check if backend is running"
	@echo "  start-backend  Start the backend server"
	@echo "  setup          Complete setup (backend + dependencies)"
	@echo ""
	@echo "Backend Integration:"
	@echo "  The app requires the AI Financial Accountant backend to be running."
	@echo "  Run 'make start-backend' or manually start:"
	@echo "    cd ../financial_advisor && python api_server_real.py"

# Build the application
build:
	@echo "Building LedgerPro..."
	swift build -c release

# Run the application in development mode
run:
	@echo "Running LedgerPro..."
	swift run

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	swift package clean
	rm -rf .build/

# Run tests
test:
	@echo "Running tests..."
	swift test

# Resolve dependencies
deps:
	@echo "Resolving Swift package dependencies..."
	swift package resolve

# Install the application to /Applications
install: build
	@echo "Installing LedgerPro to Applications..."
	@if [ -d ".build/release/LedgerPro" ]; then \
		echo "Copying LedgerPro to /Applications..."; \
		sudo cp -R .build/release/LedgerPro /Applications/; \
		echo "LedgerPro installed successfully!"; \
	else \
		echo "Error: Build not found. Run 'make build' first."; \
		exit 1; \
	fi

# Create a distribution package
package: build
	@echo "Creating distribution package..."
	@mkdir -p dist
	@if [ -d ".build/release/LedgerPro" ]; then \
		cp -R .build/release/LedgerPro dist/; \
		cd dist && zip -r LedgerPro.zip LedgerPro/; \
		echo "Package created: dist/LedgerPro.zip"; \
	else \
		echo "Error: Build not found. Run 'make build' first."; \
		exit 1; \
	fi

# Run SwiftLint if available
lint:
	@echo "Running SwiftLint..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint lint Sources/; \
	else \
		echo "SwiftLint not found. Install with: brew install swiftlint"; \
	fi

# Format Swift code
format:
	@echo "Formatting Swift code..."
	@if command -v swiftformat >/dev/null 2>&1; then \
		swiftformat Sources/; \
	else \
		echo "SwiftFormat not found. Install with: brew install swiftformat"; \
	fi

# Check if backend is running
check-backend:
	@echo "Checking backend status..."
	@if curl -s http://127.0.0.1:8000/api/health >/dev/null 2>&1; then \
		echo "✅ Backend is running on http://127.0.0.1:8000"; \
		curl -s http://127.0.0.1:8000/api/health | python3 -m json.tool; \
	else \
		echo "❌ Backend is not running"; \
		echo "Start it with: make start-backend"; \
		echo "Or manually: cd ../financial_advisor && python api_server_real.py"; \
	fi

# Start the backend server
start-backend:
	@echo "Starting AI Financial Accountant backend..."
	@if [ -f "../financial_advisor/api_server_real.py" ]; then \
		echo "Starting backend server on http://127.0.0.1:8000..."; \
		cd ../financial_advisor && python api_server_real.py & \
		echo "Backend server started. Use 'make check-backend' to verify."; \
		echo "Note: Server is running in background. Stop with: pkill -f api_server_real.py"; \
	else \
		echo "Error: Backend not found at ../financial_advisor/api_server_real.py"; \
		echo "Make sure you're in the correct directory structure."; \
		exit 1; \
	fi

# Complete setup
setup: deps check-backend
	@echo "Setting up LedgerPro development environment..."
	@echo ""
	@echo "✅ Dependencies resolved"
	@echo "✅ Backend status checked"
	@echo ""
	@echo "Ready to develop! Use 'make run' to start the application."

# Development targets
dev: deps
	@echo "Starting development environment..."
	swift run &
	@echo "LedgerPro started in development mode."

# Quick build and run
quick: build run

# Clean and rebuild
rebuild: clean build

# Run with verbose output
verbose:
	swift run --verbose

# Debug build
debug:
	swift build --configuration debug

# Release build
release:
	swift build --configuration release

# Show build info
info:
	@echo "LedgerPro Build Information:"
	@echo "Swift Version: $(shell swift --version | head -n1)"
	@echo "Build Directory: .build/"
	@echo "Target Platform: macOS"
	@echo "Minimum macOS Version: 13.0"

# Validate build
validate: build
	@echo "Validating build..."
	@if [ -f ".build/release/LedgerPro" ]; then \
		echo "✅ Build successful"; \
		ls -la .build/release/LedgerPro; \
	else \
		echo "❌ Build validation failed"; \
		exit 1; \
	fi

# Dependencies check
check-deps:
	@echo "Checking Swift package dependencies..."
	swift package show-dependencies

# Update dependencies
update-deps:
	@echo "Updating Swift package dependencies..."
	swift package update

# Generate Xcode project (optional)
xcode:
	@echo "Generating Xcode project..."
	swift package generate-xcodeproj
	@echo "Open LedgerPro.xcodeproj to use Xcode"

# Performance build
perf: 
	swift build -c release --arch arm64

# Universal build (Intel + Apple Silicon)
universal:
	swift build -c release --arch x86_64 --arch arm64

# Show project stats
stats:
	@echo "LedgerPro Project Statistics:"
	@echo "Swift files: $(shell find Sources -name '*.swift' | wc -l)"
	@echo "Lines of code: $(shell find Sources -name '*.swift' -exec cat {} \; | wc -l)"
	@echo "Project size: $(shell du -sh . | cut -f1)"

# Archive for distribution
archive: package
	@echo "Creating archive for distribution..."
	@mkdir -p archives
	@cp dist/LedgerPro.zip archives/LedgerPro-$(shell date +%Y%m%d-%H%M%S).zip
	@echo "Archive created in archives/ directory"