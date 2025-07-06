#!/bin/bash

CALLED="$PWD"

WRITE_PATH=""
EXPAND_OPTIONS=""

ARGUMENTS=("$0")
while (($# > 0)); do
    case "$1" in
    -f | --file)
        TARGET="$2"
        shift
        ;;
    -a | --ac-lib | --expand-atcoder-library)
        EXPAND_OPTIONS+=" --acl"
        ;;
    -C | --no-compress | --expand-compression-disabled)
        EXPAND_OPTIONS+=" --no-compress"
        ;;
    -w | --write)
        WRITE_PATH=$(readlink -f "${2:-out.cpp}")
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

EXTNAME=""

if [ "$TARGET" == "" ]; then
    if [ ${#ARGUMENTS[@]} -lt 1 ]; then
        echo "At least one argument is required:"
        echo "1. File Name"
        echo "[2.] Extension (Default: *)"
        exit 0
    fi
    FILE="${ARGUMENTS[1]}"

    FILENAME_WITHOUT_EXT="${FILE%.*}"
    EXTNAME="${FILE##*.}"

    if [ "$FILENAME_WITHOUT_EXT" == "$EXTNAME" ]; then
        if [ "${ARGUMENTS[2]}" == "" ]; then
            EXTNAME="*"
        else
            EXTNAME="${ARGUMENTS[2]}"
        fi
        FILE+=.$EXTNAME
    fi

    TARGETS=$(find . -ipath "./$FILE")

    if [ "$TARGETS" == "" ]; then
        echo "$(tput setaf 3)WARN: $(tput sgr0)Source files not found: $(tput setaf 5)$FILE"
        exit 1
    fi

    for TARGET in $TARGETS; do
        break
    done
fi

EXTNAME="${TARGET##*.}"

TARGET=$(readlink -f "$TARGET")

cd "$(dirname "${ARGUMENTS[0]}")" || exit 1

# shellcheck source=/dev/null
source cp.env

cd "$ROOT" || exit 1
cd commands || exit 1

EXPANDER_OUTPUT_PATH="$(readlink -f ./mock-judges/expanded)"
EXPANDER_OUTPUT_PATH+=".$EXTNAME"

if [ "$EXPAND_COMMAND" == "" ]; then
    if [ "$EXTNAME" == "cpp" ] || [ "$EXTNAME" == "cxx" ] || [ "$EXTNAME" == "hpp" ]; then
        EXPAND_COMMAND="$ROOT/commands/ccore.sh expand_cpp $ROOT/sources/libraries"
    else
        EXPAND_COMMAND="cp"
    fi
fi

# shellcheck disable=2086
$EXPAND_COMMAND "$TARGET" "$EXPANDER_OUTPUT_PATH" $EXPAND_OPTIONS

if [ "${WRITE_PATH}" != "" ]; then
    cp "${EXPANDER_OUTPUT_PATH}" "${WRITE_PATH}"
fi

clip.exe <"$EXPANDER_OUTPUT_PATH"
echo "$(tput setaf 6)INFO: $(tput sgr0)Copied to the clipboard: $(tput setaf 5)$(basename "$EXPANDER_OUTPUT_PATH")"

cd "$CALLED" || exit 1
