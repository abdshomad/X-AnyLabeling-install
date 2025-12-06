#!/bin/bash

# X-AnyLabeling-Server Monitor Script
# Displays server status, logs, and GPU usage

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR"
PID_FILE="$INSTALL_DIR/server.pid"
LOGS_DIR="$INSTALL_DIR/logs"
LOG_FILE="$LOGS_DIR/server.log"
ENV_FILE="$INSTALL_DIR/.env"

# Load .env file if it exists
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

# Get port from environment, .env file, or use default
PORT="${PORT:-${XANYLABELING_PORT:-8014}}"

# Function to check if server is running
check_server_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0
        fi
    fi
    
    # Also check by port
    if command -v lsof >/dev/null 2>&1; then
        local port="${PORT:-${XANYLABELING_PORT:-8014}}"
        PID=$(lsof -ti:$port 2>/dev/null || echo "")
        if [ -n "$PID" ]; then
            return 0
        fi
    fi
    
    return 1
}

# Function to get server PID
get_server_pid() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "$PID"
            return
        fi
    fi
    
    # Try to find by port
    if command -v lsof >/dev/null 2>&1; then
        local port="${PORT:-${XANYLABELING_PORT:-8014}}"
        PID=$(lsof -ti:$port 2>/dev/null || echo "")
        if [ -n "$PID" ]; then
            echo "$PID"
        fi
    fi
}

# Server Status
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  X-AnyLabeling-Server Monitor${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check server status
if check_server_status; then
    PID=$(get_server_pid)
    echo -e "${GREEN}Status: RUNNING${NC}"
    echo "PID: $PID"
    echo "Port: $PORT"
    echo ""
    
    # Check if server responds
    if command -v curl >/dev/null 2>&1; then
        HEALTH_RESPONSE=$(curl -s "http://localhost:$PORT/health" 2>/dev/null)
        if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
            echo -e "${GREEN}Health Check: OK${NC}"
            # Extract models_loaded from response
            MODELS_LOADED=$(echo "$HEALTH_RESPONSE" | grep -o '"models_loaded":[0-9]*' | cut -d: -f2)
            if [ -n "$MODELS_LOADED" ]; then
                echo "  Models loaded: $MODELS_LOADED"
            fi
        else
            echo -e "${YELLOW}Health Check: Server not responding${NC}"
        fi
    fi
else
    echo -e "${RED}Status: STOPPED${NC}"
    echo ""
fi

# GPU Usage
echo ""
echo -e "${CYAN}GPU Usage:${NC}"
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits | \
    awk -F', ' '{printf "GPU %s (%s):\n", $1, $2; printf "  Utilization: %s%%\n", $3; printf "  Memory: %s / %s MB\n", $4, $5; printf "  Temperature: %s°C\n\n", $6}'
else
    echo -e "${YELLOW}nvidia-smi not available${NC}"
fi

# Recent Logs
echo ""
echo -e "${CYAN}Recent Server Logs (last 20 lines):${NC}"
if [ -f "$LOG_FILE" ]; then
    tail -n 20 "$LOG_FILE" | sed 's/^/  /'
else
    echo -e "${YELLOW}  Log file not found: $LOG_FILE${NC}"
fi

# Process Information
if check_server_status; then
    PID=$(get_server_pid)
    echo ""
    echo -e "${CYAN}Process Information:${NC}"
    if command -v ps >/dev/null 2>&1; then
        ps -p "$PID" -o pid,ppid,cmd,%mem,%cpu,etime 2>/dev/null | tail -n +2 | sed 's/^/  /'
    fi
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo "Next steps:"
echo "  1. Activate the virtual environment (if needed):"
echo "     source $INSTALL_DIR/venv-server/bin/activate"
echo ""
echo "  2. Server management commands:"
echo "     ./start-server.sh  - Start server (background)"
echo "     ./stop-server.sh  - Stop server"
echo "     ./run-server.sh   - Run in foreground"
echo "     tail -f $LOG_FILE  - Follow logs"
echo ""

