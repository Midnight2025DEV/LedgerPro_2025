#!/bin/bash

# LedgerPro Secure API Deployment Script
# =====================================
# 
# Deploys the enhanced secure API server with proper configuration
# and security settings for production use.

set -e  # Exit on any error

echo "🚀 LedgerPro Secure API Deployment"
echo "=================================="

# Check if we're in the backend directory
if [ ! -f "api_server_secure.py" ]; then
    echo "❌ Error: Must run from backend directory"
    echo "Please cd to the backend directory and run this script"
    exit 1
fi

# Check Python version
python_version=$(python3 --version 2>&1 | awk '{print $2}')
echo "🐍 Python version: $python_version"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source venv/bin/activate

# Install/upgrade requirements
echo "📥 Installing requirements..."
pip install --upgrade pip
pip install -r requirements.txt

# Verify slowapi installation
echo "🔍 Verifying slowapi installation..."
python3 -c "import slowapi; print(f'✅ slowapi {slowapi.__version__} installed')" || {
    echo "❌ slowapi not installed properly"
    echo "Installing slowapi manually..."
    pip install slowapi==0.1.9
}

# Set production security environment variables
echo "🔒 Configuring security settings..."

# Production security configuration
export MAX_FILE_SIZE_MB=50
export MAX_BODY_SIZE_MB=52
export RATE_LIMIT_UPLOADS_UNAUTH="10/minute"
export RATE_LIMIT_UPLOADS_AUTH="30/minute"
export RATE_LIMIT_JOBS="60/minute"
export RATE_LIMIT_TRANSACTIONS="30/minute"
export RATE_LIMIT_METRICS="5/minute"
export MAX_CONCURRENT_JOBS_PER_IP=3
export IP_LIMIT_RESET_HOURS=1
export SESSION_EXPIRY_HOURS=24
export CSV_PROCESSING_TIMEOUT=30
export PDF_PROCESSING_TIMEOUT=60
export MAX_WORKERS=2
export ENABLE_DOCS=false
export HOST=127.0.0.1
export PORT=8000

# Generate secure passwords for production (if not already set)
if [ -z "$ADMIN_PASSWORD" ]; then
    export ADMIN_PASSWORD=$(openssl rand -base64 12)
    echo "🔑 Generated admin password: $ADMIN_PASSWORD"
    echo "⚠️  SAVE THIS PASSWORD - it won't be shown again!"
fi

if [ -z "$DEMO_PASSWORD" ]; then
    export DEMO_PASSWORD=$(openssl rand -base64 8)
    echo "🔑 Generated demo password: $DEMO_PASSWORD"
fi

# Show security configuration summary
echo ""
echo "📊 Security Configuration Summary:"
echo "================================="
python3 -c "
from config.security_config import config
import json
print(json.dumps(config.get_summary(), indent=2))
"

# Run security tests
echo ""
echo "🧪 Running security tests..."
if [ -f "tests/test_security.py" ]; then
    python3 -m pytest tests/test_security.py -v
    echo "✅ Security tests passed!"
else
    echo "⚠️  Security tests not found, skipping..."
fi

# Create systemd service file for production
create_systemd_service() {
    local service_file="/tmp/ledgerpro-api.service"
    local current_dir=$(pwd)
    local user=$(whoami)
    
    cat > "$service_file" << EOF
[Unit]
Description=LedgerPro Secure API Server
After=network.target

[Service]
Type=exec
User=$user
WorkingDirectory=$current_dir
Environment=PATH=$current_dir/venv/bin
Environment=MAX_FILE_SIZE_MB=50
Environment=RATE_LIMIT_UPLOADS_UNAUTH=10/minute
Environment=RATE_LIMIT_UPLOADS_AUTH=30/minute
Environment=MAX_CONCURRENT_JOBS_PER_IP=3
Environment=ENABLE_DOCS=false
Environment=ADMIN_PASSWORD=$ADMIN_PASSWORD
Environment=DEMO_PASSWORD=$DEMO_PASSWORD
ExecStart=$current_dir/venv/bin/python api_server_secure.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    echo "📄 Created systemd service file: $service_file"
    echo "To install as system service:"
    echo "  sudo cp $service_file /etc/systemd/system/"
    echo "  sudo systemctl daemon-reload"
    echo "  sudo systemctl enable ledgerpro-api"
    echo "  sudo systemctl start ledgerpro-api"
}

# Ask if user wants to create systemd service
read -p "🤔 Create systemd service file for production? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    create_systemd_service
fi

# Performance test with sample data
echo ""
echo "🏃 Running performance test..."
python3 -c "
import time
import requests

try:
    # Start server check
    response = requests.get('http://127.0.0.1:8000/api/health', timeout=5)
    if response.status_code == 200:
        print('✅ Server is already running and responding')
        data = response.json()
        print(f'   Version: {data.get(\"version\", \"unknown\")}')
        print(f'   Security features: {len(data.get(\"security_features\", []))}')
    else:
        print('⚠️  Server is not responding correctly')
except requests.exceptions.ConnectionError:
    print('🔌 Server is not running - you can start it with:')
    print('   python3 api_server_secure.py')
except Exception as e:
    print(f'❌ Error checking server: {e}')
"

# Create production checklist
echo ""
echo "✅ Production Deployment Checklist:"
echo "=================================="
echo "□ Change default passwords (ADMIN_PASSWORD, DEMO_PASSWORD)"
echo "□ Set ENABLE_DOCS=false for production"
echo "□ Configure reverse proxy (nginx/apache) with HTTPS"
echo "□ Set up proper logging and log rotation"
echo "□ Configure firewall rules (allow only necessary ports)"
echo "□ Set up monitoring and alerting"
echo "□ Configure backup procedures"
echo "□ Test rate limiting and security features"
echo "□ Set up SSL/TLS certificates"
echo "□ Configure production database (if applicable)"

echo ""
echo "🚀 Deployment preparation complete!"
echo ""
echo "To start the secure API server:"
echo "  python3 api_server_secure.py"
echo ""
echo "Security features enabled:"
echo "  🔒 File size limits: ${MAX_FILE_SIZE_MB}MB"
echo "  ⏱️  Rate limiting: ${RATE_LIMIT_UPLOADS_UNAUTH} (unauth), ${RATE_LIMIT_UPLOADS_AUTH} (auth)"
echo "  🔢 Concurrent jobs: ${MAX_CONCURRENT_JOBS_PER_IP} per IP"
echo "  📊 Request monitoring and metrics"
echo "  🛡️  Enhanced authentication with bypasses"
echo ""
echo "API will be available at: http://${HOST}:${PORT}"
echo "Health check: http://${HOST}:${PORT}/api/health"
echo "Metrics (auth required): http://${HOST}:${PORT}/api/metrics"

# Save environment variables to .env file for easy reuse
cat > .env << EOF
# LedgerPro Security Configuration
# Generated on $(date)

MAX_FILE_SIZE_MB=${MAX_FILE_SIZE_MB}
MAX_BODY_SIZE_MB=${MAX_BODY_SIZE_MB}
RATE_LIMIT_UPLOADS_UNAUTH=${RATE_LIMIT_UPLOADS_UNAUTH}
RATE_LIMIT_UPLOADS_AUTH=${RATE_LIMIT_UPLOADS_AUTH}
RATE_LIMIT_JOBS=${RATE_LIMIT_JOBS}
RATE_LIMIT_TRANSACTIONS=${RATE_LIMIT_TRANSACTIONS}
RATE_LIMIT_METRICS=${RATE_LIMIT_METRICS}
MAX_CONCURRENT_JOBS_PER_IP=${MAX_CONCURRENT_JOBS_PER_IP}
IP_LIMIT_RESET_HOURS=${IP_LIMIT_RESET_HOURS}
SESSION_EXPIRY_HOURS=${SESSION_EXPIRY_HOURS}
CSV_PROCESSING_TIMEOUT=${CSV_PROCESSING_TIMEOUT}
PDF_PROCESSING_TIMEOUT=${PDF_PROCESSING_TIMEOUT}
MAX_WORKERS=${MAX_WORKERS}
ENABLE_DOCS=${ENABLE_DOCS}
HOST=${HOST}
PORT=${PORT}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
DEMO_PASSWORD=${DEMO_PASSWORD}
EOF

echo "💾 Environment variables saved to .env file"
echo "⚠️  Keep .env file secure - it contains passwords!"