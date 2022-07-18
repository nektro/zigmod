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
- Zig master (at least `0.10.0-dev.3027+0e26c6149`)
- See [`zig.mod`](./zig.mod) and [`zigmod.lock`](./zigmod.lock)

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

There is now also a tutorial-style getting started guide that goes over various use cases that Zigmod provides and caters to. It is [available here](docs/tutorial.md).

A package index for Zigmod packages is also available at https://aquila.red/.

## Contact
- hello@nektro.net
- https://twitter.com/nektro

## License
MIT
