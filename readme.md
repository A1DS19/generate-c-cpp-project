# generate-c-cpp-project

Project scaffolding generators for modern C23 and C++23 projects with a full professional development toolchain out of the box.

## What gets generated

### C project (`generate-c-project`)
- **C23** standard, GCC 13+ / Clang 15+
- CMake 3.14+ build system with AddressSanitizer in debug builds
- Separated entry point (`src/main.c`) and library functions (`src/utils.c`)
- Built-in test framework (`tests/test_main.c`) with `ASSERT_TRUE/FALSE/EQ` macros
- `.clangd` with ClangTidy rules (snake_case functions/vars, UPPER_CASE constants, PascalCase types)
- `.clang-format` (LLVM-based, 4-space indent, pointer-left)
- HTML documentation via Doxygen (auto-runs on `make build` if installed)
- Static analysis: cppcheck, clang-tidy, scan-build (`make analyze`)
- Memory checking: AddressSanitizer + Valgrind (`make memcheck`, `make valgrind`)
- Code coverage: gcov/lcov (`make coverage`)
- Cross-platform Makefile with `build`, `run`, `test`, `debug`, `release`, `format`, `analyze`, `coverage`, `memcheck`, `docs`, `install`, `watch`

### C++ project (`generate-cpp-project`)
- **C++23** standard, GCC 13+ / Clang 15+
- CMake 3.25+ build system with AddressSanitizer in debug builds
- `std::format`, `std::string_view`, trailing return types
- Built-in test runner (`tests/test_main.cpp`)
- `.clangd` with ClangTidy rules (snake_case functions/methods, UPPER_CASE constants, PascalCase classes, trailing `_` on members)
- `.clang-format` (LLVM-based, 4-space indent, template declarations, constructor initializers)
- HTML documentation via Doxygen with class/collaboration graphs (auto-runs on `make build` if installed)
- `scripts/setup_clangd.sh` for regenerating LSP config (`make setup-lsp`)
- Cross-platform Makefile with `build`, `run`, `test`, `debug`, `release`, `format`, `setup-lsp`, `docs`, `check`

### Both projects include
- `.gitignore` tuned for CMake, compiled artifacts, coverage, and generated docs
- `scripts/build.sh`, `format.sh`, `clean.sh`
- `Doxyfile` pre-configured for HTML output with SVG call graphs
- `docs/` directory (output gitignored)
- `README.md` with full usage instructions

## Installation

Clone the repository first, then run the installer from inside it:

```bash
git clone <repo-url>
cd generate-c-cpp-project
```

#### C++ Installation

```bash
chmod +x generate-cpp-project.sh install-cpp.sh
./install-cpp.sh
```

#### C Installation

```bash
chmod +x generate-c-project.sh install-c.sh
./install-c.sh
```

The installer copies the scripts and the `lib/` directory to `/usr/local/share/generate-c-cpp-project/` and creates a wrapper command in `/usr/local/bin/`.

## Usage

```bash
generate-cpp-project my-project-name
generate-c-project my-project-name
```

## Updating

To update after pulling new changes, re-run the installer:

```bash
git pull
./install-cpp.sh   # re-installs C++ generator
./install-c.sh     # re-installs C generator
```

## Optional dependencies

Install these to unlock the full toolchain in generated projects:

```bash
sudo apt install doxygen graphviz       # HTML documentation
sudo apt install cppcheck               # static analysis
sudo apt install valgrind               # memory checking
sudo apt install lcov gcovr             # code coverage reports
sudo apt install clang-format           # code formatting
sudo apt install clang-tidy             # linting
```
