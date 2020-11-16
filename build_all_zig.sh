#!/usr/bin/env bash

set -e

date=$(date +'%Y.%m.%d')
version=${CIRCLE_BUILD_NUM-$date}
tag=v$version-$(git log --format=%h -1)

for item in $(zig targets | jq --raw-output '.libc[]' | grep gnu$ | grep x86_64)
do
    echo "$tag-$item"
    zig build -Dtarget=$item -Drelease -Duse-full-name -Dtag=$tag
done
