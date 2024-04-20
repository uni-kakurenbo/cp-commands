#! /bin/bash

CALLED="$PWD"

LANGUAGE_HINT="---"
EXPAND_OPTIONS=""

ARGUMENTS=("$0")
while (($# > 0)); do
    case "$1" in
    -t | --task)
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
    -f | --file)
        TARGET="$2"
        shift
        ;;
    -C | --no-compress | --expand-compression-disabled)
        EXPAND_OPTIONS+=" --no-compress"
        ;;
    -a | --ac-lib | --expand-atcoder-library)
        EXPAND_OPTIONS+=" --acl"
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

    TARGETS=$(find . -ipath "./$FIND_QUERY")

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
if expr "$CONTEST_ID" : "[0-9]*$" >&/dev/null; then
    CONTEST_ID=$(basename "$(dirname "$CALLED")")
fi

if ! [ "$PROBLEM_INDEX" ]; then
    PROBLEM_INDEX="${ARGUMENTS[1]}"
fi
if ! [ "$PROBLEM_ID" ]; then
    PROBLEM_ID="${CONTEST_ID//-/_}_$PROBLEM_INDEX"
fi

TARGET=$(readlink -f "$TARGET")

cd "$ROOT" || exit 1
cd commands || exit 1

EXPANDER_OUTPUT_PATH="$(readlink -f ./temp/expanded)"
EXPANDER_OUTPUT_PATH+=".$EXTNAME"

if [ "$EXPAND_COMMAND" == "" ]; then
    if [ "$EXTNAME" == "cpp" ]; then
        EXPAND_COMMAND="$ROOT/commands/ccore.sh expand_cpp $ROOT/sources/libraries"
    else
        EXPAND_COMMAND="cp"
    fi
fi

sleep 2

# shellcheck disable=2086
$EXPAND_COMMAND "$TARGET" "$EXPANDER_OUTPUT_PATH" $EXPAND_OPTIONS
./ccore.sh submit "$CONTEST_ID" "$PROBLEM_ID" "$EXPANDER_OUTPUT_PATH" "$LANGUAGE_HINT" "$EXTNAME_LANGUAGE" || exit 1

echo "$(tput setaf 2)INFO: $(tput sgr0)Submitted to $(tput setaf 6)$PROBLEM_ID $(tput sgr0)at $(tput setaf 6)${CONTEST_ID}$(tput sgr0): $(tput setaf 5)$(basename "$TARGET")"
