#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
BACKEND_DIR="$PROJECT_ROOT/backend"
RESOURCES_DIR="$PROJECT_ROOT/Resources"

echo "=== Building LedgerPro Backend ==="
echo "Project root: $PROJECT_ROOT"

# Check if backend directory exists
if [ ! -d "$BACKEND_DIR" ]; then
    echo "Error: Backend directory not found at $BACKEND_DIR"
    exit 1
fi

cd "$BACKEND_DIR"

# Create Resources directory if it doesn't exist
mkdir -p "$RESOURCES_DIR"

# Check for Python 3.9+
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
REQUIRED_VERSION="3.9"

if ! python3 -c "import sys; exit(0 if sys.version_info >= (3,9) else 1)"; then
    echo "Error: Python 3.9+ is required, found $PYTHON_VERSION"
    exit 1
fi

echo "Using Python $PYTHON_VERSION"

# Create build environment
echo "Creating build environment..."
python3 -m venv build_env
source build_env/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt
pip install pyinstaller

# Create PyInstaller spec file
echo "Creating PyInstaller spec file..."
cat > pyinstaller.spec << 'EOF'
# -*- mode: python ; coding: utf-8 -*-
import sys
import os
from pathlib import Path

# Get the backend directory
backend_dir = Path(os.getcwd())

# Collect all data files
datas = [
    ('config/', 'config'),
    ('processors/', 'processors'),
]

# Ensure all hidden imports are included
hiddenimports = [
    'uvicorn.logging',
    'uvicorn.loops',
    'uvicorn.loops.auto',
    'uvicorn.protocols',
    'uvicorn.protocols.http',
    'uvicorn.protocols.http.auto',
    'uvicorn.protocols.websockets',
    'uvicorn.protocols.websockets.auto',
    'uvicorn.lifespan',
    'uvicorn.lifespan.on',
    'camelot',
    'cv2',
    'ghostscript',
    'PyPDF2',
    'pdfminer',
    'pdfminer.six',
    'pandas',
    'numpy',
    'openai',
    'aiofiles',
    'multipart',
]

# Analysis
a = Analysis(
    ['api_server_real.py'],
    pathex=[str(backend_dir)],
    binaries=[],
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=None,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=None)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='ledgerpro-backend',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
EOF

# Build the executable
echo "Building backend executable..."
pyinstaller pyinstaller.spec --clean --noconfirm

# Check if build was successful
if [ ! -f "dist/ledgerpro-backend" ]; then
    echo "Error: Backend build failed!"
    deactivate
    exit 1
fi

# Copy to Resources
echo "Copying backend to Resources..."
cp dist/ledgerpro-backend "$RESOURCES_DIR/"

# Make executable
chmod +x "$RESOURCES_DIR/ledgerpro-backend"

# Clean up
echo "Cleaning up..."
deactivate
rm -rf build_env build dist *.spec

echo "=== Backend build complete! ==="
echo "Backend executable: $RESOURCES_DIR/ledgerpro-backend"