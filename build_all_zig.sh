#!/bin/sh

set -e

zig build

targets="
x86_64-linux-musl
x86_64-macos-none

aarch64-linux-musl
aarch64-macos-none

riscv64-linux-musl

powerpc64le-linux-musl

mips64el-linux-muslabi64

s390x-linux-musl
"

for item in $targets
do
    ./build_release.sh $item
done
