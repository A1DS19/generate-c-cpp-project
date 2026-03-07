#!/bin/bash

create_readme() {
    local name="$1"
    cat > README.md << EOF
# ${name}

Modern C++23 project with cross-platform support and professional development tooling.

## Features

- **Modern C++23** features
- **Cross-platform** support (Windows, macOS, Linux)
- **CMake** build system
- **LSP support** via clangd
- **Code formatting** with clang-format
- **Unit testing** framework ready

## Quick Start

### Prerequisites

- **CMake 3.25+**
- **C++23 compatible compiler:**
  - GCC 13+ (Linux/Windows)
  - Clang 15+ (macOS/Linux)
  - MSVC 2022 (Windows)

### Building

\`\`\`bash
cd ${name}
make setup-lsp  # Setup LSP for your editor (recommended)
make build      # or just 'make'
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
./scripts/setup_clangd.sh # Regenerate LSP configuration
\`\`\`

## Platform-Specific Notes

### Linux (Ubuntu 24.04+)
\`\`\`bash
sudo apt update
sudo apt install build-essential cmake g++-13 clang-format
sudo apt install gdb
\`\`\`

### macOS
\`\`\`bash
brew install cmake llvm clang-format
xcode-select --install
\`\`\`

### Windows
- Install Visual Studio 2022 with C++ workload
- Or install MSYS2/MinGW-w64 for GCC
- Install CMake from cmake.org

## Project Structure

\`\`\`
${name}/
├── Makefile           # Cross-platform make targets
├── CMakeLists.txt     # CMake configuration
├── .clangd            # LSP configuration
├── .clang-format      # Code formatting rules
├── .gitignore
│
├── bin/               # Compiled executables
├── build/             # CMake build files
├── lib/               # External libraries
│
├── include/           # Header files (.hpp, .h)
│   └── main.hpp
│
├── src/               # Source files (.cpp, .cxx)
│   └── main.cpp
│
├── tests/             # Test files
│   └── test_main.cpp
│
└── scripts/           # Build and utility scripts
    ├── build.sh
    ├── format.sh
    ├── clean.sh
    └── setup_clangd.sh
\`\`\`

## Modern C++ Features Used

- C++23 standard library features
- Auto return type deduction
- String views for efficient string handling
- \`std::format\` for modern string formatting (when available)

## Editor Setup

### LunarVim / Neovim
1. Run \`make setup-lsp\` to configure clangd
2. LSP should work automatically with proper IntelliSense

### VS Code
1. Install C/C++ extension
2. Run \`make setup-lsp\`

### CLion / Other IDEs
- Import as CMake project

## Contributing

1. Format code before committing: \`make format\`
2. Run tests: \`make test\`

## License

[Add your license here]
EOF
}
