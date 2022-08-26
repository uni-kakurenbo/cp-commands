#! /bin/bash

BITS=/usr/include/x86_64-linux-gnu/c++/9/bits

cd "$(dirname "$0")" || exit 1

# shellcheck source=/dev/null
source cp.env

LIBRARY_PATH="$ROOT/sources/libraries"

sudo "$ROOT/commands/ccore.sh" build_cpp "$LIBRARY_PATH" "$BITS/stdc++.h" "$BITS/stdc++.h.gch"
sudo "$ROOT/commands/ccore.sh" build_cpp "$LIBRARY_PATH" "$LIBRARY_PATH/debugger/debug.hpp" "$LIBRARY_PATH/debugger/debug.hpp.gch"
