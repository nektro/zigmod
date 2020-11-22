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
- Zig 0.7.0

### Build from Source
Initially,
```
$ git clone https://github.com/nektro/zigmod --recursive
```

To build,
```
$ zig build
$ ./zig-cache/bin/zigmod
```

## Usage

### `init` command
```
zigmod init [name] [entry_file]
```

- `[name]` defaults to the name of the folder you run the program in. It will also remove `zig-` from the start of the directory name by default if is prefixed by that.
- `[entry_file]` defaults to `src/main.zig`
- This command will create a `zig.mod` file in the root of your project. It is in yaml syntax.

<!--
### `add` command
```
zigmod add <type> <path>
```

- `<type>` is the type of package we're adding.
- `<path>` is the URL to the package you'd like to include.
-->

#### Available types
- `git`
- `hg`

### `fetch` command
```
zigmod fetch
```

- This command takes no parameters and will generate a `deps.zig` in the root of your project.
- `deps.zig` should not be checked into your source control.

### Adding `deps.zig` to `build.zig`
```diff
const Builder = @import("std").build.Builder;
+const deps = @import("./deps.zig");

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});

    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zigmod", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
+   deps.addAllTo(exe);
    exe.install();
```

## Prior Art
- https://golang.org/ref/mod#go-mod-file
- https://github.com/mattnite/zkg
- https://github.com/MasterQ32/LoLa

## Contact
- hello@nektro.net
- https://twitter.com/nektro

## License
MIT
