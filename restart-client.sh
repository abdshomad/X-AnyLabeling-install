#!/bin/bash

# X-AnyLabeling Client Restart Script
# Stops and then starts the client

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR"
VENV_DIR="$INSTALL_DIR/venv-client"
ENV_FILE="$INSTALL_DIR/.env"

# Load .env file if it exists
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

echo -e "${BLUE}Restarting X-AnyLabeling client...${NC}"
echo ""

# Stop the client
echo "Stopping client..."
./stop-client.sh

# Wait a moment
sleep 2

# Start the client
echo ""
echo "Starting client..."
./start-client.sh

echo ""
echo "Next steps:"
echo "  1. Activate the virtual environment (if needed):"
echo "     source $VENV_DIR/bin/activate"
echo ""
echo "  2. Monitor the client:"
echo "     ./monitor-client.sh"
echo ""

