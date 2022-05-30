#!/usr/bin/env bash

set -e

zig build
zigmod license > licenses.txt
zigmod sum

targets="
aarch64-linux-musl
aarch64-macos-none
x86_64-linux-musl
x86_64-macos-none
x86_64-windows-gnu
"

for item in $targets
do
    ./build_release.sh $item
done
