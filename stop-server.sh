#!/bin/bash

# X-AnyLabeling-Server Stop Script
# Gracefully stops the running server

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
PID_FILE="$INSTALL_DIR/server.pid"
ENV_FILE="$INSTALL_DIR/.env"

# Load .env file if it exists
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

# Function to find server process by port
find_server_by_port() {
    local port="${PORT:-${XANYLABELING_PORT:-8014}}"
    # Find process using the port
    PID=$(lsof -ti:$port 2>/dev/null || echo "")
    echo "$PID"
}

# Check PID file
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${BLUE}Stopping server (PID: $PID)...${NC}"
        kill "$PID" 2>/dev/null || true
        
        # Wait for process to stop
        for i in {1..10}; do
            if ! ps -p "$PID" > /dev/null 2>&1; then
                break
            fi
            sleep 1
        done
        
        # Force kill if still running
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}Process still running, forcing termination...${NC}"
            kill -9 "$PID" 2>/dev/null || true
        fi
        
        rm -f "$PID_FILE"
        echo -e "${GREEN}Server stopped.${NC}"
        exit 0
    else
        echo -e "${YELLOW}PID file exists but process is not running. Cleaning up...${NC}"
        rm -f "$PID_FILE"
    fi
fi

# Try to find server by port
PORT="${PORT:-${XANYLABELING_PORT:-8014}}"
PID=$(find_server_by_port)

if [ -n "$PID" ]; then
    echo -e "${BLUE}Found server process on port $PORT (PID: $PID)...${NC}"
    kill "$PID" 2>/dev/null || true
    
    # Wait for process to stop
    for i in {1..10}; do
        if ! ps -p "$PID" > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    # Force kill if still running
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}Process still running, forcing termination...${NC}"
        kill -9 "$PID" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}Server stopped.${NC}"
else
    echo -e "${YELLOW}No running server found.${NC}"
fi

echo ""
echo "Next steps:"
echo "  1. Activate the virtual environment (if needed):"
echo "     source $(dirname "$SCRIPT_DIR")/X-AnyLabeling-Install/venv-server/bin/activate"
echo ""
echo "  2. Start the server again:"
echo "     ./start-server.sh  - Start in background"
echo "     ./run-server.sh    - Run in foreground"

