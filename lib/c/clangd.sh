#!/bin/bash

create_clangd() {
    cat > .clangd << 'EOF'
CompileFlags:
  Add:
    - -std=c23
    - -Wall
    - -Wextra
    - -I/usr/include
  Remove:
    - -W*
  Compiler: gcc

Index:
  Background: Build

Diagnostics:
  UnusedIncludes: Strict
  MissingIncludes: Strict
  ClangTidy:
    Add:
      - readability-*
      - bugprone-*
      - cert-*
      - misc-*
    Remove:
      - readability-magic-numbers
      - cert-dcl37-c
    CheckOptions:
      # Types: PascalCase (structs, enums, typedefs)
      readability-identifier-naming.StructCase: CamelCase
      readability-identifier-naming.EnumCase: CamelCase
      readability-identifier-naming.TypedefCase: CamelCase
      readability-identifier-naming.UnionCase: CamelCase

      # Functions: snake_case
      readability-identifier-naming.FunctionCase: lower_case

      # Variables: snake_case
      readability-identifier-naming.VariableCase: lower_case
      readability-identifier-naming.ParameterCase: lower_case
      readability-identifier-naming.LocalVariableCase: lower_case

      # Constants: SCREAMING_CASE
      readability-identifier-naming.ConstantCase: UPPER_CASE
      readability-identifier-naming.EnumConstantCase: UPPER_CASE
      readability-identifier-naming.MacroDefinitionCase: UPPER_CASE

InlayHints:
  Enabled: true
  ParameterNames: true
  DeducedTypes: true

Hover:
  ShowAKA: true
EOF
}
