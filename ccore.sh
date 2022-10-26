#!/bin/bash

cd "$(dirname "$0")" || exit 1

# shellcheck source=/dev/null
source cp.env

cd "$ROOT" || exit 1
cd ./commands/core || exit 1

subcommand="$1"
shift

EXIT_CODE=0
case $subcommand in
expand_cpp)
  RESPONSE="$(./expand_cpp.sh "$@")"
  ;;
build_cpp)
  RESPONSE="$(./build_cpp.sh "$@")"
  ;;
select-dir)
  RESPONSE="$(./select-dir.sh "$@")"
  ;;
sample)
  RESPONSE="$(node ./scrape-sample-cases.js "$@")"
  ;;
submit)
  RESPONSE="$(node ./submit-code.js "$@")"
  ;;
esac
EXIT_CODE=$?

echo "$RESPONSE"
exit "$EXIT_CODE"
