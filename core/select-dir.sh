#! /bin/bash

cd "$(dirname "$0")" || exit 1

# shellcheck source=/dev/null
source ../cp.env

# shellcheck source=/dev/null
source ./functions/is_useable.sh

DIRECTORY="$1"
if ! is_useable "$DIRECTORY"; then
  DIRECTORY="$(dirname "$DIRECTORY")"
fi

if ! is_useable "$DIRECTORY"; then
  exit 1
fi

echo "$DIRECTORY"
