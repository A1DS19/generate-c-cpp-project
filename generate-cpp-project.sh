#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <project-name>"
  exit 1
fi

# Create project folder structure
mkdir -p "$1"/{bin,build,include,lib,scripts,src,tests}
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

# CMake
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
Makefile

# Compiled objects
*.o
*.obj
*.exe
*.out
*.app

# Editor files
*.swp
*~
.vscode/
.idea/
*.vcxproj*
*.sln

# OS-specific
.DS_Store
Thumbs.db
.cache/

# Generated
compile_commands.json
.clang_complete
EOF

# Create .gitkeep files to retain empty directories in Git
touch build/.gitkeep bin/.gitkeep lib/.gitkeep

# Create enhanced CMakeLists.txt with modern C++23 features
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.25)

# Dynamically name the project after the folder
get_filename_component(PROJECT_NAME ${CMAKE_SOURCE_DIR} NAME)
project(${PROJECT_NAME} 
    VERSION 1.0.0
    DESCRIPTION "Modern C++ Project"
    LANGUAGES CXX
)

# Set default build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

# Enable compile_commands.json for LSP support
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Modern C++ standard (change to 20 if C++23 is not available)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Compiler-specific options
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_compile_options(
        -Wall -Wextra -Wpedantic
        -Wconversion -Wsign-conversion
        -Wunused -Wuninitialized
        -Wshadow -Wformat=2
    )
    
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        add_compile_options(-g -O0 -fsanitize=address,undefined)
        add_link_options(-fsanitize=address,undefined)
    else()
        add_compile_options(-O3 -DNDEBUG)
    endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    add_compile_options(
        -Wall -Wextra -Wpedantic
        -Wconversion -Wsign-conversion
        -Wunused -Wuninitialized
        -Wshadow -Wformat=2
    )
    
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        add_compile_options(-g -O0 -fsanitize=address,undefined)
        add_link_options(-fsanitize=address,undefined)
    else()
        add_compile_options(-O3 -DNDEBUG)
    endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    add_compile_options(/W4 /permissive-)
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        add_compile_options(/Od /RTC1)
    else()
        add_compile_options(/O2 /DNDEBUG)
    endif()
endif()

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/include)

# Gather all source files
file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS 
    ${CMAKE_SOURCE_DIR}/src/*.cpp
    ${CMAKE_SOURCE_DIR}/src/*.cxx
)

file(GLOB_RECURSE HEADERS CONFIGURE_DEPENDS
    ${CMAKE_SOURCE_DIR}/include/*.hpp
    ${CMAKE_SOURCE_DIR}/include/*.h
)

# Define the executable
add_executable(main ${SOURCES} ${HEADERS})

# Target-specific properties
set_target_properties(main PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin
    CXX_STANDARD 23
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
)

# Platform-specific configurations
if(WIN32)
    target_compile_definitions(main PRIVATE WIN32_LEAN_AND_MEAN)
elseif(APPLE)
    # macOS-specific settings
    set_target_properties(main PROPERTIES
        MACOSX_RPATH TRUE
    )
elseif(UNIX)
    # Linux-specific settings
    target_link_libraries(main PRIVATE dl)
endif()

# Copy compile_commands.json to project root for LSP
if(EXISTS ${CMAKE_BINARY_DIR}/compile_commands.json)
    add_custom_command(
        TARGET main POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_BINARY_DIR}/compile_commands.json
            ${CMAKE_SOURCE_DIR}/compile_commands.json
        COMMENT "Copying compile_commands.json to project root"
    )
endif()

# Optional: Enable testing
option(BUILD_TESTS "Build tests" OFF)
if(BUILD_TESTS)
    enable_testing()
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tests)
        file(GLOB_RECURSE TEST_SOURCES CONFIGURE_DEPENDS 
            ${CMAKE_SOURCE_DIR}/tests/*.cpp
        )
        add_executable(test_main ${TEST_SOURCES})
        target_include_directories(test_main PRIVATE ${CMAKE_SOURCE_DIR}/include)
        set_target_properties(test_main PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin
        )
        add_test(NAME unit_tests COMMAND test_main)
    endif()
endif()

# Development target for setup
add_custom_target(dev-setup
    COMMAND ${CMAKE_COMMAND} -E echo "Setting up development environment..."
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_BINARY_DIR}/compile_commands.json
        ${CMAKE_SOURCE_DIR}/compile_commands.json
    COMMENT "Development setup complete"
)

# Print configuration summary
message(STATUS "")
message(STATUS "Configuration Summary:")
message(STATUS "  Project Name:     ${PROJECT_NAME}")
message(STATUS "  Build Type:       ${CMAKE_BUILD_TYPE}")
message(STATUS "  C++ Standard:     ${CMAKE_CXX_STANDARD}")
message(STATUS "  Compiler:         ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "  Source Directory: ${CMAKE_SOURCE_DIR}")
message(STATUS "  Binary Directory: ${CMAKE_BINARY_DIR}")
message(STATUS "")
EOF

# Create include/main.hpp
cat > include/main.hpp << 'EOF'
#pragma once

#include <string_view>

void hello();
void greet(std::string_view name);
EOF

# Create src/main.cpp with modern C++23 features
cat > src/main.cpp << 'EOF'
#include "main.hpp"

#include <cstdlib>
#include <iostream>
#include <string_view>
#include <format>  // C++23 feature

void hello() {
    std::cout << "Hello, World!" << std::endl;
}

void greet(std::string_view name) {
    // Using C++23 std::format if available, fallback to iostream
    #ifdef __cpp_lib_format
    std::cout << std::format("Hello, {}!\n", name);
    #else
    std::cout << "Hello, " << name << "!" << std::endl;
    #endif
}

auto main() -> int {
    hello();
    greet("Modern C++");
    return EXIT_SUCCESS;
}
EOF

# Create cross-platform build script
cat > scripts/build.sh << 'EOF'
#!/bin/bash
set -e

# Change to project root directory
cd "$(dirname "$0")/.."

# Detect platform
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    PLATFORM="Windows"
    CMAKE_GENERATOR="Visual Studio 17 2022"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macOS"
    CMAKE_GENERATOR="Unix Makefiles"
else
    PLATFORM="Linux"
    CMAKE_GENERATOR="Unix Makefiles"
fi

echo "🔧 Configuring project for $PLATFORM..."

# Create build directory if it doesn't exist
mkdir -p build

# Configure CMake
if [[ "$PLATFORM" == "Windows" ]]; then
    cmake -B build -S . -G "$CMAKE_GENERATOR" -DCMAKE_BUILD_TYPE=Debug
else
    cmake -B build -S . -G "$CMAKE_GENERATOR" -DCMAKE_BUILD_TYPE=Debug
fi

echo "🔨 Building project..."
cmake --build build --config Debug

echo "✅ Build complete! Run with:"
if [[ "$PLATFORM" == "Windows" ]]; then
    echo "  .\\bin\\main.exe"
else
    echo "  ./bin/main"
fi
EOF

# Make build script executable on Unix-like systems
if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
    chmod +x scripts/build.sh
fi

# Create cross-platform format script
cat > scripts/format.sh << 'EOF'
#!/bin/bash

# Change to project root directory
cd "$(dirname "$0")/.."

echo "🎨 Formatting code..."

# Find clang-format
CLANG_FORMAT=""
if command -v clang-format >/dev/null 2>&1; then
    CLANG_FORMAT="clang-format"
elif command -v clang-format-15 >/dev/null 2>&1; then
    CLANG_FORMAT="clang-format-15"
elif command -v clang-format-14 >/dev/null 2>&1; then
    CLANG_FORMAT="clang-format-14"
else
    echo "⚠️  clang-format not found. Install it to use code formatting."
    exit 1
fi

# Format files
find src include tests -name "*.cpp" -o -name "*.hpp" -o -name "*.h" -o -name "*.cxx" 2>/dev/null | \
    xargs "$CLANG_FORMAT" -i 2>/dev/null

echo "✅ Code formatting complete!"
EOF

if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
    chmod +x scripts/format.sh
fi

# Create cross-platform clean script
cat > scripts/clean.sh << 'EOF'
#!/bin/bash

# Change to project root directory
cd "$(dirname "$0")/.."

echo "🧹 Cleaning build artifacts..."

# Remove build artifacts
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows
    if [ -d "build" ]; then
        rm -rf build/*
    fi
    if [ -d "bin" ]; then
        rm -rf bin/*
    fi
    if [ -d "lib" ]; then
        rm -rf lib/*
    fi
else
    # Unix-like systems
    rm -rf build/* bin/* lib/*
fi

# Recreate .gitkeep files
touch build/.gitkeep bin/.gitkeep lib/.gitkeep

# Remove compile_commands.json from root
rm -f compile_commands.json

echo "✅ Clean complete!"
EOF

if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
    chmod +x scripts/clean.sh
fi

# Create platform-aware .clangd config with auto-detection
cat > scripts/setup_clangd.sh << 'EOF'
#!/bin/bash

# Change to project root directory
cd "$(dirname "$0")/.."

echo "🔧 Setting up clangd configuration..."

# Detect compiler and paths
if command -v g++ >/dev/null 2>&1; then
    GCC_VERSION=$(g++ -dumpversion | cut -d. -f1)
    COMPILER="g++"
elif command -v clang++ >/dev/null 2>&1; then
    CLANG_VERSION=$(clang++ --version | head -n1 | sed 's/.*version \([0-9]*\).*/\1/')
    COMPILER="clang++"
else
    echo "⚠️  No suitable C++ compiler found"
    exit 1
fi

# Platform-specific configuration
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows with MSYS2/Cygwin
    cat > .clangd << 'CLANGD_EOF'
CompileFlags:
  Add:
    - -std=c++23
    - -Wall
    - -Wextra
  Compiler: g++

Index:
  Background: Build

Diagnostics:
  UnusedIncludes: Strict
  MissingIncludes: Strict

InlayHints:
  Enabled: true
  ParameterNames: true
  DeducedTypes: true
CLANGD_EOF

elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    cat > .clangd << 'CLANGD_EOF'
CompileFlags:
  Add:
    - -std=c++23
    - -Wall
    - -Wextra
    - -I/usr/local/include
    - -I/opt/homebrew/include
  Compiler: clang++

Index:
  Background: Build

Diagnostics:
  UnusedIncludes: Strict
  MissingIncludes: Strict

InlayHints:
  Enabled: true
  ParameterNames: true
  DeducedTypes: true
CLANGD_EOF

else
    # Linux - detect architecture and GCC paths
    ARCH=$(dpkg --print-architecture 2>/dev/null || echo "x86_64")
    if [ "$ARCH" = "amd64" ]; then
        ARCH="x86_64"
    fi
    
    cat > .clangd << CLANGD_EOF
CompileFlags:
  Add:
    - -std=c++23
    - -Wall
    - -Wextra
    - -I/usr/include/c++/${GCC_VERSION}
    - -I/usr/include/${ARCH}-linux-gnu/c++/${GCC_VERSION}
    - -I/usr/include/c++/${GCC_VERSION}/backward
  Remove:
    - -W*
  Compiler: ${COMPILER}

Index:
  Background: Build

Diagnostics:
  UnusedIncludes: Strict
  MissingIncludes: Strict
  ClangTidy:
    Add:
      - modernize-*
      - performance-*
      - readability-*
    Remove:
      - modernize-use-trailing-return-type

InlayHints:
  Enabled: true
  ParameterNames: true
  DeducedTypes: true
  Designators: true

Hover:
  ShowAKA: true
CLANGD_EOF
fi

echo "✅ clangd configuration created for $OSTYPE with $COMPILER"
EOF

if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
    chmod +x scripts/setup_clangd.sh
fi

# Create enhanced cross-platform Makefile
cat > Makefile << 'EOF'
# Project variables
PROJECT_NAME := $(shell basename $(CURDIR))
BUILD_DIR := build
BIN_DIR := bin
SRC_DIR := src
INCLUDE_DIR := include
TESTS_DIR := tests

# Detect platform
ifeq ($(OS),Windows_NT)
    PLATFORM := Windows
    EXECUTABLE_EXT := .exe
    CMAKE_GENERATOR := "Visual Studio 17 2022"
    RM := del /Q
    MKDIR := mkdir
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        PLATFORM := Linux
        EXECUTABLE_EXT :=
        CMAKE_GENERATOR := "Unix Makefiles"
    endif
    ifeq ($(UNAME_S),Darwin)
        PLATFORM := macOS
        EXECUTABLE_EXT :=
        CMAKE_GENERATOR := "Unix Makefiles"
    endif
    RM := rm -rf
    MKDIR := mkdir -p
endif

# Build configurations
BUILD_TYPE ?= Debug
CMAKE_FLAGS := -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Default target
.PHONY: all
all: build

# Help target
.PHONY: help
help:
	@echo "Available targets for $(PLATFORM):"
	@echo "  build       - Build the project (default)"
	@echo "  clean       - Clean build artifacts"
	@echo "  rebuild     - Clean and build"
	@echo "  run         - Build and run the main executable"
	@echo "  debug       - Build with debug info and run with debugger"
	@echo "  release     - Build optimized release version"
	@echo "  test        - Build and run tests"
	@echo "  format      - Format code with clang-format"
	@echo "  setup-lsp   - Setup clangd configuration"
	@echo "  check       - Check build environment"
	@echo "  help        - Show this help message"

# Build target
.PHONY: build
build: $(BUILD_DIR)/Makefile
	@echo "🔨 Building $(PROJECT_NAME) for $(PLATFORM)..."
	@cmake --build $(BUILD_DIR) --config $(BUILD_TYPE)
	@echo "✅ Build complete!"

# Configure CMake
$(BUILD_DIR)/Makefile:
	@echo "🔧 Configuring CMake for $(PLATFORM)..."
	@$(MKDIR) $(BUILD_DIR)
	@cmake -B $(BUILD_DIR) -S . -G $(CMAKE_GENERATOR) $(CMAKE_FLAGS)

# Clean target
.PHONY: clean
clean:
	@echo "🧹 Cleaning build artifacts..."
ifeq ($(PLATFORM),Windows)
	@if exist $(BUILD_DIR) $(RM) $(BUILD_DIR)\*
	@if exist $(BIN_DIR) $(RM) $(BIN_DIR)\*
	@if exist lib $(RM) lib\*
else
	@$(RM) $(BUILD_DIR)/* $(BIN_DIR)/* lib/* 2>/dev/null || true
	@touch $(BUILD_DIR)/.gitkeep $(BIN_DIR)/.gitkeep lib/.gitkeep
endif
	@echo "✅ Clean complete!"

# Rebuild target
.PHONY: rebuild
rebuild: clean build

# Run target
.PHONY: run
run: build
	@echo "🚀 Running $(PROJECT_NAME)..."
ifeq ($(PLATFORM),Windows)
	@$(BIN_DIR)\main$(EXECUTABLE_EXT)
else
	@./$(BIN_DIR)/main$(EXECUTABLE_EXT)
endif

# Debug target
.PHONY: debug
debug: BUILD_TYPE = Debug
debug: build
	@echo "🐛 Running $(PROJECT_NAME) with debugger..."
ifeq ($(PLATFORM),Windows)
	@echo "Start debugging in Visual Studio or use windbg"
	@$(BIN_DIR)\main$(EXECUTABLE_EXT)
else ifeq ($(PLATFORM),macOS)
	@lldb ./$(BIN_DIR)/main$(EXECUTABLE_EXT)
else
	@gdb -q ./$(BIN_DIR)/main$(EXECUTABLE_EXT)
endif

# Release build
.PHONY: release
release: BUILD_TYPE = Release
release: clean build

# Test target
.PHONY: test
test: build
	@echo "🧪 Building and running tests..."
	@cmake --build $(BUILD_DIR) --target test_main --config $(BUILD_TYPE) 2>/dev/null || echo "⚠️  No tests configured"
ifeq ($(PLATFORM),Windows)
	@if exist $(BIN_DIR)\test_main$(EXECUTABLE_EXT) $(BIN_DIR)\test_main$(EXECUTABLE_EXT)
else
	@if [ -f $(BIN_DIR)/test_main$(EXECUTABLE_EXT) ]; then ./$(BIN_DIR)/test_main$(EXECUTABLE_EXT); fi
endif

# Format target
.PHONY: format
format:
	@echo "🎨 Formatting code..."
	@bash scripts/format.sh 2>/dev/null || echo "⚠️  Format script failed. Check clang-format installation."

# Setup LSP target
.PHONY: setup-lsp
setup-lsp:
	@echo "🔧 Setting up LSP configuration..."
	@bash scripts/setup_clangd.sh

# Check build environment
.PHONY: check
check:
	@echo "🔍 Checking build environment for $(PLATFORM)..."
	@command -v cmake >/dev/null 2>&1 && echo "✅ CMake found" || echo "❌ CMake not found"
	@command -v make >/dev/null 2>&1 && echo "✅ Make found" || echo "❌ Make not found"
ifeq ($(PLATFORM),Windows)
	@where cl >nul 2>&1 && echo "✅ MSVC found" || echo "⚠️  MSVC not found"
	@where g++ >nul 2>&1 && echo "✅ g++ found" || echo "⚠️  g++ not found"
else
	@command -v g++ >/dev/null 2>&1 && echo "✅ g++ found" || echo "❌ g++ not found"
	@command -v clang++ >/dev/null 2>&1 && echo "✅ clang++ found" || echo "⚠️  clang++ not found"
endif
	@command -v clang-format >/dev/null 2>&1 && echo "✅ clang-format found" || echo "⚠️  clang-format not found (optional)"
EOF

# Create basic test file with modern C++
cat > tests/test_main.cpp << 'EOF'
#include "../include/main.hpp"

#include <cassert>
#include <iostream>
#include <string_view>

// Simple test function
void test_hello() {
    // Test that hello() doesn't crash
    hello();
    std::cout << "✓ hello() test passed" << std::endl;
}

void test_greet() {
    // Test that greet() doesn't crash
    greet("Test");
    std::cout << "✓ greet() test passed" << std::endl;
}

auto main() -> int {
    std::cout << "Running tests..." << std::endl;
    
    test_hello();
    test_greet();
    
    std::cout << "✅ All tests passed!" << std::endl;
    return 0;
}
EOF

# Create enhanced README template
cat > README.md << EOF
# $1

Brief description of your project using modern C++23.

## Features

- Modern C++23 features
- Cross-platform support (Windows, macOS, Linux)
- CMake build system
- Automated LSP setup for development
- Code formatting with clang-format
- Unit testing framework ready

## Quick Start

### Prerequisites

- CMake 3.25+
- C++23 compatible compiler:
  - GCC 13+ (Linux/Windows)
  - Clang 15+ (macOS/Linux)
  - MSVC 2022 (Windows)

### Building

\`\`\`bash
# Clone and enter project
cd $1

# Setup LSP for your editor (recommended)
make setup-lsp

# Build the project
make build    # or just 'make'

# Run the executable
make run
\`\`\`

## Development

### Available Make Targets
\`\`\`bash
make help       # Show all available commands
make build      # Build the project
make clean      # Clean build artifacts
make rebuild    # Clean and build
make run        # Build and run
make debug      # Build and run with debugger
make release    # Build optimized version
make test       # Build and run tests
make format     # Format code with clang-format
make setup-lsp  # Setup clangd configuration
make check      # Check build environment
\`\`\`

### Using Scripts Directly
\`\`\`bash
./scripts/build.sh        # Cross-platform build script
./scripts/format.sh       # Format code
./scripts/clean.sh        # Clean build
./scripts/setup_clangd.sh # Setup LSP configuration
\`\`\`

## Platform-Specific Notes

### Linux (Ubuntu 24.04+)
\`\`\`bash
# Install dependencies
sudo apt update
sudo apt install build-essential cmake g++-13 clang-format

# For debugging
sudo apt install gdb
\`\`\`

### macOS
\`\`\`bash
# Install via Homebrew
brew install cmake llvm clang-format

# Xcode Command Line Tools
xcode-select --install
\`\`\`

### Windows
- Install Visual Studio 2022 with C++ workload
- Or install MSYS2/MinGW-w64 for GCC
- Install CMake from cmake.org

## Project Structure

\`\`\`
$1/
├── bin/               # Compiled executables
├── build/             # CMake build files
├── include/           # Header files (.hpp, .h)
├── lib/               # External libraries
├── scripts/           # Build and utility scripts
│   ├── build.sh       # Cross-platform build
│   ├── format.sh      # Code formatting
│   ├── clean.sh       # Clean build artifacts
│   └── setup_clangd.sh # LSP configuration
├── src/               # Source files (.cpp, .cxx)
├── tests/             # Test files
├── .clangd            # LSP configuration (auto-generated)
├── CMakeLists.txt     # CMake configuration
├── Makefile           # Cross-platform make targets
└── README.md          # This file
\`\`\`

## Modern C++ Features Used

- C++23 standard library features
- Auto return type deduction
- String views for efficient string handling
- Modern formatting with std::format (when available)
- Range-based for loops
- Smart pointers and RAII

## Editor Setup

### LunarVim / Neovim
1. Run \`make setup-lsp\` to configure clangd
2. LSP should work automatically with proper IntelliSense

### VS Code
1. Install C/C++ extension
2. Run \`make setup-lsp\`
3. Open workspace, IntelliSense should work

### CLion / Other IDEs
- Import as CMake project
- Build configuration should be detected automatically

## Contributing

1. Format code before committing: \`make format\`
2. Run tests: \`make test\`
3. Check build on multiple platforms if possible

## License

[Add your license here]
EOF

# Run the clangd setup script
echo "🔧 Setting up clangd configuration..."
bash scripts/setup_clangd.sh

echo "✅ Project '$1' created successfully with modern C++23 features!"
echo ""
echo "🚀 Next steps:"
echo "  cd $1"
echo "  make setup-lsp    # Setup LSP for your editor"
echo "  make build        # Build the project"
echo "  make run          # Run the executable"
echo ""
echo "📚 Run 'make help' to see all available commands"
