#! /bin/bash

TEST_PATH=./mock-judges

CALLED="$PWD"
LANGUAGE_HINT="---"

ARGUMENTS=("$0")
while (($# > 0)); do
  case "$1" in
  -p | --problem)
    PROBLEM_INDEX="$2"
    shift
    ;;
  -c | --contest)
    CONTEST_ID="$2"
    shift
    ;;
  -i | --identifier)
    PROBLEM_ID="$2"
    shift
    ;;
  -l | --lunguage-id)
    LANGUAGE_HINT="$2"
    shift
    ;;
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
  if [ ${#ARGUMENTS[@]} -lt 2 ]; then
    echo "At least one argument is required:"
    echo "1. Filename (without extension)"
    echo "[2.] Extension (Default: *)"
    exit 0
  fi

  FIND_QUERY="${ARGUMENTS[1]}"
  if [ "${ARGUMENTS[2]}" = "" ]; then
    FIND_QUERY+=".*"
  else
    FIND_QUERY+=".${ARGUMENTS[2]}"
  fi

  TARGETS=$(find . -iname "$FIND_QUERY")

  if [ "$TARGETS" == "" ]; then
    echo "$(tput setaf 3)WARN: $(tput sgr0)Source files not found: $(tput setaf 5)$FIND_QUERY"
    exit 1
  fi
fi

cd "$(dirname "${ARGUMENTS[0]}")" || exit 1

# shellcheck source=/dev/null
source cp.env

cd "$CALLED" || exit 1

if [ "$TARGET" == "" ]; then
  for FILE in $TARGETS; do
    break
  done

  TARGET=$(readlink -f "$FILE")
else
  FILE=$(basename "$TARGET")
fi

EXTNAME="${FILE##*.}"

EXTNAME_LANGUAGE="---"
if [ "$EXTNAME" == "cpp" ]; then
  EXTNAME_LANGUAGE="C++ GCC"
elif [ "$EXTNAME" == "py" ]; then
  EXTNAME_LANGUAGE="PyPy3"
elif [ "$EXTNAME" == "js" ]; then
  EXTNAME_LANGUAGE="JavaScript"
elif [ "$EXTNAME" == "txt" ]; then
  EXTNAME_LANGUAGE="Text"
fi

if ! [ "$CONTEST_ID" ]; then
  CONTEST_ID=$(basename "$CALLED")
fi
if ! [ "$PROBLEM_INDEX" ]; then
  PROBLEM_INDEX="${ARGUMENTS[1]}"
fi
if ! [ "$PROBLEM_ID" ]; then
  PROBLEM_ID="${CONTEST_ID}_$PROBLEM_INDEX"
fi

cd "$ROOT" || exit 1
cd commands || exit 1

./ccore.sh submit "$CONTEST_ID" "$PROBLEM_ID" "$TARGET" "$LANGUAGE_HINT" "$EXTNAME_LANGUAGE" || exit 1

echo "$(tput setaf 2)INFO: $(tput sgr0)Submitted to $(tput setaf 6)$PROBLEM_ID $(tput sgr0)at $(tput setaf 6)${CONTEST_ID}$(tput sgr0): $(tput setaf 5)$(basename "$TARGET")"
