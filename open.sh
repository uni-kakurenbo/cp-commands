#! /bin/bash

CALLED="$PWD"

if [ $# -lt 1 ]; then
    echo "At least one argument is required:"
    echo "1. File Name"
    echo "[2.] Extension (Default: .cpp)"
    exit 0
fi

FILE="$1"
FILENAME_WITHOUT_EXT="${FILE%.*}"
EXTNAME="${FILE##*.}"
if [ "$FILENAME_WITHOUT_EXT" == "$EXTNAME" ]; then
    if [ "$2" == "" ]; then
        PREV=$(find . -ipath "./$1.*")
        if [ "$PREV" != "" ]; then
            if [ "$(printf "%s\n" "$PREV" | wc -l)" -gt 3 ]; then
                echo "$(tput setaf 197)ERROR: $(tput sgr0)Too many files are matched."
                exit 1
            fi
            # shellcheck disable=2116,2086
            echo "$(tput setaf 6)INFO: $(tput sgr0)Some files were found that already exist:$(tput setaf 5) $(echo $PREV)"
            echo "$(tput setaf 2)INFO: $(tput sgr0)Open them."
            for file in $PREV; do
                code "$file"
            done
            exit 0
        fi
        if [[ "$CALLED" == *"abc"* ]] && { [ "$FILE" == "a" ] || [ "$FILE" == "b" ]; }; then
            EXTNAME="py"
        else
            EXTNAME="cpp"
        fi
    else
        EXTNAME=$2
    fi
    FILE+=.$EXTNAME
fi

FOUND=$(find . -ipath "./$FILE")
if [ "$FOUND" == "" ]; then
    echo "$(tput setaf 6)INFO: $(tput sgr0)Could not find the file."
    echo "$(tput setaf 10)INFO: $(tput sgr0)Do you want to create a new file? (y/n)"
    read -p "$(tput setaf 8)>> $(tput sgr0)" -r input
    if ! { [ "$input" == "y" ] || [ "$input" == "yes" ] || [ "$input" == "YES" ]; }; then
        exit 0
    fi
else
    for TARGET in $FOUND; do
        break
    done
    echo "$(tput setaf 6)INFO: $(tput sgr0)The file was found that already exist:$(tput setaf 5) $TARGET"
    code "$TARGET"
    exit 0
fi

cd "$(dirname "$0")" || exit 1
# shellcheck source=/dev/null
source cp.env

cd "$ROOT" || exit 1

touch "./sources/templates/template.$EXTNAME"
TEMPLATE=$(readlink -f "./sources/templates/template.$EXTNAME")

cd "$CALLED" || exit 1

echo "$(tput setaf 2)INFO: $(tput sgr0)Create a new file and open it: $(tput setaf 5)$FILE"
cp -n "$TEMPLATE" "./$FILE"
code "$FILE"
