#!/bin/bash

# X-AnyLabeling Restart All Script
# Restarts both server and client

# Note: Not using set -e here to allow graceful handling of individual service failures

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

echo -e "${BLUE}Restarting X-AnyLabeling Server and Client...${NC}"
echo ""

# Restart server
echo -e "${BLUE}Step 1: Restarting server...${NC}"
if ./restart-server.sh; then
    echo -e "${GREEN}Server restarted successfully${NC}"
else
    echo -e "${YELLOW}Warning: Server restart had issues${NC}"
fi
echo ""

sleep 2

# Restart client
echo -e "${BLUE}Step 2: Restarting client...${NC}"
if ./restart-client.sh; then
    echo -e "${GREEN}Client restarted successfully${NC}"
else
    echo -e "${YELLOW}Warning: Client restart had issues (may not be installed)${NC}"
fi
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Both services restarted!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Monitor both services:"
echo "     ./monitor-all.sh"
echo ""
echo "  2. Individual management:"
echo "     ./monitor-server.sh  - Monitor server only"
echo "     ./monitor-client.sh  - Monitor client only"
echo ""

