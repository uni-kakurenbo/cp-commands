#!/bin/bash

CALLED="$PWD"

ARGUMENTS=("$0")
while (($# > 0)); do
  case "$1" in
  -c | --contest)
    CONTEST_ID="$2"
    shift
    ;;
  -*)
    echo "$(tput setaf 1)ERROR: $(tput sgr0)Unexpected command option: $(tput setaf 5)$1"
    exit 1
    ;;
  *)
    ARGUMENTS=("${ARGUMENTS[@]}" "$1")
    ;;
  esac
  shift
done

if ! [ "$CONTEST_ID" ]; then
  CONTEST_ID=$(basename "$CALLED")
fi
if expr "$CONTEST_ID" : "[0-9]*$" >&/dev/null; then
    CONTEST_ID=$(basename "$(dirname "$CALLED")")
fi

PROBLEM_ID="${ARGUMENTS[1]}"

cd "$(dirname "${ARGUMENTS[0]}")" || exit 1

# shellcheck source=/dev/null
source cp.env

# shellcheck source=/dev/null
source ./core/functions/is_useable.sh

is_useable "$CALLED"
FIRST="$?"
is_useable "$(dirname "$CALLED")"
SECOND="$?"
is_useable "$(dirname "$(dirname "$CALLED")")"
THIRD="$?"

URL=""

if [ "$FIRST" == "0" ] || [ "$SECOND" == "0" ] || [ "$THIRD" == "0" ]; then
  URL="https://atcoder.jp/contests/$CONTEST_ID"
else
  echo "$(tput setaf 3)WARN: $(tput sgr0)This command cannot be used within this directory."
  exit 1
fi

if { [ "$SECOND" == "0" ] || [ "$THIRD" == "0" ]; } && [ "$PROBLEM_ID" != "" ]; then
  if [ "$PROBLEM_ID" == "sub" ]; then
    URL+="/submissions/me"
  else
    URL+="/tasks/${CONTEST_ID//-/_}_$PROBLEM_ID"
  fi
fi

echo "$(tput setaf 2)INFO: $(tput sgr0)Oepn: $(tput setaf 6)$URL"
"$CHROME_PATH" "$URL"
