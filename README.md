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
- Zig master
- 0.8.0-dev.1071+fdc875ed0

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

#### Available types
- `system_lib`
- `git`
- `hg`
- `http`
-->

### `fetch` command
```
zigmod fetch
```

- This command takes no parameters and will generate a `deps.zig` in the root of your project.
- `deps.zig` should not be checked into your source control.

### `sum` command
```
zigmod sum
```

- This will generate a `zig.sum` file with the blake3 hashes of your modules.
<!-- - Place that hash in the `hash: blake-<hash>` property of a dependency to be able to check it with `verify`. -->

### Adding `deps.zig` to `build.zig`
```diff
const std = @import("std");
const Builder = std.build.Builder;
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

### Example
```yml
id: t5ch3nfmdaa25ndlch7ucz7yztq8n1iaanv2d7iwiw4q5n65
name: my_app
main: src/main.zig
dependencies:
- src: git https://github.com/Hejsil/zig-clap
- src: git https://github.com/alexnask/ctregex.zig
  # ctregex.zig doesn't have a zig.mod file so we can manually
  # define its entry point. this can also be used generally to
  # override any attribute we want in this dependency.
  name: ctregex
  main: ctregex.zig
```

### `zig.mod` Reference
| Name | Type | Note | Description |
|------|------|------|-------------|
| `name` | `string` | required | The value users will put into `@import` |
| `main` | `string` | required | The `.zig` entry point into your package |
| `c_include_dirs` | `[]string` | | A list of relative paths to directories with `.h` files |
| `c_source_flags` | `[]string` | | A list of clang flags to pass to each of the `.c` files in `c_source_files` |
| `c_source_files` | `[]string` | | A list of relative paths to `.c` files to compile along with project |
| `dependencies` | `[]Dep` | | An array of dependency objects |

#### Dep object
| Name | Type | Note | Description |
|------|------|------|-------------|
| `type` | `string` | required, enum | One of `system_lib`, `git`, `hg`, `http` |
| `path` | `string` | required | URL/path to this dependency. depends on the type |
| `src` | `string` | Shorthand for the format `type path`. |
| `version` | `string` | only on some types | pin this dependency at a specific version |
| `only_os` | `string` | | comma separated list of OS names to add this Dep to |
| `except_os` | `string` | | comma separated list of OS names to exclude this Dep from |

- `name`, `main`, `c_include_dirs`, `c_source_flags`, `c_source_files`, can be overwritten as well.
- `type.git` supports version pinning by `branch-XX`, `tag-XX`, and `commit-XX`.
- `type.http` supports version checking by `blake3-XX`, `sha256-XX`, and `sha512-XX`.

## Prior Art
- https://golang.org/ref/mod#go-mod-file
- https://github.com/mattnite/zkg
- https://github.com/MasterQ32/LoLa

## Contributors
- https://github.com/nektro
- https://github.com/truemedian

## Contact
- hello@nektro.net
- https://twitter.com/nektro

## License
MIT
