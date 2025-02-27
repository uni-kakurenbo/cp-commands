#! /bin/bash

LIBRARY_PATH=$1

TARGET=$2

OUTPUT_PATH=$3

# EXPANDED_SOURCE_PATH="../temp/expanded.cpp"

shift 3

# Regulaer
# echo "$LIBRARY_PATH/benchmark/include/"
ccache g++ \
    "$TARGET" \
    -std=gnu++23 \
    -fdiagnostics-color=always \
    -Wno-misleading-indentation \
    -Wall -Wextra -Wdangling-reference \
    -fdiagnostics-all-candidates -fconcepts-diagnostics-depth=5 \
    -Wno-char-subscripts \
    -fsplit-stack \
    -I"$HOME/boost/" \
    -I"$LIBRARY_PATH/ac-library/" \
    -I"$LIBRARY_PATH/uni/" \
    "$@" \
    -o "$OUTPUT_PATH"
# -I"$LIBRARY_PATH/uni/debugger/" \
# -isystem "$LIBRARY_PATH/benchmark/include/" -L"$LIBRARY_PATH/benchmark/build/src/" -lbenchmark \

# JOI
# ccache g++ -std=gnu++20 -fdiagnostics-color=always -Wno-misleading-indentation -Wall -Wextra -fconcepts-diagnostics-depth=5 -Wno-char-subscripts -fsplit-stack -march=native -O2 -pipe -static -s -I"$LIBRARY_PATH/uni" -o "$OUTPUT_PATH" "$@" "$TARGET"
