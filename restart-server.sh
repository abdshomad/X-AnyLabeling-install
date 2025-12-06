#!/bin/bash

# X-AnyLabeling-Server Restart Script
# Stops and then starts the server

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR"
VENV_DIR="$INSTALL_DIR/venv-server"
ENV_FILE="$INSTALL_DIR/.env"

# Load .env file if it exists
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

echo -e "${BLUE}Restarting X-AnyLabeling-Server...${NC}"
echo ""

# Stop the server
echo "Stopping server..."
./stop-server.sh

# Wait a moment
sleep 2

# Start the server
echo ""
echo "Starting server..."
./start-server.sh

echo ""
echo "Next steps:"
echo "  1. Activate the virtual environment (if needed):"
echo "     source $VENV_DIR/bin/activate"
echo ""
echo "  2. Monitor the server:"
echo "     ./monitor-server.sh"
echo ""

