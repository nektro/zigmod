#!/bin/sh

set -x
set -e

os="linux"
arch="x86_64"
version="$1"

dir="zig-$os-$arch-$version"
file="$dir.tar.xz"

cd ~
apk add wget tar
wget https://ziglang.org/download/$version/$file
tar -vxf $file
ln -s ~/$dir/zig /bin
