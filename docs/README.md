# `zigmod` Documentation

Zigmod is a prototype package manager for the Zig programming language.

You can learn more about Zig here:
- https://ziglang.org/
- https://github.com/ziglang/zig

The rest of this documentation will assume you already have Zig installed.

As Zig is still in development itself, if you plan to contribute to Zigmod you will need a master download of Zig. Those can be obtained from https://ziglang.org/download/#release-master. The most recent release Zigmod was verified to work with is `0.8.0-dev.1158+0aef1faa8`.

## Download
You may download a precompiled binary from https://github.com/nektro/zigmod/releases or build the project from source.

### Build Zigmod from source
Assuming you have Zig master installed,
```
$ git clone https://github.com/nektro/zigmod --recursive
$ cd zigmod
$ zig build -Dbootstrap
$ ./zig-cache/bin/zigmod fetch
$ zig build
$ ./zig-cache/bin/zigmod
```

## Getting Started

For a full command reference you can check [here](./commands/).

### A new project
Create a new directory for your project and run these commands to get started:
```
$ git init
$ zig init-exe
$ zigmod init
```

## Principles
Zigmod is but a prototype and not the official Zig package manager. As such I wanted to lay out some of the guiding principles learned/used when making the project. You can find that document [here](./principles.md).

## Contact
- https://github.com/nektro/zigmod/issues
- hello@nektro.net
- https://twitter.com/nektro

## License
MIT
