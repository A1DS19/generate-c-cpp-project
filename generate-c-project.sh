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
*.so
*.dylib
*.dll
*.a

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

# Coverage and profiling
*.gcno
*.gcda
*.gcov
coverage/
*.profraw
*.profdata

# Analysis results
analysis-results/
valgrind-report.log
EOF

# Create .gitkeep files to retain empty directories in Git
touch build/.gitkeep bin/.gitkeep lib/.gitkeep

# Enhanced CMakeLists.txt with FIXED test building
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.14)

# Dynamically name the project after the folder
get_filename_component(PROJECT_NAME ${CMAKE_SOURCE_DIR} NAME)
project(${PROJECT_NAME} 
    VERSION 1.0.0
    DESCRIPTION "Modern C Project"
    LANGUAGES C
)

# Set default build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

# Enable compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Use modern C standard (C23 is now available with GCC 13+)
set(CMAKE_C_STANDARD 23)  # or 17 for wider compatibility
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

# Platform-specific settings
if(WIN32)
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
elseif(UNIX AND NOT APPLE)
    add_compile_definitions(_GNU_SOURCE)
endif()

# Include local headers
include_directories(${CMAKE_SOURCE_DIR}/include)

# Gather all source files
file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS ${CMAKE_SOURCE_DIR}/src/*.c)
file(GLOB_RECURSE HEADERS CONFIGURE_DEPENDS ${CMAKE_SOURCE_DIR}/include/*.h)

# Define the executable
add_executable(main ${SOURCES} ${HEADERS})

# Enhanced compiler-specific options
if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    target_compile_options(main PRIVATE 
        -Wall -Wextra -Wpedantic -Wstrict-prototypes
        -Wconversion -Wsign-conversion -Wcast-align
        -Wwrite-strings -Wpointer-arith -Winit-self
        -Wvla -Wdeclaration-after-statement
        -Wundef -Wshadow -Wstrict-overflow=5
        $<$<CONFIG:Debug>:-g3 -O0 -DDEBUG -fstack-protector-strong>
        $<$<CONFIG:Release>:-O3 -DNDEBUG -march=native>
    )
    # AddressSanitizer for debug builds
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        target_compile_options(main PRIVATE -fsanitize=address,undefined)
        target_link_options(main PRIVATE -fsanitize=address,undefined)
    endif()
elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
    target_compile_options(main PRIVATE 
        -Wall -Wextra -Wpedantic -Wstrict-prototypes
        -Wconversion -Wsign-conversion -Wcast-align
        -Wwrite-strings -Wpointer-arith -Winit-self
        -Wvla -Wdeclaration-after-statement
        -Wundef -Wshadow
        $<$<CONFIG:Debug>:-g3 -O0 -DDEBUG>
        $<$<CONFIG:Release>:-O3 -DNDEBUG>
    )
elseif(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(main PRIVATE 
        /W4 /permissive- /analyze
        $<$<CONFIG:Debug>:/Od /RTC1 /DDEBUG>
        $<$<CONFIG:Release>:/O2 /DNDEBUG>
    )
endif()

# Set output directory
set_target_properties(main PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin
)

# Link required libraries
find_package(Threads REQUIRED)
target_link_libraries(main PRIVATE Threads::Threads)

# Link math library on Unix systems
if(UNIX)
    target_link_libraries(main PRIVATE m)
endif()

# Copy compile_commands.json to root for LSP
add_custom_command(
    TARGET main POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_BINARY_DIR}/compile_commands.json
        ${CMAKE_SOURCE_DIR}/compile_commands.json
    COMMENT "Copying compile_commands.json to project root"
)

# Testing support - FIXED VERSION
option(BUILD_TESTS "Build tests" OFF)
if(BUILD_TESTS OR CMAKE_BUILD_TYPE STREQUAL "Debug")
    enable_testing()
    
    # Build test executable if tests exist
    file(GLOB TEST_SOURCES ${CMAKE_SOURCE_DIR}/tests/*.c)
    if(TEST_SOURCES)
        # First, create a library from all non-main source files
        file(GLOB_RECURSE LIB_SOURCES ${CMAKE_SOURCE_DIR}/src/*.c)
        
        # Remove main.c from library sources (using absolute path)
        set(MAIN_SOURCE "${CMAKE_SOURCE_DIR}/src/main.c")
        list(REMOVE_ITEM LIB_SOURCES ${MAIN_SOURCE})
        
        # Debug: Print what sources we found
        message(STATUS "Library sources for tests: ${LIB_SOURCES}")
        message(STATUS "Test sources: ${TEST_SOURCES}")
        
        # Create test executable
        if(LIB_SOURCES)
            # If we have library sources (functions), create library first
            add_library(${PROJECT_NAME}_lib STATIC ${LIB_SOURCES} ${HEADERS})
            target_include_directories(${PROJECT_NAME}_lib PUBLIC ${CMAKE_SOURCE_DIR}/include)
            target_link_libraries(${PROJECT_NAME}_lib PUBLIC m Threads::Threads)
            
            # Apply same compiler options to library
            if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
                target_compile_options(${PROJECT_NAME}_lib PRIVATE 
                    -Wall -Wextra -Wpedantic -Wstrict-prototypes
                    -Wconversion -Wsign-conversion -Wcast-align
                    -Wwrite-strings -Wpointer-arith -Winit-self
                    -Wvla -Wdeclaration-after-statement
                    -Wundef -Wshadow -Wstrict-overflow=5
                    $<$<CONFIG:Debug>:-g3 -O0 -DDEBUG -fstack-protector-strong>
                    $<$<CONFIG:Release>:-O3 -DNDEBUG -march=native>
                )
            endif()
            
            # Create test executable linking to library
            add_executable(test_main ${TEST_SOURCES})
            target_include_directories(test_main PRIVATE ${CMAKE_SOURCE_DIR}/include)
            target_link_libraries(test_main PRIVATE ${PROJECT_NAME}_lib)
        else()
            # If no library sources, just compile test with all sources except main.c
            message(STATUS "No library sources found, compiling tests directly")
            add_executable(test_main ${TEST_SOURCES})
            target_include_directories(test_main PRIVATE ${CMAKE_SOURCE_DIR}/include)
            target_link_libraries(test_main PRIVATE m Threads::Threads)
        endif()
        
        # Set test executable properties
        set_target_properties(test_main PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin
        )
        
        # Add test
        add_test(NAME unit_tests COMMAND test_main)
    else()
        message(STATUS "No test sources found in tests/ directory")
    endif()
endif()

# Print configuration summary
message(STATUS "")
message(STATUS "Configuration Summary:")
message(STATUS "  Project Name:     ${PROJECT_NAME}")
message(STATUS "  Build Type:       ${CMAKE_BUILD_TYPE}")
message(STATUS "  C Standard:       ${CMAKE_C_STANDARD}")
message(STATUS "  Compiler:         ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}")
message(STATUS "  Source Directory: ${CMAKE_SOURCE_DIR}")
message(STATUS "  Binary Directory: ${CMAKE_BINARY_DIR}")
message(STATUS "")
EOF
cat > .clangd << 'EOF'
CompileFlags:
  Add:
    - -std=c23  # or c17 for compatibility
    - -Wall
    - -Wextra
    - -Wpedantic
    - -Wstrict-prototypes
  Compiler: gcc  # or clang

Index:
  Background: Build

Diagnostics:
  UnusedIncludes: Strict
  MissingIncludes: Strict
  ClangTidy:
    Add:
      - readability-*
      - bugprone-*
      - cert-*
      - misc-*
    Remove:
      - readability-magic-numbers
      - cert-dcl37-c

Hover:
  ShowAKA: true
EOF

# Enhanced main.h with better C practices
cat > include/main.h << 'EOF'
#ifndef MAIN_H
#define MAIN_H

#include <stddef.h>  /* For size_t */
#include <stdbool.h> /* For bool (C99+) */

/* Function prototypes */
void hello(void);
void greet(const char *name);

/* Utility functions */
bool is_valid_string(const char *str);
size_t safe_strlen(const char *str);

/* Constants */
#define MAX_NAME_LENGTH 256

#endif /* MAIN_H */
EOF

# Create main.c with ONLY main function
cat > src/main.c << 'EOF'
#include "main.h"

#include <stdio.h>
#include <stdlib.h>

int main(void) {
    hello();
    greet("Modern C");
    
    /* Demonstrate error handling */
    greet(NULL);  /* This will show error message */
    greet("");    /* This will also show error message */
    
    return EXIT_SUCCESS;
}
EOF

# Create utils.c with all utility functions
cat > src/utils.c << 'EOF'
#include "main.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void hello(void) {
    puts("Hello, World!");  /* puts is safer than printf for simple strings */
}

void greet(const char *name) {
    if (!is_valid_string(name)) {
        fprintf(stderr, "Error: Invalid name provided\n");
        return;
    }
    
    printf("Hello, %s!\n", name);
}

bool is_valid_string(const char *str) {
    return str != NULL && strlen(str) > 0;
}

size_t safe_strlen(const char *str) {
    return str ? strlen(str) : 0;
}
EOF

# Enhanced test file with better testing practices
cat > tests/test_main.c << 'EOF'
#include "../include/main.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

/* Simple test framework macros */
#define ASSERT_TRUE(expr) do { \
    if (!(expr)) { \
        fprintf(stderr, "FAIL: %s at %s:%d\n", #expr, __FILE__, __LINE__); \
        exit(EXIT_FAILURE); \
    } \
} while(0)

#define ASSERT_FALSE(expr) ASSERT_TRUE(!(expr))
#define ASSERT_EQ(a, b) ASSERT_TRUE((a) == (b))

/* Test functions */
static void test_is_valid_string(void) {
    printf("Testing is_valid_string... ");
    
    ASSERT_TRUE(is_valid_string("hello"));
    ASSERT_FALSE(is_valid_string(NULL));
    ASSERT_FALSE(is_valid_string(""));
    
    printf("✓ PASSED\n");
}

static void test_safe_strlen(void) {
    printf("Testing safe_strlen... ");
    
    ASSERT_EQ(safe_strlen("hello"), 5);
    ASSERT_EQ(safe_strlen(""), 0);
    ASSERT_EQ(safe_strlen(NULL), 0);
    
    printf("✓ PASSED\n");
}

int main(void) {
    printf("Running C project tests...\n\n");
    
    test_is_valid_string();
    test_safe_strlen();
    
    printf("\n✅ All tests passed!\n");
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
    CMAKE_GENERATOR="MinGW Makefiles"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macOS"
    CMAKE_GENERATOR="Unix Makefiles"
else
    PLATFORM="Linux"
    CMAKE_GENERATOR="Unix Makefiles"
fi

echo "🔧 Configuring C project for $PLATFORM..."

# Create build directory if it doesn't exist
mkdir -p build

# Configure CMake
cmake -B build -S . -G "$CMAKE_GENERATOR" -DCMAKE_BUILD_TYPE=Debug

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

echo "🎨 Formatting C code..."

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

# Format files with C-specific style
find src include tests -name "*.c" -o -name "*.h" 2>/dev/null | \
    xargs "$CLANG_FORMAT" -i -style="{BasedOnStyle: GNU, IndentWidth: 4, UseTab: Never}" 2>/dev/null

echo "✅ C code formatting complete!"
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

# Remove compile_commands.json from root and coverage files
rm -f compile_commands.json *.gcno *.gcda *.gcov
rm -rf coverage/ analysis-results/ valgrind-report.log

echo "✅ Clean complete!"
EOF

if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
    chmod +x scripts/clean.sh
fi

# Add static analysis script
cat > scripts/analyze.sh << 'EOF'
#!/bin/bash

# Change to project root directory
cd "$(dirname "$0")/.."

echo "🔍 Running static analysis..."

# Run cppcheck if available
if command -v cppcheck >/dev/null 2>&1; then
    echo "Running cppcheck..."
    cppcheck --enable=all --std=c23 --platform=unix64 \
             --suppress=missingIncludeSystem \
             --suppress=unusedFunction \
             -I include/ src/ || true
else
    echo "⚠️  cppcheck not found. Install it for static analysis."
fi

# Run clang-tidy if available
if command -v clang-tidy >/dev/null 2>&1; then
    echo "Running clang-tidy..."
    find src/ -name "*.c" | xargs clang-tidy -p build/ || true
else
    echo "⚠️  clang-tidy not found. Install it for enhanced analysis."
fi

# Run scan-build if available (Clang static analyzer)
if command -v scan-build >/dev/null 2>&1; then
    echo "Running Clang static analyzer..."
    scan-build -o analysis-results make clean build || true
    echo "Analysis results saved to analysis-results/"
else
    echo "⚠️  scan-build not found. Install clang-tools for static analysis."
fi

echo "✅ Static analysis complete!"
EOF

if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
    chmod +x scripts/analyze.sh
fi

# Add memory profiling script
cat > scripts/memcheck.sh << 'EOF'
#!/bin/bash

# Change to project root directory
cd "$(dirname "$0")/.."

if ! command -v valgrind >/dev/null 2>&1; then
    echo "⚠️  Valgrind not found. Install it for memory checking."
    exit 1
fi

echo "🔍 Running comprehensive memory check..."

# Build with debug symbols
echo "Building with debug symbols..."
cmake -B build -S . -DCMAKE_BUILD_TYPE=Debug
cmake --build build

echo "Running Valgrind with comprehensive checks..."
valgrind \
    --tool=memcheck \
    --leak-check=full \
    --show-leak-kinds=all \
    --track-origins=yes \
    --verbose \
    --error-exitcode=1 \
    --log-file=valgrind-report.log \
    ./bin/main

echo "✅ Memory check complete! Report saved to valgrind-report.log"
EOF

if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
    chmod +x scripts/memcheck.sh
fi

# Add coverage script for C projects
cat > scripts/coverage.sh << 'EOF'
#!/bin/bash

# Change to project root directory
cd "$(dirname "$0")/.."

if ! command -v gcov >/dev/null 2>&1; then
    echo "⚠️  gcov not found. Install gcc for coverage analysis."
    exit 1
fi

echo "📊 Generating code coverage report..."

# Clean previous coverage data
rm -rf coverage/ *.gcno *.gcda *.gcov

# Build with coverage flags
echo "Building with coverage instrumentation..."
cmake -B build -S . \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_C_FLAGS="--coverage -fprofile-arcs -ftest-coverage"
cmake --build build

# Run tests to generate coverage data
if [ -f bin/test_main ]; then
    echo "Running tests to generate coverage data..."
    ./bin/test_main
else
    echo "Running main executable for coverage..."
    ./bin/main
fi

# Generate coverage reports
mkdir -p coverage
gcov -r src/*.c
mv *.gcov coverage/

# Generate HTML report if lcov is available
if command -v lcov >/dev/null 2>&1 && command -v genhtml >/dev/null 2>&1; then
    echo "Generating HTML coverage report..."
    lcov --capture --directory . --output-file coverage/coverage.info
    genhtml coverage/coverage.info --output-directory coverage/html
    echo "HTML coverage report generated in coverage/html/"
fi

echo "✅ Coverage analysis complete! Results in coverage/"
EOF

if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
    chmod +x scripts/coverage.sh
fi

# Enhanced cross-platform Makefile for C projects
cat > Makefile << 'EOF'
# Enhanced Makefile for C Project Template
# Supports Linux, macOS, and Windows (MSYS2/MinGW)

# Project variables
PROJECT_NAME := $(shell basename $(CURDIR))
BUILD_DIR := build
BIN_DIR := bin
SRC_DIR := src
INCLUDE_DIR := include
TESTS_DIR := tests
SCRIPTS_DIR := scripts
LIB_DIR := lib

# Detect platform
ifeq ($(OS),Windows_NT)
    PLATFORM := Windows
    EXECUTABLE_EXT := .exe
    CMAKE_GENERATOR := "MinGW Makefiles"
    RM := del /Q /S
    RMDIR := rmdir /S /Q
    MKDIR := mkdir
    SHELL_CHECK := where
    NULL_DEVICE := nul
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
    RMDIR := rm -rf
    MKDIR := mkdir -p
    SHELL_CHECK := command -v
    NULL_DEVICE := /dev/null
endif

# Build configurations
BUILD_TYPE ?= Debug
CMAKE_FLAGS := -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Tool detection
HAS_CMAKE := $(shell $(SHELL_CHECK) cmake >$(NULL_DEVICE) 2>&1 && echo "yes" || echo "no")
HAS_GCC := $(shell $(SHELL_CHECK) gcc >$(NULL_DEVICE) 2>&1 && echo "yes" || echo "no")
HAS_CLANG := $(shell $(SHELL_CHECK) clang >$(NULL_DEVICE) 2>&1 && echo "yes" || echo "no")
HAS_CLANG_FORMAT := $(shell $(SHELL_CHECK) clang-format >$(NULL_DEVICE) 2>&1 && echo "yes" || echo "no")
HAS_CPPCHECK := $(shell $(SHELL_CHECK) cppcheck >$(NULL_DEVICE) 2>&1 && echo "yes" || echo "no")
HAS_VALGRIND := $(shell $(SHELL_CHECK) valgrind >$(NULL_DEVICE) 2>&1 && echo "yes" || echo "no")
HAS_GDB := $(shell $(SHELL_CHECK) gdb >$(NULL_DEVICE) 2>&1 && echo "yes" || echo "no")
HAS_LLDB := $(shell $(SHELL_CHECK) lldb >$(NULL_DEVICE) 2>&1 && echo "yes" || echo "no")
HAS_GCOV := $(shell $(SHELL_CHECK) gcov >$(NULL_DEVICE) 2>&1 && echo "yes" || echo "no")

# Colors for output (if terminal supports it)
ifndef NO_COLOR
    RED := \033[31m
    GREEN := \033[32m
    YELLOW := \033[33m
    BLUE := \033[34m
    MAGENTA := \033[35m
    CYAN := \033[36m
    WHITE := \033[37m
    RESET := \033[0m
    BOLD := \033[1m
else
    RED :=
    GREEN :=
    YELLOW :=
    BLUE :=
    MAGENTA :=
    CYAN :=
    WHITE :=
    RESET :=
    BOLD :=
endif

# Default target
.PHONY: all
all: build

# Help target with enhanced formatting
.PHONY: help
help:
	@echo "$(BOLD)$(BLUE)Available targets for C development on $(PLATFORM):$(RESET)"
	@echo ""
	@echo "$(BOLD)$(GREEN)Building:$(RESET)"
	@echo "  $(CYAN)build$(RESET)       - Build the project (default)"
	@echo "  $(CYAN)rebuild$(RESET)     - Clean and build"
	@echo "  $(CYAN)release$(RESET)     - Build optimized release version"
	@echo "  $(CYAN)install$(RESET)     - Install to system (requires sudo on Unix)"
	@echo "  $(CYAN)uninstall$(RESET)   - Remove from system (requires sudo on Unix)"
	@echo ""
	@echo "$(BOLD)$(GREEN)Running & Testing:$(RESET)"
	@echo "  $(CYAN)run$(RESET)         - Build and run the main executable"
	@echo "  $(CYAN)test$(RESET)        - Build and run tests"
	@echo "  $(CYAN)debug$(RESET)       - Build and run with debugger"
	@echo "  $(CYAN)valgrind$(RESET)    - Run with Valgrind (Linux/macOS only)"
	@echo "  $(CYAN)memcheck$(RESET)    - Comprehensive memory analysis"
	@echo ""
	@echo "$(BOLD)$(GREEN)Code Quality:$(RESET)"
	@echo "  $(CYAN)format$(RESET)      - Format code with clang-format"
	@echo "  $(CYAN)analyze$(RESET)     - Run static analysis tools"
	@echo "  $(CYAN)lint$(RESET)        - Run linting checks"
	@echo "  $(CYAN)coverage$(RESET)    - Generate code coverage report"
	@echo ""
	@echo "$(BOLD)$(GREEN)Maintenance:$(RESET)"
	@echo "  $(CYAN)clean$(RESET)       - Clean build artifacts"
	@echo "  $(CYAN)distclean$(RESET)   - Deep clean (including CMake cache)"
	@echo "  $(CYAN)deps$(RESET)        - Show build dependencies"
	@echo "  $(CYAN)check$(RESET)       - Check build environment"
	@echo "  $(CYAN)info$(RESET)        - Show project information"
	@echo ""
	@echo "$(BOLD)$(GREEN)Development:$(RESET)"
	@echo "  $(CYAN)watch$(RESET)       - Watch for changes and auto-build"
	@echo "  $(CYAN)benchmark$(RESET)   - Run performance benchmarks"
	@echo "  $(CYAN)help$(RESET)        - Show this help message"

# Build target
.PHONY: build
build: check-cmake $(BUILD_DIR)/Makefile
	@echo "$(BOLD)$(BLUE)🔨 Building $(PROJECT_NAME) for $(PLATFORM)...$(RESET)"
	@cmake --build $(BUILD_DIR) --config $(BUILD_TYPE)
	@echo "$(GREEN)✅ Build complete!$(RESET)"

# Configure CMake
$(BUILD_DIR)/Makefile: CMakeLists.txt
	@echo "$(BOLD)$(BLUE)🔧 Configuring CMake for $(PLATFORM)...$(RESET)"
	@$(MKDIR) $(BUILD_DIR) 2>$(NULL_DEVICE) || true
	@cmake -B $(BUILD_DIR) -S . -G $(CMAKE_GENERATOR) $(CMAKE_FLAGS)

# Clean target
.PHONY: clean
clean:
	@echo "$(BOLD)$(YELLOW)🧹 Cleaning build artifacts...$(RESET)"
ifeq ($(PLATFORM),Windows)
	@if exist $(BUILD_DIR) $(RMDIR) $(BUILD_DIR) 2>$(NULL_DEVICE) || true
	@if exist $(BIN_DIR) $(RMDIR) $(BIN_DIR) 2>$(NULL_DEVICE) || true
	@if exist $(LIB_DIR) $(RMDIR) $(LIB_DIR) 2>$(NULL_DEVICE) || true
	@$(MKDIR) $(BUILD_DIR) $(BIN_DIR) $(LIB_DIR) 2>$(NULL_DEVICE) || true
else
	@$(RM) $(BUILD_DIR)/* $(BIN_DIR)/* $(LIB_DIR)/* compile_commands.json 2>$(NULL_DEVICE) || true
	@$(RM) *.gcno *.gcda *.gcov coverage/ valgrind-report.log analysis-results/ 2>$(NULL_DEVICE) || true
	@touch $(BUILD_DIR)/.gitkeep $(BIN_DIR)/.gitkeep $(LIB_DIR)/.gitkeep
endif
	@echo "$(GREEN)✅ Clean complete!$(RESET)"

# Deep clean target
.PHONY: distclean
distclean:
	@echo "$(BOLD)$(YELLOW)🧹 Deep cleaning (including CMake cache)...$(RESET)"
ifeq ($(PLATFORM),Windows)
	@if exist $(BUILD_DIR) $(RMDIR) $(BUILD_DIR) 2>$(NULL_DEVICE) || true
	@if exist $(BIN_DIR) $(RMDIR) $(BIN_DIR) 2>$(NULL_DEVICE) || true
	@if exist $(LIB_DIR) $(RMDIR) $(LIB_DIR) 2>$(NULL_DEVICE) || true
	@$(MKDIR) $(BUILD_DIR) $(BIN_DIR) $(LIB_DIR) 2>$(NULL_DEVICE) || true
else
	@$(RM) $(BUILD_DIR) $(BIN_DIR)/* $(LIB_DIR)/* compile_commands.json 2>$(NULL_DEVICE) || true
	@$(RM) *.gcno *.gcda *.gcov coverage/ valgrind-report.log analysis-results/ 2>$(NULL_DEVICE) || true
	@$(MKDIR) $(BUILD_DIR) $(BIN_DIR) $(LIB_DIR)
	@touch $(BUILD_DIR)/.gitkeep $(BIN_DIR)/.gitkeep $(LIB_DIR)/.gitkeep
endif
	@echo "$(GREEN)✅ Deep clean complete!$(RESET)"

# Rebuild target
.PHONY: rebuild
rebuild: clean build

# Run target
.PHONY: run
run: build
	@echo "$(BOLD)$(BLUE)🚀 Running $(PROJECT_NAME)...$(RESET)"
ifeq ($(PLATFORM),Windows)
	@$(BIN_DIR)\main$(EXECUTABLE_EXT)
else
	@./$(BIN_DIR)/main$(EXECUTABLE_EXT)
endif

# Debug target
.PHONY: debug
debug: BUILD_TYPE = Debug
debug: build
	@echo "$(BOLD)$(BLUE)🐛 Running $(PROJECT_NAME) with debugger...$(RESET)"
ifeq ($(PLATFORM),Windows)
	@echo "$(YELLOW)Start debugging with your preferred debugger$(RESET)"
	@$(BIN_DIR)\main$(EXECUTABLE_EXT)
else ifeq ($(PLATFORM),macOS)
ifeq ($(HAS_LLDB),yes)
	@lldb ./$(BIN_DIR)/main$(EXECUTABLE_EXT)
else
	@echo "$(RED)❌ lldb not found. Install Xcode command line tools.$(RESET)"
endif
else
ifeq ($(HAS_GDB),yes)
	@gdb -q ./$(BIN_DIR)/main$(EXECUTABLE_EXT)
else
	@echo "$(RED)❌ gdb not found. Install it with: sudo apt install gdb$(RESET)"
endif
endif

# Valgrind target (Linux/macOS only)
.PHONY: valgrind
valgrind: BUILD_TYPE = Debug
valgrind: build
ifeq ($(PLATFORM),Windows)
	@echo "$(YELLOW)⚠️  Valgrind not available on Windows. Use Application Verifier instead.$(RESET)"
else
ifeq ($(HAS_VALGRIND),yes)
	@echo "$(BOLD)$(BLUE)🔍 Running $(PROJECT_NAME) with Valgrind...$(RESET)"
	@valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes \
		--error-exitcode=1 ./$(BIN_DIR)/main$(EXECUTABLE_EXT)
else
	@echo "$(RED)❌ Valgrind not found.$(RESET)"
ifeq ($(PLATFORM),Linux)
	@echo "Install with: sudo apt install valgrind"
else
	@echo "Install with: brew install valgrind"
endif
endif
endif

# Comprehensive memory check
.PHONY: memcheck
memcheck: BUILD_TYPE = Debug
memcheck: build
	@echo "$(BOLD)$(BLUE)🔍 Running comprehensive memory check...$(RESET)"
ifeq ($(PLATFORM),Windows)
	@echo "$(YELLOW)⚠️  Using built-in runtime checks on Windows$(RESET)"
	@$(BIN_DIR)\main$(EXECUTABLE_EXT)
else
	@if [ -f $(SCRIPTS_DIR)/memcheck.sh ]; then \
		bash $(SCRIPTS_DIR)/memcheck.sh; \
	else \
		make valgrind; \
	fi
endif

# Release build
.PHONY: release
release: BUILD_TYPE = Release
release: distclean build
	@echo "$(GREEN)✅ Release build complete!$(RESET)"

# Test target
.PHONY: test
test: BUILD_TYPE = Debug
test: build
	@echo "$(BOLD)$(BLUE)🧪 Building and running tests...$(RESET)"
	@cmake --build $(BUILD_DIR) --target test_main --config $(BUILD_TYPE) 2>$(NULL_DEVICE) || echo "$(YELLOW)⚠️  No tests configured$(RESET)"
ifeq ($(PLATFORM),Windows)
	@if exist $(BIN_DIR)\test_main$(EXECUTABLE_EXT) ( \
		echo "Running tests..." && \
		$(BIN_DIR)\test_main$(EXECUTABLE_EXT) \
	) else ( \
		echo "$(YELLOW)⚠️  No test executable found$(RESET)" \
	)
else
	@if [ -f $(BIN_DIR)/test_main$(EXECUTABLE_EXT) ]; then \
		echo "Running tests..." && \
		./$(BIN_DIR)/test_main$(EXECUTABLE_EXT); \
	else \
		echo "$(YELLOW)⚠️  No test executable found$(RESET)"; \
	fi
endif

# Format target
.PHONY: format
format:
	@echo "$(BOLD)$(BLUE)🎨 Formatting C code...$(RESET)"
ifeq ($(HAS_CLANG_FORMAT),yes)
	@find $(SRC_DIR) $(INCLUDE_DIR) $(TESTS_DIR) -name "*.c" -o -name "*.h" 2>$(NULL_DEVICE) | \
		xargs clang-format -i -style="{BasedOnStyle: GNU, IndentWidth: 4, UseTab: Never}"
	@echo "$(GREEN)✅ Code formatting complete!$(RESET)"
else
	@echo "$(RED)❌ clang-format not found.$(RESET)"
ifeq ($(PLATFORM),Linux)
	@echo "Install with: sudo apt install clang-format"
else ifeq ($(PLATFORM),macOS)
	@echo "Install with: brew install clang-format"
else
	@echo "Install via MSYS2: pacman -S mingw-w64-x86_64-clang"
endif
endif

# Static analysis target
.PHONY: analyze
analyze: build
	@echo "$(BOLD)$(BLUE)🔍 Running static analysis...$(RESET)"
	@if [ -f $(SCRIPTS_DIR)/analyze.sh ]; then \
		bash $(SCRIPTS_DIR)/analyze.sh; \
	else \
		echo "$(YELLOW)⚠️  Analysis script not found$(RESET)"; \
	fi
	@echo "$(GREEN)✅ Static analysis complete!$(RESET)"

# Lint target
.PHONY: lint
lint: analyze

# Coverage target
.PHONY: coverage
coverage: BUILD_TYPE = Debug
coverage: 
	@echo "$(BOLD)$(BLUE)📊 Generating code coverage...$(RESET)"
	@if [ -f $(SCRIPTS_DIR)/coverage.sh ]; then \
		bash $(SCRIPTS_DIR)/coverage.sh; \
	else \
		echo "$(YELLOW)⚠️  Coverage script not found$(RESET)"; \
	fi

# Install target
.PHONY: install
install: release
	@echo "$(BOLD)$(BLUE)📦 Installing $(PROJECT_NAME)...$(RESET)"
ifeq ($(PLATFORM),Windows)
	@echo "$(YELLOW)⚠️  Manual installation required on Windows$(RESET)"
	@echo "Copy $(BIN_DIR)\\main$(EXECUTABLE_EXT) to your desired location"
else
	@sudo cp $(BIN_DIR)/main$(EXECUTABLE_EXT) /usr/local/bin/$(PROJECT_NAME)
	@sudo chmod +x /usr/local/bin/$(PROJECT_NAME)
	@echo "$(GREEN)✅ Installed to /usr/local/bin/$(PROJECT_NAME)$(RESET)"
endif

# Uninstall target
.PHONY: uninstall
uninstall:
	@echo "$(BOLD)$(YELLOW)🗑️  Uninstalling $(PROJECT_NAME)...$(RESET)"
ifeq ($(PLATFORM),Windows)
	@echo "$(YELLOW)⚠️  Manual uninstallation required on Windows$(RESET)"
else
	@sudo rm -f /usr/local/bin/$(PROJECT_NAME)
	@echo "$(GREEN)✅ Uninstalled from /usr/local/bin/$(PROJECT_NAME)$(RESET)"
endif

# Show dependencies
.PHONY: deps
deps:
	@echo "$(BOLD)$(BLUE)📋 Build dependencies for C development on $(PLATFORM):$(RESET)"
	@echo ""
	@echo "$(BOLD)$(GREEN)Required:$(RESET)"
	@echo "  - CMake 3.14+"
	@echo "  - C23 compatible compiler (GCC 13+, Clang 15+, MSVC 2022+)"
	@echo "  - make"
	@echo ""
	@echo "$(BOLD)$(GREEN)Optional:$(RESET)"
	@echo "  - clang-format (code formatting)"
	@echo "  - cppcheck (static analysis)"
	@echo "  - clang-tidy (enhanced static analysis)"
	@echo "  - scan-build (Clang static analyzer)"
ifeq ($(PLATFORM),Windows)
	@echo "  - Application Verifier (memory checking)"
else
	@echo "  - valgrind (memory checking)"
	@echo "  - gdb/lldb (debugging)"
endif
	@echo "  - lcov/gcov (code coverage)"

# Check build environment
.PHONY: check
check:
	@echo "$(BOLD)$(BLUE)🔍 Checking C development environment for $(PLATFORM)...$(RESET)"
	@echo ""
ifeq ($(HAS_CMAKE),yes)
	@echo "$(GREEN)✅ CMake found$(RESET)"
else
	@echo "$(RED)❌ CMake not found$(RESET)"
endif
	@$(SHELL_CHECK) make >$(NULL_DEVICE) 2>&1 && echo "$(GREEN)✅ Make found$(RESET)" || echo "$(RED)❌ Make not found$(RESET)"
ifeq ($(HAS_GCC),yes)
	@echo "$(GREEN)✅ GCC found$(RESET)"
else ifeq ($(HAS_CLANG),yes)
	@echo "$(GREEN)✅ Clang found$(RESET)"
else
	@echo "$(RED)❌ No C compiler found$(RESET)"
endif
ifeq ($(HAS_CLANG_FORMAT),yes)
	@echo "$(GREEN)✅ clang-format found$(RESET)"
else
	@echo "$(YELLOW)⚠️  clang-format not found (optional)$(RESET)"
endif
ifeq ($(HAS_CPPCHECK),yes)
	@echo "$(GREEN)✅ cppcheck found$(RESET)"
else
	@echo "$(YELLOW)⚠️  cppcheck not found (optional)$(RESET)"
endif
ifeq ($(HAS_GCOV),yes)
	@echo "$(GREEN)✅ gcov found$(RESET)"
else
	@echo "$(YELLOW)⚠️  gcov not found (optional)$(RESET)"
endif
ifneq ($(PLATFORM),Windows)
ifeq ($(HAS_VALGRIND),yes)
	@echo "$(GREEN)✅ valgrind found$(RESET)"
else
	@echo "$(YELLOW)⚠️  valgrind not found (optional)$(RESET)"
endif
ifeq ($(HAS_GDB),yes)
	@echo "$(GREEN)✅ gdb found$(RESET)"
else ifeq ($(HAS_LLDB),yes)
	@echo "$(GREEN)✅ lldb found$(RESET)"
else
	@echo "$(YELLOW)⚠️  no debugger found (optional)$(RESET)"
endif
endif

# Project information
.PHONY: info
info:
	@echo "$(BOLD)$(BLUE)📊 C Project Information:$(RESET)"
	@echo ""
	@echo "$(BOLD)Project:$(RESET)     $(PROJECT_NAME)"
	@echo "$(BOLD)Platform:$(RESET)    $(PLATFORM)"
	@echo "$(BOLD)Build Type:$(RESET)  $(BUILD_TYPE)"
	@echo "$(BOLD)Generator:$(RESET)   $(CMAKE_GENERATOR)"
	@echo "$(BOLD)Language:$(RESET)    C23"
	@echo ""
	@echo "$(BOLD)$(GREEN)Directories:$(RESET)"
	@echo "  Source:      $(SRC_DIR)/"
	@echo "  Headers:     $(INCLUDE_DIR)/"
	@echo "  Tests:       $(TESTS_DIR)/"
	@echo "  Build:       $(BUILD_DIR)/"
	@echo "  Binaries:    $(BIN_DIR)/"
	@echo "  Libraries:   $(LIB_DIR)/"
	@echo ""
	@find $(SRC_DIR) -name "*.c" 2>$(NULL_DEVICE) | wc -l | xargs echo "C source files:"
	@find $(INCLUDE_DIR) -name "*.h" 2>$(NULL_DEVICE) | wc -l | xargs echo "Header files:"

# Watch for changes (Linux/macOS with inotify-tools)
.PHONY: watch
watch:
ifneq ($(PLATFORM),Windows)
	@if command -v inotifywait >$(NULL_DEVICE) 2>&1; then \
		echo "$(BOLD)$(BLUE)👀 Watching for changes... (Ctrl+C to stop)$(RESET)"; \
		while true; do \
			inotifywait -q -r -e modify,create,delete $(SRC_DIR) $(INCLUDE_DIR) && \
			make build; \
		done; \
	else \
		echo "$(YELLOW)⚠️  inotifywait not found. Install inotify-tools for watch functionality.$(RESET)"; \
	fi
else
	@echo "$(YELLOW)⚠️  Watch functionality not implemented for Windows$(RESET)"
endif

# Benchmark target (placeholder)
.PHONY: benchmark
benchmark: release
	@echo "$(BOLD)$(BLUE)⚡ Running performance benchmarks...$(RESET)"
	@echo "$(YELLOW)⚠️  Benchmark implementation needed$(RESET)"

# Utility targets
.PHONY: check-cmake
check-cmake:
ifneq ($(HAS_CMAKE),yes)
	@echo "$(RED)❌ CMake not found. Please install CMake 3.14 or later.$(RESET)"
	@exit 1
endif

# Prevent make from deleting intermediate files
.SECONDARY:

# Make sure these targets are always run regardless of file existence
.PHONY: all help build clean distclean rebuild run debug valgrind memcheck release test \
        format analyze lint coverage install uninstall deps check info watch \
        benchmark check-cmake
EOF

# Create enhanced README template for C projects
cat > README.md << EOF
# $1

Modern C23 project with comprehensive development tools and cross-platform support.

## Features

- **Modern C23** with GCC 13+ support
- **Cross-platform** (Windows, macOS, Linux)
- **Memory safety** with AddressSanitizer and Valgrind
- **Static analysis** with cppcheck, clang-tidy, and scan-build
- **Code coverage** with gcov/lcov
- **Automated testing** framework
- **Professional build system** with CMake and Make

## Quick Start

### Prerequisites

- **CMake 3.14+**
- **Modern C compiler:**
  - GCC 13+ (Linux/Windows)
  - Clang 15+ (macOS/Linux)
  - MSVC 2022 (Windows)

### Building

\`\`\`bash
# Clone and enter project
cd $1

# Build the project
make build    # or just 'make'

# Run the executable
make run
\`\`\`

## Development Workflow

### Building & Running
\`\`\`bash
make build      # Standard build
make rebuild    # Clean + build
make release    # Optimized build
make run        # Build and run
make test       # Run unit tests
\`\`\`

### Code Quality
\`\`\`bash
make format     # Format code with clang-format
make analyze    # Static analysis with multiple tools
make coverage   # Generate code coverage report
make memcheck   # Memory leak detection (Linux/macOS)
make valgrind   # Comprehensive memory analysis
\`\`\`

### Debugging
\`\`\`bash
make debug      # Run with debugger (gdb/lldb)
make valgrind   # Memory debugging
\`\`\`

### Maintenance
\`\`\`bash
make clean      # Clean build artifacts
make distclean  # Deep clean including CMake cache
make check      # Verify build environment
make info       # Show project information
make deps       # Show dependencies
\`\`\`

## Platform-Specific Setup

### Linux (Ubuntu 24.04+)
\`\`\`bash
# Install dependencies
sudo apt update
sudo apt install build-essential cmake gcc-13

# Development tools
sudo apt install clang-format cppcheck valgrind gdb
sudo apt install lcov gcovr  # For coverage reports

# Set GCC 13 as default
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100
sudo update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-13 100
\`\`\`

### macOS
\`\`\`bash
# Install via Homebrew
brew install cmake llvm cppcheck

# Xcode Command Line Tools for debugger
xcode-select --install
\`\`\`

### Windows (MSYS2/MinGW)
\`\`\`bash
# Install MSYS2, then:
pacman -S base-devel mingw-w64-x86_64-gcc mingw-w64-x86_64-cmake
pacman -S mingw-w64-x86_64-clang mingw-w64-x86_64-cppcheck
\`\`\`

## Project Structure

\`\`\`
$1/
├── Makefile           # Cross-platform build automation
├── CMakeLists.txt     # Modern CMake configuration
├── README.md          # This file
├── .clangd            # LSP configuration for editors
├── .gitignore         # Git ignore patterns
│
├── bin/               # Compiled executables
├── build/             # CMake build files (auto-generated)
├── lib/               # External libraries
│
├── include/           # Header files (.h)
│   └── main.h         # Main header with function prototypes
│
├── src/               # Source files (.c)
│   ├── main.c         # Main function (entry point)
│   └── utils.c        # Utility functions (library code)
│
├── tests/             # Unit tests
│   └── test_main.c    # Test suite with simple framework
│
└── scripts/           # Development scripts
    ├── build.sh       # Cross-platform build script
    ├── format.sh      # Code formatting
    ├── clean.sh       # Clean build artifacts
    ├── analyze.sh     # Static analysis tools
    ├── memcheck.sh    # Memory analysis with Valgrind
    └── coverage.sh    # Code coverage generation
\`\`\`

## Modern C23 Features Used

- **C23 standard library** features
- **Enhanced type safety** with strict prototypes
- **Memory safety** practices
- **Error handling** patterns
- **Modern header organization**
- **Cross-platform compatibility**

## Code Quality Tools

### Static Analysis
- **cppcheck**: Comprehensive C static analyzer
- **clang-tidy**: Modern C/C++ linter
- **scan-build**: Clang static analyzer

### Memory Analysis
- **AddressSanitizer**: Runtime memory error detection
- **Valgrind**: Memory leak and error detection
- **Stack protection**: Compiler-based stack overflow protection

### Code Coverage
- **gcov/lcov**: Line and branch coverage analysis
- **HTML reports**: Visual coverage reporting

## Editor Integration

### LunarVim / Neovim
- Automatic LSP configuration with .clangd
- IntelliSense and error checking
- Symbol navigation and refactoring

### VS Code
- C/C++ extension support
- Integrated debugging
- Task integration with Makefile

### CLion / Other IDEs
- CMake project import
- Built-in static analysis
- Integrated debugging

## Testing Framework

Simple, lightweight testing macros included:

\`\`\`c
ASSERT_TRUE(expression);     // Assert expression is true
ASSERT_FALSE(expression);    // Assert expression is false
ASSERT_EQ(actual, expected); // Assert values are equal
\`\`\`

Add tests in \`tests/\` directory and they'll be automatically built and run.

## Memory Safety

The project includes multiple layers of memory safety:

1. **Compile-time**: Comprehensive warnings and static analysis
2. **Runtime**: AddressSanitizer in debug builds
3. **Testing**: Valgrind integration for memory leak detection
4. **Code practices**: Safe string handling and null checks

## Performance

- **Release builds**: Optimized with \`-O3\` and \`-march=native\`
- **Debug builds**: Full symbols with \`-g3\` for debugging
- **Profiling ready**: Easy integration with profiling tools

## Contributing

1. **Format code**: \`make format\`
2. **Run tests**: \`make test\`
3. **Check memory**: \`make memcheck\`
4. **Static analysis**: \`make analyze\`
5. **Coverage check**: \`make coverage\`

## License

[Add your license here]

---

**Built with modern C23 and professional development practices** 🚀
EOF

echo "✅ Enhanced C Project '$1' created successfully with comprehensive tooling!"
echo ""
echo "🚀 Next steps:"
echo "  cd $1"
echo "  make check        # Verify build environment"
echo "  make build        # Build the project"
echo "  make run          # Run the executable"
echo "  make test         # Run tests"
echo ""
echo "📚 Development commands:"
echo "  make help         # Show all available commands"
echo "  make format       # Format code"
echo "  make analyze      # Static analysis"
echo "  make coverage     # Code coverage"
echo "  make memcheck     # Memory analysis (Linux/macOS)"
echo ""
echo "🔧 This C23 project includes:"
echo "  • Cross-platform build system"
echo "  • Separated library functions (src/utils.c) from main (src/main.c)"
echo "  • Memory safety with AddressSanitizer & Valgrind"
echo "  • Static analysis with cppcheck & clang-tidy"
echo "  • Code coverage with gcov/lcov"
echo "  • Modern C23 features and best practices"
echo "  • Professional testing framework"
echo "  • Fixed CMake test building with proper library linking"
