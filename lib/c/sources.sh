#!/bin/bash

create_sources() {
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

    printf("PASSED\n");
}

static void test_safe_strlen(void) {
    printf("Testing safe_strlen... ");

    ASSERT_EQ(safe_strlen("hello"), 5);
    ASSERT_EQ(safe_strlen(""), 0);
    ASSERT_EQ(safe_strlen(NULL), 0);

    printf("PASSED\n");
}

int main(void) {
    printf("Running C project tests...\n\n");

    test_is_valid_string();
    test_safe_strlen();

    printf("\nAll tests passed!\n");
    return EXIT_SUCCESS;
}
EOF
}
