#!/bin/bash

create_readme() {
    local name="$1"
    cat > README.md << EOF
# ${name}

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
cd ${name}
make build    # or just 'make'
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

### Documentation
\`\`\`bash
sudo apt install doxygen graphviz
make docs       # Generate HTML docs (also runs automatically on make build)
\`\`\`
Open \`docs/html/index.html\` in your browser.

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
sudo apt update
sudo apt install build-essential cmake gcc-13
sudo apt install clang-format cppcheck valgrind gdb
sudo apt install lcov gcovr
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100
sudo update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-13 100
\`\`\`

### macOS
\`\`\`bash
brew install cmake llvm cppcheck
xcode-select --install
\`\`\`

### Windows (MSYS2/MinGW)
\`\`\`bash
pacman -S base-devel mingw-w64-x86_64-gcc mingw-w64-x86_64-cmake
pacman -S mingw-w64-x86_64-clang mingw-w64-x86_64-cppcheck
\`\`\`

## Project Structure

\`\`\`
${name}/
├── Makefile           # Cross-platform build automation
├── CMakeLists.txt     # Modern CMake configuration
├── .clangd            # LSP configuration for editors
├── .clang-format      # Code formatting rules
├── .gitignore
│
├── bin/               # Compiled executables
├── build/             # CMake build files (auto-generated)
├── lib/               # External libraries
│
├── include/           # Header files (.h)
│   └── main.h
│
├── src/               # Source files (.c)
│   ├── main.c         # Entry point
│   └── utils.c        # Utility functions
│
├── tests/             # Unit tests
│   └── test_main.c
│
└── scripts/           # Development scripts
    ├── build.sh
    ├── format.sh
    ├── clean.sh
    ├── analyze.sh
    ├── memcheck.sh
    └── coverage.sh
\`\`\`

## Testing

Simple built-in test macros:

\`\`\`c
ASSERT_TRUE(expression);
ASSERT_FALSE(expression);
ASSERT_EQ(actual, expected);
\`\`\`

## License

[Add your license here]
EOF
}
