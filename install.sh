#!/bin/bash
#
# stay-active installer
# https://github.com/sleekhost/stay-active
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "  _____ _                              _   _"
echo " / ____| |                    /\      | | (_)"
echo "| (___ | |_ __ _ _   _ ______/  \   __| |_ ___   _____"
echo " \___ \| __/ _\` | | | |_____/ /\ \ / _\` __| \ \ / / _ \\"
echo " ____) | || (_| | |_| |    / ____ \ (_| |_| |\ V /  __/"
echo "|_____/ \__\__,_|\__, |   /_/    \_\__|\__|_| \_/ \___|"
echo "                  __/ |"
echo "                 |___/"
echo -e "${NC}"
echo "Keep Microsoft Teams showing you as Active"
echo ""

# Check macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script only works on macOS${NC}"
    exit 1
fi

echo -e "${BLUE}[1/4]${NC} Checking for Homebrew..."
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo -e "${GREEN}Homebrew found${NC}"
fi

echo ""
echo -e "${BLUE}[2/4]${NC} Installing cliclick..."
if ! command -v cliclick &> /dev/null; then
    brew install cliclick
    echo -e "${GREEN}cliclick installed${NC}"
else
    echo -e "${GREEN}cliclick already installed${NC}"
fi

echo ""
echo -e "${BLUE}[3/4]${NC} Installing stay-active..."
mkdir -p "$HOME/.local/bin"

# Download the script
curl -fsSL https://raw.githubusercontent.com/sleekhost/stay-active/main/stay-active -o "$HOME/.local/bin/stay-active"
chmod +x "$HOME/.local/bin/stay-active"
echo -e "${GREEN}stay-active installed to ~/.local/bin/${NC}"

echo ""
echo -e "${BLUE}[4/4]${NC} Configuring PATH..."
SHELL_RC=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [[ -n "$SHELL_RC" ]]; then
    if ! grep -q '.local/bin' "$SHELL_RC" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
        echo -e "${GREEN}Added ~/.local/bin to PATH${NC}"
    else
        echo -e "${GREEN}PATH already configured${NC}"
    fi
fi

# Add to current session
export PATH="$HOME/.local/bin:$PATH"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Installation complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: Grant Accessibility permissions${NC}"
echo ""
echo "1. Open System Settings → Privacy & Security → Accessibility"
echo "2. Click + and add your Terminal app"
echo "3. Also add: /opt/homebrew/bin/cliclick"
echo ""
echo -e "${BLUE}Quick start:${NC}"
echo ""
echo "  stay-active start    # Start keeping you active"
echo "  stay-active stop     # Stop"
echo "  stay-active status   # Check status"
echo "  stay-active --help   # Show all commands"
echo ""
echo -e "${YELLOW}Note: Open a new terminal or run 'source $SHELL_RC' to use stay-active${NC}"
