#!/usr/bin/env bash

set -x
set -e

os="linux"
arch="x86_64"
version="$1"

dir="zig-$os-$arch-$version"
file="$dir.tar.xz"

cd /
tar -xf $file
ln -s /$dir/zig /usr/local/bin

if [[ $1 == *"dev"* ]]; then
    wget https://ziglang.org/builds/$file
else
    wget https://ziglang.org/download/$version/$file
fi

