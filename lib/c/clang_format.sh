#!/bin/bash

create_clang_format() {
    cat > .clang-format << 'EOF'
# C Formatting Style
# Based on LLVM with adjustments for clarity
# Run: clang-format -i <file> or enable format-on-save in your editor

BasedOnStyle: LLVM
IndentWidth: 4
TabWidth: 4
UseTab: Never
ColumnLimit: 100

# Braces on same line (Attach style)
BreakBeforeBraces: Attach

# Indentation
IndentCaseLabels: true
IndentPPDirectives: BeforeHash
NamespaceIndentation: None

# Alignment
AlignAfterOpenBracket: Align
AlignConsecutiveAssignments: false
AlignConsecutiveDeclarations: false
AlignOperands: true
AlignTrailingComments: true

# Line breaks
AllowShortBlocksOnASingleLine: Empty
AllowShortCaseLabelsOnASingleLine: false
AllowShortFunctionsOnASingleLine: Inline
AllowShortIfStatementsOnASingleLine: Never
AllowShortLoopsOnASingleLine: false
BinPackArguments: true
BinPackParameters: true
BreakBeforeBinaryOperators: None
BreakBeforeTernaryOperators: true

# Spacing
SpaceAfterCStyleCast: false
SpaceBeforeAssignmentOperators: true
SpaceBeforeParens: ControlStatements
SpaceInEmptyParentheses: false
SpacesInCStyleCastParentheses: false
SpacesInParentheses: false
SpacesInSquareBrackets: false

# Pointers and references
DerivePointerAlignment: false
PointerAlignment: Left

# Includes
IncludeBlocks: Regroup
SortIncludes: true
EOF
}
