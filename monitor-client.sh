#!/bin/bash

# X-AnyLabeling Client Monitor Script
# Displays client status, logs, and resource usage

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
PID_FILE="$INSTALL_DIR/client.pid"
LOGS_DIR="$INSTALL_DIR/logs"
LOG_FILE="$LOGS_DIR/client.log"
ENV_FILE="$INSTALL_DIR/.env"

# Load .env file if it exists
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

# Function to check if client is running
check_client_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0
        fi
    fi
    
    # Also check by process name
    PID=$(pgrep -f "xanylabeling\|anylabeling/app.py" 2>/dev/null | head -n 1 || echo "")
    if [ -n "$PID" ]; then
        return 0
    fi
    
    return 1
}

# Function to get client PID
get_client_pid() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "$PID"
            return
        fi
    fi
    
    # Try to find by process name
    PID=$(pgrep -f "xanylabeling\|anylabeling/app.py" 2>/dev/null | head -n 1 || echo "")
    if [ -n "$PID" ]; then
        echo "$PID"
    fi
}

# Client Status
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  X-AnyLabeling Client Monitor${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check client status
if check_client_status; then
    PID=$(get_client_pid)
    echo -e "${GREEN}Status: RUNNING${NC}"
    echo "PID: $PID"
    echo ""
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
echo -e "${CYAN}Recent Client Logs (last 20 lines):${NC}"
if [ -f "$LOG_FILE" ]; then
    tail -n 20 "$LOG_FILE" | sed 's/^/  /'
else
    echo -e "${YELLOW}  Log file not found: $LOG_FILE${NC}"
fi

# Process Information
if check_client_status; then
    PID=$(get_client_pid)
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
echo "     source $INSTALL_DIR/venv-client/bin/activate"
echo ""
echo "  2. Client management commands:"
echo "     ./start-client.sh  - Start client (background)"
echo "     ./stop-client.sh   - Stop client"
echo "     ./run-client.sh    - Run in foreground"
echo "     tail -f $LOG_FILE  - Follow logs"
echo ""

