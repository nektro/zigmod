# Zigmod Documentation

Zigmod is a prototype package manager for the Zig programming language.

You can learn more about Zig here:
- https://ziglang.org/
- https://github.com/ziglang/zig

The rest of this documentation will assume you already have Zig installed.

As Zig is still in development itself, if you plan to contribute to Zigmod you will need a master download of Zig. Those can be obtained from https://ziglang.org/download/#release-master.

The earliest Zig release this Zigmod was verified to work with is `0.11.0-dev.1898+1a4a0b5e9`.

## Download
You may download a precompiled binary from https://github.com/nektro/zigmod/releases or build the project from source.

### Build Zigmod from source
```
$ git clone https://github.com/nektro/zigmod
$ cd zigmod
$ zig build
```

## Getting Started

Check here for the [full command reference](./commands/).

Check here for the [`zigmod.yml` reference](./zig.mod.md).

Check here for the [`deps.zig` reference](./deps.zig.md).

There is now also a tutorial-style guide that goes over various use cases that Zigmod provides and caters to. It is [available here](tutorial.md).

### A new project
Create a new directory for your project and run these commands to get started:
```
$ git init
$ zig init-exe
$ zigmod init
```

You will also want to add `/.zigmod` and `/deps.zig` to your `.gitignore`.

Then run `zigmod fetch`. After that you will be ready to integrate Zigmod with your existing `build.zig` which you can learn how to do [here](commands/fetch.md).

## Principles
Zigmod is but a prototype and not the official Zig package manager. As such I wanted to lay out some of the guiding principles learned/used when making the project. You can find that document [here](./principles.md).

## Contact
- https://github.com/nektro/zigmod/issues
- hello@nektro.net
- https://twitter.com/nektro

## License
MIT
