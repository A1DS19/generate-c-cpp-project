#!/bin/bash

# Installation script for generate-c-project

INSTALL_NAME="generate-c-project"
INSTALL_DIR="/usr/local/bin"
LIB_DIR="/usr/local/share/generate-c-cpp-project"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Installing C Project Generator...${NC}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -f "${SCRIPT_DIR}/generate-c-project.sh" ]; then
  echo -e "${RED}Error: generate-c-project.sh not found in ${SCRIPT_DIR}${NC}"
  exit 1
fi

if [ ! -d "${SCRIPT_DIR}/lib" ]; then
  echo -e "${RED}Error: lib/ directory not found in ${SCRIPT_DIR}${NC}"
  exit 1
fi

echo -e "${YELLOW}Installing library files to ${LIB_DIR}...${NC}"
sudo mkdir -p "${LIB_DIR}"
sudo cp -r "${SCRIPT_DIR}/lib" "${LIB_DIR}/"
sudo cp "${SCRIPT_DIR}/generate-c-project.sh" "${LIB_DIR}/"

echo -e "${YELLOW}Creating command in ${INSTALL_DIR}/${INSTALL_NAME}...${NC}"
sudo tee "${INSTALL_DIR}/${INSTALL_NAME}" >/dev/null <<EOF
#!/bin/bash
exec "${LIB_DIR}/generate-c-project.sh" "\$@"
EOF
sudo chmod +x "${INSTALL_DIR}/${INSTALL_NAME}"

if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
  echo -e "${YELLOW}Warning: ${INSTALL_DIR} is not in your PATH${NC}"
  echo "Add it to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
  echo -e "  ${YELLOW}export PATH=\"${INSTALL_DIR}:\$PATH\"${NC}"
else
  echo -e "${GREEN}${INSTALL_DIR} is already in your PATH${NC}"
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Usage:"
echo -e "  ${YELLOW}${INSTALL_NAME} <project-name>${NC}"
echo ""

if command -v "${INSTALL_NAME}" &>/dev/null; then
  echo -e "${GREEN}Command '${INSTALL_NAME}' is ready to use!${NC}"
else
  echo -e "${YELLOW}You may need to reload your shell: source ~/.zshrc${NC}"
fi
