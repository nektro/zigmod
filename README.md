# zigmod
![loc](https://sloc.xyz/github/nektro/zigmod)
[![license](https://img.shields.io/github/license/nektro/zigmod.svg)](https://github.com/nektro/zigmod/blob/master/LICENSE)
[![discord](https://img.shields.io/discord/551971034593755159.svg?logo=discord)](https://discord.gg/P6Y4zQC)
[![circleci](https://circleci.com/gh/nektro/zigmod.svg?style=svg)](https://circleci.com/gh/nektro/zigmod)
[![release](https://img.shields.io/github/v/release/nektro/zigmod)](https://github.com/nektro/zigmod/releases/latest)
[![downloads](https://img.shields.io/github/downloads/nektro/zigmod/total.svg)](https://github.com/nektro/zigmod/releases)

A package manager for the Zig programming language.

## Zig
- https://ziglang.org/
- https://github.com/ziglang/zig
- https://github.com/ziglang/zig/wiki/Community

## Download
- https://github.com/nektro/zigmod/releases

0.11.0-dev.389+e35f297ae ArrayList.toOwnedSlice
0.11.0-dev.874+40ed6ae84 field_type -> type, layout field
0.11.0-dev.692+023b597ab ascii rename
0.11.0-dev.632+d69e97ae1 compileError is comptime
0.11.0-dev.67+1d6804591  .i386 -> .x86
0.11.0-dev.1570+693b12f8e std.build.Pkg removed, updated to new system
0.11.0-dev.1567+60935decd std.zig.Ast.parse

## Built With
- Zig master (at least `0.11.0-dev.1570+693b12f8e`)
- See [`zig.mod`](./zig.mod) and [`zigmod.lock`](./zigmod.lock)

### Build from Source
```
$ git clone https://github.com/nektro/zigmod
$ cd zigmod
$ zig build
```

## Usage
Check out our [docs](docs/) or the website: https://nektro.github.io/zigmod/.

There is now also a tutorial-style getting started guide that goes over various use cases that Zigmod provides and caters to. It is [available here](docs/tutorial.md).

A package index for Zigmod packages is also available at https://aquila.red/.

## Contact
- hello@nektro.net
- https://twitter.com/nektro

## License
MIT
