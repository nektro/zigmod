# Zigmod Tutorial

This guide will go over the various common workflows done while using Zigmod as well as how its design goals fit into them.

## Initialize a new project
To get started you'll want to run through these commands.

```
git init
zig init-exe
zigmod init
```

Zigmod's init wizard will ask you if the current project is an application or a library and setup some initial properties in your `zig.mod`. However, if you do plan to have a project that is both a library to be used in other Zig projects and an application itself, don't fret. For Zigmod is able to support both of thses configurations simultaneously.

The wizard will also ask if you'd like it setup any additional metadata files such as `.gitignore` or `LICENSE` for you.

> Ref: See [`zigmod init`](./commands/init.md) for more info.
