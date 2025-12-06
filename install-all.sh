#!/bin/bash

# X-AnyLabeling Install All Script
# Installs both server and client

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

echo -e "${BLUE}Installing X-AnyLabeling Server and Client...${NC}"
echo ""

# Install server
echo -e "${BLUE}Step 1: Installing server...${NC}"
if ./install-server.sh; then
    echo -e "${GREEN}Server installed successfully${NC}"
else
    echo -e "${RED}Failed to install server${NC}"
    exit 1
fi

echo ""
sleep 2

# Install client
echo -e "${BLUE}Step 2: Installing client...${NC}"
if ./install-client.sh; then
    echo -e "${GREEN}Client installed successfully${NC}"
else
    echo -e "${YELLOW}Warning: Failed to install client${NC}"
    echo "Server is installed. You can install the client manually with:"
    echo "  ./install-client.sh"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Both server and client installed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Start both services:"
echo "     ./start-all.sh"
echo ""
echo "  2. Individual management:"
echo "     ./start-server.sh   - Start server only"
echo "     ./start-client.sh   - Start client only"
echo "     ./monitor-all.sh    - Monitor both services"
echo ""

