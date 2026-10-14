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

PLATFORM=$(uname -s)
# The upstream project is macOS-only; this fork provides the Linux implementation.
REPOSITORY="https://raw.githubusercontent.com/Ruy-Araujo/stay-active/main/stay-active"
LOCAL_SCRIPT=""
LINUX_DEPENDENCY=""

if [ -f "$0" ]; then
    LOCAL_SCRIPT="$(cd "$(dirname "$0")" && pwd)/stay-active"
fi

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo > /dev/null 2>&1; then
        if ! sudo "$@"; then
            echo -e "${RED}Error: Could not install ${LINUX_DEPENDENCY}${NC}"
            echo "Install ${LINUX_DEPENDENCY} manually, then run this installer again."
            return 1
        fi
    else
        echo -e "${RED}Error: Administrative privileges are required${NC}"
        echo "Install ${LINUX_DEPENDENCY} manually, then run this installer again."
        return 1
    fi
}

install_linux_dependency() {
    if command -v "$LINUX_DEPENDENCY" > /dev/null 2>&1; then
        echo -e "${GREEN}${LINUX_DEPENDENCY} already installed${NC}"
        return
    fi

    if command -v apt-get > /dev/null 2>&1; then
        run_as_root apt-get update
        run_as_root apt-get install -y "$LINUX_DEPENDENCY"
    elif command -v dnf > /dev/null 2>&1; then
        run_as_root dnf install -y "$LINUX_DEPENDENCY"
    elif command -v pacman > /dev/null 2>&1; then
        run_as_root pacman -S --needed --noconfirm "$LINUX_DEPENDENCY"
    elif command -v zypper > /dev/null 2>&1; then
        run_as_root zypper --non-interactive install "$LINUX_DEPENDENCY"
    else
        echo -e "${RED}Error: No supported package manager found${NC}"
        echo "Install ${LINUX_DEPENDENCY} manually, then run this installer again."
        return 1
    fi
}

is_wayland() {
    [ "${XDG_SESSION_TYPE:-}" = "wayland" ] || [ -n "${WAYLAND_DISPLAY:-}" ]
}

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

case "$PLATFORM" in
    Darwin)
        echo -e "${BLUE}[1/4]${NC} Checking for Homebrew..."
        if ! command -v brew > /dev/null 2>&1; then
            echo -e "${YELLOW}Homebrew not found. Installing...${NC}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # Add Homebrew to PATH for Apple Silicon
            if [ -f "/opt/homebrew/bin/brew" ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        else
            echo -e "${GREEN}Homebrew found${NC}"
        fi

        echo ""
        echo -e "${BLUE}[2/4]${NC} Installing cliclick..."
        if ! command -v cliclick > /dev/null 2>&1; then
            brew install cliclick
            echo -e "${GREEN}cliclick installed${NC}"
        else
            echo -e "${GREEN}cliclick already installed${NC}"
        fi
        ;;
    Linux)
        if is_wayland; then
            LINUX_DEPENDENCY="ydotool"
        else
            LINUX_DEPENDENCY="xdotool"
        fi
        echo -e "${BLUE}[1/4]${NC} Checking for ${LINUX_DEPENDENCY}..."
        install_linux_dependency
        ;;
    *)
        echo -e "${RED}Error: Unsupported platform: ${PLATFORM}${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}[3/4]${NC} Installing stay-active..."
mkdir -p "$HOME/.local/bin"

# Install from the checkout when available; otherwise download the current release.
if [ -f "$LOCAL_SCRIPT" ]; then
    cp "$LOCAL_SCRIPT" "$HOME/.local/bin/stay-active"
else
    curl -fsSL "$REPOSITORY" -o "$HOME/.local/bin/stay-active"
fi
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

if [ "$PLATFORM" = "Darwin" ]; then
    echo -e "${YELLOW}IMPORTANT: Grant Accessibility permissions${NC}"
    echo ""
    echo "1. Open System Settings → Privacy & Security → Accessibility"
    echo "2. Click + and add your Terminal app"
    echo "3. Also add: /opt/homebrew/bin/cliclick"
else
    if is_wayland; then
        echo -e "${YELLOW}IMPORTANT: Configure ydotoold${NC}"
        echo ""
        echo "ydotoold must be running with access to /dev/uinput before starting stay-active."
    else
        echo -e "${YELLOW}IMPORTANT: Use an X11 desktop session${NC}"
    fi
fi

echo ""
echo -e "${BLUE}Quick start:${NC}"
echo ""
echo "  stay-active start    # Start keeping you active"
echo "  stay-active stop     # Stop"
echo "  stay-active status   # Check status"
echo "  stay-active --help   # Show all commands"
echo ""
if [[ -n "$SHELL_RC" ]]; then
    echo -e "${YELLOW}Note: Open a new terminal or run 'source $SHELL_RC' to use stay-active${NC}"
fi
