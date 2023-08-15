#!/bin/sh

set -eu

tag="r$(./release_num.sh)"
rev=$(git log --format=%h -1)

target=$1

echo "$tag.$rev $target"
$(which time) zig build -Dtarget=$target -Duse-full-name -Dtag=$tag --prefix .
