#! /bin/bash

cd "$PWD" || exit 1
find . -ipath "./$1.*"
