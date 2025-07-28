#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <project-name>"
  exit 1
fi

# Create project folder structure
mkdir -p "$1"/{bin,build,include,lib,scripts,src}
cd "$1" || exit 1

# Create .gitignore
cat > .gitignore << 'EOF'
# Build artifacts
build/*
!build/.gitkeep
bin/*
!bin/.gitkeep
lib/*
!lib/.gitkeep

# Editor files
*.swp
*~

# OS-specific
.DS_Store
.cache/

# Generated
compile_commands.json
.clang_complete
EOF

# Create .gitkeep files to retain empty directories in Git
touch build/.gitkeep bin/.gitkeep lib/.gitkeep


# Create CMakeLists.txt
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.14)

# Dynamically name the project after the folder
get_filename_component(PROJECT_NAME \${CMAKE_SOURCE_DIR} NAME)
project(\${PROJECT_NAME} LANGUAGES CXX)

# Enable compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Use modern C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable verbose makefile
set(CMAKE_VERBOSE_MAKEFILE ON)

# Include local headers
include_directories(\${CMAKE_SOURCE_DIR}/include)

# Gather all source files
file(GLOB SOURCES CONFIGURE_DEPENDS \${CMAKE_SOURCE_DIR}/src/*.cpp)

# Define the executable
add_executable(main \${SOURCES})

# Set output directory
set_target_properties(main PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY \${CMAKE_SOURCE_DIR}/bin
)

# Optional: link libraries from lib/
# link_directories(\${CMAKE_SOURCE_DIR}/lib)
# target_link_libraries(main PRIVATE pdcurses)

# Optional: custom target to generate .clang_complete
add_custom_target(
  generate_clang_complete
  COMMAND python \${CMAKE_SOURCE_DIR}/scripts/cc_args.py \${CMAKE_BINARY_DIR}/compile_commands.json > \${CMAKE_SOURCE_DIR}/.clang_complete
  DEPENDS \${CMAKE_BINARY_DIR}/compile_commands.json
)
EOF

# Create include/main.hpp
cat > include/main.hpp << 'EOF'
#pragma once

#include <iostream>
#include <cstdlib>

void hello();
EOF

# Create src/main.cpp
cat > src/main.cpp << 'EOF'
#include "main.hpp"

void hello() {
    std::cout << "Hello, World!" << std::endl;
}

int main() {
    hello();
    return EXIT_SUCCESS;
}
EOF

# Create scripts/cc_args.py (placeholder script)
cat > scripts/cc_args.py << 'EOF'
#!/usr/bin/env python
import sys

if len(sys.argv) < 2:
    sys.exit("Usage: cc_args.py <compile_commands.json>")

with open(sys.argv[1], 'r') as f:
    print(f.read())
EOF

chmod +x scripts/cc_args.py

# Linux-specific: generate .clangd config
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  cat > .clangd << 'EOF'
CompileFlags:
  Add: [
    "-I/usr/lib/gcc/x86_64-linux-gnu/13/include",
    "-I/usr/lib/gcc/x86_64-linux-gnu/13/include-fixed",
    "-I/usr/include/c++/13",
    "-I/usr/include/x86_64-linux-gnu/c++/13",
    "-I/usr/local/include",
    "-I/usr/include/x86_64-linux-gnu",
    "-I/usr/include"
  ]
EOF
fi

echo "✅ Project '$1' created successfully."
