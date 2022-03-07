## `ci` command
```
zigmod ci
```

- This command takes no parameters and will do almost exactly the same thing as the [`fetch`](./fetch.md) command, except it will read version strings from your `zigmod.lock` file instead of from dependencies' `zigmod.yml` definitions.
- Inspired by the [`npm ci`](https://docs.npmjs.com/cli/ci.html) command.
- Enables [Reproducible builds](https://reproducible-builds.org/).
- Often used in Continuous Integration environments.
