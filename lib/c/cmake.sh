#!/bin/bash

create_cmake() {
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
option(ENABLE_SANITIZERS "Enable AddressSanitizer and UBSan (incompatible with Valgrind)" ON)

if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    target_compile_options(main PRIVATE
        -Wall -Wextra -Wpedantic -Wstrict-prototypes
        -Wconversion -Wsign-conversion -Wcast-align
        -Wwrite-strings -Wpointer-arith -Winit-self
        -Wvla -Wundef -Wshadow -Wstrict-overflow=5
        $<$<CONFIG:Debug>:-g3 -O0 -DDEBUG -fstack-protector-strong -Werror>
        $<$<CONFIG:Release>:-O3 -DNDEBUG -march=native>
    )
    if(ENABLE_SANITIZERS AND CMAKE_BUILD_TYPE STREQUAL "Debug")
        target_compile_options(main PRIVATE -fsanitize=address,undefined)
        target_link_options(main PRIVATE -fsanitize=address,undefined)
    endif()
elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
    target_compile_options(main PRIVATE
        -Wall -Wextra -Wpedantic -Wstrict-prototypes
        -Wconversion -Wsign-conversion -Wcast-align
        -Wwrite-strings -Wpointer-arith -Winit-self
        -Wvla -Wundef -Wshadow
        $<$<CONFIG:Debug>:-g3 -O0 -DDEBUG -Werror>
        $<$<CONFIG:Release>:-O3 -DNDEBUG>
    )
elseif(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(main PRIVATE
        /W4 /permissive- /analyze
        $<$<CONFIG:Debug>:/Od /RTC1 /DDEBUG /WX>
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

# Vendor libraries — auto-detected from vendor/*/src/ and vendor/*/include/
# To add a new library: drop it into vendor/<name>/src/ and vendor/<name>/include/
# All vendor sources are compiled into a single static library called "vendor".
# -w suppresses all warnings since we don't own this code.
file(GLOB_RECURSE VENDOR_SOURCES ${CMAKE_SOURCE_DIR}/vendor/*/src/*.c)
if(VENDOR_SOURCES)
    add_library(vendor STATIC ${VENDOR_SOURCES})
    # Add every vendor/<lib>/include as a public include path
    file(GLOB VENDOR_DIRS LIST_DIRECTORIES true ${CMAKE_SOURCE_DIR}/vendor/*)
    foreach(VENDOR_DIR ${VENDOR_DIRS})
      if(IS_DIRECTORY ${VENDOR_DIR})
        target_include_directories(vendor PUBLIC ${VENDOR_DIR}/include)
      endif()
    endforeach()
    set_target_properties(vendor PROPERTIES COMPILE_FLAGS "-w")
    target_link_libraries(main PRIVATE vendor)
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
                    -Wvla -Wundef -Wshadow -Wstrict-overflow=5
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
}
