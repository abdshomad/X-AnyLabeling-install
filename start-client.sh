#!/bin/bash

# X-AnyLabeling Client Start Script (Production Mode)
# Starts the client in background with PID tracking

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
CLIENT_DIR="$LABS_DIR/X-AnyLabeling"
VENV_DIR="$INSTALL_DIR/venv-client"
LOGS_DIR="$INSTALL_DIR/logs"
PID_FILE="$INSTALL_DIR/client.pid"
LOG_FILE="$LOGS_DIR/client.log"
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
    echo "Please run ./install-client.sh first."
    exit 1
fi

# Check if client directory exists
if [ ! -d "$CLIENT_DIR" ]; then
    echo -e "${RED}Error: X-AnyLabeling directory not found.${NC}"
    exit 1
fi

# Check if client is already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}Client is already running (PID: $OLD_PID)${NC}"
        echo "Use ./stop-client.sh to stop it first, or ./monitor-client.sh to check status."
        exit 1
    else
        # Stale PID file
        rm -f "$PID_FILE"
    fi
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Change to client directory
cd "$CLIENT_DIR"

echo -e "${BLUE}Starting X-AnyLabeling client in production mode...${NC}"
echo "Log file: $LOG_FILE"
echo "PID file: $PID_FILE"
echo ""

# Start client in background
# Use xanylabeling command if available, otherwise use python
if command -v xanylabeling >/dev/null 2>&1; then
    nohup xanylabeling > "$LOG_FILE" 2>&1 &
    CLIENT_PID=$!
else
    nohup python anylabeling/app.py > "$LOG_FILE" 2>&1 &
    CLIENT_PID=$!
fi

# Save PID
echo "$CLIENT_PID" > "$PID_FILE"

# Wait a moment to check if process started successfully
sleep 2

if ps -p "$CLIENT_PID" > /dev/null 2>&1; then
    echo -e "${GREEN}Client started successfully!${NC}"
    echo "PID: $CLIENT_PID"
    echo ""
    echo "Next steps:"
    echo "  1. Activate the virtual environment (if needed):"
    echo "     source $VENV_DIR/bin/activate"
    echo ""
    echo "  2. Manage the client:"
    echo "     ./stop-client.sh    - Stop client"
    echo "     ./monitor-client.sh - Monitor client"
    echo "     tail -f $LOG_FILE  - View logs"
    echo ""
    echo "  3. Connect to server:"
    echo "     Press Ctrl+A in the client and select Remote-Server model"
else
    echo -e "${RED}Failed to start client.${NC}"
    echo "Check logs: $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
fi

