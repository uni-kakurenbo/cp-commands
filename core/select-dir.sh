#! /bin/bash

cd "$(dirname "$0")" || exit 1

# shellcheck source=/dev/null
source ../cp.env

# shellcheck source=/dev/null
source ./functions/isUseable.sh

DIRECTORY="$1"
if ! isUseable "$DIRECTORY"; then
  DIRECTORY="$(dirname "$DIRECTORY")"
fi

if ! isUseable "$DIRECTORY"; then
  exit 1
fi

echo "$DIRECTORY"
