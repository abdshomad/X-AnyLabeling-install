#!/bin/bash

# X-AnyLabeling Client Run Script (Development Mode)
# Runs the client in foreground for development/testing

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR"
LABS_DIR="$(dirname "$INSTALL_DIR")"
CLIENT_DIR="$LABS_DIR/X-AnyLabeling"
VENV_DIR="$INSTALL_DIR/venv-client"
ENV_FILE="$INSTALL_DIR/.env"

# Load .env file if it exists
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${RED}Error: Virtual environment not found.${NC}"
    echo "Please run ./install-client.sh first."
    exit 1
fi

# Check if client directory exists
if [ ! -d "$CLIENT_DIR" ]; then
    echo -e "${RED}Error: X-AnyLabeling directory not found.${NC}"
    exit 1
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Change to client directory
cd "$CLIENT_DIR"

echo -e "${BLUE}Starting X-AnyLabeling client in development mode...${NC}"
echo "Press Ctrl+C to stop"
echo ""
echo "Note: Virtual environment is automatically activated."
echo "To manually activate: source $VENV_DIR/bin/activate"
echo ""

# Run client
# Use xanylabeling command if available, otherwise use python
if command -v xanylabeling >/dev/null 2>&1; then
    xanylabeling
else
    python anylabeling/app.py
fi

