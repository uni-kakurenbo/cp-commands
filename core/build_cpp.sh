#! /bin/bash

LIBRARY_PATH=$1

TARGET=$2

OUTPUT_PATH=$3

# EXPANDED_SOURCE_PATH="../temp/expanded.cpp"

shift 3

# Regulaer
ccache g++-12 -std=gnu++20 -fdiagnostics-color=always -Wno-misleading-indentation -Wall -Wextra -fconcepts-diagnostics-depth=5 -Wno-char-subscripts -fsplit-stack -I"$HOME/boost" -I"$LIBRARY_PATH/ac-library" -I"$LIBRARY_PATH/original" -I"$LIBRARY_PATH/original/debugger" -o "$OUTPUT_PATH" "$@" "$TARGET"

# JOI
# ccache g++ -std=gnu++20 -fdiagnostics-color=always -Wno-misleading-indentation -Wall -Wextra -fconcepts-diagnostics-depth=5 -Wno-char-subscripts -fsplit-stack -march=native -O2 -pipe -static -s -I"$LIBRARY_PATH/original" -o "$OUTPUT_PATH" "$@" "$TARGET"
