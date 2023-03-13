#!/bin/sh

set -e

tag="r$(./release_num.sh)"
rev=$(git log --format=%h -1)

target=$1

# TODO error if $target is empty

echo "$tag.$rev $target"
$(which time) zig build -Dtarget=$target -Duse-full-name -Dtag=$tag --prefix .
