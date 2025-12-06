#!/bin/bash

# X-AnyLabeling Monitor All Script
# Monitors both server and client status

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
ENV_FILE="$INSTALL_DIR/.env"

# Load .env file if it exists
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  X-AnyLabeling Server & Client Monitor${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Server Status Section
echo -e "${CYAN}--- Server Status ---${NC}"
if [ -f "$INSTALL_DIR/server.pid" ]; then
    SERVER_PID=$(cat "$INSTALL_DIR/server.pid")
    if ps -p "$SERVER_PID" > /dev/null 2>&1; then
        echo -e "${GREEN}Status: RUNNING${NC}"
        echo "PID: $SERVER_PID"
    else
        echo -e "${RED}Status: STOPPED${NC}"
    fi
else
    echo -e "${RED}Status: STOPPED${NC}"
fi
echo ""

# Client Status Section
echo -e "${CYAN}--- Client Status ---${NC}"
if [ -f "$INSTALL_DIR/client.pid" ]; then
    CLIENT_PID=$(cat "$INSTALL_DIR/client.pid")
    if ps -p "$CLIENT_PID" > /dev/null 2>&1; then
        echo -e "${GREEN}Status: RUNNING${NC}"
        echo "PID: $CLIENT_PID"
    else
        echo -e "${RED}Status: STOPPED${NC}"
    fi
else
    # Try to find by process name
    CLIENT_PID=$(pgrep -f "xanylabeling\|anylabeling/app.py" 2>/dev/null | head -n 1 || echo "")
    if [ -n "$CLIENT_PID" ]; then
        echo -e "${GREEN}Status: RUNNING${NC}"
        echo "PID: $CLIENT_PID"
    else
        echo -e "${RED}Status: STOPPED${NC}"
    fi
fi
echo ""

# GPU Usage
echo -e "${CYAN}--- GPU Usage ---${NC}"
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits | \
    awk -F', ' '{printf "GPU %s (%s):\n", $1, $2; printf "  Utilization: %s%%\n", $3; printf "  Memory: %s / %s MB\n", $4, $5; printf "  Temperature: %s°C\n\n", $6}'
else
    echo -e "${YELLOW}nvidia-smi not available${NC}"
fi

# Server Health Check
if [ -f "$INSTALL_DIR/server.pid" ]; then
    SERVER_PID=$(cat "$INSTALL_DIR/server.pid")
    if ps -p "$SERVER_PID" > /dev/null 2>&1; then
        PORT="${PORT:-${XANYLABELING_PORT:-8014}}"
        echo -e "${CYAN}--- Server Health Check ---${NC}"
        if command -v curl >/dev/null 2>&1; then
            HEALTH_RESPONSE=$(curl -s "http://localhost:$PORT/health" 2>/dev/null)
            if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
                echo -e "${GREEN}Health Check: OK${NC}"
                MODELS_LOADED=$(echo "$HEALTH_RESPONSE" | grep -o '"models_loaded":[0-9]*' | cut -d: -f2)
                if [ -n "$MODELS_LOADED" ]; then
                    echo "  Models loaded: $MODELS_LOADED"
                fi
            else
                echo -e "${YELLOW}Health Check: Server not responding${NC}"
            fi
        fi
        echo ""
    fi
fi

# Recent Logs
echo -e "${CYAN}--- Recent Server Logs (last 10 lines) ---${NC}"
if [ -f "$INSTALL_DIR/logs/server.log" ]; then
    tail -n 10 "$INSTALL_DIR/logs/server.log" | sed 's/^/  /'
else
    echo -e "${YELLOW}  Log file not found${NC}"
fi
echo ""

echo -e "${CYAN}--- Recent Client Logs (last 10 lines) ---${NC}"
if [ -f "$INSTALL_DIR/logs/client.log" ]; then
    tail -n 10 "$INSTALL_DIR/logs/client.log" | sed 's/^/  /'
else
    echo -e "${YELLOW}  Log file not found${NC}"
fi
echo ""

echo -e "${CYAN}========================================${NC}"
echo "Management commands:"
echo "  ./start-all.sh      - Start both server and client"
echo "  ./stop-all.sh       - Stop both server and client"
echo "  ./monitor-server.sh - Monitor server only"
echo "  ./monitor-client.sh - Monitor client only"
echo ""

