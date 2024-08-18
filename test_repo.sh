#!/bin/sh

set -e

clone_url=$1
clone_dir=$(mktemp -d)

git clone $clone_url $clone_dir
cd $clone_dir

zigmod fetch

zig build test --summary all
