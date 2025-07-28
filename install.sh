#!/bin/bash

# Installation script for generate-cpp-project

SCRIPT_NAME="generate-cpp-project.sh"
INSTALL_NAME="generate-cpp-project"
INSTALL_DIR="/usr/local/bin"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing C++ Project Generator...${NC}"

# Check if script exists
if [ ! -f "$SCRIPT_NAME" ]; then
    echo -e "${RED}Error: $SCRIPT_NAME not found in current directory${NC}"
    echo "Please run this script from the directory containing $SCRIPT_NAME"
    exit 1
fi

# Check if /usr/local/bin exists and is writable
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Creating $INSTALL_DIR directory...${NC}"
    sudo mkdir -p "$INSTALL_DIR"
fi

# Copy script to /usr/local/bin
echo -e "${YELLOW}Copying script to $INSTALL_DIR/$INSTALL_NAME...${NC}"
sudo cp "$SCRIPT_NAME" "$INSTALL_DIR/$INSTALL_NAME"

# Make it executable
echo -e "${YELLOW}Making script executable...${NC}"
sudo chmod +x "$INSTALL_DIR/$INSTALL_NAME"

# Check if /usr/local/bin is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "${YELLOW}Warning: $INSTALL_DIR is not in your PATH${NC}"
    echo ""
    echo "Add the following line to your shell profile:"
    echo "  ~/.bashrc (for Bash)"
    echo "  ~/.zshrc (for Zsh)"
    echo "  ~/.config/fish/config.fish (for Fish)"
    echo ""
    echo -e "${YELLOW}export PATH=\"$INSTALL_DIR:\$PATH\"${NC}"
    echo ""
    echo "Then reload your shell or run:"
    echo -e "${YELLOW}source ~/.bashrc${NC} (or ~/.zshrc, etc.)"
else
    echo -e "${GREEN}✅ $INSTALL_DIR is already in your PATH${NC}"
fi

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo "Usage:"
echo -e "  ${YELLOW}$INSTALL_NAME <project-name>${NC}"
echo ""
echo "Example:"
echo -e "  ${YELLOW}$INSTALL_NAME my-awesome-project${NC}"
echo ""

# Test if command is available
if command -v "$INSTALL_NAME" &> /dev/null; then
    echo -e "${GREEN}✅ Command '$INSTALL_NAME' is ready to use!${NC}"
else
    echo -e "${YELLOW}⚠️  You may need to reload your shell or update your PATH${NC}"
    echo "Try running: hash -r"
fi
