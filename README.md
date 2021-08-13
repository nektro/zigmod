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

## Built With
- Zig master `0.9.0-dev.787+c53423f8a`
- https://github.com/yaml/libyaml
- https://github.com/nektro/zig-ansi
- https://github.com/ziglibs/known-folders
- https://github.com/nektro/zig-licenses
- https://github.com/truemedian/zfetch
- https://github.com/nektro/zig-json
- https://github.com/nektro/zig-range
- https://github.com/marlersoft/zigwin32
- https://github.com/nektro/zig-detect-license
- https://github.com/nektro/zig-inquirer
- https://github.com/arqv/ini

### Build from Source
Initially,
```
$ git clone https://github.com/nektro/zigmod --recursive
$ cd zigmod
$ zig build -Dbootstrap
$ ./zig-out/bin/zigmod fetch
```

To build,
```
$ zig build
$ ./zig-out/bin/zigmod
```

## Usage
Check out our [docs](docs/) or the website: https://nektro.github.io/zigmod/.

## Prior Art
- https://golang.org/ref/mod#go-mod-file
- https://github.com/mattnite/zkg

## Honorable mentions
- https://github.com/truemedian
- https://github.com/MasterQ32

## Contact
- hello@nektro.net
- https://twitter.com/nektro

## License
MIT
