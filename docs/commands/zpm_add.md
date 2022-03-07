## `zpm add` command
```
zigmod zpm add <name>
```

- `<name>` is required and will pull the corresponding package from https://zpm.random-projects.net/ and add it to your `zigmod.yml`.
- Since zpm is not native to Zigmod is will also manually define the `name` and `main` attributes based on the zpm data. Normally, if the source you reference contains a `zigmod.yml` file in its root, those fields are not required to defined by the dependent.

For example running `zigmod zpm add apple_pie` will append the following to your `zigmod.yml`:
```yml
  - src: git https://github.com/Luukdegram/apple_pie
```
