#!/bin/bash

# X-AnyLabeling-Server Installation Script
# This script installs X-AnyLabeling-Server with SAM3 support

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR"
LABS_DIR="$(dirname "$INSTALL_DIR")"
SERVER_DIR="$LABS_DIR/X-AnyLabeling-Server"
VENV_DIR="$INSTALL_DIR/venv-server"
LOGS_DIR="$INSTALL_DIR/logs"
ENV_FILE="$INSTALL_DIR/.env"

# Load .env file if it exists to get default port
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

# Get port from .env or use default
DEFAULT_PORT="${PORT:-8014}"

# Create logs directory
mkdir -p "$LOGS_DIR"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOGS_DIR/install.log"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOGS_DIR/install.log"
}

log_error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOGS_DIR/install.log"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOGS_DIR/install.log"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

log "Starting X-AnyLabeling-Server installation with SAM3 support..."

# Step 1: Check Python version
log "Step 1: Checking Python version..."
if ! command_exists python3; then
    log_error "Python 3 is not installed. Please install Python 3.12 or higher."
    exit 1
fi

PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 12 ]); then
    log_error "Python 3.12+ is required for SAM3. Found: Python $PYTHON_VERSION"
    exit 1
fi

log_success "Python version: $PYTHON_VERSION (meets SAM3 requirement)"

# Step 2: Check GPU availability
log "Step 2: Checking GPU availability..."
if ! command_exists nvidia-smi; then
    log_warning "nvidia-smi not found. GPU support may not be available."
    GPU_COUNT=0
else
    GPU_INFO=$(nvidia-smi --query-gpu=index,name,memory.total --format=csv,noheader 2>/dev/null)
    GPU_COUNT=$(echo "$GPU_INFO" | wc -l)
    
    if [ "$GPU_COUNT" -eq 0 ]; then
        log_warning "No GPUs detected. SAM3 will run on CPU (not recommended)."
    else
        log_success "Detected $GPU_COUNT GPU(s):"
        echo "$GPU_INFO" | while IFS= read -r line; do
            log "  - $line"
        done
    fi
fi

# Step 3: Check CUDA version
log "Step 3: Checking CUDA version..."
if command_exists nvcc; then
    CUDA_VERSION=$(nvcc --version 2>/dev/null | grep "release" | sed 's/.*release \([0-9]\+\.[0-9]\+\).*/\1/')
    CUDA_MAJOR=$(echo $CUDA_VERSION | cut -d. -f1)
    CUDA_MINOR=$(echo $CUDA_VERSION | cut -d. -f2)
    
    if [ "$CUDA_MAJOR" -lt 12 ] || ([ "$CUDA_MAJOR" -eq 12 ] && [ "$CUDA_MINOR" -lt 6 ]); then
        log_warning "CUDA 12.6+ recommended for SAM3. Found: CUDA $CUDA_VERSION"
    else
        log_success "CUDA version: $CUDA_VERSION (meets SAM3 requirement)"
    fi
else
    log_warning "nvcc not found. CUDA may not be properly installed."
fi

# Step 4: Check if server directory exists
log "Step 4: Checking X-AnyLabeling-Server directory..."
if [ ! -d "$SERVER_DIR" ]; then
    log_error "X-AnyLabeling-Server directory not found at: $SERVER_DIR"
    log "Please clone the repository first:"
    log "  cd $LABS_DIR"
    log "  git clone https://github.com/CVHub520/X-AnyLabeling-Server.git"
    exit 1
fi
log_success "Server directory found: $SERVER_DIR"

# Step 5: Create virtual environment
log "Step 5: Checking virtual environment..."
if [ -d "$VENV_DIR" ]; then
    log_success "Virtual environment already exists. Using existing: $VENV_DIR"
else
    log "Creating new virtual environment..."
    python3 -m venv "$VENV_DIR"
    log_success "Virtual environment created: $VENV_DIR"
fi

# Step 6: Activate virtual environment and upgrade pip
log "Step 6: Activating virtual environment and upgrading pip..."
source "$VENV_DIR/bin/activate"
pip install --upgrade pip setuptools wheel > "$LOGS_DIR/pip_upgrade.log" 2>&1
log_success "pip upgraded"

# Step 7: Install uv (recommended package manager)
log "Step 7: Installing uv package manager..."
if command_exists uv; then
    log_success "uv is already installed"
else
    pip install --upgrade uv > "$LOGS_DIR/uv_install.log" 2>&1
    log_success "uv installed"
fi

# Step 8: Install PyTorch with CUDA support
log "Step 8: Installing PyTorch with CUDA 12.6 support..."
if [ "$GPU_COUNT" -gt 0 ]; then
    log "Installing PyTorch 2.7+ with CUDA 12.6 support..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126 > "$LOGS_DIR/pytorch_install.log" 2>&1
    log_success "PyTorch with CUDA support installed"
    
    # Verify PyTorch CUDA
    log "Verifying PyTorch CUDA installation..."
    python3 -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA Available: {torch.cuda.is_available()}'); print(f'CUDA Version: {torch.version.cuda}'); print(f'GPU Count: {torch.cuda.device_count()}')" > "$LOGS_DIR/pytorch_verify.log" 2>&1
    if python3 -c "import torch; exit(0 if torch.cuda.is_available() else 1)" 2>/dev/null; then
        log_success "PyTorch CUDA verification passed"
    else
        log_warning "PyTorch CUDA verification failed. Check logs: $LOGS_DIR/pytorch_verify.log"
    fi
else
    log_warning "No GPUs detected. Installing CPU-only PyTorch..."
    pip install torch torchvision torchaudio > "$LOGS_DIR/pytorch_install.log" 2>&1
    log_success "PyTorch (CPU) installed"
fi

# Step 9: Install X-AnyLabeling-Server with all dependencies
log "Step 9: Installing X-AnyLabeling-Server with all dependencies (including SAM3)..."
cd "$SERVER_DIR"

# Use uv if available, otherwise use pip
if command_exists uv && [ -f "$SERVER_DIR/pyproject.toml" ]; then
    log "Using uv to install dependencies..."
    uv pip install -e .[all] > "$LOGS_DIR/server_install.log" 2>&1
else
    log "Using pip to install dependencies..."
    pip install -e .[all] > "$LOGS_DIR/server_install.log" 2>&1
fi

log_success "X-AnyLabeling-Server installed with all dependencies"

# Step 10: Verify installation
log "Step 10: Verifying installation..."
if python3 -c "from app import __version__; print(f'X-AnyLabeling-Server v{__version__}')" 2>/dev/null; then
    VERSION=$(python3 -c "from app import __version__; print(__version__)" 2>/dev/null)
    log_success "X-AnyLabeling-Server v$VERSION installed successfully"
else
    log_error "Failed to verify X-AnyLabeling-Server installation"
    exit 1
fi

# Step 11: Check SAM3 dependencies
log "Step 11: Verifying SAM3 dependencies..."
SAM3_DEPS_OK=true
for dep in "torch" "timm" "huggingface_hub"; do
    if python3 -c "import $dep" 2>/dev/null; then
        log_success "  $dep: installed"
    else
        log_error "  $dep: missing"
        SAM3_DEPS_OK=false
    fi
done

if [ "$SAM3_DEPS_OK" = true ]; then
    log_success "All SAM3 dependencies are installed"
else
    log_error "Some SAM3 dependencies are missing. Please check the installation logs."
    exit 1
fi

# Step 12: Configure SAM3 model settings
log "Step 12: Configuring SAM3 model settings..."
SAM3_CONFIG="$SERVER_DIR/configs/auto_labeling/segment_anything_3.yaml"
if [ -f "$SAM3_CONFIG" ]; then
    # Set device to cuda:0 if GPUs are available
    if [ "$GPU_COUNT" -gt 0 ]; then
        # Check if device is already configured
        if ! grep -q "device:" "$SAM3_CONFIG" || grep -q "device: \"cpu\"" "$SAM3_CONFIG"; then
            log "Setting SAM3 device to cuda:0..."
            # Use sed to update device setting
            if grep -q "device:" "$SAM3_CONFIG"; then
                sed -i 's/device:.*/device: "cuda:0"/' "$SAM3_CONFIG"
            else
                # Add device setting if not present
                sed -i '/params:/a\  device: "cuda:0"' "$SAM3_CONFIG"
            fi
            log_success "SAM3 device configured to cuda:0"
        else
            log_success "SAM3 device already configured"
        fi
    else
        log_warning "No GPUs available. SAM3 will use CPU (not recommended for performance)."
    fi
else
    log_warning "SAM3 config file not found: $SAM3_CONFIG"
fi

# Step 13: Test SAM3 model loading (optional, can be slow)
log "Step 13: Testing SAM3 model import (full loading will happen on first use)..."
# Test through the app structure like the server does
TEST_IMPORT_SCRIPT="
import sys
sys.path.insert(0, '$SERVER_DIR')
try:
    from app.models.segment_anything_3 import SegmentAnything3
    print('SAM3 model class imported successfully')
except Exception as e:
    print(f'Import error: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"
if python3 -c "$TEST_IMPORT_SCRIPT" > "$LOGS_DIR/sam3_test.log" 2>&1; then
    log_success "SAM3 model can be imported"
else
    log_warning "SAM3 import test had issues. Check: $LOGS_DIR/sam3_test.log"
    log "This may be OK - SAM3 will be fully tested when the server starts."
    # Don't exit with error - let the server test it on startup
fi

# Step 14: Download SAM3 model checkpoint from HuggingFace
log "Step 14: Downloading SAM3 model checkpoint from HuggingFace..."
log "Note: This is a large file (~2.4GB) and may take several minutes depending on your internet connection."
log "You can skip this step and the model will be downloaded automatically on first use."

# Activate virtual environment for the download
source "$VENV_DIR/bin/activate"

# Check if huggingface_hub is available
if python3 -c "import huggingface_hub" 2>/dev/null; then
    DOWNLOAD_SCRIPT="
import os
import sys
from huggingface_hub import hf_hub_download
from pathlib import Path

try:
    print('Starting SAM3 model checkpoint download...')
    print('Repository: facebook/sam3')
    print('Filename: sam3.pt')
    print('This may take several minutes. Please wait...')
    sys.stdout.flush()
    
    # Download the checkpoint
    checkpoint_path = hf_hub_download(
        repo_id='facebook/sam3',
        filename='sam3.pt',
        resume_download=True,
        local_files_only=False
    )
    
    # Get file size
    file_size = os.path.getsize(checkpoint_path)
    file_size_mb = file_size / (1024 * 1024)
    
    print(f'SUCCESS: Model downloaded to: {checkpoint_path}')
    print(f'File size: {file_size_mb:.2f} MB')
    sys.stdout.flush()
except Exception as e:
    print(f'ERROR: Failed to download SAM3 model: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"
    
    if python3 -c "$DOWNLOAD_SCRIPT" > "$LOGS_DIR/sam3_download.log" 2>&1; then
        log_success "SAM3 model checkpoint downloaded successfully"
        log "Model is cached and ready to use. Check: $LOGS_DIR/sam3_download.log for details"
    else
        log_warning "SAM3 model checkpoint download failed or was interrupted"
        log "This is OK - the model will be downloaded automatically on first use."
        log "Check: $LOGS_DIR/sam3_download.log for details"
        log "You can retry the download later by running the server (it will download automatically)"
        # Don't exit with error - model can be downloaded later
    fi
else
    log_warning "huggingface_hub not available. Skipping model download."
    log "The model will be downloaded automatically on first use."
fi

deactivate

# Summary
log ""
log "=========================================="
log_success "Installation completed successfully!"
log "=========================================="
log ""
log "Next steps:"
log "  1. Activate the virtual environment:"
log "     source $VENV_DIR/bin/activate"
log ""
log "  2. Start the server:"
log "     cd $INSTALL_DIR"
log "     ./start-server.sh    # Production mode (background)"
log "     ./run-server.sh      # Development mode (foreground)"
log ""
log "  3. Monitor the server:"
log "     ./monitor-server.sh"
log ""
log "  4. Connect X-AnyLabeling client:"
log "     Edit X-AnyLabeling/anylabeling/configs/auto_labeling/remote_server.yaml"
log "     Set server_url: http://localhost:$DEFAULT_PORT"
log ""
log "Installation logs saved to: $LOGS_DIR/install.log"
log ""

