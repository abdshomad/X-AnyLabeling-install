#!/bin/bash

# X-AnyLabeling Stop All Script
# Stops both server and client

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

echo -e "${BLUE}Stopping X-AnyLabeling Server and Client...${NC}"
echo ""

# Stop client first (reverse order of start)
echo -e "${BLUE}Step 1: Stopping client...${NC}"
./stop-client.sh || true  # Continue even if client is not running
echo ""

sleep 1

# Stop server
echo -e "${BLUE}Step 2: Stopping server...${NC}"
./stop-server.sh || true  # Continue even if server is not running
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Both services stopped!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Start both services again:"
echo "     ./start-all.sh"
echo ""
echo "  2. Individual management:"
echo "     ./start-server.sh   - Start server only"
echo "     ./start-client.sh   - Start client only"
echo ""

