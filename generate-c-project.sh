#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <project-name>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/c/gitignore.sh"
source "${SCRIPT_DIR}/lib/c/cmake.sh"
source "${SCRIPT_DIR}/lib/c/clangd.sh"
source "${SCRIPT_DIR}/lib/c/clang_format.sh"
source "${SCRIPT_DIR}/lib/c/sources.sh"
source "${SCRIPT_DIR}/lib/c/project_scripts.sh"
source "${SCRIPT_DIR}/lib/c/makefile.sh"
source "${SCRIPT_DIR}/lib/c/readme.sh"

create_structure "$1"
cd "$1" || exit 1

create_gitignore
create_cmake
create_clangd
create_clang_format
create_sources
create_project_scripts
create_makefile
create_readme "$1"

echo "C project '$1' created successfully!"
echo ""
echo "Next steps:"
echo "  cd $1"
echo "  make check        # Verify build environment"
echo "  make build        # Build the project"
echo "  make run          # Run the executable"
echo "  make test         # Run tests"
echo ""
echo "Run 'make help' to see all available commands."
