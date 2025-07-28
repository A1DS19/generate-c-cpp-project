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

\`\`\`bash
./scripts/build.sh
\`\`\`

## Running

\`\`\`bash
./bin/main
\`\`\`

## Development

### Formatting Code
\`\`\`bash
./scripts/format.sh
\`\`\`

### Cleaning Build
\`\`\`bash
./scripts/clean.sh
\`\`\`

### Running Tests
\`\`\`bash
# Build first, then run tests
./scripts/build.sh
./bin/test_main  # if you build tests
\`\`\`

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
