# `zigmod` Documentation

Zigmod is a prototype package manager for the Zig programming language.

You can learn more about Zig here:
- https://ziglang.org/
- https://github.com/ziglang/zig

The rest of this documentation will assume you already have Zig installed.

As Zig is still in development itself, if you plan to contribute to Zigmod you will need a master download of Zig. Those can be obtained from https://ziglang.org/download/#release-master. The most recent release Zigmod was verified to work with is `0.8.0-dev.1127+6a5a6386c`.

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
Zigmod is but a prototype and not the official Zig package manager. As such I wanted to lay out some of the guiding principles learned/used when making the project. You can find that documen [here](./principles.md).
