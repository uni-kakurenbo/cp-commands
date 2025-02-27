#! /bin/bash

TEST_PATH=./mock-judges
COMPILE_ERROR_PATH="$TEST_PATH/.compile-error"
CASES_PATH="$TEST_PATH/cases"
CACHE_PATH="$TEST_PATH/.cache"
CASES_INFO_PATH="$CASES_PATH/.info"
EXPANDER_OUTPUT_PATH="$TEST_PATH/expanded"
COMPILER_OUTPUT_PATH="$TEST_PATH/run"
RUNNER_OUTPUT_PATH="$TEST_PATH/res"

CALLED="$PWD"

EXPAND_COMMAND=""
BUILD_COMMAND=""
EXECUTE_COMMAND=""
TEST_MODE=0
SAMPLE_INDEX=0
TIME_LIMIT_S=2
LOGGING=1
DEVELOPMENT_MODE=1
NO_LIMIT_LOG=false

EXPAND_OPTIONS=""
BUILD_OPTIONS=""
EXECUTE_OPTIONS=""

EXPAND_COMPRESS=0
FORCE=false

ARGUMENTS=("$0")
while (($# > 0)); do
    case "$1" in
    -h | --handmade)
        TEST_MODE=1
        ;;
    -L | --log-disabled | --no-log)
        LOGGING=0
        ;;
    -D | --development-mode-disabled | --no-dev)
        DEVELOPMENT_MODE=0
        ;;
    -K | --no-log-limit)
        NO_LIMIT_LOG=true
        ;;
    -r | --time | --timeout)
        TIME_LIMIT_S="$2"
        shift
        ;;
    -s | --sample | --sample-index)
        SAMPLE_INDEX="$2"
        shift
        ;;
    -t | --task | --problem)
        PROBLEM_INDEX="$2"
        shift
        ;;
    -c | --contest)
        CONTEST_ID="$2"
        shift
        ;;
    -i | --id | --identifier | --slug)
        PROBLEM_ID="$2"
        shift
        ;;
    -f | --force)
        FORCE=true
        ;;
    -p | --expand | --expander)
        EXPAND_COMMAND="$2"
        shift
        ;;
    -P | --expand-opt | --expand-options)
        EXPAND_OPTIONS+=" $2"
        shift
        ;;
    -z | --compress | --expand-compression)
        EXPAND_COMPRESS=1
        ;;
    -a | --ac-lib | --expand-atcoder-library)
        EXPAND_OPTIONS+=" --acl"
        ;;
    -b | --build | --builder)
        BUILD_COMMAND="$2"
        shift
        ;;
    -B | --build-opt | --build-options)
        BUILD_OPTIONS+=" $2"
        shift
        ;;
    -e | --exe | -executer)
        EXECUTE_COMMAND="$2"
        shift
        ;;
    -E | --exe-opt | --execute-options)
        EXECUTE_OPTIONS+=" $2"
        shift
        ;;
    -cpp:s | --cpp:sanitizer-enabled)
        BUILD_OPTIONS+=" -fsanitize=undefined,leak,address -fsanitize-address-use-after-scope"
        ;&
    -cpp:p | --cpp:polite-enabled)
        BUILD_OPTIONS+=" -ftrapv -fstack-protector-all -Wconversion -Wfloat-equal -D_GLIBCXX_DEBUG"
        ;;
    \?)
        echo "-h    | --handmade"
        echo
        echo "-L    | --log-disabled | --no-log"
        echo "-D    | --development-mode-disabled | --no-dev"
        echo "-K    | --no-log-limit"
        echo
        echo "-r {} | --time | --timeout"
        echo
        echo "-c {} | --contest"
        echo "-t {} | --task | --problem"
        echo "-s {} | --sample | --sample-index"
        echo "-i {} | --id | --identifier | --slug"
        echo "-f    | --force"
        echo
        echo "-p {} | --expand | --expander"
        echo "-P {} | --expand-opt | --expand-options"
        echo "-z    | --compress | --expand-compression"
        echo "-a    | --ac-lib | --expand-atcoder-library)"
        echo "-b {} | --build | --builder"
        echo "-B {} | --build-opt | --build-options"
        echo "-e {} | --exe | -executer"
        echo "-E {} | --exe-opt | --execute-options"
        echo
        echo "-cpp:s | --cpp:sanitizer-enabled"
        echo "-cpp:p | --cpp:polite-enabled"
        exit 0
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

if [ ${#ARGUMENTS[@]} -lt 2 ]; then
    echo "At least one argument is required:"
    echo "1. Filename (without extension)"
    echo "[2.] Extension (Default: *)"
    exit 0
fi

FIND_QUERY="${ARGUMENTS[1]}"
LANGUAGE_SELECTOR="${ARGUMENTS[2]}"

if [ "$LANGUAGE_SELECTOR" = "" ]; then
    FIND_QUERY+=".*"
else
    FIND_QUERY+=".$LANGUAGE_SELECTOR"
fi

if ! [[ $FIND_QUERY = ./* ]]; then
    FIND_QUERY="./${FIND_QUERY}"
fi

TARGETS=$(find . -ipath "$FIND_QUERY")

if [ "$TARGETS" == "" ]; then
    echo "$(tput setaf 3)WARN: $(tput sgr0)Source files not found: $(tput setaf 5)$FIND_QUERY"
    exit 1
fi

cd "$(dirname "${ARGUMENTS[0]}")" || exit 1

TEST_PATH=$(readlink -f "$TEST_PATH")
COMPILE_ERROR_PATH=$(readlink -f "$COMPILE_ERROR_PATH")
CASES_PATH=$(readlink -f "$CASES_PATH")
CASES_INFO_PATH=$(readlink -f "$CASES_INFO_PATH")
EXPANDER_OUTPUT_PATH=$(readlink -f "$EXPANDER_OUTPUT_PATH")
COMPILER_OUTPUT_PATH=$(readlink -f "$COMPILER_OUTPUT_PATH")
RUNNER_OUTPUT_PATH=$(readlink -f "$RUNNER_OUTPUT_PATH")

# shellcheck source=/dev/null
source cp.env
# shellcheck source=/dev/null
source ./core/functions/indent_stdin.sh
# # shellcheck source=/dev/null
# source ./core/functions/is_useable.sh
# shellcheck source=/dev/null
source ./core/functions/min_max.sh

# if ! is_useable "$(dirname "$CALLED")"; then
#   echo "$(tput setaf 3)WARN: $(tput sgr0)This command cannot be used within this directory."
#   exit 1
# fi

cd "$CALLED" || exit 1

for FILE in $TARGETS; do
    break
done
EXTNAME="${FILE##*.}"

EXPANDER_OUTPUT_PATH+=".$EXTNAME"

if [ "$EXPAND_COMMAND" == "" ]; then
    if [ "$EXTNAME" == "cpp" ]; then
        EXPAND_COMMAND="$ROOT/commands/ccore.sh expand_cpp $ROOT/sources/libraries"
        if [ "$EXPAND_COMPRESS" == 0 ]; then
            EXPAND_OPTIONS+=" --no-compress"
        fi
    else
        EXPAND_COMMAND="cp"
    fi
fi

if [ "$BUILD_COMMAND" == "" ]; then
    if [ "$EXTNAME" == "cpp" ]; then
        BUILD_COMMAND="$ROOT/commands/ccore.sh build_cpp $ROOT/sources/libraries"
        if [ $DEVELOPMENT_MODE == 1 ]; then
            BUILD_OPTIONS+=" -DLOCAL_JUDGE"
        fi
    else
        BUILD_COMMAND="cp"
    fi
fi

if [ "$EXECUTE_COMMAND" == "" ]; then
    if [ "$EXTNAME" == "py" ]; then
        EXECUTE_COMMAND="pypy3"
        if [ $DEVELOPMENT_MODE == 1 ]; then
            EXECUTE_OPTIONS="LOCAL_JUDGE"
        fi
    elif [ "$EXTNAME" == "js" ]; then
        EXECUTE_COMMAND="node"
    elif [ "$EXTNAME" == "txt" ]; then
        EXECUTE_COMMAND="cat"
    fi
fi

TARGET=$(readlink -f "$FILE")

cd "$ROOT" || exit 1

echo "$(tput setaf 4)INFO: $(tput sgr0)Exepanding: $(tput setaf 5)$(basename "$TARGET")"
{
    tput sgr0
    touch "$EXPANDER_OUTPUT_PATH"

    # shellcheck disable=SC2086
    time $EXPAND_COMMAND "$TARGET" "$EXPANDER_OUTPUT_PATH" $EXPAND_OPTIONS &>/dev/null
    echo
}

echo "$(tput setaf 4)INFO: $(tput sgr0)Building: $(tput setaf 5)$(basename "$EXPANDER_OUTPUT_PATH")"
{
    tput sgr0

    rm -f "$COMPILER_OUTPUT_PATH"

    # shellcheck disable=SC2086
    time $BUILD_COMMAND "$EXPANDER_OUTPUT_PATH" "$COMPILER_OUTPUT_PATH" $BUILD_OPTIONS 2>"$COMPILE_ERROR_PATH" >/dev/null
    echo
} &

if [ $TEST_MODE == 1 ]; then
    cd "$RUNNER_OUTPUT_PATH" || exit 1

    rm -f .log .status .res

    wait
    COMPILE_ERROR=$(cat "$COMPILE_ERROR_PATH")
    if ! [ -f "$COMPILER_OUTPUT_PATH" ]; then
        if [ "$COMPILE_ERROR" != "" ]; then
            echo "$(tput setaf 197)ERROR: $(tput sgr0)Failed to compile:"
            echo "$COMPILE_ERROR" | indent_stdin "  "
        fi
        exit 1
    else
        if [ "$COMPILE_ERROR" != "" ]; then
            echo "$(tput setaf 3)WARN: $(tput sgr0)Compiler warnings:"
            echo "$COMPILE_ERROR" | indent_stdin "  "
        fi
    fi

    {
        echo "$(tput setaf 109)INFO: $(tput sgr0)Running: $(tput sgr0)[PID:$BASHPID]"
        echo -n "$(tput setaf 8)>> $(tput sgr0)"
        #shellcheck disable=SC2086
        $EXECUTE_COMMAND "$COMPILER_OUTPUT_PATH" $EXECUTE_OPTIONS 1>".res" 2>".log"
        echo "$?" >.status
    }
    wait

    response=$(cat .res)
    response=$(echo "$response" | sed -E 's/^[[:blank:]]+|[[:blank:]]+$//')

    if [[ "$(wc -l <.log)" -lt 1024 || ${NO_LIMIT_LOG} ]]; then
        log=$(cat ".log")
    else
        log="$(tput setaf 3)WARN: $(tput sgr0)Too many logged messages"
    fi

    status_code=$(cat ".status")

    echo -e "\r$(tput setaf 12)---response---"
    echo "$(tput sgr0)$response"

    if [ $LOGGING == 1 ] && [ "$log" != "" ]; then
        echo "$(tput setaf 12)---log---"
        echo "$(tput sgr0)$log"
    fi

    if [ "$status_code" == "0" ]; then
        echo "$(tput setaf 109)STATUS : $(tput setaf 6)0"
    else
        echo "$(tput setaf 109)STATUS : $(tput sgr0)$status_code"
    fi

    exit 0
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

cd ./commands || exit 1

touch "$CASES_INFO_PATH"

PRE_PROBLEM_ID=$(head -n 1 "$CASES_INFO_PATH")
PRE_NUM_OF_CASES=$(head -n 2 "$CASES_INFO_PATH" | tail -n 1)

if [ "$PRE_PROBLEM_ID" == "$PROBLEM_ID" ] && [ "$PRE_NUM_OF_CASES" != "" ] && [ "$PRE_NUM_OF_CASES" != "0" ] && [ "$FORCE" != 'true' ]; then
    echo "$(tput setaf 6)INFO: $(tput sgr0)Previous cases will be used directly."
    NUM_OF_CASES="$PRE_NUM_OF_CASES"
else
    {
        CURRENT_CASE_PATH=$(find "$CACHE_PATH" -type d -name "$PROBLEM_ID")
        if [ "$CURRENT_CASE_PATH" == "" ] || [ "$PRE_NUM_OF_CASES" == "0" ] || [ "$FORCE" == 'true' ]; then
            mkdir -p "$CACHE_PATH/$PROBLEM_ID"
            chmod +x "$CACHE_PATH/$PROBLEM_ID"
            CURRENT_CASE_PATH=$(readlink -e "$CACHE_PATH/$PROBLEM_ID/")

            NUM_OF_CASES=$(./ccore.sh sample "$CONTEST_ID" "$PROBLEM_ID" "$CURRENT_CASE_PATH")

            if [ "$FORCE" != 'true' ]; then
                echo "$(tput setaf 6)INFO: $(tput sgr0)Cached cases was not exist."
            else
                echo "$(tput setaf 6)INFO: $(tput sgr0)Cached cases was ignored."
            fi

            echo "$(tput setaf 2)INFO: $(tput sgr0)Scrape from the web page."

            echo "$PROBLEM_ID" >"$CURRENT_CASE_PATH/.info"
            echo "$NUM_OF_CASES" >>"$CURRENT_CASE_PATH/.info"

            chmod +x -R "$CURRENT_CASE_PATH"
        else
            echo "$(tput setaf 6)INFO: $(tput sgr0)Cached cases was loaded."
        fi

        rm -rf "$CASES_PATH"
        mkdir "$CASES_PATH"
        cp -r "$CURRENT_CASE_PATH/." "$CASES_PATH"
    } &
fi

wait
COMPILE_ERROR=$(cat "$COMPILE_ERROR_PATH")
if ! [ -f "$COMPILER_OUTPUT_PATH" ]; then
    if [ "$COMPILE_ERROR" != "" ]; then
        echo "$(tput setaf 197)ERROR: $(tput sgr0)Failed to compile:"
        echo "$COMPILE_ERROR" | indent_stdin "  "
    fi
    exit 1
fi

NUM_OF_CASES=$(head -n 2 "$CASES_INFO_PATH" | tail -n 1)

if [ "$NUM_OF_CASES" -lt 1 ]; then
    echo "$(tput setaf 1)ERROR: $(tput sgr0)Sample cases not found."
    exit 1
fi

mkdir -p "$RUNNER_OUTPUT_PATH" && cd "$RUNNER_OUTPUT_PATH" || exit 1
rm -rf ./*

function test_sample_case() {
    local index="$1"
    local input_file="$CASES_PATH/${index}.in" output_file="$CASES_PATH/${index}.out"
    if ! [ -f "$input_file" ] || ! [ -f "$output_file" ]; then
        echo "$(tput setaf 1)ERROR: $(tput sgr0)Sample case $index does not exist."
        exit 1
    fi
    {
        local started_at ended_at
        started_at=$(date +%s.%N)
        echo "$(tput setaf 109)INFO: $(tput sgr0)Running: $(tput setaf 109)${index} $(tput sgr0)[PID:$BASHPID]"
        timeout "$TIME_LIMIT_S" $EXECUTE_COMMAND "$COMPILER_OUTPUT_PATH" $EXECUTE_OPTIONS <"$input_file" 1>"$index.res" 2>"$index.log"
        echo "$?" >"$index.status"
        ended_at=$(date +%s.%N)
        local execute_time
        execute_time=$(echo "($ended_at- $started_at) * 1000" | bc)
        echo "$execute_time" >"$index.time"
    } &
}

if [ "$SAMPLE_INDEX" == 0 ]; then
    for index in $(seq 1 "$NUM_OF_CASES"); do
        test_sample_case "$index"
    done
else
    for index in $(echo "$SAMPLE_INDEX" | fold -s1); do
        test_sample_case "$index"
    done
    NUM_OF_CASES=${#SAMPLE_INDEX}
fi

wait

AC_COUNT=0
TIME_INFO=("$TIME_LIMIT_S"0000 0 -"$TIME_LIMIT_S"0000)

function print_results() {
    local index="$1"
    local response log

    local input_file="$CASES_PATH/${index}.in"
    local output_file="$CASES_PATH/${index}.out"
    input_data=$(cat "$input_file")
    expected_output=$(cat "$output_file")

    response=$(cat "$index.res")
    response=$(echo "$response" | sed -E 's/^[[:blank:]]+|[[:blank:]]+$//')

    if [[ "$(wc -l <"$index.log")" -lt 1024 || ${NO_LIMIT_LOG} ]]; then
        log=$(cat "$index.log")
    else
        log="$(tput setaf 3)WARN: $(tput sgr0)Too many logged messages"
    fi

    local time_required
    time_required=$(cat "$index.time")
    TIME_INFO[0]="$(min "${TIME_INFO[0]}" "${time_required}")"
    TIME_INFO[2]="$(max "${TIME_INFO[2]}" "${time_required}")"
    TIME_INFO[1]=$(echo "${TIME_INFO[1]} + $time_required" | bc -l)

    status_code=$(cat "$index.status")

    echo
    echo "$(tput setaf 14)----- Samplse Case $index -----"
    echo "$(tput setaf 13)---inputted---"
    echo "$(tput sgr0)$input_data"
    echo "$(tput setaf 13)---expected---"
    echo "$(tput sgr0)$expected_output"
    echo "$(tput setaf 12)---response---"
    echo "$(tput sgr0)$response"
    if [ $LOGGING == 1 ] && [ "$log" != "" ]; then
        echo "$(tput setaf 12)---log---"
        echo "$(tput sgr0)$log"
    fi
    tput setaf 202

    expected_output=$(echo "$expected_output" | sed -E -z 's/[ \f\n\r\t]*/ /g')
    response=$(echo "$response" | sed -E -z 's/[ \f\n\r\t]*/ /g')

    if [ "$status_code" != "0" ]; then
        if [ "$status_code" == "124" ]; then
            echo "JUDGE  : TLE"
        else
            echo "JUDGE  : RE"
        fi
    elif [ "$response" == "$expected_output" ]; then
        echo "$(tput setaf 10)JUDGE  : AC"
        AC_COUNT=$((AC_COUNT + 1))
    else
        echo "JUDGE  : WA"
    fi
    if [ "$status_code" == "0" ]; then
        echo "$(tput setaf 109)STATUS : $(tput setaf 6)0"
    else
        echo "$(tput setaf 109)STATUS : $(tput sgr0)$status_code"
    fi
    echo "$(tput setaf 109)TIME   : $(tput sgr0)$(echo "scale=2; $time_required / 1" | bc)[ms]"
}

if [ "$SAMPLE_INDEX" == 0 ]; then
    for index in $(seq 1 "$NUM_OF_CASES"); do
        print_results "$index"
    done
else
    for index in $(echo "$SAMPLE_INDEX" | fold -s1); do
        print_results "$index"
    done
    NUM_OF_CASES=${#SAMPLE_INDEX}
fi

if [ "$AC_COUNT" == "$NUM_OF_CASES" ]; then
    final_result="$(tput setaf 148)ACCEPTED"
else
    final_result="$(tput setaf 204)REJECTED"
fi

echo
echo "$(tput setaf 9)AC: ${AC_COUNT}/${NUM_OF_CASES}"
echo "$(tput setaf 183)----- Summary -----"
echo "$final_result$(tput sgr0)"
echo -n "$(echo "scale=2; ${TIME_INFO[0]} / 1" | bc -l)[ms] ― "
echo -n "$(echo "scale=2; ${TIME_INFO[1]} / $NUM_OF_CASES" | bc -l)[ms] ― "
echo "$(echo "scale=2; ${TIME_INFO[2]} / 1" | bc -l)[ms] "

if [ "$COMPILE_ERROR" != "" ]; then
    echo
    echo "$(tput setaf 3)WARN: $(tput sgr0)Compiler warnings:"
    echo "$COMPILE_ERROR" | indent_stdin "  "
fi

if [ "$AC_COUNT" = "$NUM_OF_CASES" ]; then
    echo
    echo "$(tput setaf 2)INFO: $(tput sgr0)All Cases were accepted."
    echo "$(tput setaf 6)INFO: $(tput sgr0)Do you want to copy to the clipboard or submit? (clp/sub/..)"

    read -p "$(tput setaf 8)>> $(tput sgr0)" -r input_data

    cd "$ROOT" || exit 1
    cd ./commands || exit 1

    if [ "$input_data" == "clp" ]; then
        ./clip.sh -f "$TARGET"
    elif [ "$input_data" == "sub" ]; then
        ./submit.sh -f "$TARGET" -c "$CONTEST_ID" -i "$PROBLEM_ID"
    fi
fi
