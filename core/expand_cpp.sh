#! /bin/bash

LIBRARY_PATH=$1

TARGET=$2
OUTPUT_PATH=$3

shift 3

pypy3 expander.py "$TARGET" --lib "$LIBRARY_PATH/original;$LIBRARY_PATH/original/debugger; $LIBRARY_PATH/original/outputter" --console > "$OUTPUT_PATH"
