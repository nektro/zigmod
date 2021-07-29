## `init` command
```
zigmod init [name] [entry_point]
```

This command will generate a `zig.mod` file and place it in the current directory. `[name]` and `[entry_point]` can be used to override the default values. `[name]` defaults to the name of the current directory, optionally removing a `zig-` prefix from it. `[entry_point]` defaults to either `src/lib.zig` or `src/main.zig` in that order.

The resulting file will look something like this:

```yml
id: e8bx53yvuyhaudzhvoh16bov9ond5a5tp1zk76aflwtwsea7
name: hello
main: src/main.zig
dependencies:
```

- `id` is a randomly generated identifier that will uniquely identify your project coming from different versions or sources.
- `name` is the string other developers will `@import` your package with.
- `main` is the root Zig file of your package.
- `dependencies` is a list that we'll add to later.

Check out the [`zig.mod` reference](./../zig.mod.md) for more info.

Also check out `zigmod`'s own `zig.mod` for a useful example: https://github.com/nektro/zigmod/blob/master/zig.mod.

## Screenshot
![image](https://user-images.githubusercontent.com/5464072/127482415-15ff2f0c-4564-4d3c-9157-f0b7b588eec4.png)
