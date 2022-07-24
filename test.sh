#! /bin/bash

TEST_PATH=./mock-judges
COMPILE_ERROR_PATH="$TEST_PATH/.compile-error"
CASES_PATH="$TEST_PATH/cases"
CACHE_PATH="$TEST_PATH/.cache"
CASES_INFO_PATH="$CASES_PATH/.info"
COMPILER_OUTPUT_PATH="$TEST_PATH/run"
RUNNER_OUTPUT_PATH="$TEST_PATH/res"

CALLED="$PWD"

TEST_MODE=0
SAMPLE_INDEX=0
TIME_LIMIT_S=2
LOGGING=1
DEVELOPMENT_MODE=1

ARGUMENTS=("$0")
while (($# > 0)); do
  case "$1" in
  -h | --handmade)
    TEST_MODE=1
    ;;
  -L | --log-off)
    LOGGING=0
    ;;
  -D | --development-mode-off)
    DEVELOPMENT_MODE=0
    ;;
  -t | --timeout)
    TIME_LIMIT_S="$2"
    shift
    ;;
  -s | --sample)
    SAMPLE_INDEX="$2"
    shift
    ;;
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

cd "$(dirname "${ARGUMENTS[0]}")" || exit 1

TEST_PATH=$(readlink -f "$TEST_PATH")
COMPILE_ERROR_PATH=$(readlink -f "$COMPILE_ERROR_PATH")
CASES_PATH=$(readlink -f "$CASES_PATH")
CASES_INFO_PATH=$(readlink -f "$CASES_INFO_PATH")
COMPILER_OUTPUT_PATH=$(readlink -f "$COMPILER_OUTPUT_PATH")
RUNNER_OUTPUT_PATH=$(readlink -f "$RUNNER_OUTPUT_PATH")

# shellcheck source=/dev/null
source cp.env
# shellcheck source=/dev/null
source ./core/functions/indent_stdin.sh
# shellcheck source=/dev/null
source ./core/functions/is_useable.sh
# shellcheck source=/dev/null
source ./core/functions/min_max.sh

if ! is_useable "$(dirname "$CALLED")"; then
  echo "$(tput setaf 3)WARN: $(tput sgr0)This command cannot be used in the directory."
  exit 1
fi

cd "$CALLED" || exit 1

for FILE in $TARGETS; do
  break
done
EXTNAME="${FILE##*.}"

BUILD_COMMAND=""
BUILD_OPTIONS=""
EXECUTE_COMMAND=""
EXECUTE_OPTIONS=""

if [ "$EXTNAME" == "cpp" ]; then
  BUILD_COMMAND="$ROOT/commands/ccore.sh build_cpp $ROOT/sources/libraries"
  if [ $DEVELOPMENT_MODE == 1 ]; then
    BUILD_OPTIONS="-DLOCAL_JUDGE"
  fi
else
  BUILD_COMMAND="cp"
fi

if [ "$EXTNAME" == "py" ]; then
  EXECUTE_COMMAND="python3.8"
  if [ $DEVELOPMENT_MODE == 1 ]; then
    EXECUTE_OPTIONS="LOCAL_JUDGE"
  fi
elif [ "$EXTNAME" == "js" ]; then
  EXECUTE_COMMAND="node"
elif [ "$EXTNAME" == "txt" ]; then
  EXECUTE_COMMAND="cat"
fi

TARGET=$(readlink -f "$FILE")

cd "$ROOT" || exit 1

echo "$(tput setaf 4)INFO: $(tput sgr0)Building: $(tput setaf 5)$(basename "$TARGET")"
{
  tput sgr0

  rm -f "$COMPILER_OUTPUT_PATH"

  $BUILD_COMMAND "$TARGET" "$COMPILER_OUTPUT_PATH" $BUILD_OPTIONS 2>"$COMPILE_ERROR_PATH" >/dev/null
} &

if [ $TEST_MODE == 1 ]; then
  cd "$RUNNER_OUTPUT_PATH" || exit 1
  rm -rf ./*

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
      echo "$(tput setaf 3)WARN: $(tput sgr0)Notes from the compiler:"
      echo "$COMPILE_ERROR" | indent_stdin "  "
    fi
  fi

  {
    echo "$(tput setaf 109)INFO: $(tput sgr0)Running: $(tput sgr0)[PID:$BASHPID]"
    echo -n "$(tput setaf 8)>> $(tput sgr0)"
    $EXECUTE_COMMAND "$COMPILER_OUTPUT_PATH" $EXECUTE_OPTIONS 1>".res" 2>".log"
    echo "$?" >.status
  }
  wait

  response=$(cat .res)
  response=$(echo "$response" | sed -E 's/^[[:blank:]]+|[[:blank:]]+$//')

  if [ "$(wc -l <.log)" -lt 100 ]; then
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
if ! [ "$PROBLEM_INDEX" ]; then
  PROBLEM_INDEX="${ARGUMENTS[1]}"
fi
if ! [ "$PROBLEM_ID" ]; then
  PROBLEM_ID="${CONTEST_ID}_$PROBLEM_INDEX"
fi

cd ./commands || exit 1

touch "$CASES_INFO_PATH"

PRE_PROBLEM_ID=$(head -n 1 "$CASES_INFO_PATH")
PRE_NUM_OF_CASES=$(head -n 2 "$CASES_INFO_PATH" | tail -n 1)

if [ "$PRE_PROBLEM_ID" == "$PROBLEM_ID" ] && [ "$PRE_NUM_OF_CASES" != "" ] && [ "$PRE_NUM_OF_CASES" != "0" ]; then
  echo "$(tput setaf 6)INFO: $(tput sgr0)Previous cases will be used directly."
  NUM_OF_CASES="$PRE_NUM_OF_CASES"
else
  {
    CURRENT_CASE_PATH=$(find "$CACHE_PATH" -type d -name "$PROBLEM_INDEX")
    if [ "$CURRENT_CASE_PATH" == "" ]; then
      mkdir -p "$CACHE_PATH/$PROBLEM_ID"
      chmod +x "$CACHE_PATH/$PROBLEM_ID"
      CURRENT_CASE_PATH=$(readlink -e "$CACHE_PATH/$PROBLEM_ID/")

      NUM_OF_CASES=$(./ccore.sh sample "$CONTEST_ID" "$PROBLEM_ID" "$CURRENT_CASE_PATH")

      echo "$(tput setaf 6)INFO: $(tput sgr0)Cached cases was not exist."
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

cd "$RUNNER_OUTPUT_PATH" || exit 1
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
  if [ "$(wc -l <"$index.log")" -lt 100 ]; then
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
  echo "$(tput setaf 3)WARN: $(tput sgr0)Notes from the compiler:"
  echo "$COMPILE_ERROR" | indent_stdin "  "
fi

if [ "$AC_COUNT" = "$NUM_OF_CASES" ]; then
  echo
  echo "$(tput setaf 2)INFO: $(tput sgr0)All Cases were accepted."
  echo "$(tput setaf 6)INFO: $(tput sgr0)Do you want to copy to the clipboard? (y/n)"
  read -p "$(tput setaf 8)>> $(tput sgr0)" -r input_data
  if ! { [ "$input_data" == "y" ] || [ "$input_data" == "yes" ] || [ "$input_data" == "YES" ]; }; then
    exit 0
  fi
  cd "$ROOT" || exit 1
  clip.exe <"$TARGET"
  echo "$(tput setaf 6)INFO: $(tput sgr0)Copied to the clipboard: $(tput setaf 5)$(basename "$TARGET")"
fi
