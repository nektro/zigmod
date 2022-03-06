#!/usr/bin/env bash

set -e

targets="
aarch64-linux-musl
aarch64-macos-gnu
aarch64-windows-gnu
i386-linux-musl
x86_64-linux-musl
x86_64-macos-gnu
x86_64-windows-gnu
"

for item in $targets
do
    ./build_release.sh $item
done
