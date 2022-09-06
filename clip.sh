#!/bin/bash

ARGUMENTS=("$0")
while (($# > 0)); do
  case "$1" in
  -t | --target)
    TARGET="$2"
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

if [ "$TARGET" == "" ]; then
  if [ $# -lt 1 ]; then
    echo "At least one argument is required:"
    echo "1. File Name"
    echo "[2.] Extension (Default: *)"
    exit 0
  fi
  FILE="$1"

  FILENAME_WITHOUT_EXT="${FILE%.*}"
  EXTNAME="${FILE##*.}"

  if [ "$FILENAME_WITHOUT_EXT" == "$EXTNAME" ]; then
    if [ "$2" == "" ]; then
      EXTNAME="*"
    else
      EXTNAME=$2
    fi
    FILE+=.$EXTNAME
  fi

  TARGETS=$(find . -iname "$FILE")

  if [ "$TARGETS" == "" ]; then
    echo "$(tput setaf 3)WARN: $(tput sgr0)Source files not found: $(tput setaf 5)$FILE"
    exit 1
  fi

  for TARGET in $TARGETS; do
    break
  done
fi

clip.exe <"$TARGET"
echo "$(tput setaf 6)INFO: $(tput sgr0)Copied to the clipboard: $(tput setaf 5)$(basename "$TARGET")"
