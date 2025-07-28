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

# Create enhanced CMakeLists.txt
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.14)

# Dynamically name the project after the folder
get_filename_component(PROJECT_NAME ${CMAKE_SOURCE_DIR} NAME)
project(${PROJECT_NAME} LANGUAGES CXX)

# Set default build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

# Enable compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Use modern C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Include local headers
include_directories(${CMAKE_SOURCE_DIR}/include)

# Gather all source files
file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS ${CMAKE_SOURCE_DIR}/src/*.cpp)

# Define the executable
add_executable(main ${SOURCES})

# Compiler-specific options
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_compile_options(main PRIVATE 
        -Wall -Wextra -Wpedantic
        $<$<CONFIG:Debug>:-g -O0>
        $<$<CONFIG:Release>:-O3 -DNDEBUG>
    )
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(main PRIVATE /W4)
endif()

# Set output directory
set_target_properties(main PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin
)

# Optional: link libraries from lib/
# link_directories(${CMAKE_SOURCE_DIR}/lib)
# target_link_libraries(main PRIVATE your_library_name)

# Optional: Enable testing
# enable_testing()
# add_subdirectory(tests)
EOF

# Create include/main.hpp
cat > include/main.hpp << 'EOF'
#pragma once

void hello();
EOF

# Create src/main.cpp
cat > src/main.cpp << 'EOF'
#include "main.hpp"
#include <cstdlib>
#include <iostream>

void hello() {
    std::cout << "Hello, World!" << std::endl;
}

int main() {
    hello();
    return EXIT_SUCCESS;
}
EOF

# Create build script
cat > scripts/build.sh << 'EOF'
#!/bin/bash
set -e

# Change to project root directory
cd "$(dirname "$0")/.."

# Create build directory if it doesn't exist
mkdir -p build

# Configure and build
echo "🔧 Configuring project..."
cmake -B build -S . -DCMAKE_BUILD_TYPE=Debug

echo "🔨 Building project..."
cmake --build build

echo "✅ Build complete! Run with: ./bin/main"
EOF
chmod +x scripts/build.sh

# Create format script
cat > scripts/format.sh << 'EOF'
#!/bin/bash

# Change to project root directory
cd "$(dirname "$0")/.."

echo "🎨 Formatting code..."
find src include tests -name "*.cpp" -o -name "*.hpp" 2>/dev/null | xargs clang-format -i 2>/dev/null || {
    echo "⚠️  clang-format not found. Install it to use code formatting."
    exit 1
}
echo "✅ Code formatting complete!"
EOF
chmod +x scripts/format.sh

# Create clean script
cat > scripts/clean.sh << 'EOF'
#!/bin/bash

# Change to project root directory
cd "$(dirname "$0")/.."

echo "🧹 Cleaning build artifacts..."
rm -rf build/* bin/* lib/*

# Recreate .gitkeep files
touch build/.gitkeep bin/.gitkeep lib/.gitkeep

echo "✅ Clean complete!"
EOF
chmod +x scripts/clean.sh

# Create cross-platform .clangd config
cat > .clangd << 'EOF'
CompileFlags:
  CompilationDatabase: build/
Index:
  Background: Build
Diagnostics:
  UnusedIncludes: Strict
  MissingIncludes: Strict
EOF

# Create Makefile for common operations
cat > Makefile << 'EOF'
# Project variables
PROJECT_NAME := $(shell basename $(CURDIR))
BUILD_DIR := build
BIN_DIR := bin
SRC_DIR := src
INCLUDE_DIR := include
TESTS_DIR := tests

# Build configurations
BUILD_TYPE ?= Debug
CMAKE_FLAGS := -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Default target
.PHONY: all
all: build

# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build       - Build the project (default)"
	@echo "  clean       - Clean build artifacts"
	@echo "  rebuild     - Clean and build"
	@echo "  run         - Build and run the main executable"
	@echo "  debug       - Build with debug info and run with GDB"
	@echo "  release     - Build optimized release version"
	@echo "  test        - Build and run tests"
	@echo "  format      - Format code with clang-format"
	@echo "  install     - Install to system (requires sudo)"
	@echo "  uninstall   - Remove from system (requires sudo)"
	@echo "  deps        - Show build dependencies"
	@echo "  help        - Show this help message"

# Build target
.PHONY: build
build: $(BUILD_DIR)/Makefile
	@echo "🔨 Building $(PROJECT_NAME)..."
	@cmake --build $(BUILD_DIR)
	@echo "✅ Build complete!"

# Configure CMake
$(BUILD_DIR)/Makefile:
	@echo "🔧 Configuring CMake..."
	@mkdir -p $(BUILD_DIR)
	@cmake -B $(BUILD_DIR) -S . $(CMAKE_FLAGS)

# Clean target
.PHONY: clean
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)/* $(BIN_DIR)/* lib/*
	@touch $(BUILD_DIR)/.gitkeep $(BIN_DIR)/.gitkeep lib/.gitkeep
	@echo "✅ Clean complete!"

# Rebuild target
.PHONY: rebuild
rebuild: clean build

# Run target
.PHONY: run
run: build
	@echo "🚀 Running $(PROJECT_NAME)..."
	@./$(BIN_DIR)/main

# Debug target
.PHONY: debug
debug: BUILD_TYPE = Debug
debug: build
	@echo "🐛 Running $(PROJECT_NAME) with GDB..."
	@gdb -q ./$(BIN_DIR)/main

# Release build
.PHONY: release
release: BUILD_TYPE = Release
release: clean build

# Test target
.PHONY: test
test: build
	@if [ -f $(BIN_DIR)/test_main ]; then \
		echo "🧪 Running tests..."; \
		./$(BIN_DIR)/test_main; \
	else \
		echo "⚠️  No tests found. Build test target first."; \
	fi

# Format target
.PHONY: format
format:
	@echo "🎨 Formatting code..."
	@if command -v clang-format >/dev/null 2>&1; then \
		find $(SRC_DIR) $(INCLUDE_DIR) $(TESTS_DIR) -name "*.cpp" -o -name "*.hpp" 2>/dev/null | xargs clang-format -i; \
		echo "✅ Code formatting complete!"; \
	else \
		echo "⚠️  clang-format not found. Install it to use code formatting."; \
		exit 1; \
	fi

# Install target
.PHONY: install
install: release
	@echo "📦 Installing $(PROJECT_NAME)..."
	@sudo cp $(BIN_DIR)/main /usr/local/bin/$(PROJECT_NAME)
	@sudo chmod +x /usr/local/bin/$(PROJECT_NAME)
	@echo "✅ Installed to /usr/local/bin/$(PROJECT_NAME)"

# Uninstall target
.PHONY: uninstall
uninstall:
	@echo "🗑️  Uninstalling $(PROJECT_NAME)..."
	@sudo rm -f /usr/local/bin/$(PROJECT_NAME)
	@echo "✅ Uninstalled from /usr/local/bin/$(PROJECT_NAME)"

# Show dependencies
.PHONY: deps
deps:
	@echo "📋 Build dependencies:"
	@echo "  - CMake 3.14+"
	@echo "  - C++20 compatible compiler"
	@echo "  - make"
	@echo ""
	@echo "Optional dependencies:"
	@echo "  - clang-format (for code formatting)"
	@echo "  - gdb (for debugging)"

# Check if tools are available
.PHONY: check
check:
	@echo "🔍 Checking build environment..."
	@command -v cmake >/dev/null 2>&1 && echo "✅ CMake found" || echo "❌ CMake not found"
	@command -v make >/dev/null 2>&1 && echo "✅ Make found" || echo "❌ Make not found"
	@command -v g++ >/dev/null 2>&1 && echo "✅ g++ found" || echo "❌ g++ not found"
	@command -v clang++ >/dev/null 2>&1 && echo "✅ clang++ found" || echo "❌ clang++ not found"
	@command -v clang-format >/dev/null 2>&1 && echo "✅ clang-format found" || echo "⚠️  clang-format not found (optional)"
	@command -v gdb >/dev/null 2>&1 && echo "✅ gdb found" || echo "⚠️  gdb not found (optional)"

# Watch for changes and rebuild (requires inotify-tools on Linux)
.PHONY: watch
watch:
	@if command -v inotifywait >/dev/null 2>&1; then \
		echo "👀 Watching for changes... (Ctrl+C to stop)"; \
		while true; do \
			inotifywait -q -r -e modify,create,delete $(SRC_DIR) $(INCLUDE_DIR) && \
			make build; \
		done; \
	else \
		echo "⚠️  inotifywait not found. Install inotify-tools for watch functionality."; \
	fi
EOF

# Create basic test file
cat > tests/test_main.cpp << 'EOF'
#include "../include/main.hpp"
#include <cassert>
#include <iostream>

int main() {
    std::cout << "Running tests..." << std::endl;
    
    // Add your tests here
    // Example: assert(some_function() == expected_value);
    
    std::cout << "✅ All tests passed!" << std::endl;
    return 0;
}
EOF

# Create README template
cat > README.md << EOF
# $1

Brief description of your project.

## Building

```bash
make build    # or just 'make'
```

## Running

```bash
make run
```

## Development

### Available Make Targets
```bash
make help       # Show all available commands
make build      # Build the project
make clean      # Clean build artifacts
make rebuild    # Clean and build
make run        # Build and run
make debug      # Build and run with GDB
make release    # Build optimized version
make test       # Build and run tests
make format     # Format code
make check      # Check build environment
make watch      # Watch for changes and auto-build
```

### Using Scripts Directly
```bash
./scripts/build.sh   # Build script
./scripts/format.sh  # Format code
./scripts/clean.sh   # Clean build
```

## Dependencies

- CMake 3.14+
- C++20 compatible compiler (GCC 10+, Clang 10+, MSVC 2019+)
- Optional: clang-format for code formatting

## Project Structure

\`\`\`
$1/
├── bin/           # Compiled executables
├── build/         # CMake build files
├── include/       # Header files
├── lib/           # External libraries
├── scripts/       # Build and utility scripts
├── src/           # Source files
├── tests/         # Test files
├── CMakeLists.txt # CMake configuration
└── README.md      # This file
\`\`\`
EOF

echo "✅ Project '$1' created successfully!"
echo ""
echo "Next steps:"
echo "  cd $1"
echo "  ./scripts/build.sh"
echo "  ./bin/main"
