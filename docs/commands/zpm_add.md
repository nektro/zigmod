## `zpm add` command
```
zigmod zpm add <name>
```

- `<name>` is required and will pull the corresponding package from https://zpm.random-projects.net/ and add it to your `zig.mod`.
- Since zpm is not native to Zigmod is will also manually define the `name` and `main` attributes based on the zpm data. Normally, if the source you reference contains a `zig.mod` file in its root, those fields are not required to defined by the dependent.

For example running `zigmod zpm add apple_pie` will append the following to your `zig.mod`:
```yml
  - src: git https://github.com/Luukdegram/apple_pie
    name: apple_pie
    main: src/apple_pie.zig
```
