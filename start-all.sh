#!/bin/bash

# X-AnyLabeling Start All Script
# Starts both server and client together

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

echo -e "${BLUE}Starting X-AnyLabeling Server and Client...${NC}"
echo ""

# Start server
echo -e "${BLUE}Step 1: Starting server...${NC}"
if ./start-server.sh; then
    echo -e "${GREEN}Server started successfully${NC}"
else
    echo -e "${RED}Failed to start server${NC}"
    exit 1
fi

echo ""
sleep 2

# Start client
echo -e "${BLUE}Step 2: Starting client...${NC}"
if ./start-client.sh; then
    echo -e "${GREEN}Client started successfully${NC}"
else
    echo -e "${YELLOW}Warning: Failed to start client${NC}"
    echo "Server is still running. You can start the client manually with:"
    echo "  ./start-client.sh"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Both services started!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Monitor both services:"
echo "     ./monitor-all.sh"
echo ""
echo "  2. Stop both services:"
echo "     ./stop-all.sh"
echo ""
echo "  3. Individual management:"
echo "     ./monitor-server.sh  - Monitor server only"
echo "     ./monitor-client.sh  - Monitor client only"
echo ""

