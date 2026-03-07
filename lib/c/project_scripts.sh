#!/bin/bash

create_project_scripts() {
    cat > scripts/build.sh << 'EOF'
#!/bin/bash
set -e

cd "$(dirname "$0")/.."

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

echo "Configuring C project for $PLATFORM..."

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

echo "Formatting C code..."

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

find src include tests -name "*.c" -o -name "*.h" 2>/dev/null | \
    xargs "$CLANG_FORMAT" -i 2>/dev/null

echo "C code formatting complete!"
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

rm -f compile_commands.json *.gcno *.gcda *.gcov
rm -rf coverage/ analysis-results/ valgrind-report.log

echo "Clean complete!"
EOF

    chmod +x scripts/clean.sh

    cat > scripts/analyze.sh << 'EOF'
#!/bin/bash

cd "$(dirname "$0")/.."

echo "Running static analysis..."

if command -v cppcheck >/dev/null 2>&1; then
    echo "Running cppcheck..."
    cppcheck --enable=all --std=c23 --platform=unix64 \
             --suppress=missingIncludeSystem \
             --suppress=unusedFunction \
             -I include/ src/ || true
else
    echo "cppcheck not found. Install it for static analysis."
fi

if command -v clang-tidy >/dev/null 2>&1; then
    echo "Running clang-tidy..."
    find src/ -name "*.c" | xargs clang-tidy -p build/ || true
else
    echo "clang-tidy not found. Install it for enhanced analysis."
fi

if command -v scan-build >/dev/null 2>&1; then
    echo "Running Clang static analyzer..."
    scan-build -o analysis-results make clean build || true
    echo "Analysis results saved to analysis-results/"
else
    echo "scan-build not found. Install clang-tools for static analysis."
fi

echo "Static analysis complete!"
EOF

    chmod +x scripts/analyze.sh

    cat > scripts/memcheck.sh << 'EOF'
#!/bin/bash

cd "$(dirname "$0")/.."

if ! command -v valgrind >/dev/null 2>&1; then
    echo "Valgrind not found. Install it for memory checking."
    exit 1
fi

echo "Running comprehensive memory check..."

cmake -B build -S . -DCMAKE_BUILD_TYPE=Debug
cmake --build build

valgrind \
    --tool=memcheck \
    --leak-check=full \
    --show-leak-kinds=all \
    --track-origins=yes \
    --verbose \
    --error-exitcode=1 \
    --log-file=valgrind-report.log \
    ./bin/main

echo "Memory check complete! Report saved to valgrind-report.log"
EOF

    chmod +x scripts/memcheck.sh

    cat > scripts/coverage.sh << 'EOF'
#!/bin/bash

cd "$(dirname "$0")/.."

if ! command -v gcov >/dev/null 2>&1; then
    echo "gcov not found. Install gcc for coverage analysis."
    exit 1
fi

echo "Generating code coverage report..."

rm -rf coverage/ *.gcno *.gcda *.gcov

cmake -B build -S . \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_C_FLAGS="--coverage -fprofile-arcs -ftest-coverage"
cmake --build build

if [ -f bin/test_main ]; then
    echo "Running tests to generate coverage data..."
    ./bin/test_main
else
    echo "Running main executable for coverage..."
    ./bin/main
fi

mkdir -p coverage
gcov -r src/*.c
mv *.gcov coverage/

if command -v lcov >/dev/null 2>&1 && command -v genhtml >/dev/null 2>&1; then
    echo "Generating HTML coverage report..."
    lcov --capture --directory . --output-file coverage/coverage.info
    genhtml coverage/coverage.info --output-directory coverage/html
    echo "HTML coverage report generated in coverage/html/"
fi

echo "Coverage analysis complete! Results in coverage/"
EOF

    chmod +x scripts/coverage.sh
}
