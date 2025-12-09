#!/bin/bash
#
# stay-active uninstaller
# https://github.com/sleekhost/stay-active
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Uninstalling stay-active...${NC}"
echo ""

# Stop the daemon if running
if [[ -f "$HOME/.local/.stay_active_on" ]]; then
    echo "Stopping daemon..."
    rm -f "$HOME/.local/.stay_active_on"
    if [[ -f "$HOME/.local/.stay_active_pid" ]]; then
        pid=$(cat "$HOME/.local/.stay_active_pid")
        kill "$pid" 2>/dev/null || true
    fi
    echo -e "${GREEN}Daemon stopped${NC}"
fi

# Remove files
echo "Removing files..."
rm -f "$HOME/.local/bin/stay-active"
rm -f "$HOME/.local/.stay_active_on"
rm -f "$HOME/.local/.stay_active_pid"
rm -f "$HOME/.local/.stay_active_log"
echo -e "${GREEN}Files removed${NC}"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  stay-active has been uninstalled${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Optional: To also remove cliclick, run:"
echo "  brew uninstall cliclick"
echo ""
echo "Thank you for using stay-active!"
