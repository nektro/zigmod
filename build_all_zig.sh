#!/usr/bin/env bash

set -e

date=$(date +'%Y.%m.%d')
version=${CIRCLE_BUILD_NUM-$date}
tag=v$version.$(git log --format=%h -1)

targets="
aarch64-linux-gnu
x86_64-linux-gnu
x86_64-windows-gnu
x86_64-macos-gnu
"

for item in $targets
do
    echo "$tag-$item"
    zig build -Dtarget=$item -Drelease -Duse-full-name -Dtag=$tag
done
