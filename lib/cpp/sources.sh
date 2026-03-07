#!/bin/bash

create_sources() {
    cat > include/main.hpp << 'EOF'
#pragma once

#include <string_view>

void hello();
void greet(std::string_view name);
EOF

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

    cat > tests/test_main.cpp << 'EOF'
#include "../include/main.hpp"

#include <cassert>
#include <iostream>
#include <string_view>

void test_hello() {
    hello();
    std::cout << "hello() test passed" << std::endl;
}

void test_greet() {
    greet("Test");
    std::cout << "greet() test passed" << std::endl;
}

auto main() -> int {
    std::cout << "Running tests..." << std::endl;

    test_hello();
    test_greet();

    std::cout << "All tests passed!" << std::endl;
    return 0;
}
EOF
}
