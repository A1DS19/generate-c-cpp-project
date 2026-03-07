#!/bin/bash

create_gitignore() {
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
}
