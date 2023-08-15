#!/bin/sh

set -e

zig build
zigmod license > licenses.txt
zigmod sum

targets="
x86_64-linux-musl
x86_64-macos-none
x86_64-windows-gnu
aarch64-linux-musl
aarch64-macos-none
aarch64-windows-gnu
riscv64-linux-musl
"

for item in $targets
do
    ./build_release.sh $item
done
