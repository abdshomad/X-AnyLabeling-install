#!/bin/bash

# X-AnyLabeling Client Installation Script
# This script installs X-AnyLabeling client with GPU support

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
CLIENT_DIR="$LABS_DIR/X-AnyLabeling"
VENV_DIR="$INSTALL_DIR/venv-client"
LOGS_DIR="$INSTALL_DIR/logs"
ENV_FILE="$INSTALL_DIR/.env"

# Load .env file if it exists to get default port
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

# Get port from .env or use default
DEFAULT_PORT="${PORT:-${XANYLABELING_PORT:-8014}}"

# Create logs directory
mkdir -p "$LOGS_DIR"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOGS_DIR/install-client.log"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOGS_DIR/install-client.log"
}

log_error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOGS_DIR/install-client.log"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOGS_DIR/install-client.log"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

log "Starting X-AnyLabeling client installation with GPU support..."

# Step 1: Check Python version
log "Step 1: Checking Python version..."
# Check venv Python first if it exists, otherwise check system Python
if [ -d "$VENV_DIR" ] && [ -f "$VENV_DIR/bin/python3" ]; then
    PYTHON_CMD="$VENV_DIR/bin/python3"
    log "Using Python from existing virtual environment"
elif command_exists uv; then
    # uv can provide Python 3.12, so we'll create venv with it
    PYTHON_CMD="python3"  # Will be replaced by venv Python after creation
    log "Will use uv to create Python 3.12 virtual environment"
elif ! command_exists python3; then
    log_error "Python 3 is not installed. Please install Python 3.10 or higher."
    exit 1
else
    PYTHON_CMD="python3"
fi

# If venv exists, use its Python for version check
if [ -f "$VENV_DIR/bin/python3" ]; then
    PYTHON_VERSION=$("$VENV_DIR/bin/python3" --version 2>&1 | awk '{print $2}')
else
    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
fi

PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 10 ]); then
    # If venv doesn't exist and system Python is too old, try to create venv with uv
    if [ ! -d "$VENV_DIR" ] && command_exists uv; then
        log "System Python is $PYTHON_VERSION, but venv doesn't exist. Creating venv with uv (Python 3.12)..."
        uv venv --python 3.12 --seed "$VENV_DIR"
        PYTHON_VERSION=$("$VENV_DIR/bin/python3" --version 2>&1 | awk '{print $2}')
        PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
        PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
    fi
    
    # Re-check after potential venv creation
    if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 10 ]); then
        log_error "Python 3.10+ is required for X-AnyLabeling. Found: Python $PYTHON_VERSION"
        log_error "Please install Python 3.10+ or use 'uv venv --python 3.12' to create a virtual environment"
        exit 1
    fi
fi

log_success "Python version: $PYTHON_VERSION (meets requirement)"

# Step 2: Check GPU availability (optional for client)
log "Step 2: Checking GPU availability..."
if ! command_exists nvidia-smi; then
    log_warning "nvidia-smi not found. GPU support may not be available."
    GPU_COUNT=0
else
    GPU_INFO=$(nvidia-smi --query-gpu=index,name,memory.total --format=csv,noheader 2>/dev/null)
    GPU_COUNT=$(echo "$GPU_INFO" | wc -l)
    
    if [ "$GPU_COUNT" -eq 0 ]; then
        log_warning "No GPUs detected. Client will use CPU mode."
    else
        log_success "Detected $GPU_COUNT GPU(s):"
        echo "$GPU_INFO" | while IFS= read -r line; do
            log "  - $line"
        done
    fi
fi

# Step 3: Check if client directory exists
log "Step 3: Checking X-AnyLabeling directory..."
if [ ! -d "$CLIENT_DIR" ]; then
    log_error "X-AnyLabeling directory not found at: $CLIENT_DIR"
    log "Please clone the repository first:"
    log "  cd $LABS_DIR"
    log "  git clone https://github.com/CVHub520/X-AnyLabeling.git"
    exit 1
fi
log_success "Client directory found: $CLIENT_DIR"

# Step 4: Create virtual environment
log "Step 4: Checking virtual environment..."
if [ -d "$VENV_DIR" ]; then
    log_success "Virtual environment already exists. Using existing: $VENV_DIR"
else
    log "Creating new virtual environment with uv (Python 3.12)..."
    if command_exists uv; then
        uv venv --python 3.12 --seed "$VENV_DIR"
        log_success "Virtual environment created with uv: $VENV_DIR"
    else
        log "uv not found, falling back to python3 -m venv..."
        python3 -m venv "$VENV_DIR"
        log_success "Virtual environment created: $VENV_DIR"
    fi
fi

# Step 5: Activate virtual environment and upgrade pip
log "Step 5: Activating virtual environment and upgrading pip..."
source "$VENV_DIR/bin/activate"
pip install --upgrade pip setuptools wheel > "$LOGS_DIR/pip_upgrade_client.log" 2>&1
log_success "pip upgraded"

# Step 6: Install uv (recommended package manager)
log "Step 6: Installing uv package manager..."
if command_exists uv; then
    log_success "uv is already installed"
else
    pip install --upgrade uv > "$LOGS_DIR/uv_install_client.log" 2>&1
    log_success "uv installed"
fi

# Step 7: Install X-AnyLabeling with GPU support
log "Step 7: Installing X-AnyLabeling with GPU support..."
cd "$CLIENT_DIR"

# Use uv if available, otherwise use pip
if command_exists uv && [ -f "$CLIENT_DIR/pyproject.toml" ]; then
    log "Using uv to install dependencies with GPU support..."
    uv pip install -e .[gpu] > "$LOGS_DIR/client_install.log" 2>&1
else
    log "Using pip to install dependencies with GPU support..."
    pip install -e .[gpu] > "$LOGS_DIR/client_install.log" 2>&1
fi

log_success "X-AnyLabeling installed with GPU support"

# Step 8: Verify installation
log "Step 8: Verifying installation..."
if xanylabeling version > /dev/null 2>&1; then
    VERSION=$(xanylabeling version 2>/dev/null | head -n 1 || echo "unknown")
    log_success "X-AnyLabeling installed successfully: $VERSION"
else
    log_warning "Could not verify installation via xanylabeling command"
    log "Trying alternative verification method..."
    if python3 -c "from anylabeling.app_info import __version__; print(f'X-AnyLabeling v{__version__}')" 2>/dev/null; then
        VERSION=$(python3 -c "from anylabeling.app_info import __version__; print(__version__)" 2>/dev/null)
        log_success "X-AnyLabeling v$VERSION installed successfully"
    else
        log_error "Failed to verify X-AnyLabeling installation"
        exit 1
    fi
fi

# Step 9: Run system checks
log "Step 9: Running system checks..."
if xanylabeling checks > "$LOGS_DIR/client_checks.log" 2>&1; then
    log_success "System checks passed"
    log "Check details: $LOGS_DIR/client_checks.log"
else
    log_warning "System checks had warnings. Check: $LOGS_DIR/client_checks.log"
fi

# Step 10: Configure client to connect to server
log "Step 10: Configuring client to connect to server..."
REMOTE_SERVER_CONFIG="$CLIENT_DIR/anylabeling/configs/auto_labeling/remote_server.yaml"
if [ -f "$REMOTE_SERVER_CONFIG" ]; then
    # Update server URL with correct port
    SERVER_URL="http://localhost:$DEFAULT_PORT"
    
    # Check if server_url needs updating
    CURRENT_URL=$(grep "^server_url:" "$REMOTE_SERVER_CONFIG" | sed 's/.*server_url: *//' | tr -d '"' | tr -d "'" || echo "")
    
    if [ "$CURRENT_URL" != "$SERVER_URL" ]; then
        log "Updating server_url to: $SERVER_URL"
        # Use sed to update server_url
        if grep -q "^server_url:" "$REMOTE_SERVER_CONFIG"; then
            sed -i "s|^server_url:.*|server_url: $SERVER_URL|" "$REMOTE_SERVER_CONFIG"
            log_success "Server URL updated to: $SERVER_URL"
        else
            # Add server_url if not present
            sed -i "/^type: remote_server/a server_url: $SERVER_URL" "$REMOTE_SERVER_CONFIG"
            log_success "Server URL added: $SERVER_URL"
        fi
    else
        log_success "Server URL already configured correctly: $SERVER_URL"
    fi
else
    log_warning "Remote server config file not found: $REMOTE_SERVER_CONFIG"
    log "You may need to configure it manually."
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
log "  2. Start the client:"
log "     cd $INSTALL_DIR"
log "     ./start-client.sh    # Production mode (background)"
log "     ./run-client.sh      # Development mode (foreground)"
log ""
log "  3. Monitor the client:"
log "     ./monitor-client.sh"
log ""
log "  4. Start both server and client:"
log "     ./start-all.sh"
log ""
log "  5. Connect to server:"
log "     The client is configured to connect to: http://localhost:$DEFAULT_PORT"
log "     In the client, press Ctrl+A and select Remote-Server model"
log ""
log "Installation logs saved to: $LOGS_DIR/install-client.log"
log ""

