#!/usr/bin/env bash

set -e

tag="r$(./release_num.sh)"
rev=$(git log --format=%h -1)

target=$1

if [[ "$1" == "" ]]
then
  exit 2
fi

echo "$tag.$rev $target"
$(which time) zig build -Dtarget=$target -Duse-full-name -Dtag=$tag --prefix .
