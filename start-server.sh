#!/bin/bash

# X-AnyLabeling-Server Start Script (Production Mode)
# Starts the server in background with PID tracking

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR"
LABS_DIR="$(dirname "$INSTALL_DIR")"
SERVER_DIR="$LABS_DIR/X-AnyLabeling-Server"
VENV_DIR="$INSTALL_DIR/venv-server"
LOGS_DIR="$INSTALL_DIR/logs"
PID_FILE="$INSTALL_DIR/server.pid"
LOG_FILE="$LOGS_DIR/server.log"
ENV_FILE="$INSTALL_DIR/.env"

# Load .env file if it exists
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

# Create logs directory
mkdir -p "$LOGS_DIR"

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

# Check if server is already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}Server is already running (PID: $OLD_PID)${NC}"
        echo "Use ./stop-server.sh to stop it first, or ./monitor-server.sh to check status."
        exit 1
    else
        # Stale PID file
        rm -f "$PID_FILE"
    fi
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Change to server directory
cd "$SERVER_DIR"

# Get host and port from environment, .env file, or use defaults
HOST="${HOST:-${XANYLABELING_HOST:-0.0.0.0}}"
PORT="${PORT:-${XANYLABELING_PORT:-8014}}"

echo -e "${BLUE}Starting X-AnyLabeling-Server in production mode...${NC}"
echo "Server URL: http://$HOST:$PORT"
echo "Log file: $LOG_FILE"
echo "PID file: $PID_FILE"
echo ""

# Start server in background
nohup uvicorn app.main:app --host "$HOST" --port "$PORT" > "$LOG_FILE" 2>&1 &
SERVER_PID=$!

# Save PID
echo "$SERVER_PID" > "$PID_FILE"

# Wait a moment to check if process started successfully
sleep 2

if ps -p "$SERVER_PID" > /dev/null 2>&1; then
    echo -e "${GREEN}Server started successfully!${NC}"
    echo "PID: $SERVER_PID"
    echo ""
    echo "Next steps:"
    echo "  1. Activate the virtual environment (if needed):"
    echo "     source $VENV_DIR/bin/activate"
    echo ""
    echo "  2. Manage the server:"
    echo "     ./stop-server.sh    - Stop server"
    echo "     ./monitor-server.sh - Monitor server"
    echo "     tail -f $LOG_FILE  - View logs"
else
    echo -e "${RED}Failed to start server.${NC}"
    echo "Check logs: $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
fi

