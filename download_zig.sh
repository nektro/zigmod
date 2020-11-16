#!/usr/bin/env bash

set -x
set -e

os="linux"
arch="x86_64"
version="$1"

dir="zig-$os-$arch-$version"
file="$dir.tar.xz"

cd /
wget https://ziglang.org/download/$version/$file
tar -vxf $file
ln -s /$dir/zig /usr/local/bin
