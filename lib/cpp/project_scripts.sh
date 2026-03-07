#!/bin/bash

create_project_scripts() {
    cat > scripts/build.sh << 'EOF'
#!/bin/bash
set -e

cd "$(dirname "$0")/.."

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

echo "Configuring project for $PLATFORM..."

mkdir -p build

cmake -B build -S . -G "$CMAKE_GENERATOR" -DCMAKE_BUILD_TYPE=Debug

echo "Building project..."
cmake --build build --config Debug

echo "Build complete! Run with:"
if [[ "$PLATFORM" == "Windows" ]]; then
    echo "  .\\bin\\main.exe"
else
    echo "  ./bin/main"
fi
EOF

    chmod +x scripts/build.sh

    cat > scripts/format.sh << 'EOF'
#!/bin/bash

cd "$(dirname "$0")/.."

echo "Formatting code..."

CLANG_FORMAT=""
if command -v clang-format >/dev/null 2>&1; then
    CLANG_FORMAT="clang-format"
elif command -v clang-format-15 >/dev/null 2>&1; then
    CLANG_FORMAT="clang-format-15"
elif command -v clang-format-14 >/dev/null 2>&1; then
    CLANG_FORMAT="clang-format-14"
else
    echo "clang-format not found. Install it to use code formatting."
    exit 1
fi

find src include tests -name "*.cpp" -o -name "*.hpp" -o -name "*.h" -o -name "*.cxx" 2>/dev/null | \
    xargs "$CLANG_FORMAT" -i 2>/dev/null

echo "Code formatting complete!"
EOF

    chmod +x scripts/format.sh

    cat > scripts/clean.sh << 'EOF'
#!/bin/bash

cd "$(dirname "$0")/.."

echo "Cleaning build artifacts..."

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    [ -d "build" ] && rm -rf build/*
    [ -d "bin" ]   && rm -rf bin/*
    [ -d "lib" ]   && rm -rf lib/*
else
    rm -rf build/* bin/* lib/*
fi

touch build/.gitkeep bin/.gitkeep lib/.gitkeep

rm -f compile_commands.json

echo "Clean complete!"
EOF

    chmod +x scripts/clean.sh

    cat > scripts/setup_clangd.sh << 'OUTER_EOF'
#!/bin/bash

cd "$(dirname "$0")/.."

echo "Setting up clangd configuration..."

cat > .clangd << 'EOF'
CompileFlags:
  Add:
    - -std=c++23
    - -Wall
    - -Wextra
    - -I/usr/include/c++/13
    - -I/usr/include/x86_64-linux-gnu/c++/13
    - -I/usr/include/c++/13/backward
  Remove:
    - -W*
  Compiler: g++

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
    CheckOptions:
      readability-identifier-naming.ClassCase: CamelCase
      readability-identifier-naming.StructCase: CamelCase
      readability-identifier-naming.EnumCase: CamelCase
      readability-identifier-naming.TypedefCase: CamelCase
      readability-identifier-naming.TypeAliasCase: CamelCase
      readability-identifier-naming.UnionCase: CamelCase
      readability-identifier-naming.FunctionCase: lower_case
      readability-identifier-naming.MethodCase: lower_case
      readability-identifier-naming.VariableCase: lower_case
      readability-identifier-naming.ParameterCase: lower_case
      readability-identifier-naming.ConstantParameterCase: lower_case
      readability-identifier-naming.LocalVariableCase: lower_case
      readability-identifier-naming.ConstantCase: UPPER_CASE
      readability-identifier-naming.ConstexprVariableCase: UPPER_CASE
      readability-identifier-naming.EnumConstantCase: UPPER_CASE
      readability-identifier-naming.StaticConstantCase: UPPER_CASE
      readability-identifier-naming.GlobalConstantCase: UPPER_CASE
      readability-identifier-naming.MemberCase: lower_case
      readability-identifier-naming.MemberSuffix: _
      readability-identifier-naming.PrivateMemberCase: lower_case
      readability-identifier-naming.PrivateMemberSuffix: _
      readability-identifier-naming.ProtectedMemberCase: lower_case
      readability-identifier-naming.ProtectedMemberSuffix: _

InlayHints:
  Enabled: true
  ParameterNames: true
  DeducedTypes: true
  Designators: true

Hover:
  ShowAKA: true
EOF

echo "clangd configuration created"
OUTER_EOF

    chmod +x scripts/setup_clangd.sh
}
