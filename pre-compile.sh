#! /bin/bash

BITS=/usr/include/x86_64-linux-gnu/c++/12/bits

cd "$(dirname "$0")" || exit 1

# shellcheck source=/dev/null
source cp.env

LIBRARY_PATH="$ROOT/sources/libraries"

sudo rm "$BITS/stdc++.h.gch"

sudo "$ROOT/commands/ccore.sh" build_cpp "$LIBRARY_PATH" "$BITS/stdc++.h" "$BITS/stdc++.h.gch"
# sudo "$ROOT/commands/ccore.sh" build_cpp "$LIBRARY_PATH" "$LIBRARY_PATH/uni/debugger/debug.hpp" "$LIBRARY_PATH/uni/debugger/debug.hpp.gch"
