#!/usr/bin/env bash

set -e

date=$(date +'%Y%m%d')
version=${CIRCLE_BUILD_NUM-$date}
tag=v$version.$(git log --format=%h -1)

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
    echo "$tag-$item"
    zig build -Dtarget=$item -Duse-full-name -Dtag=$tag
    echo
done
