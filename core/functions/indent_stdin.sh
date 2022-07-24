#! /bin/bash

indent_stdin() {
  while IFS= read -r line; do
    echo "$1""${line}"
  done
}
