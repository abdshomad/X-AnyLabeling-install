#!/bin/bash

# X-AnyLabeling-Server Run Script (Development Mode)
# Runs the server in foreground for development/testing

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR"
LABS_DIR="$(dirname "$INSTALL_DIR")"
SERVER_DIR="$LABS_DIR/X-AnyLabeling-Server"
VENV_DIR="$INSTALL_DIR/venv-server"
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
    echo "Please run ./install-server.sh first."
    exit 1
fi

# Check if server directory exists
if [ ! -d "$SERVER_DIR" ]; then
    echo -e "${RED}Error: X-AnyLabeling-Server directory not found.${NC}"
    exit 1
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Change to server directory
cd "$SERVER_DIR"

# Get host and port from environment, .env file, or use defaults
HOST="${HOST:-${XANYLABELING_HOST:-0.0.0.0}}"
PORT="${PORT:-${XANYLABELING_PORT:-8014}}"

echo -e "${BLUE}Starting X-AnyLabeling-Server in development mode...${NC}"
echo "Server URL: http://$HOST:$PORT"
echo "Press Ctrl+C to stop"
echo ""
echo "Note: Virtual environment is automatically activated."
echo "To manually activate: source $VENV_DIR/bin/activate"
echo ""

# Run uvicorn
uvicorn app.main:app --host "$HOST" --port "$PORT" --reload

