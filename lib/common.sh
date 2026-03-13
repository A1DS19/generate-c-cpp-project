#!/bin/bash

create_structure() {
    local name="$1"
    mkdir -p "${name}"/{bin,build,docs,include,lib,scripts,src,tests,vendor}
    touch "${name}/build/.gitkeep" "${name}/bin/.gitkeep" "${name}/lib/.gitkeep" "${name}/vendor/.gitkeep"
}
