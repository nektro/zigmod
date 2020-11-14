#!/bin/sh

set -e

for item in $(zig targets | jq --raw-output '.libc[]' | grep gnu$ | grep x86_64)
do
    echo $item
    zig build -Dtarget=$item -Drelease -Duse-full-name
done
